#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'create-simple-empty-schedule'
require 'timeslot-assignment'

@DEBUG = false

# Schedules are created in 4 steps, in this order:
#
# 1. Team versus Team pairings
# 2. Timeslot assignments
# 3. Home/away assignment
# 4. Rink assignments (if multiple rinks)

module HomeAwayAssignment

    # schedule must have the following filled in:
    #
    # schedule[:teamcount]
    #
    # schedule[:weeks]
    # schedule[:weeks][wknum]
    # schedule[:weeks][wknum][:games]
    # schedule[:weeks][wknum][:games][gamenum]
    # schedule[:weeks][wknum][:games][gamenum][:teampair]
    #
    # defined.  It will set
    #
    # schedule[:weeks][wknum][:games][gamenum][:home]
    # schedule[:weeks][wknum][:games][gamenum][:away]
    #
    # in the structure.
    #
    def self.assign_home_away (schedule)

        number_of_home_games = Array.new
        (1..schedule[:teamcount]).each { |i| number_of_home_games[i] = 0 }

        results = Array.new
        schedule[:weeks].each do |week|
            new_matchups = Array.new
            week[:games].each do |game|
                pair = game[:teampair]
                t1 = pair[0]
                t2 = pair[1]
                home = nil
                away = nil
                if number_of_home_games[t1] < number_of_home_games[t2]
                    home = t1
                    away = t2
                elsif number_of_home_games[t2] < number_of_home_games[t1]
                    home = t2
                    away = t1
                else
                    pair.shuffle()
                    home = pair[0]
                    away = pair[1]
                end
                number_of_home_games[home] += 1
                game[:home] = home
                game[:away] = away
            end
            results.push(week)
        end
    end
end

def show_home_away_results(schedule)
    puts "#{schedule[:teamcount]} team schedule:"
    number_of_home_games = Hash.new
    number_of_away_games = Hash.new
    schedule[:weeks].each do |week|
        week[:games].each do |game|
            home = game[:home]
            away = game[:away]
            if !number_of_home_games.has_key?(home)
                number_of_home_games[home] = 0
            end
            number_of_home_games[home] += 1
            if !number_of_away_games.has_key?(away)
                number_of_away_games[away] = 0
            end
            number_of_away_games[away] += 1
        end
    end

    (1..schedule[:teamcount]).each do |t|
        puts "  team ##{t}: #{number_of_home_games[t]} home games, #{number_of_away_games[t]} away games, total is #{number_of_home_games[t] + number_of_away_games[t]}"
    end
end


def test_home_away_four_teams()
    schedule = CreateSimpleEmptySchedule.create_simple_four_team_empty_schedule()

    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)

    show_home_away_results(schedule)
end

def test_home_away_eight_teams()
    schedule = CreateSimpleEmptySchedule.create_simple_eight_team_empty_schedule()

    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)

    show_home_away_results(schedule)
end

def test_home_away_twelve_teams()
    schedule = CreateSimpleEmptySchedule.create_simple_twelve_team_empty_schedule()

    TeamMatchupsCircular.get_team_matchups(schedule)
    TimeslotAssignmentScoreBased.order_game_times(schedule, false)
    HomeAwayAssignment.assign_home_away(schedule)

    show_home_away_results(schedule)
end


if __FILE__ == $0
    test_home_away_four_teams()
    puts ""
    test_home_away_eight_teams()
    puts ""
    test_home_away_twelve_teams()
end
