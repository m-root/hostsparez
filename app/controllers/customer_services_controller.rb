class CustomerServicesController < ApplicationController
  #include ActionView::Helpers::DateHelper
  respond_to :json
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_user!
  before_filter :check_session_create, :except => [:sign_in, :forgot_password, :new_package]
  before_filter :check_lat_long, :only => [:get_driver_data, :get_job, :clock_in_clock_out, :sign_out, :update_driver_distance]
  include ApplicationHelper


  def sign_up
    build_resource(sign_up_params)
  end

  #Sign in function


  def sign_in
    if params[:user][:email].present? and params[:user][:password].present?
      @user = User.find_by_email(params[:user][:email])
      if @user.blank?
        render :json => {:success => "false", :errors => "Email or password is incorrect"}
      else
        if @user.status == 'active'
          if @user.customer?
            if not @user.valid_password?(params[:user][:password])
              render :json => {:success => "false", :errors => "Invalid email or password."}
            else
              unless params[:user][:device_token].blank?
                unless params[:user][:time_zone].blank?
                  @user.update_attribute(:time_zone, params[:user][:time_zone])
                  if  @user.update_attributes(:device_token => params[:user][:device_token], :device_type => params[:user][:device_type], :latitude => params[:user][:latitude], :longitude => params[:user][:longitude])
                    render :json => {:success => "true",
                                     :data => {
                                         :customer => @user.customer_json(@user),
                                         :package_sizes => Package.packages_json(),
                                         :payment_methods => @user.payment_method_json(@user)
                                     }}

                  else
                    render :json => {:success => "false", :errors => "Device token not updated"}
                  end
                else
                  render :json => {:success => "false", :errors => "Time zone is missing"}
                end
              else
                render :json => {:success => "false", :errors => "Device token missing"}
              end

            end
          else
            render :json => {:success => "false", :errors => "Email or password is incorrect"}
          end
        else
          render :json => {:success => "false", :errors => "Driver is not active by admin"}
        end
      end
    else
      render :json => {:success => "false", :errors => "Email or password is incorrect"}
    end
  end

  #Return list of customer jobs


  def update_customer_setting
    @customer_setting = @user.customer_setting
    unless @customer_setting.blank?
      if @customer_setting.update_attributes(params[:customer_setting])
        render :json => {:success => "true", :customer_setting => {:id => @customer_setting.id, :user_id => @customer_setting.user_id, :is_push_notification => @customer_setting.is_push_notification, :is_email_notification => @customer_setting.is_email_notification, :is_text_notification => @customer_setting.is_text_notification}, :message => " Customer setting successfully updated "}
      else
        render :json => {:success => "true", :message => " Customer setting was not updated "}
      end
    else
      render :json => {:success => "false", :message => " Customer setting was not found "}
    end
  end

  def get_jobs
    unless params[:user][:time_zone].blank?
      @user.update_attribute(:time_zone, params[:user][:time_zone])
      jobs = @user.customer_jobs.where("created_at >= ? and status != unavailable and status != canceled", Time.now - 1.month)
      render :json => {:success => "true",
                       :data => {
                           :jobs => jobs.blank? ? Array.new : jobs.sort_by { |j| j.created_at }.reverse.map { |j| j.customer_job_json(j) }
                       }}
    else
      render :json => {:success => "false", :message => " Time Zone missing"}
    end
  end

  def new_package
    render :json => {:success => "true",
                     :data => {
                         :package_sizes => Package.packages_json()
                     }}
  end

  #// Return packages

  def get_package_size_amount
    begin
      @package = Package.find_by_id(params[:id])
      dest_original = params[:dest_loc]
      pick_original = params[:pick_loc]
      dest_cleaned = ""
      pick_cleaned = ""
      dest_original.each_byte { |x| dest_cleaned << x unless x > 127 }
      pick_original.each_byte { |x| pick_cleaned << x unless x > 127 }
      directions = GoogleDirections.new(pick_cleaned, dest_cleaned)
      distance = directions.distance_in_miles
      if distance >= 1
        amount = distance * @package.cost_per_mile + @package.basic_fee
      else
        amount = @package.min_fare
      end
      render :json => {:success => "true", :id => @package.id, :amount => amount.round}
    rescue Exception => exc
      render :json => {:success => "false"}
    end
  end

  def save_package
    puts "PPPP", params.inspect
    puts "TTTT", params[:job][:pick_up_time].inspect
    #zip_code1 = Job.get_zip_code(params[:sender_location][:city])
    unless params[:sender_location][:zip_code].blank?
      zip_code1 = params[:sender_location][:zip_code]
    else
      zip_code1 = Job.get_zip_code(params[:sender_location][:city])
    end

    #zip_code2 = Job.get_zip_code(params[:receiver_location][:city])
    params[:job][:pick_up_time] = Time.now.utc.strftime("%m-%d-%Y %I:%M %p")
    time = Time.strptime(params[:job][:pick_up_time], '%m-%d-%Y %I:%M %p')
    params[:job][:pick_up_time] = time.strftime("%Y/%m/%d %I:%M %p")
    @job = Job.new(params[:job])
    if zip_code1.present?
      if Job.zip_code_existing(zip_code1) == true
        @send_job_location = Location.new(params[:sender_location])
        @send_job_location.contact_person = @user.email
        @receiver_job_location = Location.new(params[:receiver_location])
        unless @send_job_location.valid?
          @errors = @send_job_location.errors
          error_string = ""
          @errors.full_messages.each do |msg|
            error_string += msg
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
          return
        else
          @job.pick_up_address = @send_job_location.address
          @job.pick_up_phone = @send_job_location.contact_phone
          @job.pick_up_comment = @send_job_location.comments
        end
        unless @receiver_job_location.valid?
          @errors = @receiver_job_location.errors
          error_string = ""
          @errors.full_messages.each do |msg|
            error_string += msg
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
          return
        else
          @job.destination_address = @receiver_job_location.address
          @job.recipient_name = @receiver_job_location.contact_person
          @job.recipient_phone = @receiver_job_location.contact_phone
          @job.recipient_comment = @receiver_job_location.comments
        end
        if params[:job][:sender_location_id].blank?
          @job.sender_location_id = 1
        end
        if params[:job][:receiver_location_id].blank?
          @job.receiver_location_id = 2
        end
        unless @job.valid?
          @errors = @job.errors
          error_string = ""
          @errors.full_messages.each do |msg|
            error_string += msg
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
          return
        else
          #@job.sender_location_id = nil
          #@job.receiver_location_id = nil
        end
        if params[:job][:sender_location_id].blank?
          latitude, longitude = get_lat_long(@send_job_location.address)
          loc = Location.find_by_latitude_and_longitude_and_user_id(latitude, longitude, @send_job_location.user_id)
          if loc.present?
            @job.sender_location_id = loc.id
          else
            if @send_job_location.save
              @job.sender_location_id = @send_job_location.id
            else
              @errors = @send_job_location.errors
              error_string = ""
              @errors.full_messages.each do |msg|
                error_string += msg
              end
              render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
              return
            end
          end
        else
          if params[:sender_location][:is_active] == "1"
            @job.sender_location_id = params[:job][:sender_location_id]
            update_sender_location(params[:job][:sender_location_id])
          end
        end
        if params[:job][:receiver_location_id].blank?
          latitude, longitude = get_lat_long(@receiver_job_location.address)
          loc = Location.find_by_latitude_and_longitude_and_user_id(latitude, longitude, @receiver_job_location.user_id)
          if loc.present?
            @job.receiver_location_id = loc.id
          else
            if  @receiver_job_location.save
              @job.receiver_location_id = @receiver_job_location.id
            else
              @errors = @receiver_job_location.errors
              error_string = ""
              @errors.full_messages.each do |msg|
                error_string += msg
              end
              render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
              return
            end
          end
        else
          if params[:receiver_location][:is_active] == "1"
            @job.receiver_location_id = params[:job][:receiver_location_id]
            update_receiver_location(params[:job][:receiver_location_id])
          end
        end
        @payment_method = PaymentMethod.find_by_id(params[:payment_method_id])
        result = Braintree::CreditCard.find(@payment_method.token)
        unless result.expired?
          if @job.save
            CouponCodeUser.create(:user_id => @user.id, :job_id => @job.id, :coupon_code_id => params[:coupon_code_id])
            @customer = BraintreeRails::Customer.find(@user.customer_id)
            #@job.update_attribute("status", "available")
            @payment_method = PaymentMethod.find_by_id(params[:payment_method_id])
            @job.update_attributes(:status => "available", :payment_method_id => @payment_method.id, :billing_address_id => @payment_method.billing_address.id)
            push_notify_drivers = @job.get_push_notify_drivers(@job)
            email_notify_drivers = @job.get_email_notify_drivers(@job)
            @transaction = nil
            emails = JobEmail.new(@job, @transaction, email_notify_drivers, push_notify_drivers, request.protocol, request.host_with_port)
            Delayed::Job.enqueue(emails)
            record_activity_new("Order Placed by #{@job.customer.full_name}", @job.id, @user.id)
            render :json => {:success => true, :id => @job.id, :job_code => @job.job_code, :latitude => @job.latitude, :longitude => @job.longitude, :dest_latitude => @job.dest_latitude, :dest_longitude => @job.dest_longitude}.to_json
            return
            #@payment_method = PaymentMethod.find_by_id(params[:payment_method_id])
            #@billing_address = PaymentMethod.find_by_id(params[:payment_method_id])
            #puts "JJJJJJJ", @job.amount + @job.job_tax
            #result = Braintree::Transaction.sale(
            #    :customer_id => @customer.id,
            #    :amount => @job.amount + @job.job_tax,
            #    :payment_method_token => @payment_method.token,
            #    :options => {
            #        :submit_for_settlement => true
            #    }
            #)
            #if result.success?
            #  transaction = result.transaction
            #  final_amount = transaction.amount
            #  driver_amount = (final_amount/100) * 80
            #  ziply_revenue = final_amount - driver_amount
            #  brain_tree_fee = ((final_amount/100) * 2.9) - 0.30
            #  ziply_gross_revenue = ziply_revenue - brain_tree_fee
            #  if @transaction = TransactionHistory.create!(:driver_amount => driver_amount, :ziply_revenue => ziply_revenue, :brain_tree_fee => brain_tree_fee, :ziply_gross_revenue => ziply_gross_revenue, :amount => final_amount, :user_id => @user.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.blank? ? nil : @billing_address.id, :job_id => @job.id, :transaction_id => transaction.id, :status => transaction.status, :transaction_type => transaction.type)
            #    puts "CCCCCCCCCCC", @job.inspect
            #    @job.update_attribute("status", "available")
            #    push_notify_drivers = @job.get_push_notify_drivers(@job)
            #    email_notify_drivers = @job.get_email_notify_drivers(@job)
            #    emails = JobEmail.new(@job, @transaction, email_notify_drivers, push_notify_drivers, request.protocol, request.host_with_port)
            #    Delayed::Job.enqueue(emails)
            #    record_activity_new("Order Placed by #{@job.customer.full_name}", @job.id, @user.id)
            #    render :json => {:success => true, :id => @job.id, :job_code => @job.job_code, :latitude => @job.latitude, :longitude => @job.longitude, :dest_latitude => @job.dest_latitude, :dest_longitude => @job.dest_longitude}.to_json
            #  else
            #    @errors = @transaction.errors
            #    error_string = ""
            #    @errors.full_messages.each do |msg|
            #      error_string += msg
            #    end
            #    render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
            #  end
            #else
            #  @job.destroy
            #  error_string = ""
            #  @brain_errors = result.errors
            #  @brain_errors.each do |error|
            #    error_string += error.message
            #  end
            #  render :json => {:success => "false", :message => "Something went wrong brain #{error_string}"}
            #end
            #return
          else
            puts "OOOO", @job.errors.inspect
            @errors = @job.errors
            error_string = ""
            @errors.full_messages.each do |msg|
              error_string += msg
            end
            render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
            return
          end
        else
          @job.errors.add(:pick_up_address, "Sorry, but your pickup location is out of range!")
          @errors = @job.errors
          error_string = ""
          @errors.full_messages.each do |msg|
            error_string += msg
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
          return
        end
      else
        @job.errors.add(:pick_up_address, "We are unable to find zip code from your address")
        #@job.errors.add(:destination_address, "We are unable to find zip code from your address")
        @errors = @job.errors
        error_string = ""
        @errors.full_messages.each do |msg|
          error_string += msg
        end
        render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
        return
      end
    else
      render :json => {:success => "false", :message => "This Credit Card is expired."}
      return
    end

    #else
    #  @job.errors.add(:pick_up_address, "Sorry, but your pickup location is out of range!")
    #  @errors = @job.errors
    #  error_string = ""
    #  @errors.full_messages.each do |msg|
    #    error_string += msg
    #  end
    #  render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    #  return
    #end
    #else
    #  @job.errors.add(:pick_up_address, "We are unable to find zip code from your address")
    #  #@job.errors.add(:destination_address, "We are unable to find zip code from your address")
    #  @errors = @job.errors
    #  error_string = ""
    #  @errors.full_messages.each do |msg|
    #    error_string += msg
    #  end
    #  render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    #  return
    #end
  end


  def remove_pic
    @asset = Asset.find(params[:id])
    if @asset.destroy
      render :json => {:success => "true", :message => "Picture successfully destroyed"}
    else
      render :json => {:success => "false", :message => "Picture not destroyed"}
    end
  end

  def forgot_password
    @user = User.find_by_email(params[:user][:email])
    unless @user.blank?
      @user = User.send_reset_password_instructions(params[:user])
      render :json => {:success => "true", :message => "email successfully send"}
    else
      render :json => {:success => "false", :message => "Invalid email"}
    end
  end


  def change_password
    check_password = @user.valid_password?(params[:user][:current_password])
    if check_password == true
      if @user.update_attribute('password', params[:user][:password])
        render :json => {:success => "true", :message => "Password successfully changed"}
      else
        render :json => {:success => "false", :message => "Pass change failed with error"}
      end
    else
      render :json => {:success => "false", :message => "Current password is invalid"}
    end
  end


  def get_jobs
    jobs = @user.customer_jobs.where("status = ? or status = ? or status = ? or status = ?", 'available', 'accepted', 'picked', 'delivered')
    render :json => {:success => "true",
                     :data => {
                         :jobs => jobs.blank? ? Array.new : jobs.sort_by { |j| j.created_at }.reverse.map { |j| j.customer_job_json(j) }

                     }}
  end


  def send_message_to_user(job, user)
    Message.create(:job_id => job.id, :status => "close", :subject => job.job_code, :sender_id => user.id, :sender_type => "User", :receiver_id => user.id, :receiver_type => "User", :description => "You canceled your job")
  end

  def send_notification_to_driver(job, user)
    notification = Houston::Notification.new(:device => user.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:job_id => @job.id, :job_code => job.job_code}
    notification.alert = "Customer canceled you job"
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end


  #// send notification to customr

  def send_message_notification(user, message)
    puts "FFFFFFFF", user.device_token
    notification = Houston::Notification.new(:device => user.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:user_id => user.id}
    notification.alert = message
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end


  def send_notification(user, job)
    notification = Houston::Notification.new(:device => user.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:job_id => @job.id, :job_code => job.job_code}
    notification.alert = message
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end


  def get_messages
    messages = @user.received_messages.where(:receiver_deleted => false)
    render :json => {:success => "true",
                     :data => {
                         :messages => messages.blank? ? Array.new : messages.map { |m| {:id => m.id, :status => m.status, :job_status => m.job.present? ? m.job.status : nil,
                                                                                        :job_code => m.job.job_code,
                                                                                        :job_id => m.job.id,
                                                                                        :subject => m.subject,
                                                                                        :signature => m.job.status == "delivered" ? m.job.asset.blank? ? nil : m.job.asset.avatar.url(:thumb) : nil,
                                                                                        :description => m.description, :created_at => m.created_at.strftime("%d %b,%Y-%l:%M %p"),
                                                                                        :sender_id => m.sender.id,
                                                                                        :sender_name => m.sender.full_name} }.reverse
                     }}

  end

  def save_payment_method
    #begin
    @payment_method = PaymentMethod.new(params[:payment_method])
    puts "PPPP", @payment_method.inspect
    if @payment_method.valid?
      @customer = BraintreeRails::Customer.find(@user.customer_id)
      unless @customer.blank?
        result = Braintree::CreditCard.create(
            :customer_id => @customer.id,
            :number => params[:payment_method][:card_number],
            :expiration_month => params[:payment_method][:month],
            :expiration_year => params[:payment_method][:year],
            :cardholder_name => params[:payment_method][:holder_name],
            :billing_address => {
                :first_name => @user.first_name,
                :last_name => @user.last_name,
                :street_address => @payment_method.billing_address.street_address,
                :extended_address => @payment_method.billing_address.house_no,
                :locality => @payment_method.billing_address.city,
                :region => @payment_method.billing_address.state,
                :postal_code => @payment_method.billing_address.zip_code
            }, :options => {
            :verify_card => true
        }
        )
        if result.success?
          unless check_existing_card(result.credit_card)
            render :json => {:success => "false", :message => "Duplicate Card not allowed"}
          else
            @payment_method.card_number = result.credit_card.last_4
            @payment_method.token = result.credit_card.token
            if @payment_method.save
              render :json => {:success => "true", :message => "Payment Method was successfully Added"}
            else
              error_string = ""
              @payment_method.errors.full_messages.each do |msg|
                error_string += msg
              end
              render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
            end
          end
        else
          error_string = ""
          @brain_errors = result.errors
          @brain_errors.each do |error|
            puts "PPPP", error.inspect
            error_string += error.message
          end
          @brain_errors_txt = result.credit_card_verification.present? ? result.credit_card_verification.processor_response_text : nil
          unless @brain_errors_txt.blank?
            error_string += @brain_errors_txt
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
        end
      else
      end
    else
      error_string = ""
      @payment_method.errors.full_messages.each do |msg|
        puts msg.inspect
        error_string += msg
      end
      render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    end
    #rescue Exception => e
    #  @message = e.message
    #  render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    #end
  end

  def update_payment_method
    begin
      payment_method = PaymentMethod.find_by_id(params[:payment_method][:id])

      p_method = PaymentMethod.new
      p_method.card_number = params[:payment_method][:card_number]
      p_method.month = params[:payment_method][:month]
      p_method.year = params[:payment_method][:year]

      p_method.holder_name = params[:payment_method][:holder_name]
      p_method.cvv = params[:payment_method][:cvv]
      p_method.nick_name = params[:payment_method][:nick_name]
      p_method.card_type = params[:payment_method][:card_type]
      p_method.user_id = params[:payment_method][:user_id]
      if p_method.valid?
        @payment_method = payment_method if @user.payment_methods.include?(payment_method)
        result = Braintree::CreditCard.update(
            @payment_method.token,
            :number => params[:payment_method][:card_number],
            :expiration_month => params[:payment_method][:month],
            :expiration_year => params[:payment_method][:year],
            :cardholder_name => params[:payment_method][:holder_name],
            :billing_address => {
                :first_name => @user.first_name,
                :last_name => @user.last_name,
                :street_address => @payment_method.billing_address.street_address,
                :extended_address => @payment_method.billing_address.house_no,
                :locality => @payment_method.billing_address.city,
                :region => @payment_method.billing_address.state,
                :postal_code => @payment_method.billing_address.zip_code
            }, :options => {
            :verify_card => true
        }
        )
        if result.success?
          @payment_method.card_number = result.credit_card.last_4
          @payment_method.token = result.credit_card.token
          @payment_method.month = params[:payment_method][:month]

          @payment_method.year = params[:payment_method][:year]
          @payment_method.holder_name = params[:payment_method][:holder_name]
          @payment_method.cvv = params[:payment_method][:cvv]
          @payment_method.card_type = params[:payment_method][:card_type]
          if @payment_method.save
            render :json => {:success => "true", :message => "Payment Method was successfully Updated"}
          else
            error_string = ""
            @payment_method.errors.full_messages.each do |msg|
              error_string += msg
            end
            render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
          end
        else
          error_string = ""
          @brain_errors = result.errors
          @brain_errors.each do |error|
            error_string += error.message
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
        end
      else
        error_string = ""
        p_method.errors.full_messages.each do |msg|
          error_string += msg
        end
        render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
      end
    rescue Exception => e
      @message = e.message
      render :json => {:success => "false", :message => "Something went wrong #{e.message}"}
    end
  end


  def get_payment_methods
    render :json => {:success => "true",
                     :data => {
                         :payment_methods => @user.payment_method_json(@user)
                     }
    }
  end

  def update_profile
    puts "CCC", params.inspect
    successfully_updated = if needs_password?(@user, params)
                             puts "CCCii"
                             @user.update(params[:user])
                           else
                             params[:user].delete(:password)
                             @user.update_without_password(params[:user])
                           end

    puts "CCCC", successfully_updated.inspect

    if successfully_updated
      render :json => {:success => "true", :picture_url => @user.profile.blank? ? nil : @user.profile.asset.blank? ? nil : @user.profile.asset.avatar.url(:thumb), :message => "Customer was updated"}
    else
      error_string = ""
      @user.errors.full_messages.each do |msg|
        error_string += msg
      end
      puts "CCC", @user.errors.inspect
      render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    end
  end

  def send_message
    @message = Message.new(params[:message])
    if @message.save
      if @message.receiver.device_token.present?
        send_message_notification(@message.receiver, "User send you message")
      end
      render :json => {:success => "true", :message => "Message successfully send"}
    else
      error_string = ""
      @message.errors.full_messages.each do |msg|
        error_string += msg
      end
      puts "CCC", @user.errors.inspect
      render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    end
  end

  def forgot_password
    @user = User.find_by_email(params[:user][:email])
    unless @user.blank?
      @user = User.send_reset_password_instructions(params[:user])
      render :json => {:success => "true", :message => "email successfully send"}
    else
      render :json => {:success => "false", :message => "Invalid email"}
    end
  end

  def delete_payment_method
    payment_method = PaymentMethod.find_by_id(params[:id])
    @payment_method = payment_method if @user.payment_methods.include?(payment_method)
    @jobs = Job.where(:payment_method_id => @payment_method.id)
    if @jobs.blank?
      result = Braintree::CreditCard.delete(@payment_method.token)
      if result == true
        if @payment_method.update_attribute(:is_deleted, true)
          render :json => {:success => "true", :message => "Payment method successfully deleted"}
        else
          render :json => {:success => "false", :message => "Payment method not deleted"}
        end
      else
        render :json => {:success => "false", :message => "Payment method not deleted"}
      end
    else
      @flag = false
      @jobs.each do |job|
        if job.status != "delivered"
          @flag = true
        end
      end
      if @flag == false
        result = Braintree::CreditCard.delete(@payment_method.token)
        if result == true
          if @payment_method.update_attribute(:is_deleted, true)
            render :json => {:success => "true", :message => "Payment method successfully deleted"}
          else
            render :json => {:success => "false", :message => "Payment method not deleted"}
          end
        else
          render :json => {:success => "false", :message => "Payment method not deleted"}
        end
      else
        render :json => {:success => "false", :message => "Your posted job against this card is not delivered so you cannot delete this card"}
      end
    end
  end


  def delete_message
    @message = Message.find_by_id(params[:id])
    @message.update_attribute(:receiver_deleted, true)
    render :json => {:success => "true", :message => "Message successfully deleted"}
  end

  def view_profile
    render :json => {:success => "true",
                     :data => {
                         :customer => @user.customer_json(@user)
                     }}
  end


  def save_review
    @review = Review.new(params[:review])
    if @review.save
      render :json => {:success => "true", :message => "Review successfully send"}
    else
      error_string = ""
      @review.errors.full_messages.each do |msg|
        error_string += msg
      end
      render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    end
  end


  def search_jobs
    if params[:term].length > 1
      like = "%".concat(params[:term].downcase.concat("%"))
      jobs = @user.customer_jobs.where("status != ? and lower(job_code) like ?", 'unavailable', like).limit(30)
    else
      jobs = @user.customer_jobs.where("status != ? and created_at >= ?", 'unavailable', Time.now - 1.month)
    end
    render :json => {:success => "true",
                     :data => {
                         :jobs => jobs.blank? ? Array.new : jobs.map { |j| j.customer_job_json(j) }
                     }}
  end


  def search_messages
    if params[:term].length > 1
      like = "%".concat(params[:term].downcase.concat("%"))
      messages = @user.received_messages.where("receiver_deleted=? and lower(subject) like ?", false, like).limit(30)
    else
      messages = @user.received_messages.where("receiver_deleted=? and created_at >= ?", false, Time.now - 1.month)
    end
    render :json => {:success => "true",
                     :data => {
                         :messages => messages.blank? ? Array.new : messages.map { |m| {:id => m.id, :status => m.status,
                                                                                        :job_code => m.job.job_code,
                                                                                        :job_id => m.job.id,
                                                                                        :subject => m.subject,
                                                                                        :signature => m.job.status == "delivered" ? m.job.asset.blank? ? nil : m.job.asset.avatar.url(:thumb) : nil,
                                                                                        :description => m.description, :created_at => m.created_at.strftime("%e %b %Y-%H:%M:%S%p"),
                                                                                        :sender_id => m.sender.id,
                                                                                        :sender_name => m.sender.full_name} }
                     }}

  end

  def cancel_order
    job = Job.find_by_id(params[:id])
    @job = job if @user.customer_jobs.include?(job)
    if (@job.status == "available" or @job.status == "accepted")
      result = Braintree::Transaction.sale(
          :customer_id => @job.customer.customer_id,
          :amount => "5.00",
          :payment_method_token => @job.payment_method.token,
          :options => {
              :submit_for_settlement => true
          }
      )
      if result.success?
        if @job.status == "accepted"
          send_notification_to_driver(job, job.driver)
        end
        if @job.update_attributes(:status => "canceled")
          send_message_to_user(job, job.customer)
          render :json => {:success => "true", :message => "Job successfully canceled"}
        else
          render :json => {:success => "false", :message => "Job cannot be canceled"}
        end
      else
        err = []
        @b_errors = result.errors
        @b_errors.each do |e|
          err << e.message
        end
        render :json => {:success => "false", :errors => err.blank? ? "braintree error" : err.join(".\n")}
      end
    else
      render :json => {:success => "false", :message => "You cannot cancel your job because job is #{@job.status}"}
    end
  end

  def change_password
    check_password = @user.valid_password?(params[:user][:current_password])
    if check_password == true
      if @user.update_attribute('password', params[:user][:password])
        render :json => {:success => "true", :message => "Password successfully changed"}
      else
        render :json => {:success => "false", :message => "Pass change failed with error"}
      end
    else
      render :json => {:success => "false", :message => "Current password is invalid"}
    end
  end

  def track_driver
    job = Job.find(params[:id])
    driver = job.driver
    if job.status == "picked" or job.status == "accepted"
      pack_lat = driver.travelling_times.where("latitude is not null").last.blank? ? nil : driver.travelling_times.where("latitude is not null").last.latitude
      pack_long = driver.travelling_times.where("longitude is not null").last.blank? ? nil : driver.travelling_times.where("latitude is not null").last.longitude
    elsif job.status == "delivered"
      pack_lat = job.dest_latitude
      pack_long = job.dest_longitude
    else
      pack_lat = job.latitude
      pack_long = job.longitude
    end
    render :json => {:success => "true",
                     :data => {
                         :track => {:latitude => pack_lat, :longitude => pack_long}
                     }
    }
  end

  def accepted_job_count
    jobs = Job.where("status = ? and is_read= ? and customer_id = ?", 'accepted', false, @user.id).size
    #jobs = @user.customer_jobs.where("status = ? and is_read= ?", 'accepted', false).size
    render :json => {:success => "true",
                     :data => {
                         :count => jobs
                     }
    }
  end

  def change_read_status
    job = Job.find(params[:id])
    if job.update_attribute('is_read', true)
      render :json => {:success => "true", :message => "Job read successfully"}
    else
      render :json => {:success => "false", :message => "Job not read"}
    end
  end


  def check_promo_code
    @code = CouponCode.find_by_code(params[:code])
    @amount = params[:amount].delete('$,').to_f
    unless @code.blank?
      @count = @user.CouponCodeUser.where(:coupon_code_id => @code.id).size
      @flag = true
      if @code.per_user > 0 and @count >= @code.per_user
        @flag = false
      end
      @count = CouponCodeUser.where(:coupon_code_id => @code.id).size
      if @code.per_coupon > 0 and @count >= @code.per_coupon
        @flag = false
      end
      if Time.now >= @code.valid_from and Time.now <= @code.valid_to
      else
        @flag = false
      end
      if @flag == true
        discount = 0.0
        if @code.coupon_type = "amount"
          discount = @code.coupon_value
        else
          discount = (@amount/100)*@code.coupon_value
        end
        render :json => {:success => "true", :coupon_code_id => @code.id, :code => @code.code, :discount => discount, :message => "Coupon valid"}
      else
        render :json => {:success => "false", :message => "Coupon expired"}
      end
    else
      render :json => {:success => "false", :message => "invalid coupon code"}
    end
  end

  private


  def create_credit_card
    result = Braintree::CreditCard.create(
        :customer_id => @customer.id,
        :number => params[:payment_method][:card_number],
        :expiration_month => params[:payment_method][:month],
        :expiration_year => params[:payment_method][:year],
        :cardholder_name => params[:payment_method][:holder_name],
        :billing_address => billing_hash,
        :options => {
            :verify_card => true
        }
    )
    return result
  end

  def check_existing_card(card)
    flag = false
    @customer.credit_cards.each do |credit_card|
      if credit_card.unique_number_identifier == card.unique_number_identifier
        flag = true
        break
      end
    end
    if flag == true
      res = Braintree::CreditCard.delete(card.token)
      return false
    else
      return true
    end
  end


  def needs_password?(user, params)
    #user.email != params[:user][:email] ||
    #    params[:user][:password].present?
    params[:user][:password].present?
  end


  def get_lat_long(address)
    latitude = 0
    longitude = 0
    location = Geocoder.search(address)
    unless location.blank?
      latitude = location[0].latitude
      longitude = location[0].longitude
    end
    return latitude, longitude
  end

  def update_sender_location(location_id)
    @location = Location.find_by_id(location_id)
    if @location.update_attributes(params[:sender_location])
    else
      @errors = @location.errors
      error_string = ""
      @errors.errors.full_messages.each do |msg|
        error_string += msg
      end
      render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    end
  end

  def update_receiver_location(location_id)
    @location = Location.find_by_id(location_id)
    if @location.update_attributes(params[:receiver_location])
    else
      @errors = @location.errors
      error_string = ""
      @errors.full_messages.each do |msg|
        error_string += msg
      end
      render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
    end
  end


  def check_session_create
    puts "OOOOO"
    if params[:token].present?
      @user = User.find_by_authentication_token(params[:token])
      puts "UUU", @user.inspect
      if @user.blank? or @user.status == 'inactive'
        puts "IIIII"
        render :json => {:success => "false", :errors => "authentication failed"}
        return
      end
    else
      render :json => {:success => "false", :errors => "authentication failed"}
    end
  end

  def check_lat_long
    if params[:lat].present? && params[:long].present?
      #if params[:lat].to_i > 0 && params[:long].to_i > 0
      @driver_lat = params[:lat]
      @driver_long = params[:long]
      #else
      #  render :json => {:success => "false", :errors => "Please Enable location services"}
      #end
    else
      render :json => {:success => "false", :errors => "Please Enable location services"}
    end
  end


end
