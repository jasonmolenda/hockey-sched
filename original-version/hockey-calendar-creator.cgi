#! /usr/bin/ruby
require 'open-uri'
require 'date'
require 'time'
require 'etc'
require 'cgi'



def initialize_matrix(mat, dim)
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

def matrix_full?(mat, dim)
  1.upto(dim) do |i|
    1.upto(dim) do |j|
      return false if mat[i][j] == 0
    end
  end
  return true
end

# Don't allow any games to be scheduled for team_to_avoid
# Needed to implement bye weeks for a 7-team league playing 3 games a week
def matrix_empty_spots(mat, dim, team_to_avoid)
  res = Array.new
  1.upto(dim) do |i|
    1.upto(dim) do |j|
      if mat[i][j] == 0 && i != team_to_avoid && j != team_to_avoid
        res.push([i, j]) if res.select {|a| a[0] == j && a[1] == i}.length == 0
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

def create_team_combinations_until_deadlocked (games, weekcount, teamcount)

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
    initialize_matrix(matrix, teamcount)

  # We may end up with an insolvable matrix below - if that happens,
  # bail out and try again with a new matrix.  Save a copy of all the
  # weeks we've successfully scheduled so far so we can roll back to 
  # this if we deadlock.
    loopcount = 0
    saved_weeknum = weeknum
    saved_games = Array.new
    games.each {|e| saved_games.push e}
  
    while !matrix_full?(matrix, teamcount) && weeknum <= weekcount
      if loopcount > teamcount * teamcount * 2
        weeknum = saved_weeknum
        games = saved_games
        break
      end
      loopcount += 1
  
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

  # If we're near the end, just pick out the open spots on the matrix to
  # avoid stupid deadlock problems.
      a = matrix_empty_spots(matrix, teamcount, team_to_avoid_this_week).shuffle
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
        weeknum = saved_weeknum
        games = saved_games
        next
      end
        
      this_week_games.each do |pair|
        games.push [pair[0], pair[1]]
        matrix[pair[0]][pair[1]] = 1
        matrix[pair[1]][pair[0]] = 1
      end
      weeknum += 1
    end
  end
end


# Call the deadlocking team pair generator function
# repeatedly until we get a complete solution for the number
# of weeks we're doing - or we hit the retry limit to avoid
# infinite looping.  The returned array has the team pairings
# for instance in an eight team league (4 games per week), one 
# week in the returned array may look like 
#
# team_pairings[0] == [1, 5]
# team_pairings[1] == [2, 6]
# team_pairings[2] == [8, 7]
# team_pairings[3] == [3, 4]
#
# timeslots and home/away are not yet assigned.

def create_team_combinations (weekcount, teamcount)

  # A 7 team league means that each week one team sits out.
  if teamcount % 2 != 0 && teamcount > 2
    bye_team = true
    games_per_week = (teamcount - 1) / 2
  else
    games_per_week = teamcount / 2
    bye_team = false
  end

  games = Array.new

  one_block_repeated = 0

  # 7 team leagues are a mess with a strict repeating game
  # schedule - some teams never play head to head across a
  # season somehow.
  if teamcount == 7
    one_block_repeated = 0
  end

# For 4 teams and less we won't find a random (non-repeating) full-season solution
# so just get one 3-game sequence block of games and repeat it.
  if teamcount <= 4
    one_block_repeated = 1
  end

# 8 team leagues seem to work out fine with a repeating schedule
  if teamcount == 8
    one_block_repeated = 1
  end

# 6 team leagues have problems assigning timeslots for repeated schedule... random
# seems to work better here?
  if teamcount == 6
    one_block_repeated = 0
  end

  if one_block_repeated == 1
    one_rotation = teamcount - 1
    retry_count = 0
    while games.size() != (teamcount - 1) * games_per_week && retry_count < 1000
      games = Array.new
      create_team_combinations_until_deadlocked(games, teamcount - 1, teamcount)
      retry_count = retry_count + 1
