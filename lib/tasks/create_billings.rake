require 'rubygems'
require 'prawn'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :create_billings do
  puts "RRR"
  #if Date.today.day == 1
  res = {}
  date = Date.today.prev_month + 25.day
  first_date = Date.civil(date.year, date.month, 25)
  last_date = Date.civil(date.year, date.month, -1)
  invoiceinfo = [["Type", "Card Type", "Total Amount", "Transactions", "Date"]]
  (first_date..last_date).each do |date|
    result = Braintree::SettlementBatchSummary.generate(date.strftime("%Y-%m-%d"))
    puts result.inspect
    if result.success?
      puts "SSS"
      unless result.settlement_batch_summary.records.blank?
        puts "LLL"
        result.settlement_batch_summary.records.each do |record|
          puts "KKKKK"
          res[record[:merchant_account_id]].blank? ? res[record[:merchant_account_id]] =[] : res[record[:merchant_account_id]]
          record[:date] = date
          res[record[:merchant_account_id]] << record
        end
      end
    end
  end
  keys =res.keys
  Billing.new.create_pdf(keys, res, date, invoiceinfo)

  #end
end


