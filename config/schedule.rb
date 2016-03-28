# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
set :output, "log/cron.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
set :output, {:error => 'error.log', :standard => 'cron.log'}
every 1.day, :at => '4:30 am' do
  rake "create_clock_out"
end

every 10.minutes do
  puts "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
  rake "time_out_jobs"
end

every 1.hours do
  puts "Release payments"
  rake "release_payments"
end



