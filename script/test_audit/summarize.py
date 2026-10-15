#!/usr/bin/env python3
"""Builds the test-audit summary from the artifacts of one 'Test audit' workflow run.

Usage: python3 script/test_audit/summarize.py <audit-parts dir> <coverage-merged dir>
Prints Markdown to stdout and writes audit-summary.json in the current directory.

Layer rule (shared by the workflow and this script): a spec file is "integration" when any
folder in its path is one of controllers, requests, routing, views, mailers, integration,
features, system; otherwise it is "unit". features/*.feature (Cucumber) is "end-to-end".
"""
import collections
import glob
import json
import os
import re
import sys

parts, merged = sys.argv[1], sys.argv[2]
INTEGRATION_DIRS = {"controllers", "requests", "routing", "views", "mailers", "integration", "features", "system"}
out = {}


def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception as e:  # a shard that crashed leaves an empty or partial file; report, don't die
        print(f"WARNING: could not read {path}: {e}", file=sys.stderr)
        return None


def layer_of(path):
    segs = path.replace("./", "").split("/")
    return "integration" if any(s in INTEGRATION_DIRS for s in segs[1:-1]) else "unit"


meta_path = os.path.join(parts, "meta.json")
meta = load(meta_path) if os.path.exists(meta_path) else {}
out["meta"] = meta

# --- RSpec inventory (dry run) ----------------------------------------------
rspec = {"inventory_total": None, "by_dir": {}, "by_layer": {}, "from_shared_examples": 0}
inv_path = os.path.join(parts, "rspec-inventory.json")
if os.path.exists(inv_path):
    inv = load(inv_path) or {"summary": {"example_count": None}, "examples": []}
    rspec["inventory_total"] = inv["summary"]["example_count"]
    rspec["pending_in_inventory"] = inv["summary"].get("pending_count", 0)
    by_dir, by_layer, shared = collections.Counter(), collections.Counter(), 0
    for ex in inv["examples"]:
        host = ex["id"].split("[")[0]  # file the example runs from (shared examples report the defining file in file_path)
        if host != ex["file_path"]:
            shared += 1
        segs = host.replace("./", "").split("/")
        by_dir["/".join(segs[1:-1]) or "(root)"] += 1
        by_layer[layer_of(host)] += 1
    rspec["by_dir"] = dict(by_dir.most_common())
    rspec["by_layer"] = dict(by_layer)
    rspec["from_shared_examples"] = shared

# --- RSpec executed results per shard ---------------------------------------
executed = collections.defaultdict(collections.Counter)
failed_examples = []
for p in sorted(glob.glob(os.path.join(parts, "rspec-*-*.json"))):
    name = os.path.basename(p)[len("rspec-"):-len(".json")]
    group = name.rsplit("-", 1)[0]
    data = load(p)
    if not data:
        continue
    s = data["summary"]
    executed[group]["examples"] += s["example_count"]
    executed[group]["failures"] += s["failure_count"]
    executed[group]["pending"] += s.get("pending_count", 0)
    executed[group]["shards"] += 1
    for ex in data["examples"]:
        if ex["status"] == "failed":
            failed_examples.append(ex["id"] + " " + ex["full_description"])
rspec["executed"] = {k: dict(v) for k, v in executed.items()}
rspec["failed_examples"] = failed_examples
out["rspec"] = rspec

# --- Cucumber ----------------------------------------------------------------
def scenarios(doc):
    for feat in doc:
        for el in feat.get("elements", []):
            if el.get("type") != "scenario":
                continue
            steps = el.get("steps", [])
            statuses = [st.get("result", {}).get("status") for st in steps]
            hooks = [h.get("result", {}).get("status") for h in el.get("before", []) + el.get("after", [])]
            if "failed" in statuses or "failed" in hooks:
                status = "failed"
            elif statuses and all(s == "passed" for s in statuses):
                status = "passed"
            elif "undefined" in statuses or "pending" in statuses:
                status = "pending"
            else:
                status = "skipped"
            yield feat["uri"], el.get("keyword"), el.get("name"), el.get("line"), status


