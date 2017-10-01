#! /usr/bin/ruby

require 'date'
require 'time'
require 'etc'

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'team-matchups-randomization'
require 'timeslot-assignment'
require 'home-away-assignment'
require 'create-simple-empty-schedule'
require 'simple-schedule-analysis'
require 'holidays'

# first_game_date is a Date object of the first game for this league.
#
# last_date_this_season is the final regular season game of the season, this
# particular league may have its last game earlier.  The last_date_this_season
# may be a Friday game and this league could be a wednesday night league, for
# instance.
#
# team_names is an array of team names.  The team numbers in schedule are 1-based
# but this array is 0-based.
def create_ics_file (schedule, first_game_date, last_date_this_season, team_names)
    holidays = HolidayDates.get_holiday_schedule()

    ics = Array.new
    ics.push("BEGIN:VCALENDAR")
    ics.push("VERSION:2.0")
    ics.push("X-WR-TIMEZONE:America/Los_Angeles")
    ics.push("CALSCALE:GREGORIAN")
    ics.push("METHOD:PUBLISH")

    day = first_game_date
    wknum = 0
    while day <= last_date_this_season && wknum < schedule[:weekcount]
        if holidays.member?(day)
            day = day + 7
            next
        end
        schedule[:weeks][wknum][:games].sort {|x,y| x[:rink_id] <=> y[:rink_id]}.each do |game|
            tid = game[:timeslot_id]
            rid = game[:rink_id]
            home = game[:home]
            away = game[:away]
            home_team_name = team_names[home - 1]
            away_team_name = team_names[away - 1]
            rink_name = schedule[:rinks][rid][:short_name]
            rink_address = schedule[:rinks][rid][:address]
            rink_location = schedule[:rinks][rid][:location]
            rink_structured_location = schedule[:rinks][rid][:structured_location]

            start_hour = schedule[:timeslots][tid][:hour]
            start_minute = schedule[:timeslots][tid][:minute]

            start_time = Time.iso8601("#{day.strftime}T%02d:%02d:00" % [start_hour, start_minute])
            end_time = start_time + (60 * 75)

            ics.push("BEGIN:VEVENT")
            ics.push("DTSTART;TZID=America/Los_Angeles:#{start_time.localtime.strftime("%Y%m%dT%H%M%S")}")
            ics.push("DTEND;TZID=America/Los_Angeles:#{end_time.localtime.strftime("%Y%m%dT%H%M%S")}")
            ics.push("DTSTAMP:#{Time.now.gmtime.strftime("%Y%m%dT%H%M%SZ")}")
            ics.push("CREATED:19000101T120000Z")
            ics.push("DESCRIPTION:")
            ics.push("LAST-MODIFIED:#{Time.now.gmtime.strftime("%Y%m%dT%H%M%SZ")}")
            if rink_address != "" && rink_address != nil
                ics.push(rink_location)
                ics.push(rink_structured_location)
            end
            ics.push("SEQUENCE:1")
            ics.push("STATUS:CONFIRMED")
            if schedule[:rinkcount] > 1
                ics.push("SUMMARY:#{rink_name} #{home_team_name} v. #{away_team_name}")
            else
                ics.push("SUMMARY:#{home_team_name} v. #{away_team_name}")
            end
            ics.push("END:VEVENT")
        end
        wknum += 1
        day = day + 7
    end
    ics.push("END:VCALENDAR")
    return ics
end

def schedule_one_season_four_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_four_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    puts create_ics_file(schedule, Date.parse("2017-09-01"), Date.parse("2017-12-01"), ["one", "two", "three", "four"])
end


def schedule_one_season_six_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_six_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
end


def schedule_one_season_seven_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_seven_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
end



def schedule_one_season_eight_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_eight_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
end

def schedule_one_season_twelve_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_twelve_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    puts create_ics_file(schedule, Date.parse("2017-09-07"), Date.parse("2017-12-01"), ["Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", "Geckos", "Tarantulas"])
end


if __FILE__ == $0

    number_of_teams_to_schedule = 12
    if ARGV.size() > 0
        number_of_teams_to_schedule = ARGV[0].to_i
    end

    if number_of_teams_to_schedule == 4
        schedule_one_season_four_team_league()
    elsif number_of_teams_to_schedule == 6
        schedule_one_season_six_team_league()
    elsif number_of_teams_to_schedule == 7
        schedule_one_season_seven_team_league()
    elsif number_of_teams_to_schedule == 8
        schedule_one_season_eight_team_league()
    elsif number_of_teams_to_schedule == 12
        schedule_one_season_twelve_team_league()
    else
        puts "Unrecognized number of teams to schedule, doing nothing."
        exit
    end


end
