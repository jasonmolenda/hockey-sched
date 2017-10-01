#! /usr/bin/ruby
require 'cgi'

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'timeslot-assignment'
require 'home-away-assignment'
require 'holidays'
require 'ice-oasis-leagues'
require 'create-ics-file'


puts "Content-type: text/html; charset=utf-8"
puts ""
puts "<html><body>"

cgi = CGI.new
if !cgi.has_key?("league") || cgi["league"] == "" || cgi["league"] == nil
    puts "ERROR: No league key found in the form.  all keys:"
    puts "<pre>"
    puts cgi.keys
    puts "</pre>"
    puts "</body></html>"
    exit true
end

leagues = IceOasisLeagues.get_ice_oasis_leagues()
timeslots = IceOasisLeagues.get_timeslots()
rinks = IceOasisLeagues.get_rinks()

league = leagues[:leagues].select {|l| l[:name] == cgi["league"]}
if league.size() != 1
    puts "ERROR: Found #{league.size()} matches for string '#{cgi["league"]}'"
    puts "</body></html>"
end

# We now know this is an array of 1 element, collapse it.
league = league.first()


## Create our schedule object based on the above league / timeslots / rinks information.

schedule = Hash.new
schedule[:teamcount] = league[:team_names].size()
schedule[:weekcount] = ((leagues[:end_date] - leagues[:start_date]).to_i / 7) + 1
schedule[:gamecount] = schedule[:teamcount] / 2
schedule[:timeslots] = timeslots
schedule[:rinks] = rinks
schedule[:rinkcount] = league[:rink_ids].sort.uniq.size()
schedule[:weeks] = Array.new

num_of_tids = league[:timeslot_ids].size()
num_of_rids = league[:rink_ids].size()
0.upto(schedule[:weekcount] - 1).each do |wknum|
    schedule[:weeks][wknum] = Hash.new
    schedule[:weeks][wknum][:games] = Array.new
    0.upto(schedule[:gamecount] - 1).each do |gamenum|
        schedule[:weeks][wknum][:games][gamenum] = Hash.new
        index = (wknum * schedule[:gamecount]) + gamenum
        schedule[:weeks][wknum][:games][gamenum][:timeslot_id] = league[:timeslot_ids][index % num_of_tids]
        schedule[:weeks][wknum][:games][gamenum][:rink_id] = league[:rink_ids][index % num_of_rids]
    end
end

TeamMatchupsCircular.get_team_matchups(schedule)
TimeslotAssignmentScoreBased.order_game_times(schedule, false)
HomeAwayAssignment.assign_home_away(schedule)

ics_text = CreateICSText.create_ics_file(schedule, leagues[:start_date], leagues[:end_date], league[:day_of_week], league[:team_names])

n = 1
rootdir = "/home/molenda/molenda.us/schedules-v2"
if !File.exist?(rootdir)
    rootdir = "/tmp"
end
while File.exist?("#{rootdir}/schedule-#{n}.ics")
    n += 1
end
filename="#{rootdir}/schedule-#{n}.ics"
File.open(filename, "w") do |f|
    f.puts ics_text
end

if File.exists?(filename)
    total_number_of_weeks = (((leagues[:end_date] - leagues[:start_date]).to_i) / 7) + 1
    puts "This schedule covers a #{total_number_of_weeks} week period.  #{schedule[:weekcount]} games scheduled this season, skipping holidays"

    url = filename.gsub(/.*schedules/, "http://molenda.us/schedules")
    puts "<p>Calendar created.  Available for download at URL: <a href=\"#{url}\">#{url}</a>"
    puts "<p>"
    puts "<br>Or run it through the <a href=\"http://molenda.us/cgi-bin/hockey-calendar-lint.cgi?url=#{url.gsub(/\//, "%2F")}&startdate=&enddate=&Submit=Submit\">schedule checker</a>."
else
    puts "Failed to create calendar file."
end

puts "</body></html>"
