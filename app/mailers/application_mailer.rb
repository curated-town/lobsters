# typed: false

class ApplicationMailer < ActionMailer::Base
  default from: "#{Rails.application.class.module_parent_name} <#{ENV['EXCEPTION_SENDER_ADDRESS']}>"
end
