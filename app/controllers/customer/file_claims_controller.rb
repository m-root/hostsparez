class Customer::FileClaimsController < Customer::CustomerController

  before_filter :authenticate_user!

  before_filter do
    redirect_to root_url unless current_user.customer?
  end


  def index
    @file_claims = current_user.file_claims
  end

  def new
    @file_claim = FileClaim.new
    render :layout => false
  end

  def create
    @file_claim = FileClaim.new(params[:file_claim])
    if @file_claim.save
      flash[:notice] = ":File Claim was successfully Added."
      UserMailer.file_claim(@file_claim, request.protocol, request.host_with_port).deliver
      render :json => {:success => true, :url => customer_file_claims_path}.to_json
    else
      @errors = @file_claim.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def del_pop_up
    file_claim = FileClaim.find_by_id(params[:id])
    @file_claim = file_claim if current_user.file_claims.include?(file_claim)
    render :layout => false
  end

  def delete_claim
    file_claim = FileClaim.find_by_id(params[:id])
    @file_claim = file_claim if current_user.file_claims.include?(file_claim)
    if @file_claim.destroy
      render :json => {:success => true, :html => render_to_string(:partial => 'customer/file_claims/file_claim_del_success')}.to_json
    else
      render :json => {:success => false}
    end
  end


end
