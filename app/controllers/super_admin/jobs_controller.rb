class SuperAdmin::JobsController < SuperAdmin::SuperAdminController
  def index
    @active_jobs = Job.where("status = ? or status = ? or status = ? or status = ?", "accepted", "picked", "available", "canceled").order("created_at desc")
    @all_recent_jobs = Job.where(:status => "delivered").order("created_at desc")
    @recent_jobs = @all_recent_jobs
  end

  def edit

  end

  def cancel_order
    @job = Job.find_by_id(params[:id])
    if @job.driver.present?
      send_notification_to_drives(@job,@job.driver.device_token, "Super Admin Cancel Your Job")
      UserMailer.super_admin_cancel_job(@job, request.protocol, request.host).deliver
    end
    @job.update_attributes(:status => "canceled")
    flash[:notice] = "Job successfully Cancelled"
    redirect_to super_admin_jobs_path
  end

  def cancel_driver
    @job = Job.find_by_id(params[:id])
    if @job.status == "accepted" or @job.status == "picked"
     @job.update_attributes(:status => "available", :driver_id => nil)
    end
    if @job.driver.present?
     UserMailer.super_admin_cancel_job(@job, request.protocol, request.host).deliver
    end
    push_notify_drivers = @job.get_push_notify_drivers(@job)
    email_notify_drivers = @job.get_email_notify_drivers(@job)
    puts "PPP",push_notify_drivers.size
    puts "PPPEEE",email_notify_drivers.size
    emails = JobEmail.new(@job, @transaction, email_notify_drivers, push_notify_drivers, request.protocol, request.host_with_port)
    Delayed::Job.enqueue(emails)
    flash[:notice] = "Driver Successfully Cancelled"
    redirect_to super_admin_jobs_path
  end

  def show
    @job = Job.find_by_id(params[:id])
    @job_tax = @job.amount/100 * Preferences.first.package_tax_percentage
    if @job.status == 'delivered' or @job.status == 'picked' or @job.status == 'accepted'
      @driver_rating_whole, @driver_rating_part = @job.driver.driver_rating
    end
    @location = ""
    unless @job.driver.blank?
      unless @job.driver.travelling_times.blank?
         travelling_time = @job.driver.travelling_times.sort_by{|c| c.id}.last
         str_lat_lng =  travelling_time.latitude.to_s + "," + travelling_time.longitude.to_s
        geo = Geocoder.search(str_lat_lng)
         @location = geo[0].address_components[0]["long_name"]
      end
    end
  end

  private

  def send_notification_to_drives(job, device_token, message)
    device_token.present?
    notification = Houston::Notification.new(:device => device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:id => job.id, :type => job.class.to_s, :time => Time.now}
    notification.alert = message
    certificate = File.read("config/production_driver.pem")
    #certificate = File.read("config/driver_certificate.pem")
    #pass_phrase = "password"
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

end
