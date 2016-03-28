class RedactorAsset < ActiveRecord::Base
  #has_attached_file :asset, styles: { original: "800x800>", thumb: "118x100>" },
  #    :path => ":attachment/:id/:style/:basename.:extension",
  #    :storage => :s3,
  #    :s3_credentials => {
  #    :bucket => "ziply-dev",
  #    :access_key_id => "AKIAJ6CJFS5IMCWAGE7Q",
  #    :secret_access_key => "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"
  #}


  has_attached_file :asset, :styles => {:medium => "250x250>", :thumb => "100x100>"},
                    #:content_type => {:content_type => ["image/jpeg", "image/gif", "image/png", "image/jpg"]},
                    :path => ":attachment/:id/:style/:basename.:extension",
                    :storage => :s3,
                    :s3_credentials => {
                        :bucket => "ziply-dev",
                        :access_key_id => "AKIAJ6CJFS5IMCWAGE7Q",
                        :secret_access_key => "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"
                    }


  validates_attachment_content_type :asset, :content_type => /\Aimage\/.*\Z/
end