cuke = {}
ex_rows = []
for p in sorted(glob.glob(os.path.join(parts, "cucumber-[0-9]*.json"))):
    doc = load(p)
    if doc:
        ex_rows.extend(scenarios(doc))
if ex_rows:
    st = collections.Counter(r[4] for r in ex_rows)
    cuke = {"executed": {"scenarios": len(ex_rows), **dict(st)},
            "features": len({r[0] for r in ex_rows}),
            "by_area": dict(collections.Counter(r[0].split("/")[1] if r[0].count("/") > 1 else "(root)" for r in ex_rows).most_common()),
            "failed_scenarios": sorted(f"{r[0]}:{r[3]} {r[2]}" for r in ex_rows if r[4] == "failed")}
if not ex_rows:
    for p in sorted(glob.glob(os.path.join(parts, "cucumber-[0-9]*.log"))):
        txt = open(p, errors="replace").read()
        m = re.findall(r"(\d+) scenarios? \(([^)]*)\)", txt)
        if m:
            total = int(m[-1][0]); parts_ = dict((k.strip(), int(v)) for v, k in re.findall(r"(\d+) (\w+)", m[-1][1]))
            cuke.setdefault("executed", {"scenarios": 0})
            cuke["executed"]["scenarios"] += total
            for k, v in parts_.items():
                cuke["executed"][k] = cuke["executed"].get(k, 0) + v
            cuke["source"] = "cucumber progress summary line (JSON formatter unavailable in this Cucumber version)"
ff = os.path.join(parts, "feature-files.txt")
if os.path.exists(ff):
    all_files = {l.strip() for l in open(ff) if l.strip()}
    cuke["feature_files_in_repo"] = len(all_files)
    if ex_rows:
        cuke["feature_files_not_executed"] = sorted(all_files - {r[0] for r in ex_rows})
out["cucumber"] = cuke

# --- JavaScript suites (Jasmine / Teaspoon / Jest logs) ----------------------
js = {}
for p in sorted(glob.glob(os.path.join(parts, "js-*.log"))):
    suite = os.path.basename(p)[len("js-"):-len(".log")]
    txt = open(p, errors="replace").read()
    m = re.findall(r"(\d+) (?:examples?|specs?), (\d+) failures?", txt)
    if m:
        js[suite] = {"tests": int(m[-1][0]), "failures": int(m[-1][1])}
        continue
    m = re.search(r"Tests:\s+(?:(\d+) failed, )?(?:(\d+) skipped, )?(\d+) passed, (\d+) total", txt)
    if m:
        js[suite] = {"tests": int(m.group(4)), "failures": int(m.group(1) or 0), "passed": int(m.group(3))}
    else:
        js[suite] = {"tests": None, "failures": None, "note": "no summary line found"}
    # Istanbul text table (older Jest): "All files | stmts | branch | funcs | lines |"
    t = re.search(r"^All files\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)", txt, re.M)
    if t and "jest_coverage" not in js:
        js["jest_coverage"] = {"statements": float(t.group(1)), "branches": float(t.group(2)), "functions": float(t.group(3)), "lines": float(t.group(4))}
jest_cov = os.path.join(parts, "coverage-summary.json")
if os.path.exists(jest_cov) and load(jest_cov):
    t = load(jest_cov).get("total", {})
    js["jest_coverage"] = {k: t[k]["pct"] for k in ("lines", "branches", "functions", "statements") if k in t}
out["javascript"] = js

# --- Merged coverage per layer ---------------------------------------------
cov = {}
for g in ("unit", "integration", "cucumber", "all"):
    p = os.path.join(merged, g, "summary.json")
    if os.path.exists(p):
        cov[g] = load(p)
out["coverage"] = cov

stack_path = os.path.join(parts, "test-stack.txt")
if os.path.exists(stack_path):
    out["test_stack"] = [l.strip(" *\n") for l in open(stack_path) if l.strip()]
assign_path = os.path.join(parts, "spec-files-layers.tsv")
if os.path.exists(assign_path):
    out["spec_files_by_layer"] = dict(collections.Counter(l.split("\t")[0] for l in open(assign_path) if l.strip()))