#     puts "<br>retry #{retry_count} got an array with #{games.size} elements want an array of #{weekcount * games_per_week}"
    end
    puts "<br>It took #{retry_count} tries to generate a complete schedule."
    if retry_count > 950
      puts "<br>Could not find a solution for this league, exiting.</body></html>"
      STDOUT.flush
      exit true
    end
    repeat_count = (weekcount / (teamcount - 1)) + 1
    games = games * repeat_count
    games = games.slice(0,weekcount * games_per_week)
  else
    retry_count = 0
    while games.size() != weekcount * games_per_week && retry_count < 1000
      games = Array.new
      create_team_combinations_until_deadlocked(games, weekcount, teamcount)
      retry_count = retry_count + 1
#     puts "<br>retry #{retry_count} got an array with #{games.size} elements want an array of #{weekcount * games_per_week}"
    end
  puts "<br>It took #{retry_count} tries to generate a complete schedule."
    if retry_count > 950
      puts "<br>Could not find a solution for this league, exiting.</body></html>"
      STDOUT.flush
      exit true
    end
  end
  games
end

# team_pairings is an array of teams who will play each other.
# For an 8 team league, each four elements in team_pairings constitute one
# week of games.  e.g.
#
# team_pairings[0] == [1, 5]
# team_pairings[1] == [2, 6]
# team_pairings[2] == [8, 7]
# team_pairings[3] == [3, 4]
#
# But within a single week the timeslots have not yet been assigned.
# This function assigns the timeslots. For each team pair and each timeslot, it
# computes a score (higher scores mean worse) and then it finds the team
# with the best (lowest) score for each timeslot in a given week.

def order_game_times (team_pairings, teamcount, debug)
  # A 7 team league means that each week one team sits out.
  if teamcount % 2 != 0 && teamcount > 2
    bye_team = true
    gamecount = (teamcount - 1) / 2
  else
    gamecount = teamcount / 2
    bye_team = false
  end

  weekcount = team_pairings.size() / gamecount

# the maximum number of games any team should have at any one timeslot, ideally
  max_games_per_timeslot = ((1.0 * weekcount) / gamecount).ceil

# The following uses the team # as the primary index, 1..teamcount
  gametimes = Array.new

# This array uses the week number as its primary index, 1..weekcount
# secondary index is the game time, 1..gamecount
  schedule = Array.new

  1.upto(teamcount) do |i|
    gametimes[i] = Array.new
    1.upto(gamecount) do |j|
      gametimes[i][j] = 0
    end
  end

  1.upto(weekcount) do |i|
    schedule[i] = Array.new
    1.upto(gamecount) do |j|
      schedule[i][j] = nil
    end
  end

  1.upto(weekcount) do |weeknum|
    this_week_games = Array.new
    1.upto(gamecount) { this_week_games.push team_pairings.shift }
  
# this_week_games is an array of the gamecount teams that are playing each
# other this week.  Primary index is 1..gamecount.  Each element in this_week_games
# is an array with two elements - the two teams that are paired up.

# Come up with a score for each team A+B pairing in each timeslot this week.

    timeslot_scores = Array.new
    1.upto(gamecount) {|time| timeslot_scores[time] = Array.new}
   
    1.upto(gamecount) do |time|
      this_week_games.each_index do |i|
        team_a, team_b = this_week_games[i][0], this_week_games[i][1]
        score = 0 

# The number of games each team has played in this timeslot previously is the base score
        score = score + gametimes[team_a][time] + gametimes[team_b][time]

# Avoid teams having more than their fair share of any given timeslot
        if gametimes[team_a][time] >= max_games_per_timeslot || gametimes[team_b][time] >= max_games_per_timeslot
          score = score + 30
# The late game (10:45pm) in a 3- or 4-timeslot league is very bad to have too many of
          if (gamecount == 3 || gamecount == 4) && time == gamecount
            score = score + 30
          end
# The early game (7:00pm) in a 4-timeslot league is a little inconvenient to have too many of
          if gamecount == 4 && time == 1
            score = score + 10
          end
        end

        if weeknum > 1 && gamecount > 2
