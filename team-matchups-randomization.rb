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
#    Then, functionally, the 1'st pair of the r'th round is:
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

module TeamMatchupsRandomization

    def self.initialize_matrix(mat, dim)
        1.upto(dim) do |i|
            mat[i] = Array.new
            1.upto(dim) do |j|
                if i == j
                    mat[i][j] = 1
                else
                    mat[i][j] = 0
                end
            end
        end
    end

    def self.matrix_full?(mat, dim)
        1.upto(dim) do |i|
            1.upto(dim) do |j|
                return false if mat[i][j] == 0
            end
        end
        return true
    end

    def self.print_matrix_empty_spots(mat, dim, team_to_avoid)
    str = ""
    cnt = 0
    res = Array.new
    1.upto(dim) do |i|
        1.upto(dim) do |j|
            if mat[i][j] == 0
                if res.select {|a| (a[0] == j && a[1] == i) || (a[0] == i && a[1] == j)}.length == 0
                    res.push([i, j])
                    str += "[#{i} v #{j}] "
                    cnt += 1
                end
            end
        end
    end
    STDERR.puts "print_matrix_empty_spots: #{cnt} entries #{str} avoid:#{team_to_avoid}" if @DEBUG
    end

    # Don't allow any games to be scheduled for team_to_avoid
    # Needed to implement bye weeks for a 7-team league playing 3 games a week
    def self.matrix_empty_spots(mat, dim, team_to_avoid)
    res = Array.new
    1.upto(dim) do |i|
        1.upto(dim) do |j|
            if mat[i][j] == 0 && i != team_to_avoid && j != team_to_avoid
                res.push([i, j]) if res.select {|a| (a[0] == j && a[1] == i) || (a[0] == i && a[1] == j)}.length == 0
            end
        end
    end
    return res
    end

# This creates an array of week_count * game_count, e.g. a five week season with two games
# per week will return a ten element array.
# Each element is an array, pair of integers, [1..team_count] and [1..team_count] of two
# teams facing each other.

# The array does not take timeslots and home/away conflicts in to account.  It is only
# indicating which teams should face each other.

# Teams will not play back-to-back games against opponents except at block boundaries.
# The games are scheduled at team_count-1 game blocks (e.g. 8 team league, 7 week blocks)
# and the last game of one block and the first of the next block may have a back-to-back
# game.  Post-processing is needed to resolve these.

# Note that this function can deadlock and not supply the expected weekcount * (teamcount / 2)
# matchups.  Call it repeatedly until you get a complete schedule.  Imagine a scenario near
# the end where team 4 gets assigned to play against team 2; team 7 needs to play either team
# 4 or 2.  Given the previous 4v2 assignment, team 7 is blocked for this round and has no one to
# play.