with open("audit-summary.json", "w") as f:
    json.dump(out, f, indent=2)

# --- Markdown ---------------------------------------------------------------
def pct(d):
    return f"{d['percent']}% ({d['covered']} / {d['total']})" if d else "n/a"


print(f"# Test audit: {meta.get('repo', '?')} @ `{meta.get('sha', '?')[:9]}`")
print(f"Run: {meta.get('run_url', '?')} (attempt {meta.get('run_attempt', '?')}, label `{meta.get('label', '')}`, cucumber opts `{meta.get('cucumber_opts', '')}`)")
print()
print("## Test cases")
print("| Layer | Suite | Defined (dry run) | Executed | Failed | Pending |")
print("|---|---|---|---|---|---|")
for layer in ("unit", "integration"):
    e = rspec["executed"].get(layer, {})
    print(f"| {layer} | RSpec | {rspec['by_layer'].get(layer, 0)} | {e.get('examples', 0)} | {e.get('failures', 0)} | {e.get('pending', 0)} |")
if cuke.get("executed"):
    e = cuke["executed"]
    print(f"| end-to-end | Cucumber | {e['scenarios']} (executed set) | {e['scenarios']} | {e.get('failed', 0)} | {e.get('pending', 0) + e.get('skipped', 0)} |")
for suite, v in js.items():
    if suite == "jest_coverage":
        continue
    print(f"| JS | {suite} | – | {v.get('tests', '?')} | {v.get('failures', '?')} | – |")
if rspec.get("from_shared_examples"):
    print(f"\n{rspec['from_shared_examples']} RSpec examples come from shared example groups, attributed to the spec file that includes them.")
if cuke.get("feature_files_not_executed"):
    print(f"\n**Warning:** feature files not executed by any shard: {', '.join(cuke['feature_files_not_executed'])}")
total_inv = rspec.get("inventory_total")
total_exec = sum(v.get("examples", 0) for v in rspec["executed"].values())
if total_inv is not None:
    print(f"\nRSpec check: dry-run inventory {total_inv} vs executed {total_exec} -> {'MATCH' if total_inv == total_exec else 'MISMATCH'}")
print()
print("## Code coverage (SimpleCov, line and branch, every app/ and lib/ file counted)")
common = cov.get("all", {}).get("line", {}).get("total")
print("| Layer | Line coverage | Branch coverage | Files | Line % over common denominator |")
print("|---|---|---|---|---|")
for g, label in (("unit", "unit (RSpec)"), ("integration", "integration (RSpec)"), ("cucumber", "end-to-end (Cucumber)"), ("all", "combined")):
    c = cov.get(g)
    if not c:
        continue
    norm = f"{100 * c['line']['covered'] / common:.2f}%" if common else "n/a"
    print(f"| {label} | {pct(c.get('line'))} | {pct(c.get('branch'))} | {c.get('files_measured', '?')} | {norm} |")
if common:
    print(f"\nCommon denominator = {common} relevant lines in {cov['all'].get('files_measured')} app/ and lib/ files (union of all layers).")
if js.get("jest_coverage"):
    jc = js["jest_coverage"]
    print(f"\nJavaScript (Jest/Istanbul, separate tool, not merged): lines {jc.get('lines')}%, branches {jc.get('branches')}%, functions {jc.get('functions')}%.")
print()
if rspec["failed_examples"] or cuke.get("failed_scenarios"):
    print("## Failures in this run")
    for x in rspec["failed_examples"]:
        print(f"- RSpec: {x}")
    for x in cuke.get("failed_scenarios", []):
        print(f"- Cucumber: {x}")
    print()
print("## RSpec examples by folder")
print(", ".join(f"{k} {v}" for k, v in rspec["by_dir"].items()) or "n/a")
if cuke.get("by_area"):
    print()
    print("## Cucumber scenarios by area")
    print(", ".join(f"{k} {v}" for k, v in cuke["by_area"].items()))
print()
print("## Test stack")
print(", ".join(out.get("test_stack", [])) or "n/a")