# if this is a 3- or 4- game league the late gametime slot is bad news,
# we don't want to see back to back games in that timeslot.
          if time == gamecount
            if schedule[weeknum - 1][time][0] == team_a || schedule[weeknum - 1][time][0] == team_b || schedule[weeknum - 1][time][1] == team_a || schedule[weeknum - 1][time][1] == team_b
              score = score + 70 
            end
          else
# Try to avoid back-to-back times for other timeslots too but it's not so critical
            if schedule[weeknum - 1][time][0] == team_a || schedule[weeknum - 1][time][0] == team_b || schedule[weeknum - 1][time][1] == team_a || schedule[weeknum - 1][time][1] == team_b
              score = score + 10
            end
          end
        end

# 3 games in a row in the same timeslot is extra bad news
        if weeknum > 2 && gamecount > 2
          if ((schedule[weeknum - 1][time][0] == team_a || schedule[weeknum - 1][time][1] == team_a) && (schedule[weeknum - 2][time][0] == team_a || schedule[weeknum - 2][time][1] == team_a)) || ((schedule[weeknum - 1][time][0] == team_a || schedule[weeknum - 1][time][1] == team_a) && (schedule[weeknum - 2][time][0] == team_a || schedule[weeknum - 2][time][1] == team_a))
            score = score + 150
          end
        end

        timeslot_scores[time][i] = [i, score]
      end
    end

# Now timeslot_scores has a score for each team pair in each of the timeslots.
# We can end up with an array of scores with no easy solutions.  e.g. for weeknum 25
#
#            teams 1+2  teams 6+3  teams 5+8  teams 7+4
#timeslot 1     22        20         11         75
#timeslot 2     52        43         74        169
#timeslot 3     11        53         22         12
#timeslot 4     43        12         81         82
#
# A good score is maybe 1/2 * weeknum .. weeknum * 2 (12-50 in this case).
#
# Only one team has a good score for timeslot 2, two teams for timeslot 4 (and
# only one of them has a really good score for timeslot 4).
#
# Looking at this by hand, the best selection for this array is 
#    timeslot 1   team 5+8 (score 11)
#    timeslot 2   team 6+3 (score 43)
#    timeslot 3   team 7+4 (score 12)
#    timeslot 4   team 1+2 (score 43)
#
# and it's probably better if team 6+3 gets timeslot 4 (score 12)
# forcing team 1+2 to get timeslot 2 (score 52).  

# Give the lowest scoring team pairs the correct timeslots.

    if debug == true
      puts "<br><pre>week number #{weeknum} score summary:"
      printf "            "
      timeslot_scores[1].sort do |x,y| 
          x_team_a_b = "#{this_week_games[x[0]][0]}+#{this_week_games[x[0]][1]}"
          y_team_a_b = "#{this_week_games[y[0]][0]}+#{this_week_games[y[0]][1]}"
          x_team_a_b <=> y_team_a_b
      end.each {|x| printf "team #{this_week_games[x[0]][0]}+#{this_week_games[x[0]][1]}  "}
      printf "\n"
      1.upto(gamecount) do |time|
        printf "timeslot %d ", time
        timeslot_scores[time].sort do |x,y| 
            x_team_a_b = "#{this_week_games[x[0]][0]}+#{this_week_games[x[0]][1]}"
            y_team_a_b = "#{this_week_games[y[0]][0]}+#{this_week_games[y[0]][1]}"
            x_team_a_b <=> y_team_a_b
        end.each {|x| printf "      %3d ", x[1]}
        printf "\n"
      end
      puts "</pre>"
    end

# The simple appraoch is to do 1..gamecount but you want to put the
# least desirable timeslots up front.  If timeslot 4 (e.g. 10:45pm) is an
# especially bad timeslot that should come first.  By the time you get to
# the last timeslot you're evaluating, teams with good scores may have 
# already been assigned an earlier timeslot and you get stuck picking a
# high-scoring (bad) team pair for that timeslot.
# So the order that you pick the timeslots in is important.

