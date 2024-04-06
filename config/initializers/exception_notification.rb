require "exception_notification/rails"

ExceptionNotification.configure do |config|
  # Ignore additional exception types.
  # ActiveRecord::RecordNotFound, AbstractController::ActionNotFound and ActionController::RoutingError are already added.
  config.ignored_exceptions += %w[
    ActionController::InvalidAuthenticityToken
    ActionView::MissingTemplate
    ActionController::BadRequest
    ActionDispatch::Http::Parameters::ParseError
    ActionDispatch::Http::MimeNegotiation::InvalidType
  ]

  # Adds a condition to decide when an exception must be ignored or not.
  # The ignore_if method can be invoked multiple times to add extra conditions.
  config.ignore_if do |exception, options|
    not Rails.env.production?
  end

  config.add_notifier :email, {
    email_prefix: "[#{File.basename(pwd)}] ",
    exception_recipients: "micah@botandrose.com",
    smtp_settings: {
      address: "smtp.gmail.com",
      port: 587,
      authentication: :plain,
      user_name: "errors@botandrose.com",
      password: "4pp3rr0rs",
      ssl: nil,
      tls: nil,
      enable_starttls_auto: true,
    }
  }
end

if defined?(Rake::Application)
  Rake::Application.prepend Module.new {
    def display_error_message error
      ExceptionNotifier.notify_exception(error)
      super
    end
  }
end

