class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #before_filter :configure_permitted_parameters, :if => :devise_controller?
  #before_filter :record_activity

  #def configure_permitted_parameters
  #  devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:is_disabled, :email_sent_at, :send_email, :driver_id, :authentication_token, :status, :facebook_uid, :customer_id, :first_name, :last_name, :email, :password, :password_confirmation, :device_type, :device_token, :latitude, :longitude, :profile_attributes => [:id, :user_id, :phone_number, :phone_type_id, :vehicle_type_id]) }
  #
  #  #,
  #end

  protect_from_forgery with: :exception

  def record_activity(note, job_id)
    @activity = ActivityLog.new
    @activity.user_id = current_user.id
    @activity.note = note
    @activity.browser = request.env['HTTP_USER_AGENT']
    @activity.ip_address = request.env['REMOTE_ADDR']
    @activity.controller = controller_name
    @activity.action = action_name
    #@activity.params = params.inspect
    @activity.job_id = job_id
    @activity.save
  end

  def record_activity_new(note, job_id, user_id)
    @activity = ActivityLog.new
    @activity.user_id = user_id
    @activity.note = note
    @activity.browser = request.env['HTTP_USER_AGENT']
    @activity.ip_address = request.env['REMOTE_ADDR']
    @activity.controller = controller_name
    @activity.action = action_name
    #@activity.params = params.inspect
    @activity.job_id = job_id
    @activity.save
  end

  #before_filter :configure_permitted_parameters, if: :devise_controller?
  #
  #def configure_permitted_parameters
  #  devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :platform, :remember_me, :profile_attributes => [:user_name, :dob, :gender, :status, :picture, :pictures_attributes => [:owner, :picture, :picture_type]]) }
  #  devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
  #  devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  #end

end
