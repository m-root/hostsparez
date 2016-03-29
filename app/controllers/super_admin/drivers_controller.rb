class SuperAdmin::DriversController < SuperAdmin::SuperAdminController
  #before_filter :set_partner, :except => [:create]
  layout "super_admin"

  def new_bank_account
    @user = User.find_by_id(params[:id])
    render :layout => false
  end

  def edit_bank_account
    @user = User.find_by_id(params[:id])
    merchant_account = Braintree::MerchantAccount.find(@user.customer_id)
    puts "CCCFF", merchant_account.inspect
    @first_name = merchant_account.individual_details.first_name
    @last_name = merchant_account.individual_details.first_name
    @email = merchant_account.individual_details.first_name
    @date_of_birth = merchant_account.individual_details.date_of_birth
    @phone = merchant_account.individual_details.phone
    @street_address = merchant_account.individual_details.address.street_address
    @locality = merchant_account.individual_details.address.locality
    @region = merchant_account.individual_details.address.region
    @postal_code = merchant_account.individual_details.address.postal_code
    @account_number = merchant_account.funding_details.account_number_last_4
    @routing_number = merchant_account.funding_details.routing_number
    puts "CCCC", @account_number, @routing_number.inspect
    render :layout => false
  end

  def update_bank_account
    driver = User.find_by_id(@user.id)
    puts "CCC", driver.profile.phone_number.gsub("-", "").inspect
    result = Braintree::MerchantAccount.update(
        driver.customer_id,
        :individual => {
            :first_name => driver.first_name,
            :last_name => driver.last_name,
            :email => driver.email,
            :phone => driver.profile.phone_number.gsub("-", ""),
            :date_of_birth => driver.date_of_birth,
            #:ssn => "456-45-4567",
            :address => {
                :street_address => driver.profile.address,
                :locality => driver.profile.city,
                :region => driver.profile.state,
                :postal_code => driver.profile.zip_code
            }
        },
        :funding => {
            :destination => Braintree::MerchantAccount::FundingDestination::Bank,
            :email => driver.email,
            :mobile_phone => driver.profile.phone_number.gsub("-", ""),
            :account_number => params[:account_number],
            :routing_number => params[:routing_number]
        }
    )
    if result.success?
      driver.customer_id = result.merchant_account.id
      driver.save
      return true
      #flash[:notice] = "Account was successfully added."
      #render :json => {:success => true, :url => super_admin_drivers_path}.to_json
    else
      @brain_errors = result.errors
      result.errors.each { |error| @user.errors.add(" ", error.message) }
      return false
    end
  end


  def create_bank_account
    driver = User.find_by_id(@user.id)
    puts "CCC", driver.profile.phone_number.gsub("-", "").inspect
    result = Braintree::MerchantAccount.create(
        :individual => {
            :first_name => driver.first_name,
            :last_name => driver.last_name,
            :email => driver.email,
            :phone => driver.profile.phone_number.gsub("-", ""),
            :date_of_birth => driver.date_of_birth,
            #:ssn => "456-45-4567",
            :address => {
                :street_address => driver.profile.address,
                :locality => driver.profile.city,
                :region => driver.profile.state,
                :postal_code => driver.profile.zip_code
            }
        },
        :funding => {
            :destination => Braintree::MerchantAccount::FundingDestination::Bank,
            :email => driver.email,
            :mobile_phone => driver.profile.phone_number.gsub("-", ""),
            :account_number => params[:account_number],
            :routing_number => params[:routing_number]
        },
        :tos_accepted => true,
        :master_merchant_account_id => "ZiplyNetworkInc_marketplace"
    )
    puts "RRR", result.success?
    if result.success?
      driver.customer_id = result.merchant_account.id
      driver.save
      return true
      #flash[:notice] = "Account was successfully added."
      #render :json => {:success => true, :url => super_admin_drivers_path}.to_json
    else
      @brain_errors = result.errors
      result.errors.each { |error| @user.errors.add(" ", error.message) }
      return false
    end
  end

  #def create_bank_account
  #  driver = User.find_by_id(params[:driver_id])
  #  profile = driver.profile
  #  @result = Braintree::MerchantAccount.create(
  #      :applicant_details => {
  #          :first_name => driver.first_name,
  #          :last_name => driver.last_name,
  #          :email => driver.email,
  #          :phone => params[:phone],
  #          :address => {
  #              :street_address => params[:street_address],
  #              :postal_code => params[:zip_code],
  #              :locality => params[:city],
  #              :region => params[:state],
  #          },
  #          :date_of_birth => params[:date_of_birth],
  #          :routing_number => params[:routing_number],
  #          :account_number => params[:account_number]
  #      },
  #      :tos_accepted => true,
  #      #:master_merchant_account_id => ENV["BRAINTREE_ID"]
  #      :master_merchant_account_id => "6tqp5fwytxqdh5gv"
  #  )
  #  if @result.success?
  #    driver.customer_id = @result.merchant_account.id
  #    driver.save
  #    render :json => {:success => true}
  #  else
  #    @brain_errors = @result.errors
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #  end
  #
  #end

  def index
    @active_drivers = User.active_drivers
    @in_active_drivers = User.in_active_drivers
  end

  def new
    @user = User.new
    #render :layout => false
  end

  def create
    unless params[:user][:date_of_birth].blank?
      time = Time.strptime(params[:user][:date_of_birth], '%m-%d-%Y')
      params[:user][:date_of_birth] = time.strftime("%Y/%m/%d")
    end
    @user = User.new(params[:user])
    @user.roles << Role.find_by_name("driver")
    if @user.save and clone_driver(@user)
      UserMailer.confirm_driver(@user, request.protocol, request.host_with_port, params[:user][:password]).deliver
      render :json => {:success => true, :url => super_admin_drivers_path}.to_json
    else
      @errors = @user.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def confirm_pop_up
    @user = User.find_by_id(params[:id])
    render :layout => false
  end

  def invite
    @user = User.find_by_id(params[:id])
    generated_password = Devise.friendly_token.first(8)
    if @user.update_attributes(:is_disabled => false, :status => "active", :send_email => true, :email_sent_at => Time.now())
      # UserMailer.confirm_driver(@user, request.protocol, request.host_with_port, generated_password).deliver
      @active_drivers = User.active_drivers
      @in_active_drivers = User.in_active_drivers
      render :partial => "super_admin/drivers/list"
    end
  end

  def edit
    @user = User.find_by_id(params[:id])
    unless @user.customer_id.blank?
      merchant_account = Braintree::MerchantAccount.find(@user.customer_id)
      @account_number = merchant_account.funding_details.account_number_last_4
      @routing_number = merchant_account.funding_details.routing_number
    end

    #render :layout => false
  end

  def update
    unless params[:user][:date_of_birth].blank?
      time = Time.strptime(params[:user][:date_of_birth], '%m-%d-%Y')
      params[:user][:date_of_birth] = time.strftime("%Y/%m/%d")
    end
    @user = User.find_by_id(params[:id])
    successfully_updated = if needs_password?(@user, params)
                             @user.update(params[:user])
                           else
                             params[:user].delete(:password)
                             @user.update_without_password(params[:user])
                           end
    if successfully_updated
      if @user.customer_id.blank?
        if create_bank_account
          flash[:notice] = "Driver was successfully Updated."
          render :json => {:success => true, :url => super_admin_drivers_path}.to_json
        else
          @errors = @user.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      else
        if params[:account_number] and params[:routing_number].present?
          if update_bank_account
            flash[:notice] = "Driver was successfully Updated."
            render :json => {:success => true, :url => super_admin_drivers_path}.to_json
          else
            @errors = @user.errors
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          end
        else
          flash[:notice] = "Driver was successfully Updated."
          render :json => {:success => true, :url => super_admin_drivers_path}.to_json
        end
      end
    else
      @errors = @user.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  #def update
  #  @user = User.find_by_id(params[:id])
  #  if @user.update_without_password(params[:user])
  #    flash[:notice] = "Driver was successfully updated."
  #    @user = User.send_reset_password_instructions(params[:user])
  #    #if successfully_sent?(@user)
  #    #  head :status => 200
  #    #else
  #    #  render :status => 422, :json => {:errors => @user.errors.full_messages}
  #    #end
  #    render :json => {:success => true, :url => super_admin_drivers_path}.to_json
  #
  #  else
  #    @errors = @user.errors
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #  end
  #end

  def show
    @user = User.find_by_id(params[:id])
    @jobs = @user.driver_jobs.where(:status => "delivered").order("id desc")
    if @user.customer_id.present?
      merchant_account = Braintree::MerchantAccount.find(@user.customer_id)
      @first_name = merchant_account.individual_details.first_name
      @last_name = merchant_account.individual_details.first_name
      @email = merchant_account.individual_details.first_name
      @date_of_birth = merchant_account.individual_details.date_of_birth
      @phone = merchant_account.individual_details.phone
      @street_address = merchant_account.individual_details.address.street_address
      @locality = merchant_account.individual_details.address.locality
      @region = merchant_account.individual_details.address.region
      @postal_code = merchant_account.individual_details.address.postal_code
      @account_number = merchant_account.funding_details.account_number_last_4
      @routing_number = merchant_account.funding_details.routing_number
    end
    unless @user.driver?
      redirect_to super_admin_drivers_path
    else
      @jobs = @jobs.paginate(:page => params[:page], :per_page => 5)
    end
  end

  def destroy
    user = User.find_by_id(params[:id])
    @driver = user if @partner.drivers.include?(user)
    if @driver.destroy
      flash[:notice] = "Driver was successfully Deleted."
      redirect_to super_admin_partner_path(@partner)
    else
      flash[:alert] = "Something went wrong. Please try again later."
      redirect_to super_admin_driver_path(:id => @driver.id, :partner_id => @driver.partner.id)
    end
  end

  def disable_driver
    @user = User.find_by_id(params[:id])
    if @user.update_attributes(:status => params[:status])
      @active_drivers = User.active_drivers
      @in_active_drivers = User.in_active_drivers
      render :partial => "super_admin/drivers/list"
    end
  end

  def track_driver
    @driver = User.find_by_id(params[:id])
    @driver_lat_long = User.find_by_id(params[:id]).travelling_times.last
  end

  def get_lat_long
    @updated_lat_long = User.find_by_id(params[:id]).travelling_times.last
    # @updated_lat_long.update_attributes(:latitude => @updated_lat_long.latitude.to_f + 0.025, :longitude => @updated_lat_long.longitude.to_f + 0.025)
    render :json => {:updated_lat_long => @updated_lat_long}
  end

  private

  def needs_password?(user, params)
    params[:user][:password].present?
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
