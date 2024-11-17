if Rails.env.production?
  Lobsters::Application.config.middleware.use ExceptionNotification::Rack,
    :ignore_exceptions => [
      "ActionController::UnknownFormat",
      "ActionController::BadRequest",
      "ActionDispatch::Http::MimeNegotiation::InvalidType",
      "ActionDispatch::RemoteIp::IpSpoofAttackError",
    ] + ExceptionNotifier.ignored_exceptions,
    :email => {
      :email_prefix => "[#{ENV['LOBSTER_SITE_NAME']}] ",
      :sender_address => ENV['EXCEPTION_SENDER_ADDRESS'],
      :exception_recipients => ENV['EXCEPTION_RECIPIENTS']&.split(','),
    }

  Pushover.API_TOKEN = ENV['PUSHOVER_API_TOKEN']
  Pushover.SUBSCRIPTION_CODE = ENV['PUSHOVER_SUBSCRIPTION_CODE']
  DiffBot.DIFFBOT_API_KEY = ENV['DIFFBOT_API_KEY']
  Github.CLIENT_ID = ENV['GITHUB_CLIENT_ID']
  Github.CLIENT_SECRET = ENV['GITHUB_CLIENT_SECRET']

  # mastodon bot posting setup
  Mastodon.INSTANCE_NAME = ENV['MASTODON_INSTANCE_NAME']
  Mastodon.BOT_NAME = ENV['MASTODON_BOT_NAME']
  Mastodon.CLIENT_ID = ENV['MASTODON_CLIENT_ID']
  Mastodon.CLIENT_SECRET = ENV['MASTODON_CLIENT_SECRET']
  Mastodon.TOKEN = ENV['MASTODON_TOKEN']
  Mastodon.LIST_ID = ENV['MASTODON_LIST_ID']

  BCrypt::Engine.cost = ENV.fetch('BCRYPT_COST', 12)
  
  Keybase.DOMAIN = Rails.application.domain
  Keybase.BASE_URL = ENV.fetch('KEYBASE_BASE_URL') { 'https://keybase.io' }
  
  ActionMailer::Base.delivery_method = ENV.fetch('MAILER_DELIVERY_METHOD', :sendmail).to_sym

  class << Rails.application
    def allow_invitation_requests?
      ENV.fetch('ALLOW_INVITATION_REQUESTS', 'false') == 'true'
    end

    def allow_new_users_to_invite?
      ENV.fetch('ALLOW_NEW_USERS_TO_INVITE', 'true') == 'true'
    end

    def domain
      ENV['LOBSTER_HOSTNAME']
    end

    def name
      ENV['LOBSTER_SITE_NAME']
    end

    def ssl?
      ENV.fetch('FORCE_SSL', 'true') == 'true'
    end
  end

  Rails.application.routes.default_url_options[:host] = Rails.application.domain
end
