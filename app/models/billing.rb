class Billing < ActiveRecord::Base

  attr_accessible :document, :owner
  belongs_to :owner, :polymorphic => true
  validates :document, :presence => true

  #has_attached_file :document, :url => "/system/:attachment/:id/:style/:basename.:extension",
  #                  :path => "curbstand/:attachment/:id/:style/:basename.:extension",
  #                  :storage => :s3,
  #                  :s3_credentials => {
  #                      :bucket => ENV['BUCKET_NAME'],
  #                      :access_key_id => ENV['ACCESS_ID'],
  #                      :secret_access_key => ENV['ACCESS_KEY'],
  #                      :s3_host_name => 's3-us-west-2.amazonaws.com'
  #                  }

  has_attached_file :document, :styles => {:medium => "250x250>", :thumb => "100x100>"},
                    :path => ":attachment/:id/:style/:basename.:extension",
                    :storage => :s3,
                    :s3_credentials => {
                        :bucket => "ziply-dev",
                        :access_key_id => "AKIAJ6CJFS5IMCWAGE7Q",
                        :secret_access_key => "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"
                    }

  def create_pdf(keys, res, date, invoiceinfo)
    puts "IIIIIB"
    keys.each do |a|
      user = User.find_by_customer_id(res[a][0][:merchant_account_id])
      if user.present?
        Prawn::Document.generate("#{date.strftime("%B,%Y-Billing report.pdf")}") do |pdf|
          pdf.font_size 18
          pdf.text "Settlement summary for month #{date.month}", :align => :center
          res[a].each do |table|
            invoiceinfo << [table[:kind], table[:card_type], table[:amount_settled], table[:count], table[:date]]
            #pdf.move_down(10)
            pdf.move_down(5)
          end
          pdf.table invoiceinfo
        end
        pdf_file = File.open("#{date.strftime("%B,%Y-Billing report.pdf")}")
        bil = Billing.new
        bil.document = pdf_file
        bil.owner = user
        bil.billing_month = date
        bil.save!
        puts "IIIIIIIIIIIIIIIIIIIIIIII"
        File.delete("#{date.strftime("%B,%Y-Billing report.pdf")}")
      end
    end
  end
end
