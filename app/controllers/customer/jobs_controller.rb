require 'will_paginate/array'
require 'twilio-ruby'
class Customer::JobsController < Customer::CustomerController

  before_filter :authenticate_user!, :except => [:new, :sign_in_pop_up, :sign_up_pop_up, :get_package, :set_cookies, :get_package_sizes]

  before_filter :except => [:new, :sign_in_pop_up, :sign_up_pop_up, :get_package, :set_cookies, :get_package_sizes] do
    redirect_to root_url unless current_user.customer?
  end

  def cancel_order_pop_up
    job = Job.find_by_id(params[:id])
    @job = job if current_user.customer_jobs.include?(job)
    render :layout => false
  end

  def cancel_order
    job = Job.find_by_id(params[:id])
    @job = job if current_user.customer_jobs.include?(job)
    #if @job.update_attributes(:status => "canceled")
    #  render :json => {:success => true, :html => render_to_string(:partial => 'customer/jobs/order_cancel_success')}.to_json
    #else
    #  render :json => {:success => false}
    #end
    if (@job.status == "available")
      result = Braintree::Transaction.sale(
          :customer_id => @job.customer.customer_id,
          :amount => "5.00",
          :payment_method_token => @job.payment_method.token,
          :options => {
              :submit_for_settlement => true
          }
      )
      if result.success?
        if @job.update_attributes(:status => "canceled")
          send_message_to_user(job, job.customer)
          render :json => {:success => true, :html => render_to_string(:partial => '/customer/jobs/cancel_job_success')}.to_json
          #render :json => {:success => true, :message => "Job successfully canceled"}
        else
          render :json => {:success => false, :message => "Job cannot be canceled"}
        end
      else
        err = []
        @b_errors = result.errors
        @b_errors.each do |e|
          err << e.message
        end
        render :json => {:success => false, :errors => err.blank? ? "braintree error" : err.join(".\n")}
      end
    else
      render :json => {:success => false, :message => "You cannot cancel your job because job is #{@job.status}"}
    end
  end

  def get_jobs
    if params[:term].present?
      like = "%".concat(params[:term].downcase.concat("%"))
      @active_jobs = Job.where("lower(job_code) like ? and (status = ? or status = ? or status = ?)", like, "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = Job.where("lower(job_code) like ? and status = ?", like, "delivered").order("created_at desc")
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    else
      @active_jobs = current_user.customer_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = current_user.customer_jobs.where(:status => "delivered").order("created_at desc")
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
      puts "CCCCCCCCCCC", @recent_jobs.size, @all_recent_jobs.size
    end
    render :partial => "customer/jobs/shipment_history"
  end

  def search_jobs
    if params[:term].present?
      like = "%".concat(params[:term].downcase.concat("%"))
      @active_jobs = Job.where("lower(job_code) like ? and (status = ? or status = ? or status = ?)", like, "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = Job.where("lower(job_code) like ? and status = ?", like, "delivered").order("created_at desc")
      @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    else
      @active_jobs = current_user.customer_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc")
      @all_recent_jobs = current_user.customer_jobs.where(:status => "delivered").order("created_at desc")
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
    @active_jobs = current_user.customer_jobs.where("status = ? or status = ? or status = ?", "accepted", "picked", "available").order("created_at desc")
    @all_recent_jobs = current_user.customer_jobs.where(:status => "delivered").order("created_at desc")
    @recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
  end

  def show
    job = Job.find_by_id(params[:id])
    @job = job if current_user.customer_jobs.include?(job)
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
      render :json => {:success => true, :address => @location.address, :contact_person => @location.contact_person, :contact_phone => @location.contact_phone, :nick_name => @location.nick_name, :comments => @location.comments, :city => @location.city, :zip => @location.zip_code, :state => @location.state, :contact_email => @location.contact_email, :house_no => @location.house_no}.to_json
    else
      render :json => {:success => true, :address => "", :contact_person => "", :contact_phone => "", :nick_name => "MY LOCATION", :comments => ""}.to_json
    end
  end

  def get_payment_method
    @payment_method = PaymentMethod.find_by_id(params[:id])
    render :json => {:success => true, :nick_name => @payment_method.blank? ? "NO NAME" : @payment_method.nick_name, :html => render_to_string(:partial => 'customer/jobs/payment_method_form', :locals => {:f => PaymentMethod.new})}.to_json
  end


  def get_package_sizes
    begin
      #dest_original = params[:dest_loc]
      #pick_original = params[:pick_loc]
      #dest_cleaned = ""
      #pick_cleaned = ""
      #dest_original.each_byte { |x| dest_cleaned << x unless x > 127 }
      #pick_original.each_byte { |x| pick_cleaned << x unless x > 127 }
      #location1 = Geocoder.search(pick_original)
      pick_lat = params[:lat1]
      pick_long = params[:lon1]
      #location2 = Geocoder.search(dest_original)
      dest_lat = params[:lat2]
      dest_long = params[:lon2]
      #directions = GoogleDirections.new(pick_cleaned, dest_cleaned)
      #distance = directions.distance_in_miles
      pick_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{pick_lat},#{pick_long}&destination=#{dest_lat},#{dest_long}&sensor=true"
      pick_encoded_url = URI.encode(pick_url)
      json = Net::HTTP.get(URI.parse(pick_encoded_url))
      @result = JSON.parse(json)
      meters = @result['routes'][0]['legs'][0]['distance']['value'].inspect
      distance_in_km = meters.to_f/1000
      distance = distance_in_km * 0.621371
      puts "PPP", distance
      @package_1 = Package.find_by_id(1)
      pack1_amount = 0
      pack2_amount = 0
      if distance >= 1
        pack1_amount = (distance * @package_1.cost_per_mile + @package_1.basic_fee)*1.1
        if pack1_amount < @package_1.min_fare
          pack1_amount = @package_1.min_fare
        end
      else
        pack1_amount = @package_1.min_fare
      end
      @package_2 = Package.find_by_id(2)
      if distance >= 1
        pack2_amount = (distance * @package_2.cost_per_mile + @package_2.basic_fee)*1.1
        if pack2_amount < @package_2.min_fare
          pack2_amount = @package_2.min_fare
        end
      else
        pack2_amount = @package_2.min_fare
      end
      render :json => {:success => "true", :pack2_amount => "%.2f" % pack2_amount, :pack1_amount => "%.2f" % pack1_amount}
    rescue Exception => exc
      puts "FFF", exc
      render :json => {:success => "false", :message => exc}
    end
  end


  def get_package
    begin
      @package = Package.find_by_id(params[:id])
      #dest_original = params[:dest_loc]
      #pick_original = params[:pick_loc]
      #dest_cleaned = ""
      #pick_cleaned = ""
      #dest_original.each_byte { |x| dest_cleaned << x unless x > 127 }
      #pick_original.each_byte { |x| pick_cleaned << x unless x > 127 }
      #directions = GoogleDirections.new(pick_cleaned, dest_cleaned)
      #distance = directions.distance_in_miles
      #location1 = Geocoder.search(pick_original)
      #pick_lat =  location1[0].latitude
      #pick_long =  location1[0].longitude
      #location2 = Geocoder.search(dest_original)
      #dest_lat =  location2[0].latitude
      #dest_long =  location2[0].longitude
      pick_lat = params[:lat1]
      pick_long = params[:lon1]
      dest_lat = params[:lat2]
      dest_long = params[:lon2]
      pick_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{pick_lat},#{pick_long}&destination=#{dest_lat},#{dest_long}&sensor=true"
      pick_encoded_url = URI.encode(pick_url)
      json = Net::HTTP.get(URI.parse(pick_encoded_url))
      @result = JSON.parse(json)
      meters = @result['routes'][0]['legs'][0]['distance']['value'].inspect
      distance_in_km = meters.to_f/1000
      distance = distance_in_km * 0.621371
      puts "PPP", distance
      if distance >= 1
        amount = (distance * @package.cost_per_mile + @package.basic_fee)*1.1
        if amount < @package.min_fare
          amount = @package.min_fare
        end
      else
        amount = @package.min_fare
      end
      render :json => {:success => "true", :id => @package.id, :amount => "%.2f" % amount}
    rescue Exception => exc
      puts "DDD", exc
      render :json => {:success => "false", :message => exc.message}
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


    #sssss
    unless params[:sender_location][:zip_code].blank?
      zip_code1 = params[:sender_location][:zip_code]
    else
      zip_code1 = Job.get_zip_code(params[:sender_location][:city])
    end

    #zip_code2 = Job.get_zip_code(params[:receiver_location][:city])
    puts "zip_code1", zip_code1
    #puts "zip_code2", zip_code2
    params[:job][:pick_up_time] = Time.now
    #time = Time.strptime(params[:job][:pick_up_time], '%m-%d-%Y %I:%M %p')
    #params[:job][:pick_up_time] = time.strftime("%Y/%m/%d %I:%M %p")
    @job = Job.new(params[:job])
    @job.is_web = true
    if zip_code1.present?
      if Job.zip_code_existing(zip_code1) == true
    @send_job_location = Location.new(params[:sender_location])
    #@send_job_location.contact_phone = current_user.email
    @send_job_location.contact_person = current_user.email
    @receiver_job_location = Location.new(params[:receiver_location])
    #if params[:job][:sender_location_id].blank?
    unless @send_job_location.valid?
      @errors = @send_job_location.errors
      render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    else
      @job.pick_up_address = @send_job_location.address
      @job.pick_up_phone = @send_job_location.contact_phone
      @job.pick_up_email = @send_job_location.contact_email
      @job.pick_up_comment = @send_job_location.comments
      @job.sender_suit_number = @send_job_location.house_no
    end
    #end
    #if params[:job][:receiver_location_id].blank?
    unless @receiver_job_location.valid?
      @errors = @receiver_job_location.errors
      render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    else
      @job.destination_address = @receiver_job_location.address
      @job.recipient_name = @receiver_job_location.contact_person
      @job.recipient_phone = @receiver_job_location.contact_phone
      @job.recipient_email = @receiver_job_location.contact_email
      @job.recipient_comment = @receiver_job_location.comments
      @job.recipient_suit_number = @receiver_job_location.house_no
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
      render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
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
          render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
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
          render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
          return
        end
      end
    else
      if params[:receiver_location][:is_active] == "1"
        @job.receiver_location_id = params[:job][:receiver_location_id]
        update_receiver_location(params[:job][:receiver_location_id])
      end
    end
    if @job.save
      session[:job_id] = @job.id
      render :json => {:success => true, :url => order_customer_jobs_path}.to_json
      return
    else
      @errors = @job.errors
      render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
    else
      @job.errors.add(:pick_up_address, "Sorry, but your pickup location is out of range!")
      #@job.errors.add(:destination_address, "should be in Los Angeles and proper location address")
      @errors = @job.errors
      render :json => {:success => false, :err => "loc", :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
    else
      @job.errors.add(:pick_up_address, "We are unable to find zip code from your address")
      #@job.errors.add(:destination_address, "We are unable to find zip code from your address")
      @errors = @job.errors
      render :json => {:success => false, :err => "", :html => render_to_string(:partial => '/layouts/errors')}.to_json
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
    @payment_methods = current_user.payment_methods.where(:is_deleted => false)
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
    if params[:terms].blank?
      @billing_address.errors.add(:I, "agree to the Terms Of Use and Privacy Statement")
      @errors = @billing_address.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      return
    end
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
      @billing_address.errors.add(:I, "agree to the Terms Of Use and Privacy Statement")
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
        @brain_errors = result.errors
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
      result = Braintree::CreditCard.find(@payment_method.token)
      unless result.expired?
        #result = create_transaction_with_token(@payment_method.token)
        @job = Job.find(session[:job_id])
        @job.update_attributes(:status => "available", :payment_method_id => @payment_method.id, :billing_address_id => @payment_method.billing_address.id)
        push_notify_drivers = get_push_notify_drivers(@job)
        puts "DDDDDDDDDDDDDDDD", push_notify_drivers.inspect
        email_notify_drivers = get_email_notify_drivers(@job)
        @transaction = nil
        emails = JobEmail.new(@job, @transaction, email_notify_drivers, push_notify_drivers, request.protocol, request.host_with_port)
        Delayed::Job.enqueue(emails)
        unless email_notify_drivers.blank?
          #UserMailer.new_job_open(@job, email_notify_drivers, request.protocol, request.host_with_port).deliver
        end
        unless push_notify_drivers.blank?
          push_notify_drivers.each do |token|
            #send_notification_to_drives(@job, token, "New job is open")
          end
        end
        #send_sms_and_email(@job)
        #if params[:coupon_code_id].present? and params[:discount].present?
        #  @job.update_attributes(:amount => @job.amount - params[:discount].to_f, :discount => params[:discount])
        #  CouponCodeUser.create(:user_id => current_user.id, :job_id => @job.id, :coupon_code_id => params[:coupon_code_id])
        #end
        #record_activity("Order Placed by #{@job.customer.full_name}", @job.id)
        #render :json => {:success => true, :url => success_customer_jobs_path}.to_json
        #send_sms_and_email(@job)
        if params[:coupon_code_id].present? and params[:discount].present?
          @job.update_attributes(:amount => @job.amount - params[:discount].to_f, :discount => params[:discount])
          CouponCodeUser.create(:user_id => current_user.id, :job_id => @job.id, :coupon_code_id => params[:coupon_code_id])
        end
        record_activity("Order Placed by #{@job.customer.full_name}", @job.id)
        render :json => {:success => true, :url => success_customer_jobs_path}.to_json
      else
        @message = "This Credit Card is exired."
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        return
      end
    else
      render :json => {:success => false, :url => success_customer_jobs_path}.to_json
    end
    #if result.success?
    #  @job = Job.find(session[:job_id])
    #  @job.update_attribute("status", "available")
    #  transaction = result.transaction
    #  final_amount = transaction.amount
    #  driver_amount = (final_amount/100) * 80
    #  ziply_revenue = final_amount - driver_amount
    #  brain_tree_fee = ((final_amount/100) * 2.9) - 0.30
    #  ziply_gross_revenue = ziply_revenue - brain_tree_fee
    #  @transaction = TransactionHistory.create!(:driver_amount => driver_amount, :ziply_revenue => ziply_revenue, :brain_tree_fee => brain_tree_fee, :ziply_gross_revenue => ziply_gross_revenue, :amount => final_amount, :user_id => current_user.id, :payment_method_id => @payment_method.id, :billing_address_id => @billing_address.blank? ? nil : @billing_address.id, :job_id => session[:job_id], :transaction_id => transaction.id, :status => transaction.status, :transaction_type => transaction.type)
    #  flash[:notice] = ":Payment Method was successfully Added."
    #  #UserMailer.user_order_received(@transaction, request.protocol, request.host_with_port).deliver
    #  push_notify_drivers = get_push_notify_drivers(@job)
    #  puts "DDDDDDDDDDDDDDDD", push_notify_drivers.inspect
    #  email_notify_drivers = get_email_notify_drivers(@job)
    #  emails = JobEmail.new(@job,@transaction, email_notify_drivers, push_notify_drivers, request.protocol, request.host_with_port)
    #  Delayed::Job.enqueue(emails)
    #  unless email_notify_drivers.blank?
    #    #UserMailer.new_job_open(@job, email_notify_drivers, request.protocol, request.host_with_port).deliver
    #  end
    #  unless push_notify_drivers.blank?
    #    push_notify_drivers.each do |token|
    #      #send_notification_to_drives(@job, token, "New job is open")
    #    end
    #  end
    #  send_sms_and_email(@job)
    #
    #  record_activity("Order Placed by #{@job.customer.full_name}", @job.id)
    #  render :json => {:success => true, :url => success_customer_jobs_path}.to_json
    #else
    #  @b_errors = result.errors
    #  render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    #end
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

  def check_promo_code
    @code = CouponCode.find_by_code(params[:code])
    @job = Job.find_by_id(params[:id])
    @amount = @job.amount
    unless @code.blank?
      @count = current_user.CouponCodeUser.where(:coupon_code_id => @code.id).size
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
        if @code.coupon_type == "amount"
          discount = @code.coupon_value
          puts "IIIIIIIFFF", discount
        else
          discount = (@amount/100)*@code.coupon_value
          puts "ELLLLL", discount
        end
        @job_tax = @job.amount/100 * Preferences.first.package_tax_percentage
        @discount = discount
        render :json => {:success => "true", :coupon_code_id => @code.id, :code => @code.code, :discount => discount, :message => "Coupon valid", :html => render_to_string(:partial => 'customer/jobs/job_right_nav_new')}
      else
        render :json => {:success => "false", :message => "Coupon expired"}
      end
    else
      render :json => {:success => "false", :message => "invalid coupon code"}
    end
  end

  private

  def send_message_to_user(job, user)
    Message.create(:job_id => job.id, :status => "close", :subject => job.job_code, :sender_id => user.id, :sender_type => "User", :receiver_id => user.id, :receiver_type => "User", :description => "You canceled your job")
  end

  def send_sms_and_email(job)
    #if job.receiver_location.contact_method_type == 1
    #  begin
    #    account_sid = 'AC13a41cc74dc4be4df7ea0412260dca09'
    #    auth_token = 'd58dc082060bda19d97ad9352840b7f0'
    #    twilio_phone_number = "989-252-7117"
    #    @twilio_client = Twilio::REST::Client.new account_sid, auth_token
    #    @twilio_client.account.sms.messages.create(
    #        :from => "+1#{twilio_phone_number}",
    #        :to => "+1#{job.recipient_phone}",
    #        :body => "This is an message. It gets sent to #{16105557069}"
    #    )
    #  rescue Exception => exc
    #
    #  end
    #else
    #end
    begin
      #UserMailer.recipient_order(job, request.protocol, request.host_with_port).deliver
    rescue Exception => exc

    end
  end

  def send_notification_to_drives(job, device_token, message)
    #return unless user.device_token.present?
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

  def get_push_notify_drivers(job)
    drivers = []
    User.drivers.each do |driver|
      unless driver.travelling_times.last.blank?
        if driver.travelling_times.last.clock_out.blank?
          filter = driver.filtered_distance(driver)
          if filter[0]
            drivers << driver.device_token if driver.device_token
          else
            distance = job.distance_to([driver.travelling_times.last.latitude, driver.travelling_times.last.longitude], units = :mi)
            if driver.driver_setting.distance >= distance and driver.status == 'active'and driver.is_disabled == false
              drivers << driver.device_token if driver.device_token
            end
          end
        end
      end
    end
    return drivers
  end

  def get_email_notify_drivers(job)
    drivers = []
    User.drivers.each do |driver|
      filter = driver.filtered_distance(driver)
      if filter[0]
        drivers << driver
      else
        unless driver.travelling_times
          distance = job.distance_to([driver.travelling_times.last.latitude.blank? ? 0 : driver.travelling_times.last.latitude, driver.travelling_times.last.longitude.blank? ? 0 : driver.travelling_times.last.longitude], units = :mi)
          if driver.driver_setting.distance >= distance and driver.status == 'active' and driver.is_disabled == false
            drivers << driver
          end
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