# FIXME instead of having the sorting algorithm look at ONE timeslot at 
# a time, maybe look at all teams' scores for all timeslots and find
# the optimal timeslots for each teampair to play?

    game_schedule_order = Array.new
    if gamecount == 4
      game_schedule_order = [4, 1, 3, 2]
    elsif gamecount == 3
      game_schedule_order = [3, 1, 2]
    else
      gamecount.downto(1) { |i| game_schedule_order.push i}
    end
    
    played_this_week = Hash.new
    game_schedule_order.each do |time|
      sorted_teams = timeslot_scores[time].sort {|x,y| x[1] <=> y[1]}
      if debug == true
        puts "<br>for weeknum #{weeknum} timeslot #{time} scores are "
        sorted_teams.each do |k|
        puts "#{this_week_games[k[0]][0]}+#{this_week_games[k[0]][1]}==#{k[1]}"
        end
      end
      sorted_teams.each do |j|
        if !played_this_week.has_key?(j[0])
          played_this_week[j[0]] = "used"
          team_a, team_b = this_week_games[j[0]][0], this_week_games[j[0]][1]
          if debug == true
            puts "<br>weeknum #{weeknum} timeslot #{time} #{team_a} and #{team_b} won with score #{j[1]}"
          end
          schedule[weeknum][time] = [team_a, team_b]
          gametimes[team_a][time] += 1
          gametimes[team_b][time] += 1
          break
        end
      end
    end
  
  end 

  # We now have the SCHEDULE 2d array, primary key is week number, secondary key
  # is the timeslot #, contents is an array of [team_a, team_b] for that timeslot.
  # Flatten it and return the same format we got on iput.

  game_results = Array.new
  1.upto(weekcount) do |weeknum|
    1.upto(gamecount) do |time|
      game_results.push schedule[weeknum][time]
    end
  end
  game_results
end

# games is an array of teams who will play each other.
# For an 8 team league, each four elements in games constitute one
# week of games.  e.g.
#
# games[0] == [1, 5]
# games[1] == [2, 6]
# games[2] == [8, 7]
# games[3] == [3, 4]
#
# but home and away positions haven't yet been computed.
# Try to blanace them out so everyone has the same number of
# home & away games.  In the output array, the first team listed
# is "home" and the second team listed is "away.

# TODO opportunities for improvement:

# Make sure no team goes over 50% for home/away (possible deadlocking
# problems)
# Make sure teams don't have back-to-back away games.

def balance_home_and_away(games, teamcount)
  home_count = Array.new
  away_count = Array.new
  0.upto(teamcount) { |i| home_count[i] = away_count[i] = 0 }
  balanced_games = Array.new
  games.each do |g|
    a, b = g[0], g[1]
    if away_count[b] > away_count[a]
      home_count[b] = home_count[b] + 1
      away_count[a] = away_count[a] + 1
      balanced_games.push [b, a]
    else
      home_count[a] = home_count[a] + 1
      away_count[b] = away_count[b] + 1
      balanced_games.push [a, b]
    end
  end
  balanced_games
end

def all_arguments_present(cgi)
  return "missing start date" if !cgi.has_key?("startdate")
  return "missing end date" if !cgi.has_key?("enddate")
  return "missing day-of-week"  if !cgi.has_key?("league")
  return "missing game times" if !cgi.has_key?("times")
  return "missing game times manual list" if !cgi.has_key?("times-manual-entry")
  return "missing team names" if !cgi.has_key?("teamnames")
  return "missing team names manual entry" if !cgi.has_key?("teamnames-manual-entry")
  return "missing holidays" if !cgi.has_key?("holidays")
  return nil
end

