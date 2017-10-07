#! /usr/bin/ruby

require 'date'
require 'time'
require 'etc'

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'timeslot-assignment'
require 'home-away-assignment'
require 'holidays'

module CreateICSText

# first_date_this_season is a Date object of the first day this league plays on.  Not the
# first day that this particular division is playing -- this could be a Tuesday div
# who plays their first game on Sep 15 and the league starts with Monday league on
# Sep 14.  The start date will be Sep 14.
#
# last_date_this_season is the final regular season game of the season, this
# particular league may have its last game earlier.  Not the last day that this
# particular division is playing -- this could be a Tuesday div who has their last
# game of the season on Feb 17 and the last game of the season is Sat Feb 23.  The
# end date will be Feb 23.
#
# day_of_week that this league plays most of its games.  0 == Sunday, 6 == Saturday.
#
# team_names is an array of team names.  The team numbers in schedule are 1-based
# but this array is 0-based.

    def self.create_ics_file (schedule, first_date_this_season, last_date_this_season, day_of_week, team_names)
        holidays = HolidayDates.get_holiday_schedule()
    
        ics = Array.new
        ics.push("BEGIN:VCALENDAR")
        ics.push("VERSION:2.0")
        ics.push("X-WR-TIMEZONE:America/Los_Angeles")
        ics.push("CALSCALE:GREGORIAN")
        ics.push("METHOD:PUBLISH")
    
        day = first_date_this_season
        while day.wday != day_of_week
            day += 1
        end

        wknum = 0
        while day <= last_date_this_season && wknum < schedule[:weekcount]
            if holidays.member?(day)
                day = day + 7
                next
            end
            schedule[:weeks][wknum][:games].sort {|x,y| x[:rink_id] <=> y[:rink_id]}.each do |game|
                game_day_maybe_offset = day
                tid = game[:timeslot_id]
                rid = game[:rink_id]
                home = game[:home]
                away = game[:away]
                if schedule[:timeslots][tid][:alternate_day] == true
                    game_day_maybe_offset += schedule[:timeslots][tid][:alternate_day_offset]
                    # If the alternate day game is on a holiday, these two teams 
                    # don't get to play this week.
                    if holidays.member?(game_day_maybe_offset)
                        schedule[:weeks][wknum][:skipped_teams] = [home, away]
                        next
                    end
                end

                home_team_name = team_names[home - 1]
                away_team_name = team_names[away - 1]
                rink_name = schedule[:rinks][rid][:short_name]
                rink_address = schedule[:rinks][rid][:address]
                rink_location = schedule[:rinks][rid][:location]
                rink_structured_location = schedule[:rinks][rid][:structured_location]
    
                start_hour = schedule[:timeslots][tid][:hour]
                start_minute = schedule[:timeslots][tid][:minute]
    
                start_time = Time.iso8601("#{game_day_maybe_offset.strftime}T%02d:%02d:00" % [start_hour, start_minute])
                end_time = start_time + (60 * 75)
    
                ics.push("BEGIN:VEVENT")
                ics.push("DTSTART;TZID=America/Los_Angeles:#{start_time.localtime.strftime("%Y%m%dT%H%M%S")}")
                ics.push("DTEND;TZID=America/Los_Angeles:#{end_time.localtime.strftime("%Y%m%dT%H%M%S")}")
                ics.push("DTSTAMP:#{Time.now.gmtime.strftime("%Y%m%dT%H%M%SZ")}")
                ics.push("CREATED:19000101T120000Z")
                ics.push("DESCRIPTION:")
                ics.push("X-APPLE-TRAVEL-ADVISORY-BEHAVIOR:DISABLED")
                ts = schedule[:timeslots][tid]
                details = Array.new
                details.push("early_game=true") if ts[:early_game]
                details.push("late_game=true") if ts[:late_game]
                details.push("alternate_day=true") if ts[:alternate_day]
                if ts.has_key?(:alternate_day_offset) && ts[:alternate_day_offset] > 0
                    details.push("alternate_day_offset=#{ts[:alternate_day_offset]}")
                end
                ics.push("X-HOCKEY-SCHEDULE-DEETS: #{details.join('#')}")
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

        # Remove any unused :weeks entries off the schedule
        if wknum > 0
            schedule[:weeks].slice!(wknum..(schedule[:weekcount] - 1))
            schedule[:weekcount] = wknum
        end
        return ics
    end
end

def schedule_one_season_four_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_four_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    puts CreateICSText.create_ics_file(schedule, Date.parse("2017-09-01"), Date.parse("2017-12-01"), 6, ["one", "two", "three", "four"])
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
    puts CreateICSText.create_ics_file(schedule, Date.parse("2017-09-07"), Date.parse("2017-12-01"), 4, ["Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", "Geckos", "Tarantulas"])
end


if __FILE__ == $0
    require 'create-simple-empty-schedule'
    require 'simple-schedule-analysis'

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
