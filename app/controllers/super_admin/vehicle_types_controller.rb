class SuperAdmin::VehicleTypesController < SuperAdmin::SuperAdminController
  layout "super_admin"
  #add_breadcrumb "PRODUCTS", "/super_admin/products#index"

  def index
    @vehicle_types = current_user.vehicle_types
  end

  def new
    @vehicle_type = VehicleType.new
    #render :layout => false
  end

  def create
    @vehicle_type = VehicleType.new(params[:vehicle_type])
    if @vehicle_type.save
      flash[:notice] = "Vehicle Type was successfully Added."
      render :json => {:success => true, :url => super_admin_vehicle_types_path}.to_json
    else
      @errors = @vehicle_type.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def edit
    vehicle_type = VehicleType.find_by_id(params[:id])
    @vehicle_type = vehicle_type if current_user.vehicle_types.include?(vehicle_type)
    #render :layout => false
  end

  def update
    vehicle_type = VehicleType.find_by_id(params[:id])
    @vehicle_type = vehicle_type if current_user.vehicle_types.include?(vehicle_type)
    if @vehicle_type.update_attributes(params[:vehicle_type])
      flash[:notice] = "Vehicle Type was successfully updated."
      render :json => {:success => true, :url => super_admin_vehicle_types_path}.to_json
    else
      @errors = @vehicle_type.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def destroy
    vehicle_type = VehicleType.find_by_id(params[:id])
    @vehicle_type = vehicle_type if current_user.vehicle_types.include?(vehicle_type)
    if @vehicle_type.destroy
      flash[:notice] = "Vehicle Type was successfully deleted."
      redirect_to :action => :index
    else
      flash[:alert] = "Something went wrong. Please try again later."
      redirect_to :action => :index
    end
  end

end
