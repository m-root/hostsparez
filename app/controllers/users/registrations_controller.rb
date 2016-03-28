class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_authenticity_token

  def change_password
    @user = current_user
    render :layout => false
  end

  #def update_password
  #  @user= current_user
  #  if @user.update_with_password(params[:user])
  #    sign_in(@user, :bypass => true)
  #    flash[:notice] = "Password Successfully Change"
  #    render :json => {:success => true}.to_json
  #  else
  #    @errors = @user.errors
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #  end
  #end

  def invite_complete
    @user = User.find(params[:id])
    #render :layout => false
  end

  def choose_username

  end

  def choose_driver_id
    @user = User.find(params[:id])
    if @user.customer_id.present?
      redirect_to "/invite_complete?id=#{@user.id}"
    end
  end

  def update_driver
    unless params[:user][:date_of_birth].blank?
      time = Time.strptime(params[:user][:date_of_birth], '%m-%d-%Y')
      params[:user][:date_of_birth] = time.strftime("%Y/%m/%d")
      @user = User.find_by_driver_code(params[:id])
      if @user.update(params[:user])
        if create_bank_account(@user)
          if @merchant_account_id.present?
            @user.update_attribute(:customer_id, @merchant_account_id)
            flash[:notice] = "Driver was successfully Updated."
            render :json => {:success => true, :url => super_admin_drivers_path}.to_json
          else
            @errors = @user.errors
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          end
        else
          @errors = @user.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      end
    end
  end

  def update_password
    @user = current_user
    if params[:user][:current_password].blank?
      @message = "Please enter current password"
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    elsif params[:user][:password].blank?
      @message = "Please enter New password"
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    elsif params[:user][:password_confirmation].blank?
      @message = "Please enter confirm password"
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    else
      if params[:user][:password] == params[:user][:password_confirmation]
        if @user.valid_password?(params[:user][:current_password])
          @user.update_attribute('password', params[:user][:password])
          sign_in(@user, :bypass => true)
          render :json => {:success => true, :html => render_to_string(:partial => 'users/registrations/password_change_success')}.to_json
        else
          @message = "Current password is invalid"
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      else
        @message = "password and confirm password mismatch"
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      end
    end
  end


  def new
    build_resource({})
    #respond_with self.resource

    render :layout => false
  end

  def create
    unless params[:user][:date_of_birth].blank?
      time = Time.strptime(params[:user][:date_of_birth], '%m-%d-%Y')
      params[:user][:date_of_birth] = time.strftime("%Y/%m/%d")
    end
    build_resource(sign_up_params)
    if params[:role] == 'driver'
      resource.roles << Role.find_by_name("driver")
      resource.is_disabled = true
      resource.status = 'in_active'
      if params[:user][:profile_attributes][:phone_type_id].blank?
        resource.errors.add(:driver, "Phone type can't be blank")
        @errors = resource.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        return
      end
      if params[:user][:profile_attributes][:vehicle_type_id].blank?
        resource.errors.add(:driver, "Vehicle type can't be blank")
        @errors = resource.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        return
      end
      user_exists = User.where(:email => params[:user][:email]).first
      if user_exists.blank?
        if create_bank_account(resource)
          if @merchant_account_id.present?
            resource.customer_id = @merchant_account_id
            if resource.save and clone_driver(resource)
              UserMailer.new_driver(resource).deliver
              render :json => {:success => true, :role => "driver", :user_id => resource.id}
            else
              clean_up_passwords resource
              @errors = resource.errors
              render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
            end
          else
            @errors = resource.errors
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          end
        else
          @errors = resource.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      else
        resource.errors.add(:email, "This email has already been taken by #{user_exists.role}")
        @errors = resource.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      end
    else
      resource.roles << Role.find_by_name("customer")
      puts "FFFssss", request.format(request)
      unless params[:user][:device_type] == "ios"
        user_exists = User.where(:email => params[:user][:email]).first
        if user_exists.blank?
          if resource.save and resource.clone_customer_setting(resource)
            yield resource if block_given?
            if resource.active_for_authentication?
              set_flash_message :notice, :signed_up if is_flashing_format?
              sign_up(resource_name, resource)
              #respond_with resource, :location => after_sign_up_path_for(resource)
              UserMailer.welcome_customer(resource, request.protocol, request.host_with_port).deliver
              render :json => {:success => true, :role => "customer", :user_id => resource.id, :url => after_sign_up_path_for(resource)}
            else
              set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
              expire_data_after_sign_in!
              respond_with resource, :location => after_inactive_sign_up_path_for(resource)
            end
          else
            clean_up_passwords resource
            if params[:role] == 'driver'
              if params[:user][:profile_attributes][:phone_type_id].blank?
                resource.errors.add(:phone_type_id, "Phone type can't be blank")
              end
              if params[:user][:profile_attributes][:vehicle_type_id].blank?
                resource.errors.add(:phone_type_id, "Vehicle type can't be blank")
              end
            end
            @errors = resource.errors
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
            #respond_with resource
          end
        else
          resource.errors.add(:email, "This email has already been taken by #{user_exists.role}")
          @errors = resource.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      else
        create_json
      end
    end
  end


  def create_json
    resource.is_disabled = false
    if params[:user][:facebook_uid].blank?
      user_exists = User.where(:email => params[:user][:email]).first
      if user_exists.blank?
        unless params[:user][:time_zone].blank?
          if resource.save and resource.clone_customer_setting(resource)
            UserMailer.welcome_customer(resource, request.protocol, request.host_with_port).deliver
            render :json => {:success => "true",
                             :data => {
                                 :customer => resource.customer_json(resource),
                                 :package_sizes => Package.packages_json(),
                                 :payment_methods => PaymentMethod.payment_method_json(resource)
                             }}
          else
            error_string = ""
            resource.errors.full_messages.each do |msg|
              error_string += msg
            end
            puts "CCC", resource.errors.inspect
            render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
          end
        else
          render :json => {:success => "false", :message => "Time zone is blank"}
        end
      else
        render :json => {:success => "false", :message => "This email has already been taken by #{user_exists.role}"}
      end
    else
      user = User.where(:facebook_uid => params[:user][:facebook_uid]).first
      if user.blank?
        resource.password = Devise.friendly_token[0, 20]
        if resource.save and resource.clone_customer_setting(resource)
          UserMailer.welcome_customer(resource, request.protocol, request.host_with_port).deliver
          render :json => {:success => "true",
                           :data => {
                               :customer => resource.customer_json(resource, true),
                               :package_sizes => Package.packages_json(),
                               :payment_methods => resource.payment_method_json(resource)
                           }}
        else
          error_string = ""
          resource.errors.full_messages.each do |msg|
            error_string += msg
          end
          render :json => {:success => "false", :message => "Something went wrong #{error_string}"}
        end
      else
        render :json => {:success => "true",
                         :data => {
                             :customer => user.customer_json(user),
                             :package_sizes => Package.packages_json(),
                             :payment_methods => user.payment_method_json(user)
                         }}
      end
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:is_disabled, :date_of_birth, :company_name, :time_zone, :email_sent_at, :send_email, :driver_id, :authentication_token, :status, :facebook_uid, :customer_id, :first_name, :last_name, :email, :password, :password_confirmation, :device_type, :device_token, :latitude, :longitude, :profile_attributes => [:id, :user_id, :phone_number, :phone_type_id, :vehicle_type_id, :address, :city, :state, :zip_code])
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

  def create_bank_account(driver)
    result = Braintree::MerchantAccount.create(
        :individual => {
            :first_name => params[:user][:first_name],
            :last_name => params[:user][:last_name],
            :email => params[:user][:email],
            :phone => params[:user][:profile_attributes][:phone_number].gsub("-", ""),
            :date_of_birth => params[:user][:date_of_birth],
            #:ssn => "456-45-4567",
            :address => {
                :street_address => params[:user][:profile_attributes][:address],
                :locality => params[:user][:profile_attributes][:city],
                :region => params[:user][:profile_attributes][:state],
                :postal_code => params[:user][:profile_attributes][:zip_code]
            }
        },
        :funding => {
            :destination => Braintree::MerchantAccount::FundingDestination::Bank,
            :email => params[:user][:email],
            :mobile_phone => params[:user][:profile_attributes][:phone_number].gsub("-", ""),
            :account_number => params[:account_number],
            :routing_number => params[:routing_number]
        },
        :tos_accepted => true,
        :master_merchant_account_id => "ZiplyNetworkInc_marketplace"
    )
    puts "RRR", result.success?
    if result.success?
      @merchant_account_id = result.merchant_account.id
      #driver.customer_id = result.merchant_account.id
      #driver.save
      return true
      #flash[:notice] = "Account was successfully added."
      #render :json => {:success => true, :url => super_admin_drivers_path}.to_json
    else
      @merchant_account_id = nil
      @brain_errors = result.errors
      #result.errors.each { |error| @user.errors.add(" ", error.message) }
      return false
    end
  end


end
