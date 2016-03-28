class SuperAdmin::PackagesController < SuperAdmin::SuperAdminController

  #add_breadcrumb "PRODUCTS", "/super_admin/products#index"
  layout "super_admin"
  def index
    @packages = current_user.packages.paginate(:page => params[:page], :per_page => 5)
  end

  def new
    @package = Package.new
    render :layout => false
  end

  def create
    @package = Package.new(params[:package])
    if @package.save
      flash[:notice] = "Package was successfully Added."
      render :json => {:success => true, :url => super_admin_packages_path}.to_json
    else
      @errors = @package.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def edit
    package = Package.find_by_id(params[:id])
    @package = package if current_user.packages.include?(package)
    #render :layout => false
  end

  def update
    package = Package.find_by_id(params[:id])
    @package = package if current_user.packages.include?(package)
    if @package.update_attributes(params[:package])
      flash[:notice] = "Package was successfully updated."
      render :json => {:success => true, :url => super_admin_packages_path}.to_json
    else
      @errors = @package.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def destroy
    package = Package.find_by_id(params[:id])
    @package = package if current_user.packages.include?(package)
    if @package.destroy
      flash[:notice] = "Package was successfully deleted."
      redirect_to :action => :index
    else
      flash[:alert] = "Something went wrong. Please try again later."
      redirect_to :action => :index
    end
  end

end
