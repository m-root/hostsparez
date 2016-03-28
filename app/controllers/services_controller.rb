require 'aws-sdk'
class ServicesController < ApplicationController
  #include ActionView::Helpers::DateHelper
  respond_to :json
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_user!
  before_filter :check_session_create, :except => [:sign_in, :forgot_password, :push_testing, :push_testing_user]
  before_filter :check_lat_long, :only => [:change_job_status, :get_driver_data, :sign_in, :get_jobs, :get_jobs_history, :get_job, :clock_in_clock_out, :sign_out, :update_driver_distance]
  include ApplicationHelper


  def push_testing
    if params[:device_id].present?
      job = Job.first
      notification = Houston::Notification.new(:device => params[:device_id])
      notification.badge = 0
      notification.sound = "sosumi.aiff"
      notification.content_available = true
      notification.custom_data = {:id => job.id, :type => job.class.to_s, :time => Date}
      notification.alert = "This is test message"
      certificate = File.read("config/production_driver.pem")
      pass_phrase = "push"
      connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
      connection.open
      connection.write(notification.message)
      connection.close
      render :json => {:success => 'true', :message => 'message send '}
    else
      render :json => {:success => 'false', :message => 'device_id not found'}
    end
  end

  def push_testing_user
    if params[:device_id].present?
      job = Job.first
      notification = Houston::Notification.new(:device => params[:device_id])
      notification.badge = 0
      notification.sound = "sosumi.aiff"
      notification.content_available = true
      notification.custom_data = {:id => job.id, :type => job.class.to_s, :time => Date}
      notification.alert = "This is test message"
      certificate = File.read("config/ziply-userProduction.pem")
      pass_phrase = "push"
      connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
      connection.open
      connection.write(notification.message)
      connection.close
      render :json => {:success => 'true', :message => 'message send '}
    else
      render :json => {:success => 'false', :message => 'device_id not found'}
    end
  end


  def get_driver_data
    unless params[:time_zone].blank?
      @user.update_attribute(:time_zone, params[:time_zone])
      jobs = Job.nearby_jobs(@driver_lat, @driver_long, @user)
      driver_jobs = @user.driver_jobs.where("status = ? or status = ?", "accepted", "picked")
      unless jobs.blank? and driver_jobs.blank?
        jobs = jobs + driver_jobs
      end
      unless jobs.blank?
        jobs = jobs.sort_by { |job| job.id }.reverse
      end
      pick_result_hash, dest_result_hash = distance_vector(jobs, @driver_lat, @driver_long)
      render :json => {:success => "true",
                       :data => {
                           :driver => driver_json(@user),
                           :jobs => jobs.blank? ? Array.new : jobs.map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) }
                       }}
    else
      render :json => {:success => 'false', :message => 'User time zone is missing'}
    end
  end

  def sign_in
    #begin
    if params[:email].present? and params[:password].present?
      @user = User.find_by_email(params[:email])
      if @user.blank?
        render :json => {:success => "false", :errors => "Email or password is incorrect"}
      else
        if @user.is_disabled == false and @user.status == 'active'
          if @user.driver?
            if not @user.valid_password?(params[:password])
              render :json => {:success => "false", :errors => "Invalid email or password."}
            else
              unless params[:device_token].blank?
                if  @user.update_attribute(:device_token, params[:device_token])
                  unless params[:time_zone].blank?
                    @user.update_attribute(:time_zone, params[:time_zone])
                    jobs = Job.nearby_jobs(@driver_lat, @driver_long, @user)
                    driver_jobs = @user.driver_jobs.where("status = ? or status = ?", "accepted", "picked")
                    unless jobs.blank? and driver_jobs.blank?
                      jobs = jobs + driver_jobs
                    end
                    unless jobs.blank?
                      jobs = jobs.sort_by { |job| job.id }.reverse
                    end
                    pick_result_hash, dest_result_hash = distance_vector(jobs, @driver_lat, @driver_long)
                    render :json => {:success => "true",
                                     :data => {
                                         :driver => driver_json(@user),
                                         :jobs => jobs.blank? ? Array.new : jobs.map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) }
                                     }}
                  else
                    render :json => {:success => "false", :errors => "User time zone is missing"}
                  end
                else
                  render :json => {:success => "false", :errors => "Device token not updated"}
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
    #rescue Exception => exc
    #  render :json => {:success => "server", :errors => exc.message}
    #end
  end


  def search_jobs
    puts "PPPPOOO", params.inspect
    unless params[:term].blank?
      like = "%".concat(params[:term].downcase.concat("%"))
      jobs = Job.where("lower(pick_up_address) like ?", like)
      pick_result_hash, dest_result_hash = distance_vector(jobs, @driver_lat, @driver_long)
      render :json => {:success => "true",
                       :data => {
                           :jobs => jobs.blank? ? Array.new : jobs.map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) }
                       }}
    else
      render :json => {:success => "false", :errors => "Jobs Not Found param search is missing"}
    end
  end


  def get_jobs
    jobs = Job.nearby_jobs(@driver_lat, @driver_long, @user)
    pick_result_hash, dest_result_hash = distance_vector(jobs, @driver_lat, @driver_long)
    render :json => {:success => "true",
                     :data => {
                         :jobs => jobs.blank? ? Array.new : jobs.map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) }
                     }}
  end

  def get_jobs_history
    jobs = Job.nearby_jobs(@driver_lat, @driver_long, @user)
    pick_result_hash, dest_result_hash = distance_vector(jobs, @driver_lat, @driver_long)
    render :json => {:success => "true",
                     :data => {
                         :active => jobs.blank? ? Array.new : jobs.where(:status => "accepted").map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) },
                         :completed => jobs.blank? ? Array.new : jobs.where(:status => "picked").map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) },
                         :canceled => jobs.blank? ? Array.new : jobs.where(:status => "canceled").map { |j| driver_job_json(pick_result_hash[j.id], dest_result_hash[j.id], j, @driver_lat, @driver_long) }
                     }}
  end


  def get_job
    unless params[:id].blank?
      jobs = Job.where(:id => params[:id])
      unless jobs.blank?
        pick_result_hash, dest_result_hash = distance_vector(jobs, @driver_lat, @driver_long)
        render :json => {:success => "true",
                         :data => {
                             :job => driver_job_json(pick_result_hash[jobs.first.id], dest_result_hash[jobs.first.id], jobs.first, @driver_lat, @driver_long)
                         }}
      else
        render :json => {:success => "false", :errors => "job not found"}
      end
    else
      render :json => {:success => "false", :errors => "params job can't be blank"}
    end
  end

  def change_job_status
    unless params[:status].blank?
      job = Job.find_by_id(params[:id])
      if job.present?
        if params[:status] == "accepted" and job.driver_id.blank?
          if job.update_attributes!(:status => params[:status], :driver_id => @user.id, :driver_type => "User")
            #UserMailer.job_accepted(job, @user, request.protocol, request.host_with_port).deliver
            #lat_long = params[:lat].to_s + "," + params[:long].to_s
            #directions = GoogleDirections.new(Geocoder.search(lat_long)[0].formatted_address, job.pick_up_address)
            #drive_time_in_minutes = directions.drive_time_in_minutes
            #total_minutes =   drive_time_in_minutes + 15
            #final_minutes = job.time_value + 45
            #puts "PPPP", total_minutes.inspect
            job.update_attribute(:accepted_time, Time.now)
            job.update_attribute(:pick_up_time, Time.now + 15.minutes)
            job.update_attribute(:delivery_time, job.pick_up_time + 45.minutes)
            if job.customer.device_token.present?
              send_job_notification(job.customer, "Your Job Accepted", job)
            end
            email = SpecialJobEmail.new(job, @user, request.protocol, request.host_with_port, "job_accepted")
            Delayed::Job.enqueue(email)
            render :json => {:success => "true", :message => "Job status changed"}
          else
            render :json => {:success => "false", :message => "Job not assigned"}
          end
        elsif params[:status] == "picked" and job.driver_id.present?
          if job.update_attributes!(:status => params[:status], :driver_id => @user.id, :driver_type => "User")
            #UserMailer.job_picked(job, @user, request.protocol, request.host_with_port).deliver
            job.update_attribute(:pick_up_time, Time.now)
            final_minutes = job.time_value + 45
            job.update_attribute(:delivery_time, job.pick_up_time + final_minutes.minutes)
            #
            if job.customer.device_token.present?
              send_job_notification(job.customer, "Your item has been picked up!", job)
            end
            #
            email = SpecialJobEmail.new(job, @user, request.protocol, request.host_with_port, "job_picked")
            Delayed::Job.enqueue(email)
            render :json => {:success => "true", :message => "Job status changed"}
          else
            render :json => {:success => "false", :message => "Job not assigned"}
          end
        else
          render :json => {:success => "false", :errors => "Job already picked"}
        end
      else
        render :json => {:success => "false", :errors => "Job Not Found"}
      end
    else
      render :json => {:success => "false", :errors => "Job Not Found status can't be blank"}
    end
  end

  def change_password
    check_password = @user.valid_password?(params[:user][:current_password])
    if check_password == true
      if @user.update_attribute('password', params[:user][:password])
        render :json => {:success => "true", :errors => "Password successfully changed"}
      else
        render :json => {:success => "false", :errors => "Pass change failed with error"}
      end
    else
      render :json => {:success => "false", :errors => "Current password is invalid"}
    end
  end

  def save_message
    @message = Message.new(params[:message])
    if @message.save
      #UserMailer.new_message_from_driver(@message, request.protocol, request.host_with_port).deliver
      #message = MessageEmail.new(@message, request.protocol, request.host_with_port, "new_message_from_driver")
      message = MessageEmail.new(@message, request.protocol, request.host_with_port, "new_message_from_driver",params[:MessageTo])
      Delayed::Job.enqueue(message)
      render :json => {:success => "true", :errors => "Message was successfully Added"}
    else
      render :json => {:success => "false", :errors => "Message Not Saved"}
    end
  end

  def get_messages
    messages = @user.received_messages.where(:receiver_deleted => false)
    sent_messages = @user.sent_messages
    reviews = @user.driver_reviews
    reviews_jobs = {}
    unless messages.blank?
      messages.each do |m|
        reviews_jobs["message_#{m.id}"] = m
      end
    end
    unless sent_messages.blank?
      sent_messages.each do |m|
        reviews_jobs["message_#{m.id}"] = m
      end
    end
    unless reviews.blank?
      reviews.each do |r|
        reviews_jobs["review_#{r.id}"] = r
      end
    end
    reviews_jobs = reviews_jobs.sort_by { |k, v| v.created_at }.reverse
    render :json => {:success => "true",
                     :data => {
                         :messages => reviews_jobs.blank? ? Array.new : reviews_jobs.map { |k, rm| review_message_json(rm) }
                     }}

  end

  def get_message
    unless params[:id].blank?
      message = Message.find_by_id(params[:id])
      unless message.blank?
        render :json => {:success => "true",
                         :data => {
                             :message => review_message_json(message)
                         }}
      else
        render :json => {:success => "false", :errors => "message not found"}
      end
    else
      render :json => {:success => "false", :errors => "params id can't be blank"}
    end
  end


  def change_message_status
    if params[:type].present? and params[:id].present? and params[:status].present?
      if params[:type] == "Message"
        message = Message.find_by_id(params[:id])
        unless message.blank?
          message.update_attributes(:status => params[:status])
          render :json => {:success => "true", :errors => "Message successfully updated"}
        else
          render :json => {:success => "false", :errors => "Message not found"}
        end
      else
        review = Review.find_by_id(params[:id])
        unless review.blank?
          review.update_attributes(:status => params[:status])
          render :json => {:success => "true", :errors => "Review successfully updated"}
        else
          render :json => {:success => "false", :errors => "Review not found"}
        end
      end
    else
      render :json => {:success => "false", :errors => "Params missing"}
    end
  end

  def review_message_json(rm)
    {:id => rm.id,
     :status => rm.status,
     :job_code => rm.job.job_code,
     :job_id => rm.job.id,
     :subject => rm.subject,
     :description => rm.description,
     :type => rm.class.to_s,
     :message_type => rm.class.to_s == "Message" ? rm.sender.id == @user.id ? "sent" : "received" : "review",
     :rating => rm.class.to_s == "Review" ? rm.rating : nil,
     :customer_id => rm.class.to_s == "Review" ? rm.customer.id : nil,
     :customer_name => rm.class.to_s == "Review" ? rm.customer.full_name : nil,
     :sender_id => rm.class.to_s == "Message" ? rm.sender.id : nil,
     :sender_name => rm.class.to_s == "Message" ? rm.sender.full_name : nil,
     :created_at => rm.created_at.to_s
    }
  end

  def delete_message
    message = Message.find(params[:id])
    if message.destroy
      render :json => {:message => "Message deleted", :success => "true"}
    else
      render :json => {:message => "Message not deleted", :success => "false"}
    end
  end

  def get_driver_setting
    unless @user.driver_setting.blank?
      render :json => {:success => " true ", :driver_setting => @user.driver_setting}
    else
      render :json => {:success => " false ", :errors => " Driver Setting Not Found "}
    end
  end

  def update_driver_setting
    @driver_setting = @user.driver_setting
    unless @driver_setting.blank?
      if @driver_setting.update_attributes(params[:driver_setting])
        render :json => {:success => "true", :message => " Driver setting successfully updated "}
      else
        render :json => {:success => "true", :message => " Driver setting was not updated "}
      end
    else
      render :json => {:success => "false", :message => " Driver setting was not found "}
    end
  end

  def clock_in_clock_out
    unless params[:clock].blank?
      if params[:clock] == "in"
        TravellingTime.create!(:clock_in => Time.now, :user_id => @user.id, :latitude => @driver_lat, :longitude => @driver_long)
        render :json => {:success => "true", :message => "clock in updated"}
      else
        begin
          distance = Geocoder::Calculations.distance_between([@user.travelling_times.last.latitude, @user.travelling_times.last.longitude], [@driver_lat, @driver_long])
          @user.travelling_times.last.update_attributes(:clock_out => Time.now, :total_miles => distance + @user.travelling_times.last.total_miles, :latitude => @driver_lat, :longitude => @driver_long)
          render :json => {:success => "true", :message => "clock out updated"}
        rescue Exception => exc
          render :json => {:success => "false", :message => "Params clock not found"}
        end
      end
    else
      render :json => {:success => "false", :message => "Params clock not found"}
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


  def get_driver_stats

    if params[:date_crt] == "All Time"
      @travelling_times = @user.travelling_times
    elsif params[:date_crt] == "Today"
      @travelling_times = @user.travelling_times.where("Date(clock_in) = ?", Date.today)
    elsif params[:date_crt] == "This Week"
      @travelling_times = @user.travelling_times.where("Date(clock_in) >= ? and Date(clock_in) <= ?", Date.today- 7, Date.today)
    elsif params[:date_crt] == "Last Week"
      @travelling_times = @user.travelling_times.where("Date(clock_in) >= ? and Date(clock_in) <= ?", Date.today- 14, Date.today - 7)
    elsif params[:date_crt] == "This Month"
      @travelling_times = @user.travelling_times.where("Date(clock_in) >= ? and Date(clock_in) <= ?", Date.today- 30, Date.today)
    elsif params[:date_crt] == "Last Month"
      @travelling_times = @user.travelling_times.where("Date(clock_in) >= ? and Date(clock_in) <= ?", Date.today- 60, Date.today - 30)
    elsif params[:date_crt] == "Year to Date"
      @travelling_times = @user.travelling_times.where("Date(clock_in) >= ? and Date(clock_in) <= ?", Date.today- 300, Date.today)
    end
    total_time = 0
    unless @travelling_times.blank?
      @travelling_times.each do |travelling_time|
        if travelling_time.clock_in.present? and travelling_time.clock_out.present?
          total_time += ((travelling_time.clock_out - travelling_time.clock_in) / 3600)
        elsif travelling_time.clock_out.blank?
          total_time += ((Time.now - travelling_time.clock_in) / 3600)
        end
      end
    end
    render :json => {:success => "true",
                     :total_time => total_time.round(2)
    }
  end

  def get_driver_delivery_stats
    if params[:report_type] == "stats"
      if params[:date_crt] == "All Time"
        @travelling_times = @user.travelling_times
      elsif params[:date_crt] == "Today"
        @travelling_times = @user.travelling_times.where("Date(created_at) = ?", Date.today)
      elsif params[:date_crt] == "This Week"
        @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 7, Date.today)
      elsif params[:date_crt] == "This Month"
        @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 30, Date.today)
      elsif params[:date_crt] == "Last Month"
        @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 60, Date.today - 30)
      elsif params[:date_crt] == "Year to Date"
        @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 365, Date.today)
      end
      total_time = 0
      distance = 0
      unless @travelling_times.blank?
        @travelling_times.each do |travelling_time|
          if travelling_time.clock_in.present? and travelling_time.clock_out.present?
            total_time += ((travelling_time.clock_out - travelling_time.clock_in) / 3600)
          elsif travelling_time.clock_in.present? and travelling_time.clock_out.blank?
            total_time += ((Time.now - travelling_time.clock_in) / 3600)
          end
          if travelling_time.total_miles.present?
            distance += travelling_time.total_miles
          end
        end
      end
      render :json => {:success => "true",
                       :total_time => total_time,
                       :total_distance => distance
      }
    else
      if params[:date_crt] == "All Time"
        @jobs = @user.driver_jobs.where(:status => "delivered")
      elsif params[:date_crt] == "Today"
        @jobs = @user.driver_jobs.where("Date(delivered_date) = ?", Date.today)
      elsif params[:date_crt] == "This Week"
        @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 7, Date.today)
      elsif params[:date_crt] == "This Month"
        @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 30, Date.today)
      elsif params[:date_crt] == "Last Month"
        @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 60, Date.today - 30)
      elsif params[:date_crt] == "Year to Date"
        @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 365, Date.today)
      end
      total_revenue = 0
      deliveries_count = 0
      ziply_revenue = 0
      driver_earning = 0
      unless @jobs.blank?
        @jobs.each_with_index do |job, index|
          if job.transaction_history.present?
            unless job.transaction_history.amount.blank?
              total_revenue += job.transaction_history.amount
              deliveries_count = deliveries_count + 1
              ziply_revenue += job.transaction_history.ziply_revenue if job.transaction_history.ziply_revenue
              driver_earning += job.transaction_history.driver_amount if job.transaction_history.driver_amount
            end
          end
        end
      end
      render :json => {:success => "true",
                       :total_revenue => total_revenue.round(2),
                       :deliveries_count => deliveries_count,
                       :ziply_revenue => ziply_revenue.round(2),
                       :driver_earning => driver_earning.round(2)
      }
    end
  end

  def get_driver_detail
    render :json => {:success => "true",
                     :user => driver_json(@user)
    }
  end

  def get_reviews
    render :json => {:success => "true",
                     :data => {
                         :reviews => @user.driver_reviews.map { |review| review_json(review) }
                     }}
  end

  def get_review
    unless params[:id].blank?
      review = Review.find_by_id(params[:id])
      render :json => {:success => "true",
                       :data => {
                           :review => review.blank? ? Review.new : review_json(review)
                       }}
    else
      render :json => {:success => false, :message => "params id can't be blank"}
    end
  end

  def get_profile
    if @user.driver?
      render :json => {:success => " true ", :data => {:profile => @user.profile, :email => @user.email, :image => (@user.profile.asset.present? ? @user.profile.asset.avatar.url : " ")}}
    else
      render :json => {:success => " true ", :data => {:profile => @user.profile, :email => @user.email}}
    end
  end

  def update_driver_profile
    if @user.update_without_password(params[:user])
      render :json => {:success => "true", :message => " profile was updated "}
    else
      render :json => {:success => "false", :message => " profile was not updated "}
    end
  end

  def sign_in_for_delivery
    unless params[:uploaded_picture].blank?
      job = Job.find_by_id(params[:id])
      if job.driver.customer_id.present?
        if job.present?
          if job.asset = Asset.create!(params[:uploaded_picture])
            if job.discount.blank?
              #UserMailer.job_delivered(job, @user, request.protocol, request.host_with_port).deliver
              @customer = BraintreeRails::Customer.find(job.customer.customer_id)
              final_amount_after = job.amount + job.job_tax
              final_amount_before = final_amount_after/1.1
              driver_amount = (final_amount_before/100) * 80
              ziply_revenue = (final_amount_before/100) * 20
              ziply_revenue = ziply_revenue + (final_amount_after - final_amount_before)
              brain_tree_fee = ((final_amount_after/100) * 2.9) - 0.30
              ziply_gross_revenue = ziply_revenue - brain_tree_fee
              puts "CCC", (job.amount + job.job_tax), ziply_revenue

              result = Braintree::Transaction.sale(
                  :customer_id => @customer.id,
                  #:service_fee_amount => (ziply_revenue.round).to_s + "." + "00",
                  :service_fee_amount => "%.2f" % ziply_revenue,
                  #:amount => ((job.amount + job.job_tax).round).to_s + "." + "00",
                  :amount => "%.2f" % (job.amount + job.job_tax),
                  :merchant_account_id => job.driver.customer_id,
                  :payment_method_token => job.payment_method.token,
                  :options => {
                      :submit_for_settlement => true
                  }
              )
              @payment_method = job.payment_method
              @billing_address = @payment_method.billing_address
              if result.success?
                transaction = result.transaction
                final_amount_after = transaction.amount
                final_amount_before = final_amount_after/1.1
                driver_amount = (final_amount_before/100) * 80
                ziply_revenue = (final_amount_before/100) * 20
                ziply_revenue = ziply_revenue + (final_amount_after - final_amount_before)
                brain_tree_fee = ((final_amount_after/100) * 2.9) - 0.30
                ziply_gross_revenue = ziply_revenue - brain_tree_fee
                @transaction = TransactionHistory.create!(:driver_amount => driver_amount, :ziply_revenue => ziply_revenue, :brain_tree_fee => brain_tree_fee, :ziply_gross_revenue => ziply_gross_revenue, :amount => final_amount_after, :user_id => job.customer.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.blank? ? nil : @billing_address.id, :job_id => job.id, :transaction_id => transaction.id, :status => transaction.status, :transaction_type => transaction.type, :escrow_status => "escrow")
                job.update_attributes!(:status => "delivered", :delivered_date => Time.now.utc)
                Message.create!(:status => "close", :sender_id => job.driver.id, :sender_type => "User", :receiver_id => job.customer.id, :receiver_type => "User", :subject => job.job_code, :job_id => job.id, :description => "Your Package Successfully delivered")
                Braintree::Transaction.hold_in_escrow(transaction.id)
                #
                if job.customer.device_token.present?
                  send_job_notification(job.customer, "Your Job delivered", job)
                end
                #
                email = SpecialJobEmail.new(job, @user, request.protocol, request.host_with_port, "job_delivered")
                job.update_attributes(:delivered_date => Time.now)
                Delayed::Job.enqueue(email)
                render :json => {:success => "true", :message => "Job status changed"}
              else
                err = []
                @b_errors = result.errors
                puts "CCCCCCCCCCCCC", @b_errors.inspect
                @b_errors.each do |e|
                  err << e.message
                end
                render :json => {:success => "false", :errors => err.blank? ? "braintree error" : err.join(".\n")}
              end
            else

              @customer = BraintreeRails::Customer.find(job.customer.customer_id)
              final_amount_after = job.amount + job.job_tax
              if final_amount_after > 0
                result = Braintree::Transaction.sale(
                    :customer_id => @customer.id,
                    :amount => "%.2f" % final_amount_after,
                    :payment_method_token => job.payment_method.token,
                    :options => {
                        :submit_for_settlement => true
                    }
                )
                if result.success?
                  @payment_method = job.payment_method
                  @billing_address = @payment_method.billing_address
                  puts "@payment_method", @payment_method.id
                  puts "@@billing_address", @billing_address.id
                  puts "@@job", job.id
                  transaction = result.transaction
                  driver_amount = 0.0
                  ziply_revenue = final_amount_after
                  brain_tree_fee = ((final_amount_after/100) * 2.9) - 0.30
                  ziply_gross_revenue = ziply_revenue - brain_tree_fee
                  @transaction = TransactionHistory.create!(:driver_amount => driver_amount, :ziply_revenue => ziply_revenue, :brain_tree_fee => brain_tree_fee, :ziply_gross_revenue => ziply_gross_revenue, :amount => final_amount_after, :user_id => job.customer.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.blank? ? nil : @billing_address.id, :job_id => job.id, :transaction_id => transaction.id, :status => transaction.status, :transaction_type => transaction.type, :escrow_status => "escrow")
                  job.update_attributes!(:status => "delivered", :delivered_date => Time.now.utc)
                  Message.create!(:status => "close", :sender_id => job.driver.id, :sender_type => "User", :receiver_id => job.customer.id, :receiver_type => "User", :subject => job.job_code, :job_id => job.id, :description => "Your Package Successfully delivered")
                  Braintree::Transaction.hold_in_escrow(transaction.id)
                  email = SpecialJobEmail.new(job, @user, request.protocol, request.host_with_port, "job_delivered")
                  job.update_attributes(:delivered_date => Time.now)
                  Delayed::Job.enqueue(email)
                  render :json => {:success => "true", :message => "Job status changed"}
                else
                  err = []
                  @b_errors = result.errors
                  puts "CCCCCCCCCCCCC", @b_errors.inspect
                  @b_errors.each do |e|
                    err << e.message
                  end
                  render :json => {:success => "false", :errors => err.blank? ? "braintree error" : err.join(".\n")}
                end
              else
                @payment_method = job.payment_method
                @billing_address = @payment_method.billing_address
                puts "@payment_method", @payment_method.id
                puts "@@billing_address", @billing_address.id
                puts "@@job", job.id
                TransactionHistory.create!(:driver_amount => 0, :ziply_revenue => 0, :brain_tree_fee => 0, :ziply_gross_revenue => 0, :amount => 0, :user_id => job.customer.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.blank? ? nil : @billing_address.id, :job_id => job.id, :transaction_id => nil, :status => 'no_braintree', :transaction_type => 'not_process')
                job.update_attributes!(:status => "delivered", :delivered_date => Time.now.utc)
                Message.create!(:status => "close", :sender_id => job.driver.id, :sender_type => "User", :receiver_id => job.customer.id, :receiver_type => "User", :subject => job.job_code, :job_id => job.id, :description => "Your Package Successfully delivered")
                email = SpecialJobEmail.new(job, @user, request.protocol, request.host_with_port, "job_delivered")
                job.update_attributes(:delivered_date => Time.now)
                Delayed::Job.enqueue(email)
                render :json => {:success => "true", :message => "Job status changed"}
              end
            end
          else
            render :json => {:success => "false", :errors => "Job image was not updated Job not Found"}
          end
        else
          render :json => {:success => "false", :errors => "Job Not Found"}
        end
      else
        render :json => {:success => "false", :errors => "Please add your account and routing number first"}
      end
    else
      render :json => {:success => "false", :errors => "Job image not found params picture not found"}
    end
  end

  def upload_driver_picture
    puts "PPPP", params.inspect
    if params[:uploaded_picture].present?
      @user.profile.asset.destroy if @user.profile.asset.present?
      if @user.profile.asset = Asset.create!(params[:uploaded_picture])
        url = "#{@user.profile.asset.avatar.url(:medium)}"
        render :json => {:success => "true", :picture_url => url, :message => " profile image was updated "}
      else
        render :json => {:success => "false", :message => " profile image was not updated "}
      end
    else
      render :json => {:success => "false", :message => " profile image was not updated "}
    end
  end

  def get_billing_histories
    #User.includes(:roles).where("roles.name" => "driver")
    transaction_histories = TransactionHistory.includes(:job).where("jobs.driver_id" => @user.id)
    render :json => {:success => "true",
                     :data => {
                         :transaction_histories => transaction_histories.map { |th| transaction_history_json(th) }
                     }}

  end

  def get_billing_history
    @transaction_history = TransactionHistory.find_by_id(params[:id])
    if @user.transaction_histories.include?(@transaction_history)
      render :json => {:success => "true",
                       :data => {
                           :transaction_histories => transaction_history_json(@transaction_history)
                       }}
    else
      render :json => {:success => " false ", :message => " Billing Histories not found "}
    end
  end

  def sign_out
    unless @user.travelling_times.last.blank?
      unless @user.travelling_times.last.latitude.blank? or @user.travelling_times.last.longitude.blank?
        if @user.travelling_times.last.clock_out.blank?
          begin
            distance = Geocoder::Calculations.distance_between([@user.travelling_times.last.latitude, @user.travelling_times.last.longitude], [@driver_lat, @driver_long])
            @user.travelling_times.last.update_attributes(:clock_out => Time.now, :total_miles => distance + @user.travelling_times.last.total_miles, :latitude => @driver_lat, :longitude => @driver_long)
            render :json => {:success => "true", :message => "Sign out successfully"}
          rescue Exception => exc
            render :json => {:success => "true", :message => "Sign out successfully"}
          end
        else
          render :json => {:success => "true", :message => "Sign out successfully"}
        end
      else
        render :json => {:success => "true", :message => "Sign out successfully"}
      end
    else
      render :json => {:success => "true", :message => "Sign out successfully"}
    end
    if @user.travelling_times.present?
      @user.travelling_times.last.update_attributes(:clock_out => Time.now)
    end
  end

  def update_driver_distance
    unless @user.travelling_times.last.blank?
      unless @user.travelling_times.last.latitude.blank? or @user.travelling_times.last.longitude.blank?
        begin
          distance = Geocoder::Calculations.distance_between([@user.travelling_times.last.latitude, @user.travelling_times.last.longitude], [@driver_lat, @driver_long])
          @user.travelling_times.last.update_attributes(:total_miles => distance + @user.travelling_times.last.total_miles, :latitude => @driver_lat, :longitude => @driver_long)
          render :json => {:success => "true", :message => "Sign out successfully"}
        rescue Exception => exc
          render :json => {:success => "true", :message => "Sign out successfully"}
        end
      else
        render :json => {:success => "true", :message => "Sign out successfully"}
      end
    else
      render :json => {:success => "true", :message => "Sign out successfully"}
    end
  end

  def get_histories
    jobs = @user.driver_jobs.where(:status => "delivered").order("delivered_date desc")
    render :json => {:success => "true",
                     :data => {
                         :jobs => jobs.blank? ? Array.new : jobs.map { |j| get_history_json(j) }
                     }}
  end

  def upload_signature
    if params[:uploaded_picture].present? and params[:job_id].present?
      job = Job.find_by_id(params[:id])
      if Asset.create!(:owner => job, :avatar => params[:uploaded_picture])
        render :json => {:success => "true", :message => "Signature image was uploaded"}
      else
        render :json => {:success => "false", :message => "Signature image was uploaded"}
      end
    else
      render :json => {:success => "false", :message => "params uploaded_picture or job id not found"}
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


  def send_notification(user, message)
    return unless user.device_token.present?
    notification = Houston::Notification.new(:device => user.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:offer_id => @offer.id, :type => @status, :code => @code}
    notification.alert = message
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

  def support_request
    unless params[:support][:description].blank?
      UserMailer.support_request(params[:support][:description], params[:support][:package_id], @user, request.host_with_port, request.protocol)
      render :json => {:success => "true", :message => "Support request successfully sent"}
    else
      render :json => {:success => "false", :message => "Support request not sent"}
    end
  end

  def cancel_order
    job = Job.find_by_id(params[:id])
    puts "PPPP", job.inspect
    @job = job if @user.driver_jobs.include?(job)
    if (@job.status == "accepted")
      job.update_attributes(:status => "available", :driver_id => nil)
      @transaction = nil
      push_notify_drivers = @job.get_push_notify_drivers(@job)
      email_notify_drivers = @job.get_email_notify_drivers(@job)
      emails = JobEmail.new(@job, @transaction, email_notify_drivers, push_notify_drivers, request.protocol, request.host_with_port)
      Delayed::Job.enqueue(emails)
      render :json => {:success => "true", :message => "Job successfully canceled"}
    else
      render :json => {:success => "false", :message => "You cannot cancel your job because job is #{@job.status}"}
    end
  end


  private

  def review_json(review)
    {:id => review.subject,
     :description => review.description,
     :rating => review.rating
    }
  end

  def transaction_history_json(th)
    {:id => th.id,
     :transaction_id => th.transaction_id,
     :status => th.status,
     :transaction_type => th.transaction_type,
     :amount => th.amount,
     #:user => user_json(@user),
     :payment_method => th.payment_method.blank? ? nil : payment_method_json(th.payment_method),
     :billing_address => th.payment_method.blank? ? nil : th.payment_method.billing_address.blank? ? nil : billing_address_json(th.payment_method.billing_address)
     #,
     #:billing_address => th.billing_address.blank? ? nil : billing_address_json(th.billing_address)
    }
  end

  def payment_method_json(pm)
    {:id => pm.id,
     :holder_name => pm.holder_name,
     :month => pm.holder_name,
     :year => pm.year,
     :cvv => pm.cvv,
     :card_number => "**** **** **** " + pm.card_number,
     :nick_name => pm.nick_name,
     :is_active => pm.is_active,
     :token => pm.token,
    }
  end

  def billing_address_json(ba)
    {:id => ba.id,
     :street_address => ba.street_address,
     :house_no => ba.house_no,
     :city => ba.city,
     :state => ba.state,
     :zip_code => ba.zip_code,
    }
  end

  def message_json(m)
    {:id => m.id,
     :sender => m.sender.blank? ? nil : {:id => m.sender.id, :full_name => m.sender.full_name},
     :receiver => m.receiver.blank? ? nil : {:id => m.receiver.id, :full_name => m.receiver.full_name},
     :subject => m.subject,
     :description => m.description,
     :status => m.status,
     :message_type => m.message_type,
     :job_id => m.job_id
    }
  end

  def map_job_json(j, lat, long)
    {:id => j.id,
     :status => j.status,
     :latitude => j.latitude,
     :longitude => j.longitude,
     :dest_latitude => j.dest_latitude,
     :dest_longitude => j.dest_longitude,
     :pick_distance => j.distance_to([lat, long]),
    }
  end

  def driver_job_json(pick_time, dest_time, j, lat, long)
    {:id => j.id,
     :job_code => j.job_code,
     :status => j.status,
     :customer_type => j.customer_type,
     :driver_id => j.driver_id,
     :driver_type => j.driver_type,
     :status => j.status,
     :distance_text => j.distance_text,
     :time_text => j.time_text,
     #:pick_up_time => j.pick_up_time.to_s,
     :pick_up_time => j.pick_up_time.in_time_zone(j.customer.time_zone).strftime("%m/%d/%y,%l:%M %p"),
     :delivery_time => pick_time.blank? ? nil : ((j.pick_up_time + j.time_value.minute) + pick_time[1].to_i.minute).in_time_zone(j.customer.time_zone).to_s,
     :is_active => j.is_active,
     :amount => j.transaction_history.blank? ? j.amount : j.transaction_history.amount,
     :pick_up_address => j.filter_pick_address,
     :pick_up_phone => j.customer.blank? ? nil : j.customer.profile.blank? ? nil : j.customer.profile.phone_number,
     :job_pick_up_phone => j.pick_up_phone,
     :pick_up_comment => j.pick_up_comment,
     :destination_address => j.filter_dest_address,
     :recipient_name => j.recipient_name,
     :recipient_phone => j.recipient_phone,
     :recipient_comment => j.recipient_comment,
     :latitude => j.latitude,
     :longitude => j.longitude,
     :dest_latitude => j.dest_latitude,
     :dest_longitude => j.dest_longitude,
     :pick_distance => j.distance_to([lat, long]).round(2),
     :delivery_distance => calculate_distance(j, lat, long),
     :pick_distance_time => pick_time.blank? ? nil : pick_time[0],
     :delivery_distance_time => dest_time.blank? ? nil : dest_time[0],
     :sender => j.customer.blank? ? nil :
         {
             :id => j.customer.id,
             :first_name => j.customer.first_name,
             :last_name => j.customer.last_name,
             :status => j.customer.status,
             :email => j.customer.email,
             :phone => j.customer.profile.blank? ? nil : j.customer.profile.phone_number
         },
     :package => j.package.blank? ? nil : {:id => j.package.id, :name => j.package.name.capitalize}
    }
  end

  def get_history_json(j)
    puts "CCCCCCCCCc", j.inspect
    {:id => j.id,
     :delivered_date => j.delivered_date.blank? ? nil : j.delivered_date.to_s,
     :job_code => j.job_code,
     :status => j.status,
     :customer_type => j.customer_type,
     :driver_id => j.driver_id,
     :driver_type => j.driver_type,
     :status => j.status,
     :distance_text => j.distance_text,
     :time_text => j.time_text,
     :pick_up_time => nil,
     :delivery_time => nil,
     :is_active => j.is_active,
     :amount => j.transaction_history.blank? ? j.amount : j.transaction_history.amount,
     :pick_up_address => j.filter_pick_address,
     :pick_up_phone => j.customer.blank? ? nil : j.customer.profile.blank? ? nil : j.customer.profile.phone_number,
     :pick_up_comment => j.pick_up_comment,
     :destination_address => j.filter_dest_address,
     :recipient_name => j.recipient_name,
     :recipient_phone => j.recipient_phone,
     :recipient_comment => j.recipient_comment,
     :latitude => j.latitude,
     :longitude => j.longitude,
     :dest_latitude => j.dest_latitude,
     :dest_longitude => j.dest_longitude,
     :pick_distance => nil,
     :delivery_distance => nil,
     :pick_distance_time => nil,
     :delivery_distance_time => nil,
     :signature => {
         :picture_url => j.asset.blank? ? nil : "#{j.asset.avatar.url}"
     },
     :sender => j.customer.blank? ? nil :
         {
             :id => j.customer.id,
             :first_name => j.customer.first_name,
             :last_name => j.customer.last_name,
             :email => j.customer.email,
             :status => j.customer.status,
             :phone => j.customer.profile.blank? ? nil : j.customer.profile.phone_number
         },
     :package => j.package.blank? ? nil : {:id => j.package.id, :name => j.package.name.capitalize}
    }
  end


  def job_json(j)
    {:id => j.id,
     :job_code => j.job_code,
     :status => j.status,
     :driver_id => j.driver_id,
     :status => j.status,
     :distance_text => j.distance_text,
     :pick_up_time => j.pick_up_time.in_time_zone(j.customer.time_zone).strftime("%m/%d/%y at %I:%M %p"),
     :delivery_time => (j.pick_up_time + j.time_value.minute).in_time_zone(j.customer.time_zone).strftime("%m/%d/%y at %I:%M %p"),
     :amount => j.amount,
     :pick_up_address => j.filter_pick_address,
     :pick_up_phone => j.pick_up_phone,
     :pick_up_comment => j.pick_up_comment,
     :destination_address => j.filter_dest_address,
     :recipient_name => j.recipient_name,
     :recipient_phone => j.recipient_phone,
     :recipient_comment => j.recipient_comment,
     :latitude => j.latitude,
     :longitude => j.longitude,
     :dest_latitude => j.dest_latitude,
     :dest_longitude => j.dest_longitude,
     :pick_distance => j.distance_to([@driver_lat, @driver_long]),
     :delivery_distance => calculate_distance(j, @driver_lat, @driver_long),
     :pick_distance_time => calculate_time(j.latitude, j.longitude),
     :delivery_distance_time => calculate_time(j.dest_latitude, j.dest_longitude),
     :sender => j.customer.blank? ? nil :
         {
             :id => j.customer.id,
             :first_name => j.customer.first_name,
             :last_name => j.customer.last_name,
             :status => j.customer.status,
             :email => j.customer.email,
             :phone => j.customer.profile.blank? ? nil : j.customer.profile.phone
         },
     :package => j.package.blank? ? nil : {:id => j.package.id, :name => j.package.name}
    }
  end

  def is_clock_in
    #travelling_times = TravellingTime.where(:user_id => @user.id)
    if @user.travelling_times.blank?
      is_clock_in = false
    else
      if @user.travelling_times.last.clock_out.blank?
        is_clock_in = true
      else
        is_clock_in = false
      end
    end
    return is_clock_in
  end


  def driver_json(u)
    {
        :id => u.id,
        :is_clock_in => is_clock_in,
        :total_time => u.total_time,
        :total_distance => u.total_distance,
        :email => u.email,
        :driver_id => u.driver_id,
        :token => u.authentication_token,
        :first_name => u.first_name,
        :last_name => u.last_name,
        :status => u.status,
        :created_at => u.created_at,
        :updated_at => u.updated_at,
        :profile => u.profile.blank? ? nil : driver_profile_json(u.profile),
        :average_rating => u.average_rating,
        :reviews => @user.driver_reviews.map { |review| review_json(review) },
        :driver_setting => @user.driver_setting
    }
  end

  def driver_profile_json(p)
    {
        :phone_number => p.phone_number,
        :phone_type_name => p.phone_type.blank? ? " " : p.phone_type.name,
        :vehicle_type_name => p.vehicle_type.blank? ? " " : p.vehicle_type.name,
        :address => p.address,
        :city => p.city,
        :state => p.state,
        :zip_code => p.zip_code,
        :picture_url => p.asset.blank? ? nil : "#{p.asset.avatar.url(:medium)}",
        :driver_type => p.vehicle_type.blank? ? "standard" : p.vehicle_type.id == 2 ? "oversize" : "standard"
    }
  end

  def asset_json(asset)
    {
        :id => asset.id,
        :owner_id => asset.owner_id,
        :owner_type => asset.owner_type,
        :avatar_file_name => asset.avatar_file_name,
        :avatar_content_type => asset.avatar_content_type,
        :avatar_file_size => asset.avatar_file_size,
        :avatar_updated_at => asset.avatar_updated_at,
        :created_at => asset.created_at,
        :updated_at => asset.updated_at,
    }
  end


  def needs_password?(user, params)
    #user.email != params[:user][:email] ||
    #    params[:user][:password].present?
    params[:user][:password].present?
  end


  def check_session_create
    puts "OOOOO"
    if params[:token].present?
      @user = User.find_by_authentication_token(params[:token])
      if @user.blank?
        puts "IIIII"
        render :json => {:success => "false", :errors => "authentication failed"}
        return
      else
        if @user.status == 'inactive'
          render :json => {:success => "false", :errors => "authentication failed"}
          return
        end
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

  def distance_vector(jobs, lat, long)
    begin
      pick_result_hash = {}
      dest_result_hash = {}
      unless jobs.blank?
        pick_string = ""
        jobs.each_with_index do |job, outer_index|
          str_array = job.pick_up_address.split(",")
          str_array.each_with_index do |st, index|
            if index < str_array.size - 1
              pick_string = pick_string + st + ","
            else
              if outer_index < jobs.size - 1
                pick_string = pick_string + st + "|"
              else
                pick_string = pick_string + st
              end
            end
          end
        end
        pick_url = "http://maps.googleapis.com/maps/api/distancematrix/xml?origins=#{pick_string}&destinations=#{lat},#{long}&mode=driving&sensor=false"
        pick_encoded_url = URI.encode(pick_url)
        @xml = Net::HTTP.get(URI.parse(pick_encoded_url))
        @result = Hash.from_xml(@xml)
        puts "FFFFFFFFFFFFFFF", @result.inspect
        if @result["DistanceMatrixResponse"]["row"].class.to_s == "Hash"
          if @result["DistanceMatrixResponse"]["row"]["element"]["status"] == "ZERO_RESULTS" or @result["DistanceMatrixResponse"]["row"]["element"]["status"] == "NOT_FOUND"
            pick_result_hash[jobs[0].id] = "0" + "_" +"0"
          else
            pick_result_hash[jobs[0].id] = @result["DistanceMatrixResponse"]["row"]["element"]["duration"]["text"] + "_" + @result["DistanceMatrixResponse"]["row"]["element"]["duration"]["value"]
          end
        else
          @result["DistanceMatrixResponse"]["row"].each_with_index do |res, index|
            if res["element"]["status"].to_s == "ZERO_RESULTS" or res["element"]["status"].to_s == "NOT_FOUND"
              pick_result_hash[jobs[index].id] = "0" + "_" +"0"
            else
              pick_result_hash[jobs[index].id] = res["element"]["duration"]["text"]
            end
          end
        end
        dest_string = ""
        unless jobs.blank?
          jobs.each_with_index do |job, outer_index|
            str_array = job.destination_address.split(",")
            str_array.each_with_index do |st, index|
              if index < str_array.size - 1
                dest_string = dest_string + st + ","
              else
                if outer_index < jobs.size - 1
                  dest_string = dest_string + st + "|"
                else
                  dest_string = dest_string + st
                end
              end
            end
          end
        end
        dest_url = "http://maps.googleapis.com/maps/api/distancematrix/xml?origins=#{dest_string}&destinations=#{lat},#{long}&mode=driving&sensor=false"
        dest_encoded_url = URI.encode(dest_url)
        @xml = Net::HTTP.get(URI.parse(dest_encoded_url))
        @result = Hash.from_xml(@xml)
        if @result["DistanceMatrixResponse"]["row"].class.to_s == "Hash"
          if @result["DistanceMatrixResponse"]["row"]["element"]["status"] == "ZERO_RESULTS" or @result["DistanceMatrixResponse"]["row"]["element"]["status"] == "NOT_FOUND"
            dest_result_hash[jobs[0].id] = "0" + "_" +"0"
          else
            dest_result_hash[jobs[0].id] = @result["DistanceMatrixResponse"]["row"]["element"]["duration"]["text"] + "_" + @result["DistanceMatrixResponse"]["row"]["element"]["duration"]["value"]
          end
        else
          @result["DistanceMatrixResponse"]["row"].each_with_index do |res, index|
            if res["element"]["status"] == "ZERO_RESULTS" or res["element"]["status"] == "NOT_FOUND"
              dest_result_hash[jobs[index].id] = "0" + "_" +"0"
            else
              dest_result_hash[jobs[index].id] = res["element"]["duration"]["text"] + "_" + res["element"]["duration"]["value"]
            end
          end
        end
      end
      return pick_result_hash, dest_result_hash
    rescue Exception => exc
      #render :json => {:success => "server", :errors => exc.message}
      puts "CCCCCCCCCCC", exc.message, pick_result_hash
      return pick_result_hash, dest_result_hash
    end
  end


  def calculate_distance(job, lat, long)
    distance = 0
    distance = Geocoder::Calculations.distance_between([lat, long], [job.dest_latitude, job.dest_longitude])
    return distance.round(2)
  end

  def calculate_time(j_lat, j_long)
    begin
      @xml = Net::HTTP.get(URI.parse("http://maps.googleapis.com/maps/api/directions/xml?origin=#{j_lat},#{j_long}&destination=#{@driver_lat},#{@driver_long}&sensor=false"))
      @result = Hash.from_xml(@xml)
      time = @result.present? ? @result["DirectionsResponse"]["route"]["leg"]["duration"]["text"] : "0"
    rescue Exception => exc
      time = distance = "0"
    end
    return time
  end


#To do

#search jobs by pick_up address


end