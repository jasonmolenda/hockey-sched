#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'team-matchups-randomization'
require 'timeslot-assignment'
require 'home-away-assignment'

def schedule_one_season_four_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_four_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    SimpleScheduleAnalysis.raw_text(schedule)
end


def schedule_one_season_six_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_six_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    SimpleScheduleAnalysis.raw_text(schedule)
end


def schedule_one_season_seven_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_seven_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    SimpleScheduleAnalysis.raw_text(schedule)
end



def schedule_one_season_eight_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_eight_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    SimpleScheduleAnalysis.raw_text(schedule)
end

def schedule_one_season_twelve_team_league()
    schedule = CreateSimpleEmptySchedule.create_simple_twelve_team_empty_schedule()
    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)
    SimpleScheduleAnalysis.raw_text(schedule)
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
