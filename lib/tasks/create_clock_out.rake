require 'rubygems'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :create_clock_out do
  User.drivers.each do |driver|
    unless driver.travelling_times.blank?
      if driver.travelling_times.last.clock_out.blank?
        travelling_time = driver.travelling_times.last
        if travelling_time.update_attibutes(:clock_out => Time.now)
          TravellingTime.create!(:clock_in => Time.now, :user_id => driver.id)
        end
      end
    end
  end
end


