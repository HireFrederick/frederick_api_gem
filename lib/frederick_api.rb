# frozen_string_literal: true

# Third-party libs
require 'json_api_client'
require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

# FrederickAPI libs
require 'frederick_api/configuration'
require 'frederick_api/v2/errors/errors'
require 'frederick_api/v2/helpers/has_many'
require 'frederick_api/v2/helpers/paginator'
require 'frederick_api/v2/helpers/query_builder'
require 'frederick_api/v2/helpers/requestor'
require 'frederick_api/v2/resource'
require 'frederick_api/v2/public_resource'

require 'frederick_api/v2/user'
require 'frederick_api/v2/location'

# Public resources
require 'frederick_api/v2/business_category'

# Core resources
require 'frederick_api/v2/automation'
require 'frederick_api/v2/communication_content'
require 'frederick_api/v2/contact'
require 'frederick_api/v2/contact_property'
require 'frederick_api/v2/contact_list'
require 'frederick_api/v2/contact_type'
require 'frederick_api/v2/interaction'
require 'frederick_api/v2/role'

# Namespace for all Frederick API client methods/classes
module FrederickAPI
end
