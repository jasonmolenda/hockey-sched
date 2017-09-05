#! /usr/bin/ruby

@DEBUG = true

# Discussions of better ways to schedule the rounds:

# http://nrich.maths.org/1443
# https://courses.cs.washington.edu/courses/csep521/07wi/prj/sam_scott.pdf
# https://en.wikipedia.org/wiki/Round-robin_tournament#Scheduling_algorithm
# 
# http://www.devenezia.com/downloads/round-robin/index.html
# http://www.devenezia.com/downloads/round-robin/rounds.php
# http://www.devenezia.com/round-robin/forum/YaBB.pl
# http://www.devenezia.com/downloads/round-robin/Schedule-musings.pdf
# http://www.devenezia.com/downloads/round-robin/schedule-source.html

# http://www.devenezia.com/javascript/article.php/index.html
# http://www.devenezia.com/javascript/article.php/RoundRobin1.html
# http://www.devenezia.com/javascript/article.php/RoundRobin2.html
#

# from http://www.devenezia.com/javascript/article.php/RoundRobin2.html
# a cyclic algorithm with 1-based numbers for teams :
#
#    Presume people are more used to number series starting with 1 instead of 0, and they want 
#    the first pair of the first round to be [1,2].
#
#    Then, functionally, the 1'st pair of the r'th round is (n == # of teams):
#
#    [  1 ,                  (r+n-1-1) % (n-1) + 2 ], r=1..n-1
#
#   and the i'th pair of the r'th round is:
#
#    [ (r+i-2) % (n-1) + 2 , (r+n-i-1) % (n-1) + 2 ], r=1..n-1, i=2..n/2

# on scheduling:
# "There is a special form of balanced round-robin called a partitioned balanced tournament design which will meet your needs"
# http://www.devenezia.com/round-robin/forum/YaBB.pl?num=1260298921
# http://etd.uwaterloo.ca/etd/sbbauman2001.pdf

# keywords include 
#   "partitioned balanced tournament design"
#   "balanaced tournament design"
#   "round robin tournament"

module TeamMatchupsCircular



    # Arguments are the # of teams in the league and the # of timeslots that are
    # scheduled each week.
    #
    # Returns two values -- an array and a string message about how many retries it took.
    #
    # Returned Array has one entry per week of the schedule.
    #
    # Each week is a Hash.  It has a key :matchups which is an array.  The array is the # of game times that 
    # week.  
    # e.g. :matchups=>[[3, 5], [9, 4], [8, 7], [2, 6]]
    #
    # It has a key :bye for team that has a bye that week.  
    # e.g. :bye=>6
    # or :bye=>nil for a schedule where no team has a bye.

    def self.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

        number_of_teams_incl_ghost = number_of_teams
        number_of_timeslots_incl_ghost = number_of_timeslots
        bye = false

        # odd # of teams means we have a bye team, we introduce a ghost team - anyone
        # who plays against ghost team has a bye.
        if number_of_teams % 2 != 0 && number_of_teams > 2
            number_of_teams_incl_ghost += 1
            number_of_timeslots_incl_ghost += 1
            bye = true
        end

        weekly_games = Array.new
        results_message = ""

        (0..number_of_weeks - 1).each do |wknum|
            team_with_bye_this_week = nil
            matchups = Array.new

            #    the 1'st pair of the r'th round is (n == # of teams):
            #    [  1 ,                  (r+n-1-1) % (n-1) + 2 ], r=1..n-1

            t1 = 1
            t2 = (wknum + number_of_teams_incl_ghost - 1 - 1) % (number_of_teams_incl_ghost - 1) + 2
            if bye == true && (t1 == number_of_teams_incl_ghost || t2 == number_of_teams_incl_ghost)
                if t1 == number_of_teams_incl_ghost
                    team_with_bye_this_week = t2
                else
                    team_with_bye_this_week = t1
                end
            else
                matchups.push([t1, t2])
            end

            (2..(number_of_teams_incl_ghost / 2)).each do |tnum|

                #   and the i'th pair of the r'th round is (i == team #, r == week #, n == # of teams):
                #    [ (r+i-2) % (n-1) + 2 , (r+n-i-1) % (n-1) + 2 ], r=1..n-1, i=2..n/2

                t1 = (wknum + tnum - 2) % (number_of_teams_incl_ghost - 1) + 2
                t2 = (wknum + number_of_teams_incl_ghost - tnum - 1) % (number_of_teams_incl_ghost - 1) + 2
                if bye == true && (t1 == number_of_teams_incl_ghost || t2 == number_of_teams_incl_ghost)
                    if t1 == number_of_teams_incl_ghost
                        team_with_bye_this_week = t2
                    else
                        team_with_bye_this_week = t1
                    end
                else
                    matchups.push([t1, t2])
                end
            end
            weekly_games.push({:matchups => matchups, :bye => team_with_bye_this_week})
        end
        return weekly_games, results_message
    end
end

if __FILE__ == $0
    examples = [ 
                     {:teams => 4, :timeslots => 2, :weeks => 14},
                     {:teams => 6, :timeslots => 3, :weeks => 14},
                     {:teams => 7, :timeslots => 3, :weeks => 14},
                     {:teams => 8, :timeslots => 4, :weeks => 20},

                      {:teams => 12, :timeslots => 6, :weeks => 26},

                      {:teams => 9, :timeslots => 4, :weeks => 20}, 
               ]

    examples.each do |ex|
        puts ""
        number_of_teams = ex[:teams]
        number_of_timeslots = ex[:timeslots]
        number_of_weeks = ex[:weeks]

        puts "#{number_of_teams} teams, #{number_of_timeslots} timeslots, #{number_of_weeks} weeks"
        results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

        puts message

        games_played = Hash.new
        (1..number_of_teams).each { |t| games_played[t] = 0 }

        (1..number_of_weeks).each do |i|
            matchups = Array.new
            results[i - 1][:matchups].each do |pair|
                matchups.push("#{pair[0]} v #{pair[1]}")
            end
            print "Week #{i}: #{matchups.join(', ')}"
            if results[i - 1][:bye] != nil
                print ", bye team: #{results[i - 1][:bye]}"
            end
            puts ""
            results[i - 1][:matchups].each do |pair|
            games_played[pair[0]] += 1
            games_played[pair[1]] += 1
            end
        end

        games_against_each_opponent = Hash.new
        (1..number_of_teams).each do |j|
            games_against_each_opponent[j] = Hash.new
            (1..number_of_teams).each do |k|
                games_against_each_opponent[j][k] = 0
            end
        end
        (1..number_of_weeks).each do |i|
            results[i - 1][:matchups].each do |pair|
                t1 = pair[0]
                t2 = pair[1]
                if t1 == t2
                    puts "ERROR: in week # #{i} team #{t1} plays itself"
                end
                games_against_each_opponent[t1][t2] += 1
                games_against_each_opponent[t2][t1] += 1
            end
        end

        puts "# of games each team has:"
        (1..number_of_teams).each do |t|
            print "#{t}: #{games_played[t]} games. # of games against opponents: ("
            result = Array.new
            games_against_each_opponent[t].keys.each do |opponent|
                next if t == opponent
                result.push("#{opponent}: #{games_against_each_opponent[t][opponent]} games")
            end
            print result.join(', ')
            puts ""
        end
    end
end


exit true
