require 'rubygems'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :driver_payments do
  #if Date.today.day == 1 or Date.today.day == 15
  drivers = User.drivers
  drivers.each do |driver|
    final_amount = 0
    driver.delivered_jobs.where(:is_driver_payment_sent => false).each do |driver_job|
      #puts "DDDJOB"
      if driver_job.transaction_history.present?
        #puts "transaction_history"
        unless driver_job.transaction_history.driver_amount.blank?
          #puts "driver_amount"
          final_amount += driver_job.transaction_history.driver_amount
        end
      end
    end
    if driver.customer_id.present?
      if (final_amount > 0)
        if payment_transfer(final_amount.round(2), driver)
          puts "PPP", final_amount.inspect
          driver.delivered_jobs.update_all(:is_driver_payment_sent => true)
        end
      end
    end
  end
  #end
end

def payment_transfer(final_amount, driver)
  @super_admin = BraintreeRails::Customer.find(User.first.customer_id)
  @card = @super_admin.credit_cards.first
  puts "PPPFFFF", final_amount.inspect
  puts "MMM", driver.customer_id.inspect
  result = Braintree::Transaction.sale(
      :customer_id => User.first.customer_id,
      :service_fee_amount => 2,
      :amount => final_amount,
      :merchant_account_id => driver.customer_id,
      :payment_method_token => @card.token,
      :options => {
          :submit_for_settlement => true
      }
  )
  if result.success?
    puts "MMM", result.inspect
    return true
  else
    puts "MMMKKKK", result.inspect
    return false
  end
end