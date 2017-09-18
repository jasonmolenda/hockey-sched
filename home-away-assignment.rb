#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'

@DEBUG = false

# Schedules are created in 4 steps, in this order:
#
# 1. Team versus Team pairings
# 2. Timeslot assignments
# 3. Home/away assignment
# 4. Rink assignments (if multiple rinks)

module HomeAwayAssignment

    # This method takes a schedule from the timeslot-assignment pass and
    # determines which teams will be home versus which teams will be away
    # for each game.
    #
    # season_schedule input variable is expected to be an Array, 0-based, one
    # element for each week.  Each element is a Hash with these contents:
    #   :matchups      Array of team pairs, in timeslot schedule order.  
    #                  size of this Array is the number of games played each week.
    # (additional key-value pairs are not used in this pass)
    #
    # Returned value is an Array, 0-based, size is the # of weeks, one entry
    # in the array or each week.  The key-value pairs from the input season_schedule
    # are copied into the returned value. However, the :matchups array has been
    # modified.  :matchups is a 0-based array, the # of entries is the number of
    # timeslots in each week.  Each element in :matchups is now a Hash with 
    # :home and :away keys (& team numbers for values).
    #
    def self.assign_home_away (season_scheduled, teamcount, debug)

        number_of_home_games = Array.new
        (1..teamcount).each { |i| number_of_home_games[i] = 0 }

        results = Array.new
        weeknum = 0
        season_scheduled.each do |week|
            new_matchups = Array.new
            week[:matchups].each do |pair|
                t1 = pair[0]
                t2 = pair[1]
                this_matchup = Hash.new
                if number_of_home_games[t1] < number_of_home_games[t2]
                    this_matchup[:home] = t1
                    this_matchup[:away] = t2
                elsif number_of_home_games[t2] < number_of_home_games[t1]
                    this_matchup[:home] = t2
                    this_matchup[:away] = t1
                else
                    pair.shuffle()
                    this_matchup[:home] = pair[0]
                    this_matchup[:away] = pair[1]
                end
                number_of_home_games[this_matchup[:home]] += 1
                new_matchups.push(this_matchup)
            end
            week[:matchups] = new_matchups
            results.push(week)
            weeknum = 1
        end
        return results
    end
end


def test_home_away_four_teams()
    number_of_teams = 4
    number_of_timeslots = 2
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    schedule = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)

    puts "4 team schedule:"
    number_of_home_games = Hash.new
    number_of_away_games = Hash.new
    schedule.each do |week|
        week[:matchups].each do |pair|
            home = pair[:home]
            away = pair[:away]
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

    (1..number_of_teams).each do |t|
        puts "  team ##{t}: #{number_of_home_games[t]} home games, #{number_of_away_games[t]} away games, total is #{number_of_home_games[t] + number_of_away_games[t]}"
    end
end


def test_home_away_eight_teams()
    number_of_teams = 8
    number_of_timeslots = 4
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    schedule = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)

    puts "8 team schedule:"
    number_of_home_games = Hash.new
    number_of_away_games = Hash.new
    schedule.each do |week|
        week[:matchups].each do |pair|
            home = pair[:home]
            away = pair[:away]
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

    (1..number_of_teams).each do |t|
        puts "  team ##{t}: #{number_of_home_games[t]} home games, #{number_of_away_games[t]} away games, total is #{number_of_home_games[t] + number_of_away_games[t]}"
    end
end


def test_home_away_twelve_teams()
    number_of_teams = 12 
    number_of_timeslots = 6
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    schedule = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)

    puts "12 team schedule:"
    number_of_home_games = Hash.new
    number_of_away_games = Hash.new
    schedule.each do |week|
        week[:matchups].each do |pair|
            home = pair[:home]
            away = pair[:away]
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

    (1..number_of_teams).each do |t|
        puts "  team ##{t}: #{number_of_home_games[t]} home games, #{number_of_away_games[t]} away games, total is #{number_of_home_games[t] + number_of_away_games[t]}"
    end
end


if __FILE__ == $0
    test_home_away_four_teams()
    puts ""
    test_home_away_eight_teams()
    puts ""
    test_home_away_twelve_teams()
end
