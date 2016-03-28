class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)
    #@user.skip_confirmation!
    if @user.persisted?
      #sign_in_and_redirect @user #, :event => :authentication #this will throw if @user is not activated
      sign_in(@user)
      redirect_to new_customer_job_path
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      #sign_in(@user.first_name, @user)
      #redirect_to "sign_up"
      #facebook();
      #redirect_to after_sign_in_path_for(current_user)
      @errors = @user.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

end