def parse_args(cgi, results)
  season_start_date = ""
  if cgi.has_key?("startdate")
    season_start_date = cgi['startdate']
    if season_start_date !~ /(20[012]\d)-([01]\d)-([0-3]\d)/
      puts "Error: Start date needs to be in YYYY-MM-DD format, not #{season_start_date}</body></html>"
      exit
    else
      season_start_date = Date.new($1.to_i, $2.to_i, $3.to_i)
    end
  end

  season_end_date = ""
  if cgi.has_key?("enddate")
    season_end_date = cgi['enddate']
    if season_end_date !~ /(20[012]\d)-([01]\d)-([0-3]\d)/
      puts "Error: End date needs to be in YYYY-MM-DD format, not #{season_end_date}</body></html>"
      exit
    else
      season_end_date = Date.new($1.to_i, $2.to_i, $3.to_i)
    end
  end

  day_of_week = 0 if cgi['league'] == "Sunday"
  day_of_week = 1 if cgi['league'] == "Monday"
  day_of_week = 2 if cgi['league'] == "Tuesday"
  day_of_week = 3 if cgi['league'] == "Wednesday"
  day_of_week = 4 if cgi['league'] == "Thursday"
  day_of_week = 5 if cgi['league'] == "Friday"
  day_of_week = 6 if cgi['league'] == "Saturday"

  game_times = Array.new
  game_times = ["19:00", "20:15", "21:30", "22:45"] if cgi['times'] == "7008159301045"
  game_times = ["17:45", "19:00", "20:15"] if cgi['times'] == "545700815"
  game_times = ["20:15", "21:30", "22:45"] if cgi['times'] == "8159301045"
  game_times = ["21:00", "22:15"] if cgi['times'] == "9001015"
  game_times = ["04:30", "05:45"] if cgi['times'] == "430545"
  if cgi['times'] == "other"
    times = cgi['times-manual-entry'].gsub(/\s+/, "").split(/[\r\n,]+/)
    game_times = times.map {|l| if l =~ /(\d+):(\d+)/; sprintf("%02d:%02d", $1, $2); end}
  end

  if cgi['times'] == "same"
    game_times = ["17:45", "19:00", "20:15"] if cgi['league'] == "Sunday"
    game_times = ["20:15", "21:30", "22:45"] if cgi['league'] == "Monday"
    game_times = ["20:30", "21:45"] if cgi['league'] == "Tuesday"
    game_times = ["19:00", "20:15", "21:30", "22:45"] if cgi['league'] == "Thursday"
    game_times = ["19:00", "20:15", "21:30", "22:45"] if cgi['league'] == "Wednesday"
    game_times = ["19:00", "20:15", "21:30", "22:45"] if cgi['league'] == "Friday"
    game_times = ["21:00", "22:15"] if cgi['league'] == "Saturday"
  end

  if game_times.size() == 0
    puts "Error: empty list of game times.</body></html>"
    exit
  end

  team_names = Array.new
  if cgi['teamnames'] == "same"
    if cgi['league'] == "Monday"
      team_names = ["Flying Carpets", "Blue Martini", "Clean Solutions", "Desert Hawks", "Toasters", "Sphinx"]
    end
    if cgi['league'] == "Tuesday"
      team_names = ["Team 1", "Team 2", "Team 3", "Team 4"]
    end
    if cgi['league'] == "Wednesday"
      team_names = ["Camels", "Desert Dogs", "Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"]
    end
    if cgi['league'] == "Thursday"
      team_names = ["Desert Tribe", "Genies", "Cobras", "Sultans", "Desert Foxes", "Desert Ravens", "Scorpions", "Danger"]
    end
    if cgi['league'] == "Friday"
      team_names = ["Lightning", "Falling Stars", "Intangibles", "Old Timers", "Otters", "Polars", "Shamrocks", "Yaks"]
    end
    if cgi['league'] == "Saturday"
      team_names = ["Sabres", "Coconuts", "Desert Rats", "Desert Thieves"]
    end
    if cgi['league'] == "Sunday"
      team_names = ["Coyotes", "Bandits", "Sand Lizards", "Dates", "Desert Storm", "Blades"]
    end
  end

  if cgi['teamnames'] == "generic"
    1.upto(game_times.size() * 2) do |n|
      team_names.push("team#{n}")
    end
  end

  if cgi['teamnames'] == "other"
    team_names = cgi['teamnames-manual-entry'].split(/[\r\n]+/)
  end

