#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'timeslot-assignment'
require 'home-away-assignment'
require 'holidays'
require 'ice-oasis-leagues'
require 'create-ics-file'
require 'analyze-schedule'
require 'parse-ics'

leagues = IceOasisLeagues.get_ice_oasis_leagues()
timeslots = IceOasisLeagues.get_timeslots()
rinks = IceOasisLeagues.get_rinks()

if ARGV.size() != 1 || leagues[:leagues].count {|l|l[:name] == ARGV[0]} != 1
    STDERR.puts "Usage: crate.rb LEAGUENAME"
    STDERR.puts "Where leaguename is one of #{leagues[:leagues].map {|l| "'%s'" % [l[:name]]}.join(', ')}"
    exit true
end

league = leagues[:leagues].select {|l| l[:name] == ARGV[0]}.first()


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

ics_text = CreateICSText.create_ics_file(schedule, leagues[:start_date], leagues[:end_date], league[:day_of_week], league[:team_names].shuffle)

n = 1
rootdir = "/tmp"
while File.exist?("#{rootdir}/schedule-#{n}.ics")
    n += 1
end
filename="#{rootdir}/schedule-#{n}.ics"
File.open(filename, "w") do |f|
    f.puts ics_text
end

total_number_of_weeks = (((leagues[:end_date] - leagues[:start_date]).to_i) / 7) + 1

puts "This schedule covers a #{total_number_of_weeks} week period.  #{schedule[:weekcount]} games scheduled this season, skipping holidays"

puts "schedule analysis"

final_schedule = ParseICS.ics_to_schedule(ics_text)
AnalyzeSchedule.analyze_schedule(final_schedule, false)
