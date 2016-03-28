require 'rubygems'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :release_payments do
  drivers = User.drivers
  drivers.each do |driver|
    TransactionHistory.where(:escrow_status => "escrow").each do |th|
      if th.transaction_id.present?
        diff = ((Time.now - th.job.delivered_date) / 3600).round
        if diff > 48
          puts "JJJJJJ", th.id
          result = Braintree::Transaction.release_from_escrow(th.transaction_id)
          puts "PPPP", result.inspect
          if result.success?
            th.update_attribute(:escrow_status, "released")
            UserMailer.driver_payment_released(th.job).deliver
            puts "HHHH", th.escrow_status
          end
        end
      end
    end
  end
end