#  if team_names.size % 2 != 0
#    puts "Error: An uneven number of teams specified.</body></html>"
#    exit
#  end
#  if team_names.size != (game_times.size() * 2)
#    puts "team names #{team_names}"
#    puts "Error: There are #{game_times.size()} game times but only #{team_names.size()} teams names provided.</body></html>"
#    exit
#  end

  holidays = Hash.new
  cgi['holidays'].split(/[\r\n]+/).each do |holiday|
    next if holiday =~ /^\S*$/
    month = holiday.split[0]
    day = holiday.split[1]
    month = 1 if month =~ /^jan/i || month =~ /january/i
    month = 2 if month =~ /^feb/i || month =~ /february/i
    month = 3 if month =~ /^mar/i || month =~ /march/i
    month = 4 if month =~ /^apr/i || month =~ /april/i
    month = 5 if month =~ /^may/i || month =~ /may/i
    month = 6 if month =~ /^jun/i || month =~ /june/i
    month = 7 if month =~ /^jul/i || month =~ /july/i
    month = 8 if month =~ /^aug/i || month =~ /august/i
    month = 9 if month =~ /^sep/i || month =~ /september/i
    month = 10 if month =~ /^oct/i || month =~ /october/i
    month = 11 if month =~ /^nov/i || month =~ /november/i
    month = 12 if month =~ /^dec/i || month =~ /december/i
    tmparr = Array.new
    tmparr[0] = month
    tmparr[1] = day.to_i
    holidays[holiday] = tmparr
  end

  debug = false
  debug = true if cgi['debug'] == "true"

  results[:season_start_date] = season_start_date
  results[:season_end_date] = season_end_date
  results[:day_of_week] = day_of_week
  results[:game_times] = game_times
  results[:team_names] = team_names
  results[:holidays] = holidays
  results[:debug] = debug
  true
end


def is_holiday (day, holidays)
  holidays.keys.each do |h|
    if holidays[h][0] == day.month && holidays[h][1] == day.day
      return true
    end
  end
  return false
end

def output_ics (games, first_game_day, season_end_date, holidays, game_times, team_names)
  n = 1
  rootdir = "/home/molenda/molenda.us/schedules"
  while File.exist?("#{rootdir}/schedule-#{n}.ics")
    n = n + 1
  end
  filename="#{rootdir}/schedule-#{n}.ics"
  File.open(filename, "w") do |f|
    f.puts "BEGIN:VCALENDAR"
    f.puts "VERSION:2.0"
    f.puts "X-WR-TIMEZONE:America/Los_Angeles"
    f.puts "CALSCALE:GREGORIAN"
    f.puts "METHOD:PUBLISH"

    day = first_game_day
    i = 0
    while day < season_end_date && i < games.size()
      if is_holiday(day, holidays) == true
        day = day + 7
        next
      end
      week_number = i / game_times.size()
      gametime = game_times[i % game_times.size()]

      f.puts "BEGIN:VEVENT"
      start_time = Time.iso8601("#{day.strftime}T#{gametime}:00")
      end_time = start_time + (60 * 75)
      f.puts "DTSTART;TZID=America/Los_Angeles:#{start_time.localtime.strftime("%Y%m%dT%H%M%S")}"
      f.puts "DTEND;TZID=America/Los_Angeles:#{end_time.localtime.strftime("%Y%m%dT%H%M%S")}"
      f.puts "DTSTAMP:#{Time.now.gmtime.strftime("%Y%m%dT%H%M%SZ")}"
      f.puts "CREATED:19000101T120000Z"
      f.puts "DESCRIPTION:"
      f.puts "LAST-MODIFIED:#{Time.now.gmtime.strftime("%Y%m%dT%H%M%SZ")}"
      f.puts "LOCATION:Nazareth Ice Oasis"
      f.puts "SEQUENCE:1"
      f.puts "STATUS:CONFIRMED"
      f.puts "SUMMARY:#{team_names[games[i][0].to_i - 1]} v. #{team_names[games[i][1].to_i - 1]}"
      f.puts "END:VEVENT"

      i = i + 1
      if (i % game_times.size()) == 0
        day = day + 7
      end
    end
  
    f.puts "END:VCALENDAR"
  end

  if File.exist?(filename)
    filename
  else
    nil
  end
