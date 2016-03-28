require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Ziply
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    #config.time_zone = 'Central Time (US & Canada)'

    config.autoload_paths += %W(#{config.root}/lib)
    config.assets.precompile += %w( ckeditor/* )

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    #config.assets.initialize_on_precompile = true
    #config.time_zone = 'Pacific Time (US & Canada)'

    #config.time_zone = 'America/Los_Angeles'
    #config.time_zone = 'Asia/Karachi'
    #config.time_zone = 'America/Los_Angeles'

#    config.time_zone = 'Asia/Karachi'

    #config.autoload_paths += %W(#{config.root}/lib)
    #config.autoload_paths += Dir["#{config.root}/lib/**/"]
    #config.assets.enabled = true
    #config.assets.paths << "#{Rails.root}/app/assets/boot_assets/global/img"
    #config.assets.initialize_on_precompile = false

    #Dir.glob("#{Rails.root}/app/assets**/").each do |path|
    #  config.assets.paths << path
    #end

    config.encoding = "utf-8"

    config.filter_parameters += [:password]

    config.active_support.escape_html_entities_in_json = true

    config.active_record.whitelist_attributes = true

    config.assets.enabled = true

    config.assets.version = '1.0'

    initializer 'setup_asset_pipeline', :group => :all  do |app|
      # We don't want the default of everything that isn't js or css, because it pulls too many things in
      app.config.assets.precompile.shift

      # Explicitly register the extensions we are interested in compiling
      app.config.assets.precompile.push(Proc.new do |path|
        File.extname(path).in? [
                                   '.html', '.erb', '.haml',                 # Templates
                                   '.png',  '.gif', '.jpg', '.jpeg',         # Images
                                   '.eot',  '.otf', '.svc', '.woff', '.ttf', # Fonts
                               ]
      end)
    end

  end
end
