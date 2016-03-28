require 'rubygems'
require 'prawn'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :seed_zip_codes do
  puts "RRR"
  reader = PDF::Reader.new("#{Rails.root}/db/master zip codes.pdf")
  reader.pages.each do |page|
    #puts page.fonts
    page.text.split(" ").each do |a|
      if a.start_with?('9')
        CaZipCode.create(:code => a)
      end
    end
    #puts page.raw_content
  end
  #end
end


