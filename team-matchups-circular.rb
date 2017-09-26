#! /usr/bin/ruby

@DEBUG = true

# Schedules are created in 4 steps, in this order:
#
# 1. Team versus Team pairings
# 2. Timeslot assignments
# 3. Home/away assignment
# 4. Rink assignments (if multiple rinks)

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



    # This method takes a schedule argument and fills in the [:weeks] array with
    # the initial [:teampair] entries for each week's games.
    # The schedule must already have :teamcount, :gamecount, and :weekcount filled
    # in at this point.
    # Any exiting :weeks entry in the schedule will be overwritten.
    # 
    # See the README.md for more details about the structure of schedule.

    def self.get_team_matchups(schedule)
        teamcount = schedule[:teamcount]
        gamecount = schedule[:gamecount]
        weekcount = schedule[:weekcount]
        schedule[:weeks] = Array.new

        number_of_teams_incl_ghost = teamcount
        number_of_timeslots_incl_ghost = gamecount
        bye = false

        # There are some numbers of teams that are extraordinarily difficult to
        # distribute to timeslots fairly if each set of weeks (for n teams, n-1
        # weeks) has the matchups in the same order.  For these, each time we
        # have a new set of weeks we shuffle the order of teams.

        different_team_matchups_each_set_of_weeks = false
        if teamcount == 6 || teamcount == 7 || teamcount == 8
            different_team_matchups_each_set_of_weeks = true
        end

        # team_numbers is an Array 0-based with the numbers of the teams in this series.
        #
        team_numbers = Array.new
        (0..number_of_teams_incl_ghost - 1).each do |i|
            team_numbers[i] = i + 1
        end

        # odd # of teams means we have a bye team, we introduce a ghost team - anyone
        # who plays against ghost team has a bye.
        if teamcount % 2 != 0 && teamcount > 2
            number_of_teams_incl_ghost += 1
            number_of_timeslots_incl_ghost += 1
            bye = true
        end

        (0..weekcount - 1).each do |wknum|

            # At the start of each set of weeks, we may need to reshuffle the order
            # that the teams are assigned for a well balanced time schedule.
            if (wknum % (number_of_teams_incl_ghost - 1)) == 0
                if different_team_matchups_each_set_of_weeks == true
                    team_numbers = team_numbers.shuffle(random: Random.new(wknum))
                end
            end

            team_with_bye_this_week = nil
            matchups = Array.new

            #    the 1'st pair of the r'th round is (n == # of teams):
            #    [  1 ,                  (r+n-1-1) % (n-1) + 2 ], r=1..n-1

            t1 = 1
            t2 = (wknum + number_of_teams_incl_ghost - 1 - 1) % (number_of_teams_incl_ghost - 1) + 2
            if bye == true && (t1 == number_of_teams_incl_ghost || t2 == number_of_teams_incl_ghost)
                if t1 == number_of_teams_incl_ghost
                    team_with_bye_this_week = team_numbers[t2 - 1]
                else
                    team_with_bye_this_week = team_numbers[t1 - 1]
                end
            else
                matchups.push({ :teampair => [team_numbers[t1 - 1], team_numbers[t2 - 1]] })
            end

            (2..(number_of_teams_incl_ghost / 2)).each do |tnum|

                #   and the i'th pair of the r'th round is (i == team #, r == week #, n == # of teams):
                #    [ (r+i-2) % (n-1) + 2 , (r+n-i-1) % (n-1) + 2 ], r=1..n-1, i=2..n/2

                t1 = (wknum + tnum - 2) % (number_of_teams_incl_ghost - 1) + 2
                t2 = (wknum + number_of_teams_incl_ghost - tnum - 1) % (number_of_teams_incl_ghost - 1) + 2
                if bye == true && (t1 == number_of_teams_incl_ghost || t2 == number_of_teams_incl_ghost)
                    if t1 == number_of_teams_incl_ghost
                        team_with_bye_this_week = team_numbers[t2 - 1]
                    else
                        team_with_bye_this_week = team_numbers[t1 - 1]
                    end
                else
                    matchups.push({ :teampair => [team_numbers[t1 - 1], team_numbers[t2 - 1]] })
                end
            end
            schedule[:weeks].push({:games => matchups, :bye => team_with_bye_this_week})
        end
    end
end

if __FILE__ == $0
    examples = [ 
                     {:teamcount => 4, :gamecount => 2, :weekcount => 12},
                     {:teamcount => 6, :gamecount => 3, :weekcount => 15},
                     {:teamcount => 7, :gamecount => 3, :weekcount => 18},
                     {:teamcount => 8, :gamecount => 4, :weekcount => 21},

                      {:teamcount => 12, :gamecount => 6, :weekcount => 22},

                      {:teamcount => 9, :gamecount => 4, :weekcount => 24}, 
               ]

    examples.each do |ex|
        puts ""
        puts "#{ex[:teamcount]} teams, #{ex[:gamecount]} timeslots, #{ex[:weekcount]} weeks"
        TeamMatchupsCircular.get_team_matchups(ex)

        games_played = Hash.new
        (1..ex[:teamcount]).each { |t| games_played[t] = 0 }

        (1..ex[:weekcount]).each do |i|
            matchups = Array.new
            ex[:weeks][i - 1][:games].each do |game|
                matchups.push("#{game[:teampair][0]} v #{game[:teampair][1]}")
            end
            print "Week #{i}: #{matchups.join(', ')}"
            if ex[:weeks][i - 1][:bye] != nil
                print ", bye team: #{ex[:weeks][i - 1][:bye]}"
            end
            puts ""
            ex[:weeks][i - 1][:games].each do |game|
            games_played[game[:teampair][0]] += 1
            games_played[game[:teampair][1]] += 1
            end
        end

        games_against_each_opponent = Hash.new
        (1..ex[:teamcount]).each do |j|
            games_against_each_opponent[j] = Hash.new
            (1..ex[:teamcount]).each do |k|
                games_against_each_opponent[j][k] = 0
            end
        end
        (1..ex[:weekcount]).each do |i|
            ex[:weeks][i - 1][:games].each do |game|
                t1 = game[:teampair][0]
                t2 = game[:teampair][1]
                if t1 == t2
                    puts "ERROR: in week # #{i} team #{t1} plays itself"
                end
                games_against_each_opponent[t1][t2] += 1
                games_against_each_opponent[t2][t1] += 1
            end
        end

        puts "# of games each team has:"
        (1..ex[:teamcount]).each do |t|
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


