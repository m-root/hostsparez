class UserMailer < ActionMailer::Base
  default from: "adoorn.test@gmail.com"
  #"#{request.protocol}#{request.host_with_port}"

  def user_order_received (job, protocol, host)
    @app_url = "#{protocol}#{host}"
    @user = job.customer
    @job = job
    mail(:to => @user.email,
         :subject => "Your order has been received!")
  end

  def confirm_driver(user, protocol, host, password)
    @app_url = "#{protocol}#{host}"
    @password = password
    @user = user
    @host = host
    @protocol = protocol
    mail(:to => @user.email, :subject => 'Welcome to Hostspaerez')
  end

  def invite_complete(user, user_password)
    @user = user
    @user_password = user_password
    @host = default_url_options[:host]
    @url = "http://#{@host}/"
    mail(:to => user.email, :subject => "Here's Your Account Information")
  end

  def welcome_customer(user, protocol, host)
    @app_url = "#{protocol}#{host}"
    @user = user
    mail(:to => user.email, :subject => "Welcome to Ziply")
  end

  def new_job_open (job, drivers, protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = job
    #mail(:to => drivers.map { |driver| driver.email },
    emails_array = ["support @goziply.com", "barry @goziply.com"]
    mail(:to => emails_array.map { |email| email },
         :bcc => "support@goziply.com",
         :subject => "New Job Open in your area")
  end

  def job_accepted (job, driver, protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = job
    @driver = driver
    mail(:to => @job.customer.email,
         :bcc => "support@goziply.com",
         :subject => "Your job has been accepted")
  end

  def job_picked (job, driver, protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = job
    @driver = driver
    mail(:to => @job.customer.email,
         :bcc => "support@goziply.com",
         :subject => "Your Ziply order ##{@job.job_code} has been picked up")
  end

  def job_delivered (job, driver, protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = job
    @driver = driver
    mail(:to => @job.customer.email,
         :bcc => "support@goziply.com",
         :subject => "Your Ziply order ##{@job.job_code} has been completed")
  end

  def welcome_driver request
    @request = request
  end

  def file_claim(file_claim, protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = file_claim.job
    @user = file_claim.user
    @file_claim = file_claim
    mail(:to => "support@goziply.com",
         :subject => "New File Claim!")
  end

  def ziply_update(request, email, protocol, host)
    @app_url = "#{protocol}#{host}"
    @email = email
    mail(:to => @email,
         :subject => "Ziply driver update request!")
  end

  def new_message_from_driver(message, protocol, host)
    @app_url = "#{protocol}#{host}"
    @message = message
    if message.receiver.email.present?
      mail(:to => message.receiver.email,
           :subject => "New Message From Driver")
    end
  end

  def new_message_from_driver_for_recipient(message, protocol, host)
    @app_url = "#{protocol}#{host}"
    @message = message
    if message.job.recipient_email.present?
      mail(:to => message.job.recipient_email,
           :subject => "New Message From Driver")
    end
  end

  def recipient_order (job, protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = job
    @email = job.recipient_email
    mail(:to => @email,
         :bcc => "support@goziply.com",
         :subject => "You have a new shipment being sent to you via Ziply.")

  end

  def contact_us (name, email,subject,message, protocol, host)
    @app_url = "#{protocol}#{host}"
    @name = name
    @email = email
    @subject = subject
    @message = message
    mail(:to => 'support@goziply.com',
         :subject => "You have a new Message")

  end

  def support_request(description,package_id,user, host, protocol)
    @app_url = "#{protocol}#{host}"
    @description = description
    @package_id = package_id
    @user = user
    mail(:to => "support@goziply.com",
         :subject => "Support Request")
  end

  def new_driver(user)
    @user = user
    @first_name = user.first_name
    @last_name = user.last_name
    @phone_number = user.profile.phone_number
    @email = user.email
    @state = user.profile.state
    mail(:to => "support@goziply.com",
         :subject => "New Driver!")
  end

  def new_coupon (coupon_code, users, protocol, host)
    @app_url = "#{protocol}#{host}"
    @coupon_code = coupon_code
    mail(:to => users.map { |user| user.email },
         :subject => "You have received a coupon code from ziply")
  end


  def confirmed_driver(first_name, last_name, email, phone,vehicle_id,protocol, host)
    vehicle = VehicleType.find_by_id(vehicle_id)
    @first_name = first_name
    @last_name = last_name
    @phone_number = phone
    @email = email
    @vehicle_name =  vehicle.name
    mail(:to => "support@goziply.com",
         :subject => "New Driver!")
  end

  def time_out_job(accepted_job)
    @job = accepted_job
    @user = accepted_job.customer
    @first_name = @user.first_name
    @last_name = @user.last_name
    @email = @user.email
    mail(:to => @email,
         :subject => "no one has accepted Your request")
  end

  def super_admin_cancel_job(job,protocol, host)
    @app_url = "#{protocol}#{host}"
    @job = job
    #mail(:to => drivers.map { |driver| driver.email },
    mail(:to => @job.driver.email,
         :bcc => "support@goziply.com",
         :subject => "Super Admin cancel your job")
  end

  def super_admin_cancel_driver(user)
    @user = user
    @first_name = user.first_name
    @last_name = user.last_name
    @phone_number = user.profile.phone_number
    @email = user.email
    @state = user.profile.state
    mail(:to => "support@goziply.com",
         :subject => "Super Admin Cancel Your registartion!")
  end

  def driver_payment_released(job)
    @app_url = "http://www.goziply.com"
    @job = job
    @driver = job.driver
    mail(:to => job.driver.email,
         :bcc => "support@goziply.com",
         :subject => "Your payment released against Ziply Delivery ##{@job.job_code}")
  end

end
