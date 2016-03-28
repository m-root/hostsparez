class SuperAdmin::HomeController < SuperAdmin::SuperAdminController
  layout "super_admin"
  def index
    redirect_to super_admin_dashboard_index_path
  end

end
