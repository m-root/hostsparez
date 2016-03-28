require 'will_paginate/array'
class Driver::JobsController < Driver::DriverController
  layout "driver"
  before_filter :authenticate_user!, :except => [:new, :sign_in_pop_up, :sign_up_pop_up, :get_package, :set_cookies]

  before_filter :except => [:new, :sign_in_pop_up, :sign_up_pop_up, :get_package, :set_cookies] do
    redirect_to root_url unless current_user.driver?
  end

  def search_jobs
    if params[:term].present?
      like = "%".concat(params[:term].downcase.concat("%"))
      @active_jobs = Job.where("lower(job_code) like ? and (status = ? or status = ? or status = ?)", like, "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = Job.where("lower(job_code) like ? and status = ?", like, "delivered").order("created_at desc")
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    else
      @active_jobs = current_user.driver_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = current_user.driver_jobs.where(:status => "delivered").order("created_at desc")
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    end
    puts "DDD", @active_jobs.inspect, @all_recent_jobs.inspect
    render :partial => "customer/jobs/shipment_history"
  end

  def search_jobs_by_date
    if params[:term].present?
      @active_jobs = current_user.customer_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc").select { |job| job.created_at.strftime("%m-%d-%Y").downcase.include?(params[:term].downcase) }
      @all_recent_jobs = current_user.customer_jobs.where(:status => "delivered").order("created_at desc").order("created_at desc").select { |job| job.created_at.strftime("%m-%d-%Y").downcase.include?(params[:term].downcase) }
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    else
      @active_jobs = current_user.customer_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = current_user.customer_jobs.where(:status => "delivered").order("created_at desc")
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    end
    render :partial => "customer/jobs/shipment_history"
  end

  def index
    @active_jobs = current_user.driver_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc")
    @all_recent_jobs = current_user.driver_jobs.where(:status => "delivered").order("created_at desc")
    @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
  end

  def show
    job = Job.find_by_id(params[:id])
    @job = job if current_user.driver_jobs.include?(job)
    @job_tax = @job.amount/100 * Preferences.first.package_tax_percentage
    if @job.status == 'delivered' or @job.status == 'picked' or @job.status == 'accepted'
      @driver_rating_whole, @driver_rating_part = @job.driver.driver_rating
    end
    if @job.status == "picked"
      @driver = @job.driver
      unless @driver.travelling_times.last.blank?
        @pack_lat = @driver.travelling_times.last.latitude
        @pack_long = @driver.travelling_times.last.longitude
      else
        @pack_lat = @job.latitude
        @pack_long = @job.longitude
      end
      begin
        @xml = Net::HTTP.get(URI.parse("http://maps.googleapis.com/maps/api/directions/xml?origin=#{@pack_lat},#{@pack_long}&destination=#{@job.dest_latitude},#{@job.dest_longitude}&sensor=false"))
        @result = Hash.from_xml(@xml)
        @time = @result.present? ? @result["DirectionsResponse"]["route"]["leg"]["duration"]["text"] : "0"
      rescue Exception => exc
        @time = distance = "0"
      end
    elsif @job.status == "delivered"
      @pack_lat = @job.dest_latitude
      @pack_long = @job.dest_longitude
      begin
        @xml = Net::HTTP.get(URI.parse("http://maps.googleapis.com/maps/api/directions/xml?origin=#{@job.latitude},#{@job.longitude}&destination=#{@job.dest_latitude},#{@job.dest_longitude}&sensor=false"))
        @result = Hash.from_xml(@xml)
        @time = @result.present? ? @result["DirectionsResponse"]["route"]["leg"]["duration"]["text"] : "0"
      rescue Exception => exc
        @time = distance = "0"
      end
    else
      @pack_lat = @job.latitude
      @pack_long = @job.longitude
      begin
        @xml = Net::HTTP.get(URI.parse("http://maps.googleapis.com/maps/api/directions/xml?origin=#{@job.latitude},#{@job.longitude}&destination=#{@job.dest_latitude},#{@job.dest_longitude}&sensor=false"))
        @result = Hash.from_xml(@xml)
        @time = @result.present? ? @result["DirectionsResponse"]["route"]["leg"]["duration"]["text"] : "0"
      rescue Exception => exc
        @time = distance = "0"
      end
    end
  end


  def sign_in_pop_up
    @user = User.new
    render :partial => "customer/jobs/sign_in_pop_up"
    #render :json => {:success => false, :html => render_to_string(:partial => 'jobs/sign_in_pop_up')}.to_json
  end

  def sign_up_pop_up
    @user = User.new
    render :partial => "customer/jobs/sign_up_pop_up"
    #render :json => {:success => false, :html => render_to_string(:partial => 'jobs/sign_in_pop_up')}.to_json
  end

  def get_location
    @location = Location.find_by_id(params[:id])
    if @location
      render :json => {:success => true, :address => @location.address, :contact_person => @location.contact_person, :contact_phone => @location.contact_phone, :nick_name => @location.nick_name, :comments => @location.comments, :city => @location.city, :zip => @location.zip_code, :state => @location.state}.to_json
    else
      render :json => {:success => true, :address => "", :contact_person => "", :contact_phone => "", :nick_name => "MY LOCATION", :comments => ""}.to_json
    end
  end

  def get_payment_method
    @payment_method = PaymentMethod.find_by_id(params[:id])
    render :json => {:success => true, :nick_name => @payment_method.blank? ? "NO NAME" : @payment_method.nick_name, :html => render_to_string(:partial => 'customer/jobs/payment_method_form', :locals => {:f => PaymentMethod.new})}.to_json
  end

  def get_package
    begin
      @package = Package.find_by_id(params[:id])
      directions = GoogleDirections.new(params[:pick_loc], params[:dest_loc])
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

  def get_billing_address
    @billing_address = BillingAddress.find_by_id(params[:id])
    #render :partial => '/jobs/billing_address_form'
    render :json => {:success => false, :html => render_to_string(:partial => 'customer//jobs/billing_address_form')}.to_json
  end

  def new

    @user = User.new
    @job = Job.new
    if session['pick_time'].present?
      @pick_time = session['pick_time']
    elsif params[:pick_time].present?
      @pick_time = params[:pick_time]
    end
    if session['pick_location'].present?
      @pick_location = session['pick_location']
    elsif params[:pick_location].present?
      @pick_location = params[:pick_location]
    end
    if session['dest_location'].present?
      @dest_location = session['dest_location']
    elsif params[:dest_location].present?
      @dest_location = params[:dest_location]
    end
    @pick_comments = session['pick_comments'].present? ? session['pick_comments'] : nil
    @dest_comments = session['dest_comments'].present? ? session['dest_comments'] : nil
    @phone = session['phone'].present? ? session['phone'] : nil
    @recipient = session['recipient'].present? ? session['recipient'] : nil

    @sender_locations = current_user.blank? ? nil : current_user.locations
    @receiver_locations = current_user.blank? ? nil : current_user.locations
    remove_cookies
  end

  def remove_cookies
    session['pick_location'] = nil
    session['dest_location'] = nil
    session['pick_time'] = nil
    session['pick_comments'] = nil
    session['dest_comments'] = nil
    session['recipient'] = nil
    session['phone'] = nil
  end

  def set_cookies
    session['pick_location'] = params[:pick_location]
    session['dest_location'] = params[:dest_location]
    session['pick_time'] = params[:pick_time]
    session['pick_comments'] = params[:pick_comments]
    session['dest_comments'] = params[:dest_comments]
    session['recipient'] = params[:recipient]
    session['phone'] = params[:phone]
    render :text => "ok"
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

  #def check_unique_address(loc)
  #  location = Geocoder.search(loc.address)
  #  latitude = location[0].latitude
  #  longitude = location[0].longitude
  #  existing_location = Location.where(:user_id => self.current_user.id).select { |location| location.latitude.round(5) == latitude.round(5) and location.longitude.round(5) == longitude.round(5) }
  #  if existing_location.present?
  #    return false
  #  else
  #    return true
  #  end
  #end


  def create
    time = Time.strptime(params[:job][:pick_up_time], '%m-%d-%Y %I:%M %p')
    params[:job][:pick_up_time] = time.strftime("%Y/%m/%d %I:%M %p")
    @job = Job.new(params[:job])
    @send_job_location = Location.new(params[:sender_location])
    #@send_job_location.contact_phone = current_user.email
    @send_job_location.contact_person = current_user.email
    @receiver_job_location = Location.new(params[:receiver_location])
    #if params[:job][:sender_location_id].blank?
    unless @send_job_location.valid?
      @errors = @send_job_location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    else
      @job.pick_up_address = @send_job_location.address
      @job.pick_up_phone = @send_job_location.contact_phone
      @job.pick_up_comment = @send_job_location.comments
    end
    #end
    #if params[:job][:receiver_location_id].blank?
    unless @receiver_job_location.valid?
      @errors = @receiver_job_location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    else
      @job.destination_address = @receiver_job_location.address
      @job.recipient_name = @receiver_job_location.contact_person
      @job.recipient_phone = @receiver_job_location.contact_phone
      @job.recipient_comment = @receiver_job_location.comments
    end
    #end
    if params[:job][:sender_location_id].blank?
      @job.sender_location_id = 1
    end
    if params[:job][:receiver_location_id].blank?
      @job.receiver_location_id = 2
    end

    unless @job.valid?
      @errors = @job.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    else
      #@job.sender_location_id = nil
      #@job.receiver_location_id = nil
    end
    #ActiveRecord::Base.transaction do |t|
    #  begin
    if params[:job][:sender_location_id].blank?
      latitude, longitude = get_lat_long(@send_job_location.address)
      loc = Location.find_by_latitude_and_longitude_and_user_id(latitude, longitude, @send_job_location.user_id)
      if loc.present?
        @job.sender_location_id = loc.id
      else
        if  @send_job_location.save
          @job.sender_location_id = @send_job_location.id
        else
          @errors = @send_job_location.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
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
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          return
        end
      end
    else
      if params[:receiver_location][:is_active] == "1"
        @job.receiver_location_id = params[:job][:receiver_location_id]
        update_receiver_location(params[:job][:receiver_location_id])
      end
    end
    if  @job.save
      session[:job_id] = @job.id
      render :json => {:success => true, :url => order_customer_jobs_path}.to_json
    else
      @errors = @job.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
    #rescue => e
    #  puts "CCCCCCCCCCCCCCccc", e.inspect
    #  render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    #end
    #end
  end

  def update_sender_location(location_id)
    @location = Location.find_by_id(location_id)
    if @location.update_attributes(params[:sender_location])
    else
      @errors = @location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
  end

  def update_receiver_location(location_id)
    @location = Location.find_by_id(location_id)
    if @location.update_attributes(params[:receiver_location])
    else
      @errors = @location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
  end


  def order
    job = Job.find(session[:job_id])
    @job = job if current_user.customer_jobs.include?(job)
    @job_tax = @job.amount/100 * Preferences.first.package_tax_percentage
    @job.update_attribute(:job_tax, @job_tax)
    @payment_methods = current_user.payment_methods
    #@hash = Gmaps4rails.build_markers(@location_array) do |location, marker|
    #  marker.lat location.latitude
    #  marker.lng location.longitude
    #end
    #@billing_addresses = BillingAddress.new
    @sender_locations = current_user.locations

  end


  def print_receipt_pdf
    job = Job.find(params[:id])
    @job = job if current_user.customer_jobs.include?(job)
    render :pdf => "Receipt Pdf", :layout => false, :template => "/customer/jobs/print_receipt_pdf"
  end

  #def create_order
  #  @job = Job.find(session[:job_id])
  #  @payment_method = PaymentMethod.new(params[:payment_method])
  #  @billing_address = BillingAddress.new(params[:billing_address])
  #  if current_user.customer_id.blank?
  #    @message = "Customer Don't have a Brain tree account"
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #    return
  #  end
  #  @customer = BraintreeRails::Customer.find(current_user.customer_id)
  #  if params[:payment_method_id].blank?
  #    unless @payment_method.valid?
  #      @errors = @payment_method.errors
  #      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #      return
  #    end
  #  end
  #  unless @billing_address.valid?
  #    @errors = @billing_address.errors
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #    return
  #  else
  #    if params[:terms].blank?
  #      @billing_address.errors.add(:term, "I agree can't be blank")
  #      @errors = @billing_address.errors
  #      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #      return
  #    end
  #  end
  #  @customer = BraintreeRails::Customer.find(current_user.customer_id)
  #  if params[:payment_method_id].blank?
  #    result = create_credit_card
  #    if result.success?
  #      @payment_method.card_number = result.credit_card.last_4
  #      @payment_method.token = result.credit_card.token
  #      if @payment_method.save
  #        puts "RRRRRRRRRRRRRRRRSSSS", @payment_method
  #      else
  #        @errors = @payment_method.errors
  #        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #        return
  #      end
  #    else
  #      @b_errors = result.errors
  #      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #      return
  #    end
  #    if @billing_address.save
  #    else
  #      @errors = @billing_address.errors
  #      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #      return
  #    end
  #    if params[:is_active_payment] == "on"
  #      @billing_address.update_attribute("is_active", true)
  #    end
  #  else
  #    @payment_method = PaymentMethod.find_by_id(params[:payment_method_id])
  #    @billing_address = create_billing_address
  #  end
  #  unless @payment_method.blank? or @billing_address.blank?
  #    result = create_transaction_with_token(@payment_method.token)
  #  end
  #  if result.success?
  #    @job = Job.find(session[:job_id])
  #    @job.update_attribute("status", "available")
  #    transaction = result.transaction
  #    final_amount = transaction.amount
  #    driver_amount = (final_amount/100) * 80
  #    ziply_revenue = final_amount - driver_amount
  #    brain_tree_fee = ((final_amount/100) * 2.9) - 0.30
  #    ziply_gross_revenue = ziply_revenue - brain_tree_fee
  #    @transaction = TransactionHistory.create!(:driver_amount => driver_amount, :ziply_revenue => ziply_revenue, :brain_tree_fee => brain_tree_fee, :ziply_gross_revenue => ziply_gross_revenue, :amount => final_amount, :user_id => current_user.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.id, :job_id => session[:job_id], :transaction_id => transaction.id, :status => transaction.status, :transaction_type => transaction.type)
  #    flash[:notice] = ":Payment Method was successfully Added."
  #    UserMailer.user_order_received(@transaction).deliver
  #    push_notify_drivers = get_push_notify_drivers(@job)
  #    email_notify_drivers = get_email_notify_drivers(@job)
  #    unless email_notify_drivers.blank?
  #      UserMailer.new_job_open(@job, email_notify_drivers).deliver
  #    end
  #    unless push_notify_drivers.blank?
  #      push_notify_drivers.each do |token|
  #        send_notification_to_drives(@job, token, "New job is open")
  #      end
  #    end
  #    record_activity("Order Placed by #{@job.customer.full_name}", @job.id)
  #    render :json => {:success => true, :url => success_customer_jobs_path}.to_json
  #  else
  #    @b_errors = result.errors
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #  end
  #end

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

  def create_order
    @job = Job.find(session[:job_id])
    @payment_method = PaymentMethod.new(params[:payment_method])
    @billing_address = BillingAddress.new(params[:billing_address])
    if current_user.customer_id.blank?
      @message = "Customer Don't have a Brain tree account"
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/order_errors')}.to_json
      return
    end
    @customer = BraintreeRails::Customer.find(current_user.customer_id)
    if params[:payment_method_id].blank?
      if @payment_method.valid? and @billing_address.valid?
      else
        @errors = []
        @payment_m_errors = @payment_method.errors
        @billing_errors = @billing_address.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/order_errors')}.to_json
        return
      end
    end
    if params[:terms].blank?
      @billing_address.errors.add(:term, "I agree can't be blank")
      @errors = @billing_address.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
    @customer = BraintreeRails::Customer.find(current_user.customer_id)
    if params[:payment_method_id].blank?
      result = create_credit_card
      if result.success?
        unless check_existing_card(result.credit_card)
          @message = "Duplicate Credit Card not allowed"
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          return
        end
        @payment_method.card_number = result.credit_card.last_4
        @payment_method.token = result.credit_card.token
        if @payment_method.save
          @billing_address.payment_method_id = @payment_method.id
        else
          @errors = @payment_method.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          return
        end
      else
        @b_errors = result.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        return
      end
      if @billing_address.save
      else
        @payment_method.destroy
        @errors = @billing_address.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        return
      end
      if params[:is_active_payment] == "1"
        @payment_method.update_attribute("is_active", true)
      end
    else
      @payment_method = PaymentMethod.find_by_id(params[:payment_method_id])
      #@billing_address = create_billing_address
      @billing_address = @payment_method.billing_address
    end
    unless @payment_method.blank?
      result = create_transaction_with_token(@payment_method.token)
    end
    if result.success?
      @job = Job.find(session[:job_id])
      @job.update_attribute("status", "available")
      transaction = result.transaction
      final_amount = transaction.amount
      driver_amount = (final_amount/100) * 80
      ziply_revenue = final_amount - driver_amount
      brain_tree_fee = ((final_amount/100) * 2.9) - 0.30
      ziply_gross_revenue = ziply_revenue - brain_tree_fee
      @transaction = TransactionHistory.create!(:driver_amount => driver_amount, :ziply_revenue => ziply_revenue, :brain_tree_fee => brain_tree_fee, :ziply_gross_revenue => ziply_gross_revenue, :amount => final_amount, :user_id => current_user.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.blank? ? nil : @billing_address.id, :job_id => session[:job_id], :transaction_id => transaction.id, :status => transaction.status, :transaction_type => transaction.type)
      flash[:notice] = ":Payment Method was successfully Added."
      #commented for now   UserMailer.user_order_received(@transaction, request.protocol, request.host_with_port).deliver
      push_notify_drivers = get_push_notify_drivers(@job)
      email_notify_drivers = get_email_notify_drivers(@job)
      unless email_notify_drivers.blank?
        UserMailer.new_job_open(@job, email_notify_drivers, request.protocol, request.host_with_port).deliver
      end
      unless push_notify_drivers.blank?
        push_notify_drivers.each do |token|
          send_notification_to_drives(@job, token, "New job is open")
        end
      end
      record_activity("Order Placed by #{@job.customer.full_name}", @job.id)
      render :json => {:success => true, :url => success_customer_jobs_path}.to_json
    else
      @b_errors = result.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def update_location
    location = Location.find_by_id(params[:billing_address_id])
    location.city = params[:billing_address][:city]
    location.state = params[:billing_address][:state]
    location.zip_code = params[:billing_address][:zip_code]
    if location.save
    else
      @errors = location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
  end

  def success
    @job = Job.find(session[:job_id])
  end

  private

  def send_notification_to_drives(job, device_token, message)
    #return unless user.device_token.present?
    notification = Houston::Notification.new(device: device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:id => job.id, :type => job.class.to_s}
    notification.alert = message
    #certificate = File.read("config/driver_certificate.pem")
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

  def get_push_notify_drivers(job)
    drivers = []
    User.drivers.each do |driver|
      unless driver.travelling_times.last.blank?
        if driver.travelling_times.last.clock_out.blank?
          distance = job.distance_to([driver.travelling_times.last.latitude, driver.travelling_times.last.longitude], units = :mi)
          if driver.driver_setting.distance_push >= distance
            drivers << driver.device_token if driver.device_token
          end
        end
      end
    end
    return drivers
  end

  def get_email_notify_drivers(job)
    drivers = []
    User.drivers.each do |driver|
      unless driver.travelling_times.last.blank?
        if driver.travelling_times.last.clock_out.blank?
          distance = job.distance_to([driver.travelling_times.last.latitude, driver.travelling_times.last.longitude], units = :mi)
          #if driver.driver_setting.distance_email >= distance
          drivers << driver
          #end
        end
      end
    end
    return drivers
  end

  def billing_hash
    puts "KKKKK", params[:billing_address][:street_address].inspect
    billing = {
        :first_name => current_user.first_name,
        :last_name => current_user.last_name,
        :street_address => params[:billing_address][:street_address],
        :extended_address => params[:billing_address][:house_no],
        :locality => params[:billing_address][:city],
        :region => params[:billing_address][:state],
        :postal_code => params[:billing_address][:zip]
    }
  end

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

  def create_billing_address
    if @billing_address.save
      return @billing_address
    else
      @errors = @billing_address.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
  end

  def create_transaction_with_token(c_card_token)
    result = Braintree::Transaction.sale(
        :customer_id => @customer.id,
        :amount => @job.amount + @job.job_tax,
        :payment_method_token => c_card_token,
        :options => {
            :submit_for_settlement => true
        }
    )
  end

  def calculate_distance(src, dest)
    begin
      @xml = Net::HTTP.get(URI.parse("http://maps.googleapis.com/maps/api/directions/xml?origin=#{src}&destination=#{dest}&sensor=false"))
      @result = Hash.from_xml(@xml)
      time = @result.present? ? @result["DirectionsResponse"]["route"]["leg"]["duration"]["text"] : "0"
    rescue Exception => exc
      time = distance = "0"
    end
    return time
  end


#def jobs_params
#  params.require(:job).permit(:customer_id, :customer_type, :sender_location_id, :sender_location_type, :receiver_location_id, :receiver_location_type, :package_id, :pick_up_time, :amount)
#end

end
