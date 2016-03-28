class Asset < ActiveRecord::Base
  attr_accessible :owner_id, :owner_type, :owner, :avatar, :avatar_file_name, :avatar_content_type, :avatar_file_size
  belongs_to :owner, :polymorphic => true
  #has_attached_file :avatar, :styles => {:medium => "250x250>", :thumb => "100x100>"}, :url => "/system/:attachment/:id/:style/:basename.:extension",
  #                  :content_type => {:content_type => ["image/jpeg", "image/gif", "image/png", "image/jpg"]},
  #                  :path => ":rails_root/public/system/:attachment/:id/:style/:basename.:extension"

  #has_attached_file :avatar, :styles => lambda { |a| a.instance.images_styles? ? {:medium => "250x250>", :thumb => "100x100>"} : {} }


  #has_attached_file :avatar, :styles => lambda { |a| a.instance.images_styles? ? {:medium => "250x250>", :thumb => "100x100>"} : {} },
  #                  :path => ":attachment/:id/:style/:basename.:extension",
  #                  :storage => :s3,
  #                  :s3_credentials => {
  #                      :bucket => ENV['BUCKET_NAME'],
  #                      :access_key_id => ENV['ACCESS_ID'],
  #                      :secret_access_key => ENV['ACCESS_KEY']
  #                  }


  has_attached_file :avatar, :styles => {:medium => "250x250>", :thumb => "100x100>"},
                    :content_type => {:content_type => ["image/jpeg", "image/gif", "image/png", "image/jpg"]},
                    :path => ":attachment/:id/:style/:basename.:extension",
                    :storage => :s3,
                    :s3_credentials => {
                        :bucket => "ziply-dev",
                        :access_key_id => "AKIAJ6CJFS5IMCWAGE7Q",
                        :secret_access_key => "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"
                    }

  #def images_styles?
  #  if avatar_content_type == 'image/jpeg' || avatar_content_type == 'image/jpg' || avatar_content_type == 'image/png' || avatar_content_type == 'image/gif'
  #    return true
  #  else
  #    puts "CCCCCCCCCCCCCCC"
  #    self.errors.add(:format, "File format is incorrect")
  #    return false
  #  end
  #end
end
