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

def matrix_empty_spots(mat, dim)
  res = Array.new
  1.upto(dim) do |i|
    1.upto(dim) do |j|
      if mat[i][j] == 0
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

# Note that this function can reach a dead end and not supply the expected weekcount * (teamcount / 2)
# matchups.  Call it repeatedly until you get a complete schedule.

def create_team_combinations_until_deadlocked (games, weekcount, teamcount)
  games_per_week = teamcount / 2
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
    
  # If we're near the end, just pick out the open spots on the matrix to
  # avoid stupid deadlock problems.
      a = matrix_empty_spots(matrix, teamcount).shuffle
      if a.length <= teamcount
        0.upto((games_per_week) - 1) do |i|
          team_a = a[i][0]
          team_b = a[i][1]
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
        team_b = rand(teamcount) + 1
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
          team_b = thisweek_free[rand(thisweek_free.length)]
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

def create_team_combinations (weekcount, teamcount)
  games_per_week = teamcount / 2
  games = Array.new
  one_block_repeated = 0
  if teamcount <= 4
    one_block_repeated = 1
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

def order_game_times (team_pairings, teamcount)
  gamecount = teamcount / 2
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
        score = score + 30 if gametimes[team_a][time] >= max_games_per_timeslot
        score = score + 30 if gametimes[team_b][time] >= max_games_per_timeslot

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
# Give the lowest scoring team pairs the correct timeslots.
  
    played_this_week = Hash.new
    gamecount.downto(1) do |time|
      sorted_teams = timeslot_scores[time].sort {|x,y| x[1] <=> y[1]}
#puts "<br>for weeknum #{weeknum} timeslot #{time} scores are "
#sorted_teams.each do |k|
#puts "#{this_week_games[k[0]][0]}+#{this_week_games[k[0]][1]}==#{k[1]}"
#end
      sorted_teams.each do |j|
        if !played_this_week.has_key?(j[0])
          played_this_week[j[0]] = "used"
          team_a, team_b = this_week_games[j[0]][0], this_week_games[j[0]][1]
#puts "<br>weeknum #{weeknum} timeslot #{time} #{team_a} and #{team_b} won with score #{j[1]}"
#puts "<br>" if time == 1
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
  game_times = ["20:15", "21:30", "22:45"] if cgi['times'] == "8159301045"
  game_times = ["21:00", "22:15"] if cgi['times'] == "9001015"
  game_times = ["4:30", "5:45"] if cgi['times'] == "430545"
  if cgi['times'] == "other"
    times = cgi['times-manual-entry'].gsub(/\s+/, "").split(/[\r\n,]+/)
    game_times = times.map {|l| if l =~ /(\d+):(\d+)/; sprintf("%02d:%02d", $1, $2); end}
  end

  if game_times.size() == 0
    puts "Error: empty list of game times.</body></html>"
    exit
  end

  team_names = Array.new
  if cgi['teamnames'] == "same"
    if cgi['league'] == "Monday"
      team_names = ["Clean Solutions / Blue", "Desert Hawks / Red", "CPC Waves / Teal", "Sphinxs / Grey", "Toasters / Green", "Blue Martini / White"]
    end
    if cgi['league'] == "Tuesday"
      team_names = ["Desert Heat / Yellow", "Nomads / Black", "Helo Monsters / Blue", "Sultans / Red", "Cactus / Teal", "Desert Storm / Green"]
    end
    if cgi['league'] == "Wednesday"
      team_names = ["Oasis / Green", "Road Runners / Red", "Desert Dogs / Lite Blue", "Suns / Yellow", "Arabian Knights / Black", "Camels / Grey", "Danger / Orange", "Sahara Desert / White"]
    end
    if cgi['league'] == "Thursday"
      team_names = ["Cobras / Green", "Desert Ravens / White", "Desert Foxes / Grey", "Desert Tribe / Dark Blue", "Scorpions / Yellow", "Genies / Lite Blue"]
    end
    if cgi['league'] == "Friday"
      team_names = ["Falling Stars / White", "Polars / Yellow", "Falcons / Black", "Intangibles / Red", "Otters / Teal", "Shamrocks / Green", "Yaks / Blue", "Old Timers / Grey"]
    end
    if cgi['league'] == "Saturday"
      team_names = ["Eagles / Red", "Coconuts / White", "Desert Rats / Yellow", "Desert Thieves / Black"]
    end
    if cgi['league'] == "Sunday"
      team_names = ["Mirage / Yellow", "Turbans / Grey", "Coyotes / Blue", "Dates / White"]
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

  if team_names.size % 2 != 0
    puts "Error: An uneven number of teams specified.</body></html>"
    exit
  end
  if team_names.size != (game_times.size() * 2)
    puts "team names #{team_names}"
    puts "Error: There are #{game_times.size()} game times but only #{team_names.size()} teams names provided.</body></html>"
    exit
  end

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

  results[:season_start_date] = season_start_date
  results[:season_end_date] = season_end_date
  results[:day_of_week] = day_of_week
  results[:game_times] = game_times
  results[:team_names] = team_names
  results[:holidays] = holidays
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

      f.puts "<br>BEGIN:VEVENT"
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
  puts "</body></html>"
  exit
end

season_start_date = results[:season_start_date]
season_end_date = results[:season_end_date]
day_of_week = results[:day_of_week]
game_times = results[:game_times]
team_names = results[:team_names]
holidays = results[:holidays]

puts "#{(season_end_date - season_start_date).to_i} days between start date and end date"

first_game_day = season_start_date
while first_game_day.wday != day_of_week
  first_game_day = first_game_day + 1
end

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

team_pairings = create_team_combinations(total_weeks, team_names.size())

# team_pairings is an array the size of total_weeks * game_times.size()
# Each element in total_pairings is an Array of two elements - two teams.
# One week's game is game_times.size() entries in the array.  
# Home/away and timeslots are not yet computed at all.


games = order_game_times(team_pairings, team_names.size())

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
day = first_game_day
i = 0
while day < season_end_date && i < games.size()
  if is_holiday(day, holidays) == true
    day = day + 7
    next
  end
  week_number = i / game_times.size()
  gametime = game_times[i % game_times.size()]

#  printf("<br>%s-%02d-%02d ", day.year, day.month, day.mday)
#  puts "week num #{week_number + 1} timelsot #{gametime} #{team_names[games[i][0].to_i - 1]} v. #{team_names[games[i][1].to_i - 1]}"
  i = i + 1
  if (i % game_times.size()) == 0
    day = day + 7
#    puts "<br>"
  end
end
#i = 0
#games.each do |g| 
#  puts "#{g[0]}v#{g[1]}"
#  i += 1
## output a blank line between weeks for readability
##  if i % gamecount == 0
##    puts
##  end
#end


puts "</body></html>"
STDOUT.flush
STDOUT.flush

exit true