def self.create_team_combinations_until_deadlocked (games, weekcount, teamcount)

  bye_team = false

  # A 7 team league means that each week one team sits out.
  if teamcount % 2 != 0 && teamcount > 2
    bye_team = true
    games_per_week = (teamcount - 1) / 2
  else
    games_per_week = teamcount / 2
    bye_team = false
  end

  matrix = Array.new
  weeknum = 1
  while weeknum <= weekcount
    STDERR.puts "weeknum is #{weeknum} out of weekcount #{weekcount} weeks" if @DEBUG

    initialize_matrix(matrix, teamcount)
    
    redo_this_week_with_new_matrix = false

  # We may end up with an insolvable matrix below - if that happens,
  # bail out and try again with a new matrix.  Save a copy of all the
  # weeks we've successfully scheduled so far so we can roll back to 
  # this if we deadlock.
    loopcount = 0
    STDERR.puts "NEW SAVED_WEEKNUM - saving weeknum #{weeknum}" if @DEBUG
    saved_weeknum = weeknum
    saved_games = Array.new
    games.each {|e| saved_games.push e}
  
    while !matrix_full?(matrix, teamcount) && weeknum <= weekcount
      if loopcount > teamcount * teamcount * 2
	STDERR.puts "ABORT we've exceeded the loopcount #{loopcount} at weeknum #{weeknum} - reverting to saved_weeknum #{saved_weeknum}" if @DEBUG
        weeknum = saved_weeknum
        games = saved_games
        break
      end
      loopcount += 1
  
      STDERR.puts "loopcount is #{loopcount}" if @DEBUG

      thisweek = Array.new
      this_week_failure = false
      this_week_games = Array.new

      # assuming 7-team league playing 3 games a week
      # In week 1, don't schedule team 1
      # In week 2, don't schedule team 2
      # ...
      # In week 7, don't schedule team 7
      # In week 8, don't schedule team 1
      if bye_team == true
        team_to_avoid_this_week = ((weeknum - 1) % teamcount) + 1
      else
        team_to_avoid_this_week = -1
      end

      STDERR.puts "team to avoid is #{team_to_avoid_this_week}" if @DEBUG
      # puts "JSMFIXME weeknum #{weeknum} teamcount #{teamcount} team to avoid is #{team_to_avoid_this_week}"
  # If we're near the end, just pick out the open spots on the matrix to
  # avoid stupid deadlock problems.
      print_matrix_empty_spots(matrix, teamcount, team_to_avoid_this_week)
      a = matrix_empty_spots(matrix, teamcount, team_to_avoid_this_week).shuffle
      STDERR.puts "weeknum #{weeknum} a.length is #{a.length} and teamcount is #{teamcount}" if @DEBUG
      a.each { |p| STDERR.puts "[#{p[0]} v #{p[1]}]" } if @DEBUG
      if a.length < games_per_week
        STDERR.puts "matrix cannot be fully satisified because the remaining available games require the team with a bye to play" if @DEBUG
        redo_this_week_with_new_matrix = true
        break
      end

      if a.length <= teamcount
        0.upto((games_per_week) - 1) do |i|
          team_a = a[i][0]
          team_b = a[i][1]
          next if team_a == team_to_avoid_this_week || team_b == team_to_avoid_this_week
          next if thisweek[team_a] == 1 || thisweek[team_b] == 1
          this_week_games.push [team_a, team_b]
          thisweek[team_a] = 1
          thisweek[team_b] = 1
        end
        redo if this_week_games.size != games_per_week
        this_week_games.each do |pair|
          team_a, team_b = pair[0], pair[1]
	  STDERR.puts "playing team #{team_a} v. #{team_b}" if @DEBUG
          games.push [team_a, team_b]
          matrix[team_a][team_b] = 1
          matrix[team_b][team_a] = 1
        end
        weeknum += 1
        next
      end
    
      1.upto(teamcount) {|i| thisweek[i] = 0}
      result = 1.upto(games_per_week) do
        team_a = rand(teamcount) + 1
        while team_a == team_to_avoid_this_week
          team_a = rand(teamcount) + 1
        end
        team_b = rand(teamcount) + 1
        while team_b == team_to_avoid_this_week
          team_b = rand(teamcount) + 1
        end

        retry_count = 20
        while team_a == team_b || matrix[team_a][team_b] == 1 || thisweek[team_a] == 1 || thisweek[team_b] == 1
          zerocount = 0
          1.upto(teamcount) {|j| zerocount += 1 if thisweek[j] == 0}
          break if zerocount == 0
          break if matrix_full?(matrix, teamcount)
      
          thisweek_free = Array.new
          thisweek.each_index do |i| 
            if thisweek[i] == 0
              thisweek_free.push(i)
            end
          end
          team_a = thisweek_free[rand(thisweek_free.length)]
          while team_a == team_to_avoid_this_week
            team_a = thisweek_free[rand(thisweek_free.length)]
          end
          team_b = thisweek_free[rand(thisweek_free.length)]
          while team_b == team_to_avoid_this_week
            team_b = thisweek_free[rand(thisweek_free.length)]
          end
          retry_count += 1
          if retry_count > (teamcount * teamcount)
            this_week_failure = true
            break
          end
        end
    
        break if this_week_failure == true
    
        if team_a == team_b || matrix[team_a][team_b] == 1 || thisweek[team_a] == 1 || thisweek[team_b] == 1
          break
        end
    
        thisweek[team_a] = 1
        thisweek[team_b] = 1
        this_week_games.push([team_a, team_b])
      end
    
      # We deadlocked doing this block of weeks, bounce back to last 
      # block boundary and try again.

      if this_week_failure == true
	STDERR.puts "ABORT2 we've exceeded the loopcount #{loopcount} at weeknum #{weeknum} - reverting to saved_weeknum #{saved_weeknum}" if @DEBUG
        weeknum = saved_weeknum
        games = saved_games
        next
      end
        
      this_week_games.each do |pair|
        games.push [pair[0], pair[1]]
        matrix[pair[0]][pair[1]] = 1
        matrix[pair[1]][pair[0]] = 1
      end
      if redo_this_week_with_new_matrix == false
      	weeknum += 1
      end
    end
  end
