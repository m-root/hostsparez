#require 'net/http'
#require 'american_date'
require 'open-uri'
class HomeController < ApplicationController
  include ActionView::Helpers::DateHelper


  def contact_us_message
      UserMailer.contact_us(params[:contact][:name], params[:contact][:email],params[:contact][:subject],params[:contact][:message], request.protocol, request.host).deliver
      render :json => {:success => true, :message => "Your Message successfully delivered "}
  end

  def confirmed_driver
    @user = User.new
  end

  def create_confirm_driver
    if params[:user][:profile_attributes][:phone_type_id] == "1"
      UserMailer.confirmed_driver(params[:user][:first_name],params[:user][:last_name],params[:user][:email], params[:user][:profile_attributes][:phone_number],params[:user][:profile_attributes][:vehicle_type_id],request.protocol, request.host).deliver
      render :json => {:success => true, :is_type => true}
    else
      render :json => {:success => false, :is_type => true}
    end

  end

  def new_index
    file_claim = FileClaim.find_by_id(9)
    @job = file_claim.job
    @user = file_claim.user
    @file_claim = file_claim

  end

  def distance a, b
    rad_per_deg = Math::PI/180 # PI / 180
    rkm = 6371 # Earth radius in kilometers
    rm = rkm * 1000 # Radius in meters

    dlon_rad = (b[1]-a[1]) * rad_per_deg # Delta, converted to rad
    dlat_rad = (b[0]-a[0]) * rad_per_deg

    lat1_rad, lon1_rad = a.map! { |i| i * rad_per_deg }
    lat2_rad, lon2_rad = b.map! { |i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.asin(Math.sqrt(a))

    m = rm * c # Delta in meters
    return m/1609.344
  end

  def track_package
    #@job = Job.find_by_job_code(params[:id])
  end

  def search_package
    @job = Job.find_by_job_code(params[:id])
    unless @job.blank?
      render :json => {:success => true, :id => @job.job_code}
    else
      render :json => {:success => false}
    end
  end

  def get_location(long_lat)
    abc = Geocoder.search(long_lat)
    city = ""
    country = ""
    state = ""
    unless abc.blank?
      abc[0].address_components.each do |address_component|
        puts "CCC", address_component.inspect
        address_component["types"].each do |type|
          if type == "locality"
            city = address_component["long_name"]
          end
          if type == "country"
            country = address_component["long_name"]
          end
          if type == "administrative_area_level_1"
            state = address_component["long_name"]
          end
        end
      end
    end
    return country, state, city
  end

  def track_package_result
    @job = Job.find_by_job_code(params[:id])
    @driver = @job.driver
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

  def send_notification(user, message)
    return unless user.device_token.present?
    notification = Houston::Notification.new(device: user.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:id => @message.id, :type => @message.class.to_s}
    notification.alert = message
    certificate = File.read("config/driver_certificate.pem")
    pass_phrase = "password"
    connection = Houston::Connection.new("apn://gateway.sandbox.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

  def index
    unless current_user.blank?
      redirect_to "/#{current_user.role}s" if user_signed_in?
    end
  end

  def minutes_in_words(minutes)
    distance_of_time_in_words(Time.at(0), Time.at(minutes * 60))
  end


  def new

  end

  def edit


  end

  def become_driver
    @user = User.new
  end

  def ziply_update
    UserMailer.ziply_update(request, params[:user][:email]).deliver
    render :json => {:success => true}
  end

  def new_driver
    @user = User.new
    @user.first_name = params[:name]
    @user.email = params[:email]
    render :json => {:success => true, :html => render_to_string(:partial => 'home/driver_form')}.to_json
  end

  def driver_success
    render :partial => 'home/driver_success'
    #render :layout => false
    #render :json => {:success => true, :html => render_to_string(:partial => 'home/driver_success')}.to_json
  end

  def driver_success_account
    render :partial => 'home/driver_success_account'
    #render :layout => false
    #render :json => {:success => true, :html => render_to_string(:partial => 'home/driver_success')}.to_json
  end

  def shipping_policy
  end

  def blogs
    @blogs = Blog.where(:is_archived => false)
  end

  def clone_driver(driver)
    driver_setting = DriverSetting.where(:user_id => nil).first
    new_driver_setting = DriverSetting.new
    new_driver_setting.user_id = driver.id
    new_driver_setting.is_job_push = driver_setting.is_job_push
    new_driver_setting.is_rating_push = driver_setting.is_rating_push
    new_driver_setting.is_message_push = driver_setting.is_message_push
    new_driver_setting.is_job_email = driver_setting.is_job_email
    new_driver_setting.is_rating_email = driver_setting.is_rating_email
    new_driver_setting.is_message_email = driver_setting.is_message_email
    new_driver_setting.distance_push = driver_setting.distance_push
    new_driver_setting.distance_email = driver_setting.distance_email
    new_driver_setting.save
  end

end
