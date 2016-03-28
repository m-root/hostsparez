class Customer::PaymentMethodsController < Customer::CustomerController

  before_filter :authenticate_user!

  def del_pop_up
    payment_method = PaymentMethod.find_by_id(params[:id])
    @payment_method = payment_method if current_user.payment_methods.include?(payment_method)
    render :layout => false
  end

  def delete_payment_method
    payment_method = PaymentMethod.find_by_id(params[:id])
    @payment_method = payment_method if current_user.payment_methods.include?(payment_method)
    @jobs = Job.where(:payment_method_id => @payment_method.id)
    if @jobs.blank?
      result = Braintree::CreditCard.delete(@payment_method.token)
      puts "RRRR", result.inspect
      if result == true
        if @payment_method.update_attribute(:is_deleted, true)
          render :json => {:success => true, :html => render_to_string(:partial => 'customer/payment_methods/payment_method_del_success')}.to_json
        else
          render :json => {:success => true, :html => render_to_string(:partial => 'customer/payment_methods/payment_method_del_error')}.to_json
        end
      else
        render :json => {:success => true, :html => render_to_string(:partial => 'customer/payment_methods/payment_method_del_error')}.to_json
      end
    else
      @flag = false
      @jobs.each do |job|
        if job.status != "delivered"
          @flag = true
        end
      end
      if @flag == false
        result = Braintree::CreditCard.delete(@payment_method.token)
        if result == true
          if @payment_method.update_attribute(:is_deleted, true)
            render :json => {:success => "true", :message => "Payment method successfully deleted"}
          else
            render :json => {:success => true, :html => render_to_string(:partial => 'customer/payment_methods/payment_method_del_error')}.to_json
          end
        else
          render :json => {:success => true, :html => render_to_string(:partial => 'customer/payment_methods/payment_method_del_error')}.to_json
        end
      else
        @error = "Your posted job against this card is not delivered so you cannot delete this card"
        render :json => {:success => true, :html => render_to_string(:partial => 'customer/payment_methods/payment_method_del_error')}.to_json
      end
    end
  end

  def new
    @payment_method = PaymentMethod.new
    render :layout => false
  end

  def index
    @payment_methods = PaymentMethod.where(:is_deleted => false, :user_id => current_user.id).paginate(:page => params[:page], :per_page => 5)
  end

  def check_existing_card(card)
    flag = false
    @customer.credit_cards.each do |credit_card|
      if credit_card.unique_number_identifier == card.unique_number_identifier
        flag = true
        break
      end
    end
    if flag == true
      res = Braintree::CreditCard.delete(card.token)
      return false
    else
      return true
    end
  end

  def create
    #begin
    @payment_method = PaymentMethod.new(params[:payment_method])
    if @payment_method.valid?
      @customer = BraintreeRails::Customer.find(current_user.customer_id)
      unless @customer.blank?
        result = Braintree::CreditCard.create(
            :customer_id => @customer.id,
            :number => params[:payment_method][:card_number],
            :cvv => params[:payment_method][:cvv],
            :expiration_month => params[:payment_method][:month],
            :expiration_year => params[:payment_method][:year],
            :cardholder_name => params[:payment_method][:holder_name],
            :billing_address => {
                :first_name => current_user.first_name,
                :last_name => current_user.last_name,
                :street_address => @payment_method.billing_address.street_address,
                :extended_address => @payment_method.billing_address.house_no,
                :locality => @payment_method.billing_address.city,
                :region => @payment_method.billing_address.state,
                :postal_code => @payment_method.billing_address.zip_code
            },
            :options => {
                :verify_card => true
            }
        )
        if result.success?
          unless check_existing_card(result.credit_card)
            @message = "Duplicate Card not allowed"
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
            return
          end
          @payment_method.card_number = result.credit_card.last_4
          @payment_method.token = result.credit_card.token
          if @payment_method.save
            flash[:notice] = ":Payment Method was successfully Added."
            render :json => {:success => true, :url => customer_payment_methods_path}.to_json
          else
            @errors = @payment_method.errors
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          end
        else
          @brain_errors = result.errors
          @brain_errors_txt = result.credit_card_verification.present? ? result.credit_card_verification.processor_response_text : nil
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      else
      end
    else
      @errors = @payment_method.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
    #rescue Exception => e
    #  @message = e.message
    #  render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    #end
  end

  def edit
    payment_method = PaymentMethod.find_by_id(params[:id])
    @payment_method = payment_method if current_user.payment_methods.include?(payment_method)
    @credit_card = BraintreeRails::CreditCard.find(@payment_method.token)
    render :layout => false
  end

  def update
    begin
      payment_method = PaymentMethod.find_by_id(params[:id])
      p_method = PaymentMethod.new
      p_method.card_number = params[:payment_method][:card_number]
      p_method.month = params[:payment_method][:month]
      p_method.year = params[:payment_method][:year]
      p_method.holder_name = params[:payment_method][:holder_name]
      p_method.cvv = params[:payment_method][:cvv]
      p_method.nick_name = params[:payment_method][:nick_name]
      p_method.card_type = params[:payment_method][:card_type]
      p_method.user_id = params[:payment_method][:user_id]
      if p_method.valid?
        @payment_method = payment_method if current_user.payment_methods.include?(payment_method)
        result = Braintree::CreditCard.update(
            @payment_method.token,
            :number => params[:payment_method][:card_number],
            :expiration_month => params[:payment_method][:month],
            :expiration_year => params[:payment_method][:year],
            :cardholder_name => params[:payment_method][:holder_name],
            :billing_address => {
                :first_name => current_user.first_name,
                :last_name => current_user.last_name,
                :street_address => @payment_method.billing_address.street_address,
                :extended_address => @payment_method.billing_address.house_no,
                :locality => @payment_method.billing_address.city,
                :region => @payment_method.billing_address.state,
                :postal_code => @payment_method.billing_address.zip_code
            }, :options => {
            :verify_card => true
        }
        )
        if result.success?
          @payment_method.card_number = result.credit_card.last_4
          @payment_method.token = result.credit_card.token
          @payment_method.month = params[:payment_method][:month]
          @payment_method.year = params[:payment_method][:year]
          @payment_method.holder_name = params[:payment_method][:holder_name]
          @payment_method.cvv = params[:payment_method][:cvv]
          @payment_method.card_type = params[:payment_method][:card_type]
          if @payment_method.save
            flash[:notice] = ":Payment Method was successfully Updated."
            render :json => {:success => true, :url => customer_payment_methods_path}.to_json
          else
            @errors = @payment_method.errors
            render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
          end
        else
          @brain_errors = result.errors
          render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        end
      else
        @errors = p_method.errors
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
      end
    rescue Exception => e
      @message = e.message
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def destroy
    begin
      payment_method = PaymentMethod.find_by_id(params[:id])
      @payment_method = payment_method if current_user.payment_methods.include?(payment_method)
      result = Braintree::CreditCard.delete(@payment_method.token)
      if result == true
        if @payment_method.update_attribute(:is_deleted, true)
          flash[:notice] = "Payment Method was successfully deleted."
          redirect_to customer_payment_methods_path
        else
          flash[:alert] = "Something went wrong. Please try again later."
          redirect_to customer_payment_methods_path
        end
      else
        flash[:alert] = "Something went wrong. Please try again later."
        redirect_to customer_payment_methods_path
      end
    rescue Exception => e
      flash[:alert] = e.message
      redirect_to :action => :index
    end
  end

end
