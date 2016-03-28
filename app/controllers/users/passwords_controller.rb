class Users::PasswordsController < Devise::PasswordsController
  def new
    super
    render :layout => false
  end

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      #render :json => {:success => true, :user_id => resource.id, :url => after_sending_reset_password_instructions_path_for(resource_name)}
      render :json => {:success => true, :html => render_to_string(:partial => 'users/passwords/success')}.to_json
      #respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      @errors = resource.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      #respond_with(resource)
    end
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message(:notice, flash_message) if is_flashing_format?
      #respond_with resource, :location => after_resetting_password_path_for(resource)
      if resource.driver?
        sign_in(resource_name, resource)
        render :json => {:success => true, :role => "driver"}
      else
        sign_in(resource_name, resource)
        render :json => {:success => true, :role => "customer"}
      end

    else
      #respond_with resource
      @errors = resource.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  protected
  def after_resetting_password_path_for(resource)
    after_sign_in_path_for(resource)
  end

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(resource_name)
    new_session_path(resource_name) if is_navigational_format?
  end

  # Check if a reset_password_token is provided in the request
  def assert_reset_token_passed
    if params[:reset_password_token].blank?
      set_flash_message(:alert, :no_token)
      redirect_to new_session_path(resource_name)
    end
  end

  # Check if proper Lockable module methods are present & unlock strategy
  # allows to unlock resource on password reset
  def unlockable?(resource)
    resource.respond_to?(:unlock_access!) &&
        resource.respond_to?(:unlock_strategy_enabled?) &&
        resource.unlock_strategy_enabled?(:email)
  end

end
