class Ckeditor::Picture < Ckeditor::Asset
  #has_attached_file :data,
  #                  :url  => "/ckeditor_assets/pictures/:id/:style_:basename.:extension",
  #                  :path => ":rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension",
  #                  :styles => { :content => '800>', :thumb => '118x100#' }

  has_attached_file :data, :styles => { :content => '800>', :thumb => '118x100#' },
                    :content_type => {:content_type => ["image/jpeg", "image/gif", "image/png", "image/jpg"]},
                    :path => ":attachment/:id/:style/:basename.:extension",
                    :storage => :s3,
                    :s3_credentials => {
                        :bucket => "ziply-dev",
                        :access_key_id => "AKIAJ6CJFS5IMCWAGE7Q",
                        :secret_access_key => "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"
                    }

  validates_attachment_presence :data
  validates_attachment_size :data, :less_than => 2.megabytes
  validates_attachment_content_type :data, :content_type => /\Aimage/

  def url_content
    url(:content)
  end
end
