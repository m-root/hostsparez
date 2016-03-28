class SuperAdmin::PhoneTypesController < SuperAdmin::SuperAdminController

  #add_breadcrumb "PRODUCTS", "/super_admin/products#index"
  layout "super_admin"

  def index
    @phone_types = current_user.phone_types
  end

  def new
    @phone_type = PhoneType.new
    #render :layout => false
  end

  def create
    @phone_type = PhoneType.new(params[:phone_type])
    if @phone_type.save
      flash[:notice] = "Phone Type was successfully Added."
      render :json => {:success => true, :url => super_admin_phone_types_path}.to_json
    else
      @errors = @phone_type.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def edit
    phone_type = PhoneType.find_by_id(params[:id])
    @phone_type = phone_type if current_user.phone_types.include?(phone_type)
    #render :layout => false
  end

  def update
    phone_type = PhoneType.find_by_id(params[:id])
    @phone_type = phone_type if current_user.phone_types.include?(phone_type)
    if @phone_type.update_attributes(params[:phone_type])
      flash[:notice] = "Phone Type was successfully updated."
      render :json => {:success => true, :url => super_admin_phone_types_path}.to_json
    else
      @errors = @phone_type.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def destroy
    phone_type = PhoneType.find_by_id(params[:id])
    @phone_type = phone_type if current_user.phone_types.include?(phone_type)
    if @phone_type.destroy
      flash[:notice] = "Phone Type was successfully deleted."
      redirect_to :action => :index
    else
      flash[:alert] = "Something went wrong. Please try again later."
      redirect_to :action => :index
    end
  end

end
