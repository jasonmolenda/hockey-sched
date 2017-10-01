#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)

require 'ice-oasis-leagues'
require 'holidays'

timeslots = IceOasisLeagues.get_timeslots()
rinks = IceOasisLeagues.get_rinks()
leagues = IceOasisLeagues.get_ice_oasis_leagues()

puts "<html>"
puts "<body>"
puts "<h1 align=\"center\">Ice Oasis schedule creator v2</h1>"
puts "Schedule start date: #{leagues[:start_date]}"
puts "<br>Schedule end date: #{leagues[:end_date]}"

holidays = HolidayDates.get_holiday_schedule().select {|h| leagues[:start_date] <= h && h <= leagues[:end_date]}
holidays = holidays.map {|h| h.strftime("%b %e")}
puts "<br>Holidays during this schedule: #{holidays.join(', ')}"

leagues[:leagues].sort {|x,y| x[:day_of_week] <=> y[:day_of_week]}.each do |l|
    puts "<h2>#{l[:name]} league</h2>"
    teamcount = l[:team_names].size()
    rinkcount = l[:rink_ids].sort.uniq.size()
    rinknames = l[:rink_ids].map {|rid| rinks[rid][:long_name]}.sort.uniq
    times = Array.new
    if rinkcount > 1
        l[:timeslot_ids].each_index do |i|
            tid=l[:timeslot_ids][i]
            rid=l[:rink_ids][i]
            r=rinks[rid][:short_name]
            t=timeslots[tid][:description]
            times.push("#{r} #{t}")
        end
    else
        times = l[:timeslot_ids].map {|tid| timeslots[tid][:description]}
    end
    puts "<form action=\"/cgi-bin/hockey-sched/create.cgi\" method=\"get\">"
    puts "<blockquote>"
    puts "# of teams: #{teamcount} - #{l[:team_names].join(', ')}"
    puts "<br># of rinks: #{rinkcount} - #{rinknames.join(', ')}"
    puts "<br>Timeslots: #{times.join(', ')}"
    puts "<input type=\"hidden\" name=\"league\" value=\"#{l[:name].gsub(/ /, '%20')}\">"
    puts "<br><input type=\"submit\" value=\"Get schedule\">"
    puts "</blockquote>"
    puts "</form>"

end

puts "<hr>"
puts "All sources available at <a href=\"https://github.com/jasonmolenda/hockey-sched\">https://github.com/jasonmolenda/hockey-sched</a>"
puts "<br>This page last updated #{DateTime.now.to_s}"
puts "</body>"
puts "</html>"