end


###############################################################################################
######### main part of the program starts here
###############################################################################################



puts "Content-type: text/html; charset=utf-8"
puts ""
puts "<html><body>"

cgi = CGI.new
missing_args = all_arguments_present(cgi)
if !missing_args.nil?
  puts "Error: #{missing_args} - you need to specify this field."
  puts "</body></html>"
  exit
end


results = Hash.new
if parse_args(cgi, results) == false
  puts "Could not parse arguments</body></html>"
  exit
end

season_start_date = results[:season_start_date]
season_end_date = results[:season_end_date]
day_of_week = results[:day_of_week]
game_times = results[:game_times]
team_names = results[:team_names]
holidays = results[:holidays]
debug = results[:debug]

puts "#{(season_end_date - season_start_date).to_i} days between start date and end date"

# Count the number of weeks in this date range.

first_game_day = season_start_date
while first_game_day.wday != day_of_week
  first_game_day = first_game_day + 1
end

# Count the number of weeks that don't land on a holiday in this date range

day = first_game_day
total_weeks = 0
total_weeks_skipping_holidays = 0
while day < season_end_date
  total_weeks = total_weeks + 1
  if is_holiday(day, holidays) == false
    total_weeks_skipping_holidays = total_weeks_skipping_holidays + 1
  end
  day = day + 7
end

puts "<br />#{total_weeks} total weeks between start and end dates.  #{total_weeks_skipping_holidays} games in this season, skipping holidays."


# Get the array of which teams play which, in what order, for the entire
# season.  Timeslots and home/away are not yet determined --- start by
# fixing the head-to-heads.

team_pairings = create_team_combinations(total_weeks, team_names.size())

# Now assign the timeslots for all the teams.

if debug == true
  puts "<br>"
  0.upto(team_names.size() - 1) do  |n|
    puts "<br>Team #{n + 1} is #{team_names[n]}"
  end
  puts "<br>"
end

games = order_game_times(team_pairings, team_names.size(), debug)

# Now assign home & away positions.

games = balance_home_and_away(games, team_names.size())


filename = output_ics(games, first_game_day, season_end_date, holidays, game_times, team_names)
if filename.nil?
  puts "Error: Could not generate ICS calendar.</body></html>"
  exit false
end
url = filename.gsub(/.*schedules/, "http://molenda.us/schedules")
puts "<p>"
puts "<br>Generated schedule in .ics format is available for download at <a href=\"#{url}\">#{url}</a>."
puts "<br>Or run it through the <a href=\"http://molenda.us/cgi-bin/hockey-calendar-lint.cgi?url=#{url.gsub(/\//, "%2F")}&startdate=&enddate=&Submit=Submit\">schedule checker</a>."

puts "<p>"
if debug == true
  day = first_game_day
  i = 0
  while day < season_end_date && i < games.size()
    if is_holiday(day, holidays) == true
      day = day + 7
      next
    end
    week_number = i / game_times.size()
    gametime = game_times[i % game_times.size()]

    printf("<br>%s-%02d-%02d ", day.year, day.month, day.mday)
    puts "week num #{week_number + 1} timelsot #{gametime} #{team_names[games[i][0].to_i - 1]} v. #{team_names[games[i][1].to_i - 1]}"
    i = i + 1
    if (i % game_times.size()) == 0
      day = day + 7
      puts "<br>"
    end
  end
end


puts "</body></html>"
STDOUT.flush

exit true
