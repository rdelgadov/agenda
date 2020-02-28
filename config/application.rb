require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Achs
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.beginning_of_week = :monday
    config.time_zone = "Santiago"
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.eager_load_paths += %W(#{config.root}/lib/)
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]    # Settings in config/environments/* take precedence over those specified here.
    config.active_job.queue_adapter = :delayed_job
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
