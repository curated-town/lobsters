# typed: false

if Rails.env.production?

  ActionMailer::Base.smtp_settings = {
    address: ENV.fetch("SMTP_HOST", "127.0.0.1"),
    port: Integer(ENV.fetch("SMTP_PORT", 25)),
    domain: Rails.application.domain,
    authentication: :login,
    enable_starttls_auto: (ENV["SMTP_STARTTLS_AUTO"] == "true"),
    ssl: true,
    user_name: ENV.fetch("SMTP_USERNAME", ""),
    password: ENV.fetch("SMTP_PASSWORD", ""),
    return_response: true
  }
end
