class Driver::BankAccountsController < Driver::DriverController

  before_filter :authenticate_user!

  def edit_account
    @user = current_user
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

  def index
    @billings = current_user.billings
    @account_number = nil
    if current_user.customer_id.present?
      merchant_account = Braintree::MerchantAccount.find(current_user.customer_id)
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
    else
    end
  end

  def update_account
    result = Braintree::MerchantAccount.update(
        current_user.customer_id,
        :funding => {
            :destination => Braintree::MerchantAccount::FundingDestination::Bank,
            :email => current_user.email,
            :mobile_phone => params[:phone],
            :account_number => params[:account_number],
            :routing_number => params[:routing_number]
        })
    if result.success?
      render :json => {:success => true}
    else
      @brain_errors = result.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

end
