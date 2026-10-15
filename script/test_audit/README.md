# Test audit tooling

Produces the numbers for the Marketing Suite test-suite audit from the test tools themselves,
in a CI run anyone can open and re-run. Branch-only: runs on `audit/**` branches and manual dispatch,
never on pull requests or `development-arcus`. No existing test, workflow, or application file is changed.

| Metric | Tool | Where it comes from |
|---|---|---|
| Test cases defined | `rspec --dry-run --format json` | `audit-inventory` artifact |
| Test cases executed, failed, pending | RSpec (and Cucumber) JSON formatters | `audit-rspec-*`, `audit-cucumber-*` artifacts |
| Code coverage per layer (line + branch) | SimpleCov with `.simplecov` (every `app/` and `lib/` file counted), merged with `SimpleCov.collate` | `test-audit-report` artifact, `coverage-merged/<layer>/` |
| Flakiness | Repeat the workflow on the same commit with no Cucumber retries; compare results | several run URLs |
| Test stack | `bundle list` | `audit-inventory/test-stack.txt` |

Layers are assigned by spec folder: `controllers`, `requests`, `routing`, `views`, `mailers`, `integration`,
`features`, `system` are integration; everything else under `spec/` is unit. `features/` (Cucumber) is end-to-end.

If `Gemfile.audit` exists, SimpleCov was not in this repo's Gemfile; the workflow installs it through that
overlay with the real lockfile copied first, so no existing gem version changes.

Run it: Actions > Test audit > Run workflow. Leave `cucumber_opts` empty for flakiness runs.
