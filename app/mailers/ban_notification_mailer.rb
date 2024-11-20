# typed: false

class BanNotificationMailer < ApplicationMailer
  def notify(user, banner, reason)
    @banner = banner
    @reason = reason

    mail(
      from: "#{@banner.username} <#{ENV['EXCEPTION_SENDER_ADDRESS']}>",
      replyto: "#{@banner.username} <#{@banner.email}>",
      to: user.email,
      subject: "[#{Rails.application.name}] You have been banned"
    )
  end
end
