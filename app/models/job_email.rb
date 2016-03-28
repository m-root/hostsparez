class JobEmail < Struct.new(:job, :transaction, :email_notify_drivers, :push_notify_drivers, :protocol, :host)

  def perform
    #UserMailer.user_order_received(job, protocol, host).deliver
    #commented for now   UserMailer.user_order_received(job, protocol, host).deliver
    unless push_notify_drivers.blank?
      token_array = []
      push_notify_drivers.each do |token|
        puts "TTTTTTTTTTTTTTTTTTTTTTTT", token.inspect
        unless token_array.include?(token)
          token_array << token
          send_notification_to_drives(job, token, "New job is open")
        end
      end
    end
    #unless email_notify_drivers.blank?
    #  UserMailer.new_job_open(job, email_notify_drivers, protocol, host).deliver
    #end
    #send_sms_and_email(job)
  end

  def send_notification_to_drives(job, device_token, message)
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    return unless device_token.present?
    notification = Houston::Notification.new(device: device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:id => job.id, :type => job.class.to_s, :time => Time.now}
    notification.alert = message
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

  def send_sms_and_email(job)
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@FFFFFFFFFFFFFFFFFFF"
    if job.receiver_location.contact_method_type == 1
      begin
        account_sid = 'AC13a41cc74dc4be4df7ea0412260dca09'
        auth_token = 'd58dc082060bda19d97ad9352840b7f0'
        twilio_phone_number = "989-252-7117"
        @twilio_client = Twilio::REST::Client.new account_sid, auth_token
        @twilio_client.account.sms.messages.create(
            :from => "+1#{twilio_phone_number}",
            :to => "+1#{job.recipient_phone}",
            :body => "This is an message. It gets sent to #{16105557069}"
        )
      rescue Exception => exc

      end
    else
      begin
        UserMailer.recipient_order(job, protocol, host).deliver
      rescue Exception => exc

      end
    end

  end

end