end



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
    # It has a key :byes for teams that have a bye that week.  This will typically be one team.  
    # e.g. :byes=>[6]
    # or :byes=>[] for a schedule where no team has a bye.

    def self.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

        # A 7 team league means that each week one team sits out.
        if number_of_teams % 2 != 0 && number_of_teams > 2
            bye_team = true
        end

        games = Array.new
        results_message = ""

        one_block_repeated = true

        # 7 team leagues are a mess with a strict repeating game
        # schedule - some teams never play head to head across a
        # season somehow.
        if number_of_teams == 7
            one_block_repeated = false
        end

      # For 4 teams and less we won't find a random (non-repeating) full-season solution
      # so just get one 3-game sequence block of games and repeat it.
        if number_of_teams <= 4
            one_block_repeated = true
        end

      # 8 team leagues seem to work out fine with a repeating schedule
        if number_of_teams == 8 \
            || number_of_teams == 9 \
            || number_of_teams == 10 \
            || number_of_teams == 12
            one_block_repeated = true
        end

      # 6 team leagues have problems assigning timeslots for repeated schedule... random
      # seems to work better here?
        if number_of_teams == 6
            one_block_repeated = false
        end

        # If we repeat a bye week the last team will never get a bye
        if bye_team == true
            one_block_repeated = false
        end


        if one_block_repeated == true
            results_message = "One schedule block repeated.  "
        else
            results_message = "Different schedules for each block.  "
        end

        if one_block_repeated == true
            one_rotation = number_of_teams - 1
            retry_count = 0
            while games.size() != (number_of_teams - 1) * number_of_timeslots && retry_count < 1000
              games = Array.new
              TeamMatchupsRandomization.create_team_combinations_until_deadlocked(games, number_of_teams - 1, number_of_teams)
              retry_count = retry_count + 1
              STDERR.puts "GOT A RESULT retrycount is now #{retry_count + 1}" if @DEBUG
        #     puts "<br>retry #{retry_count} got an array with #{games.size} elements want an array of #{number_of_weeks * number_of_timeslots}"
            end
            results_message += "It took #{retry_count} tries to generate a complete schedule."
            if retry_count > 950
              puts "<br>Could not find a solution for this league, exiting.</body></html>"
              STDOUT.flush
              exit true
            end
            repeat_count = (number_of_weeks / (number_of_teams - 1)) + 1
            games = games * repeat_count
            games = games.slice(0,number_of_weeks * number_of_timeslots)
        else
            retry_count = 0
            while games.size() != number_of_weeks * number_of_timeslots && retry_count < 1000
              games = Array.new
              TeamMatchupsRandomization.create_team_combinations_until_deadlocked(games, number_of_weeks, number_of_teams)
              retry_count = retry_count + 1
            # puts "<br>JSMFIXME retry #{retry_count} got an array with #{games.size} elements want an array of #{number_of_weeks * number_of_timeslots}"
            end
            results_message += "It took #{retry_count} tries to generate a complete schedule."
            if retry_count > 950
                puts "<br>Could not find a solution for this league, exiting.</body></html>"
                STDOUT.flush
                exit true
            end
        end

        weekly_games = Array.new
        (0..number_of_weeks - 1).each do |w|
            games_this_week = games[(w * number_of_timeslots), number_of_timeslots]
            teams_seen_this_week = Hash.new
            (1..number_of_teams).each do |i|
                teams_seen_this_week[i] = false
            end
            games_this_week.each do |p|
                teams_seen_this_week[p[0]] = true
                teams_seen_this_week[p[1]] = true
            end
            bye_teams = teams_seen_this_week.keys.select {|t| teams_seen_this_week[t] == false}

            thisweek_hash = Hash.new
            thisweek_hash[:matchups] = games_this_week
            thisweek_hash[:byes] = bye_teams
            weekly_games.push(thisweek_hash)
        end
        return weekly_games, results_message
    end
end

if __FILE__ == $0
    examples = [ 
                     {:teams => 6, :timeslots => 3, :weeks => 14},
                     {:teams => 7, :timeslots => 3, :weeks => 14},
                     {:teams => 4, :timeslots => 2, :weeks => 14},
                     {:teams => 8, :timeslots => 4, :weeks => 20},

                     # twelve teams super deadlocks, gotta fix it.
                     # {:teams => 12, :timeslots => 6, :weeks => 26},

                     # The 4-timeslot 9-team combination likes to hang the program, it can't find
                     # a solution across the entire season very well.
                     # {:teams => 9, :timeslots => 4, :weeks => 20}, 
               ]

    examples.each do |ex|
        puts ""
        number_of_teams = ex[:teams]
        number_of_timeslots = ex[:timeslots]
        number_of_weeks = ex[:weeks]

        puts "#{number_of_teams} teams, #{number_of_timeslots} timeslots, #{number_of_weeks} weeks"
        results, message = TeamMatchupsRandomization.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

        puts message

        games_played = Hash.new
        (1..number_of_teams).each { |t| games_played[t] = 0 }

        (1..number_of_weeks).each do |i|
            matchups = Array.new
            results[i - 1][:matchups].each do |pair|
                matchups.push("#{pair[0]} v #{pair[1]}")
            end
            print "Week #{i}: #{matchups.join(', ')}"
            if results[i - 1][:byes].size() > 0 
                print ", bye team: #{results[i - 1][:byes].join(', ')}"
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
