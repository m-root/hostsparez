#WickedPdf.config = {
#    :exe_path => "#{Rails.root}/bin/wkhtmltopdf-amd64"
#  #:exe_path => Rails.root.join('bin', 'wkhtmltopdf-i386').to_s
#}
##wkhtmltopdf_path = "#{Rails.root}/bin/wkhtmltopdf-amd64"
#
#
#WickedPdf.config = {
#    :exe_path => Rails.root.join('bin', 'wkhtmltopdf-i386').to_s,
#}


#WickedPdf.config = {
#    :exe_path => "#{Rails.root}/bin/wkhtmltopdf-amd64"
#
#    #:exe_path => Rails.root.join('bin', 'wkhtmltopdf-i386').to_s
#}
#wkhtmltopdf_path = "#{Rails.root}/bin/wkhtmltopdf-amd64"


WickedPdf.config = {
    #exe_path: "#{ENV['GEM_HOME']}/gems/wkhtmltopdf-binary-#{Gem.loaded_specs['wkhtmltopdf-binary'].version}/bin/wkhtmltopdf_linux_386"
    :exe_path => "#{Rails.root}/bin/wkhtmltopdf"
    #:exe_path => "bundle exec #{Rails.root.join('bin','wkhtmltopdf')}"
}



