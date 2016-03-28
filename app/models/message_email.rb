#class MessageEmail < Struct.new(:message, :protocol, :host, :message_status)
class MessageEmail < Struct.new(:message, :protocol, :host, :message_status, :message_to)

  #def perform
  #  if message_status == 'new_message_from_driver'
  #    UserMailer.new_message_from_driver(message, protocol, host).deliver
  #    if message.receiver.device_token.present?
  #      send_job_notification(message.receiver, "Driver send you message")
  #    end
  #  end
  #end

  def perform
    if message_status == 'new_message_from_driver'
      if  message_to == "sender"
        UserMailer.new_message_from_driver(message, protocol, host).deliver
        if message.receiver.device_token.present?
          send_job_notification(message.receiver, "Driver send you message")
        end
      else
        if message.job.recipient_email.present?
          UserMailer.new_message_from_driver_for_recipient(message, protocol, host).deliver
        end
      end
    end
  end

  def send_job_notification(user, message)
    puts "DEVICE TOKEN", user.device_token.inspect
    notification = Houston::Notification.new(:device => user.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:user_id => user.id}
    notification.alert = message

    certificate = File.read("config/ziply-userProduction.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

end


