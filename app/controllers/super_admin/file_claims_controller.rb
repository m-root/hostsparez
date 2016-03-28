class SuperAdmin::FileClaimsController < SuperAdmin::SuperAdminController
  def index
    @active_file_claims = FileClaim.where(:status => "In Progress")
    @file_claim_history = FileClaim.where(:status => "Claimed")
  end

  def claim_file
   @file_claim =  FileClaim.find(params[:id])
   if @file_claim.update_attributes(:status => "Claimed")
     render :json => {:success => true, :message => 'message send', :url => "/super_admin/file_claims"}
   else
     render :json => {:success => false, :message => 'message send '}
   end

  end

end
