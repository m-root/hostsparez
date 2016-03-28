require 'rubygems'
require 'prawn'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :time_out_jobs do
  accepted_jobs = Job.where("status = ?", "available")
  accepted_jobs.each do |accepted_job|
    if accepted_job.is_time_out == false
      diff = ((Time.now - accepted_job.pick_up_time) / 3600).round
      puts "diffdiffdiffdiffdiffdiffdiffdiffdiff", diff
      if diff > 12
        puts "diffdiffdiffdiffdiffdiffdiffdiffdiffIIIIIIIIIIII", diff
        send_job_notification(accepted_job.customer, "No one has accepted Your request. Package ID:#{accepted_job.job_code}", accepted_job)
        UserMailer.time_out_job(accepted_job).deliver
        accepted_job.update_attribute("is_time_out", true)
      end
    end
  end

end

def send_job_notification(user, message, job)
  puts "DEVICE TOKEN", user.device_token.inspect
  notification = Houston::Notification.new(:device => user.device_token)
  notification.badge = 0
  notification.sound = "sosumi.aiff"
  notification.content_available = true
  notification.custom_data = {:offer_id => job.id, :status => job.status, :code => job.job_code}
  notification.alert = message

  certificate = File.read("config/ziply-userProduction.pem")
  pass_phrase = "push"
  connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
  connection.open
  connection.write(notification.message)
  connection.close
end


