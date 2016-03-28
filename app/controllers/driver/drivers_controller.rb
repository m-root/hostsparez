class Driver::DriversController < Driver::DriverController

  before_filter :authenticate_user!

  def profile

    unless current_user.profile.blank?
      @profile = current_user.profile
    else
      @profile = Profile.new
    end
    render :layout => false
  end

  def create

    #@profile = Profile.new(params[:profile])
    if current_user.update(params[:user])
      flash[:notice] = ":Photo was successfully Added."
      #render :json => {:success => true, :url => customer_dashboard_index_path}.to_json
      redirect_to customer_dashboard_index_path
    else
      @errors = current_user.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  #def upload_photo
  #  @user = User.find(current_user.id)
  #  puts "FFFFFFFFFF", @user.inspect
  #  if @user.update(params[:user])
  #    flash[:notice] = "Customer was successfully updated."
  #    render :json => {:success => true, :url => dashboard_index_path}.to_json
  #  else
  #    @errors = @user.errors
  #    render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
  #  end
  #end

  def update
    #@profile = Profile.find_by_user_id(current_user.id)
    if current_user.update(params[:user])
      flash[:notice] = "Photo was successfully updated."
      #render :json => {:success => true, :url => customer_dashboard_index_path}.to_json
      redirect_to customer_dashboard_index_path
    else
      @errors = current_user.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

end
