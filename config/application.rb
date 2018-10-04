require_relative 'boot'

require "rails/all"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DatabankTasks

  class TaskStatus
    PENDING = 'pending'
    PROCESSING = 'processing'
    ERROR = 'error'
    RIPE = 'ripe'
    HARVESTING = 'harvesting'
    HARVESTED = 'harvested'
  end

  class ProblemStatus
    REPORTED = 'reported'
    EXAMINED = 'examined'
    RESOLVED = 'resolved'
  end

  class PeekType
    ALL_TEXT = 'all_text'
    PART_TEXT = 'part_text'
    IMAGE = 'image'
    MICROSOFT = 'microsoft'
    PDF = 'pdf'
    LISTING = 'listing'
    NONE = 'none'
  end


  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    attr_accessor :storage_manager

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end

#establish a short cut for the Application object
Application = DatabankTasks::Application