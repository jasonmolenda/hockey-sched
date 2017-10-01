#! /usr/bin/ruby
require 'open-uri'
require 'time'
require 'etc'
require 'cgi'

# Given a url to a .ics file
# returns an array of lines of that file.

def get_ics_text_from_web(url)
  fake_user_agent="Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1"
  ics_text = Array.new
  if url =~ /^http:\/\/www.google.com/
    url.gsub!(/^http:\/\//, "https://")
  end
  open(url, "User-Agent" => fake_user_agent).read.each_line do |l|
    ics_text.push(l.strip)
  end
  ics_text
end


# ics_text is an Array of lines of text, the text is ics or iCalendar format.
# returns an array of events, each event is a hash with 
# :start_time, :end_time, :summary, :description, and :location filled in based
# on the ics entries.

def ics_parser(ics_text)
  events = Array.new
  cur_event_lines = Array.new
  processing_an_event = 0
  ics_text.each do |l|
    l = l.strip
    if l =~ /BEGIN:VEVENT/
      processing_an_event = 1
      cur_event_lines = Array.new
      next
    end
    if l =~ /END:VEVENT/
      processing_an_event = 0
      start_time = cur_event_lines.map {|i| i if i =~ /^DTSTART/}.delete_if {|j| j.nil?}
      end_time = cur_event_lines.map {|i| i if i =~ /^DTEND/}.delete_if {|j| j.nil?}
      summary = cur_event_lines.map {|i| i if i =~ /^SUMMARY/}.delete_if {|j| j.nil?}
      description = cur_event_lines.map {|i| i if i =~ /^DESCRIPTION/}.delete_if {|j| j.nil?}
      location = cur_event_lines.map {|i| i if i =~ /^LOCATION/}.delete_if {|j| j.nil?}
      uid = cur_event_lines.map {|i| i if i =~ /^UID:/}.delete_if {|j| j.nil?}

      start_time = start_time[0] if start_time.instance_of? Array
      end_time = end_time[0] if end_time.instance_of? Array
      summary = summary[0] if summary.instance_of? Array
      description = description[0] if description.instance_of? Array
      location = location[0] if location.instance_of? Array
      uid = uid[0] if uid.instance_of? Array

      if start_time.nil?
        STDERR.puts "nil start_time for Array #{cur_event_lines}"
        next
      end
      if end_time.nil?
        STDERR.puts "nil end_time for Array #{cur_event_lines}"
        next
      end

      # Convert a date like DTSTART:20091208T030000Z
      # or DTSTART;TZID=America/Los_Angeles:2009-09-15T21:30:00
      # into 2009-12-07T19:00:00
      # (assuming pacific time)

      start_time_gmt = 1
      start_time_gmt = 0 if start_time =~ /DTSTART;TZID=America.Los_Angeles/
      start_time = start_time.gsub(/^DTSTART.*:/, "").gsub(/(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)Z?/, '\1-\2-\3T\4:\5:\6')
      if start_time_gmt == 1
        start_time = Time.iso8601("#{start_time}Z")
      else
        start_time = Time.iso8601(start_time)
      end

      end_time_gmt = 1
      end_time_gmt = 0 if end_time =~ /DTEND;TZID=America.Los_Angeles/
      end_time = end_time.gsub(/^DTEND.*:/, "").gsub(/(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)Z?/, '\1-\2-\3T\4:\5:\6')
      if end_time_gmt == 1
        end_time = Time.iso8601("#{end_time}Z")
      else
        end_time = Time.iso8601(end_time)
      end

      this_event = Hash.new
      this_event[:start_time] = start_time
      this_event[:end_time] = end_time
      this_event[:summary] = summary.gsub(/^SUMMARY:\s*/, "").gsub(/\s*$/, "")
      this_event[:description] = description.gsub(/^DESCRIPTION:\s*/, "").gsub(/\s*$/, "")
      location = "" if location == nil
      this_event[:location] = location.gsub(/^LOCATION:\s*/, "").gsub(/\s*$/, "")
      uid = `uuidgen`.strip if uid == nil
      this_event[:uuid] = uid
      events.push(this_event)
      next
    end
    cur_event_lines.push(l)
  end
  events
end

# Common typeos, alternate spellings, etc.
@team_aliases = { 
            "Day Case Beer" => "Day Casebeer", "Post X" => "PostX",
            "Nomad\W" => "Nomads", "Thunders" => "Thunder", "Helo Monster\W" => "Helo Monsters", "Desert heat" => "Desert Heat",
            "Dessert Ravens" => "Desert Ravens", "Scoprions" => "Scorpions",
            "Pharoahs" => "Pharaohs", 
            "falling Stars" => "Falling Stars",
            "Tarantuals" => "Tarantulas",
            "Clean Solution" => "Clean Solutions",
            "Flying Carpet" => "Flying Carpets",
            "VMWare" => "VMware", "genies" => "Genies",
            "Vmware" => "VMware",
            "Day CAse Beer" => "Day Casebeer",
            "Day Case beer" => "Day Casebeer",
            "Day Casebeer" => "Day Casebeer",
            "Post x" => "PostX",
            "VmWare" => "VMware",
            "vmware" =>"VMware", 
            "De niles" =>"De Niles", 
            "Ssand Lizards" =>"Sand Lizards", 
            "Blue MArtini" => "Blue Martini",
            "Coconuts \\(formerly Dates\\)" => "Coconuts",
            "Dates \\(formerly Coconuts\\)" => "Dates",
            "TEAL" => "Teal",
            "Desert Owls" => "Oasis Owls" }

# takes an array of ics_entries from ics_parser() and
# returns an array of hashes with keys :time, :home, :away

def ics_entries_to_games (ics_entries)
  games = Array.new
  ics_entries.each do |event|
    teams = event[:summary].strip

    next if teams =~ /\[\d\]/
    next if teams =~ /\[Canceled\]/i
    next if teams =~ /\[consolation\]/i
    next if teams =~ /\d\s?(v|vs|vs\.)\s?\d/
    next if teams =~ /keg/i
    next if teams =~ /consolation/i
    next if teams =~ /playoff/i
    next if teams =~ /Sign up for the tournament/i
    next if teams =~ /game/i
    next if teams =~ /Tournament/i
    next if teams =~ /Pickup/i
    next if teams =~ /clinic/i

    teams = teams.gsub(/\s+$/, "").gsub(/^\s+/, "").gsub(/\s+/, " ")

    team1 = teams.gsub(/( v | vs | vs. | v. | Vs ).*/, "")
    team2 = teams.gsub(/.*( v | vs | vs. | v. | Vs )/, "")

    # strip off the color names, e.g. "Coconuts / White"
    team1 = team1.gsub(/\/\s*(black|blue|dark blue|green|grey|lite blue|orange|red|teal|white|yellow)\s*$/i, "").gsub(/\s+$/, "")
    team2 = team2.gsub(/\/\s*(black|blue|dark blue|green|grey|lite blue|orange|red|teal|white|yellow)\s*$/i, "").gsub(/\s+$/, "")

    @team_aliases.each_pair {|aliasname, truename| team1.gsub!(/#{aliasname}$/, "#{truename}")}
    @team_aliases.each_pair {|aliasname, truename| team2.gsub!(/#{aliasname}$/, "#{truename}")}

    this_game = { :time => event[:start_time],
                  :home => team1,
                  :away => team2 }
    games.push(this_game)
  end
  games.sort {|a, b| a[:time] <=> b[:time]}
end

# take an array of games (:time, :home, :away) and either a "starting" or "ending" 
# date spec in ISO8601 local time format ascii string.  
# Only return entires that are within that range.

def filter_daterange(games, starting, ending)
  starting = nil if starting == ""
  starting = nil if !starting.nil? && starting !~ /^[12][0-9][0-9][0-9]-[0-9][0-9]-[0-3][0-9]$/
  ending = nil if ending == ""
  ending = nil if !ending.nil? && ending !~ /^[12][0-9][0-9][0-9]-[0-9][0-9]-[0-3][0-9]$/
  return games if starting == nil && ending == nil

  starting="1900-01-01" if starting == nil
  ending="2100-01-01" if ending == nil

  starting="#{starting}T00:00:00"
  ending="#{ending}T23:59:59"

  starting = Time.iso8601(starting)
  ending = Time.iso8601(ending)

  return games if starting == nil && ending == nil
  return games if starting == ending
  return if ending < starting

  new_games = Array.new
  games.each do |g|
    if g[:time] >= starting && g[:time] <= ending
      new_games.push(g)
    end
  end

  new_games.sort {|a, b| a[:time] <=> b[:time]}
end

def to_date_iso8601(datetime)
  datetime.localtime.strftime("%Y-%m-%d")
end

def to_date_month_day(datetime)
  datetime.localtime.strftime("%m/%e").gsub(/ /, "").gsub(/^0/, "")
end

def to_time(datetime)
  datetime.localtime.strftime("%H:%M")
end

def to_time_human(datetime)
  datetime.localtime.strftime("%l:%M")
end

def to_date_day_of_week(datetime)
   datetime.localtime.strftime("%a")
end

def generate_report(games, verbose)
  # make a list of all teams seen
  teams = Array.new
  all_games_per_team = Hash.new
  games.each do |g|
    teams.push(g[:home])
    teams.push(g[:away])
    all_games_per_team[g[:home]] = Array.new if !all_games_per_team.has_key?(g[:home])
    all_games_per_team[g[:away]] = Array.new if !all_games_per_team.has_key?(g[:away])
    all_games_per_team[g[:home]].push(g)
    all_games_per_team[g[:away]].push(g)
  end
  teams = teams.sort.uniq
  
  # make a list of all dates (not times) seen
  dates = Array.new
  all_games_per_date = Hash.new
  games.each do |g|
    date = to_date_iso8601(g[:time])
    dates.push(date)
    all_games_per_date[date] = Array.new if !all_games_per_date.has_key?(date)
    all_games_per_date[date].push(g)
  end
  dates = dates.sort.uniq
  
  # make a list of all times (not dates) seen
  times = Array.new
  all_games_per_time = Hash.new
  games.each do |g|
    time = to_time(g[:time])
    times.push(time)
    all_games_per_time[time] = Array.new if !all_games_per_time.has_key?(time)
    all_games_per_time[time].push(g)
  end
  times = times.sort.uniq
  
  puts "#{all_games_per_team.size} teams seen in this calendar."
  puts ""

  teams.each do |team|
    puts "#{team}"
    number_of_games = all_games_per_team[team].size
    puts "Number of games: #{number_of_games}"
    number_of_home_games = all_games_per_team[team].select {|g| g[:home] == team}.size
    number_of_away_games = all_games_per_team[team].select {|g| g[:away] == team}.size
    printf("Number of home games: #{number_of_home_games} (%d%%)\n", 100.0 * number_of_home_games / number_of_games)
    printf("Number of away games: #{number_of_away_games} (%d%%)\n", 100.0 * number_of_away_games / number_of_games)
  
    puts "Game times: #{all_games_per_team[team].sort {|a, b| a[:time] <=> b[:time]}.map {|g| to_time_human(g[:time]).gsub(/\s/, "")}.join(', ')}"
    list_of_opponents = all_games_per_team[team].sort{|a, b| a[:time] <=> b[:time]}.map do |g| 
           if g[:home] == team
             g[:away]
           else
             g[:home]
           end
         end.join(', ')
    puts "Opponents: #{list_of_opponents}"
  
  
    puts "Number of games at each timeslot:"
    all_games_per_time.keys.sort.each do |time|
      games_at_this_timeslot = all_games_per_time[time].select {|g| to_time(g[:time]) == time && (g[:home] == team || g[:away] == team)}
      printf("             #{time} - %d (%d%%)\n", games_at_this_timeslot.size, 100.0 * games_at_this_timeslot.size / number_of_games)
    end
  
    puts "Number of times playing against opposing teams:"
    opponents = Hash.new
    all_games_per_team[team].each do |g|
      opp = ""
      if g[:home] == team
        opp = g[:away]
      else
        opp = g[:home]
      end
      opponents[opp] = 0 if !opponents.has_key?(opp)
      opponents[opp] = opponents[opp] + 1
    end
    all_games_per_team[team].size.downto(1) do |n|
      matched_opponents = Array.new
      opponents.each_key {|k| matched_opponents.push(k) if opponents[k] == n}
      matched_opponents.each do |opp|
        printf("             #{n} times: #{opp} (%d%%)\n", 100.0 * n / number_of_games)
      end
    end
  
    puts ""

  #  puts "Back-to-back timeslots:"
    dates = all_games_per_date.keys.sort
    back_to_backs = Hash.new
    dates.each_index do |i|
      next if i == 0
      this_week = all_games_per_date[dates[i]].select {|v| v[:home] == team || v[:away] == team}
      last_week = all_games_per_date[dates[i - 1]].select {|v| v[:home] == team || v[:away] == team}
      next if last_week.size != 1 || this_week.size != 1
      if (to_time(last_week[0][:time]) == to_time(this_week[0][:time]))
        back_to_backs[to_time(last_week[0][:time])] = Array.new if !back_to_backs.has_key?(to_time(last_week[0][:time]))
        back_to_backs[to_time(last_week[0][:time])].push("#{to_date_month_day(last_week[0][:time])} & #{to_date_month_day(this_week[0][:time])}")
      end
    end
    if back_to_backs.size > 0
      puts "Back-to-back timeslots:"
      back_to_backs.keys.sort.each do |atime|
          puts "             #{atime}: #{back_to_backs[atime].size} -- #{back_to_backs[atime].join(', ')}"
      end
    end
  
  #  puts "Back-to-back opponents:"
    back_to_backs = Hash.new
    dates.each_index do |i|
      next if i == 0
      this_week = all_games_per_date[dates[i]].select {|v| v[:home] == team || v[:away] == team}
      last_week = all_games_per_date[dates[i - 1]].select {|v| v[:home] == team || v[:away] == team}
      next if last_week.size != 1 || this_week.size != 1
      this_week_opponent = ""
      last_week_opponent = ""
      if (last_week[0][:home] == team)
        last_week_opponent = last_week[0][:away]
      else
        last_week_opponent = last_week[0][:home]
      end
      if (this_week[0][:home] == team)
        this_week_opponent = this_week[0][:away]
      else
        this_week_opponent = this_week[0][:home]
      end
  
      if (this_week_opponent == last_week_opponent)
        back_to_backs[last_week_opponent] = Array.new if !back_to_backs.has_key?(last_week_opponent)
        back_to_backs[last_week_opponent].push("#{to_date_month_day(last_week[0][:time])} & #{to_date_month_day(this_week[0][:time])}")
      end
    end
    if back_to_backs.size > 0
      puts "Back-to-back opponents:"
      back_to_backs.keys.sort.each do |opponent|
          puts "             #{opponent}: #{back_to_backs[opponent].join(', ')}"
      end
    end

    if verbose == true
        puts ""
        all_games_per_team[team].sort{|a, b| a[:time] <=> b[:time]}.each do |g| 
           date = to_date_iso8601(g[:time])
           day_of_week = to_date_day_of_week(g[:time])
           time = to_time(g[:time])
           opponent = ""
           if g[:home] == team
               opponent = g[:away]
           else
               opponent = g[:home]
           end
           puts "#{date} #{day_of_week} #{time} #{opponent}"
        end
   end
        
    
  
    puts ""
    puts ""
  end
end


league_urls_2014_and_later = { 
    "Monday" => "https://www.google.com/calendar/ical/iceoasis.com_gdo27qkf68da1n9o5a2raqh310%40group.calendar.google.com/public/basic.ics",
    "Tuesday" => "https://www.google.com/calendar/ical/iceoasis.com_q8n339llu90rk02tprosrqs7e8%40group.calendar.google.com/public/basic.ics",
    "Wednesday" => "https://www.google.com/calendar/ical/iceoasis.com_iq922dhg1rtem9r4hs1d2i2d6c%40group.calendar.google.com/public/basic.ics",
    "Thursday" => "https://www.google.com/calendar/ical/iceoasis.com_vfjj2ef3u46uqi3ifuu0iv0i14%40group.calendar.google.com/public/basic.ics",
    "Friday" => "https://www.google.com/calendar/ical/iceoasis.com_62ao3hk8v84q4da41d7ofio6r0%40group.calendar.google.com/public/basic.ics",
    "Saturday" => "https://www.google.com/calendar/ical/iceoasis.com_ahr9tvq1tjg0pdcdsg8p61p9jc%40group.calendar.google.com/public/basic.ics",
    "Sunday" => "https://www.google.com/calendar/ical/iceoasis.com_kln360a6pjk655mvbdgufnoct8%40group.calendar.google.com/public/basic.ics" }

league_urls_thru_2012 = { 
    "Monday" => "https://www.google.com/calendar/ical/iceoasis.com_gdo27qkf68da1n9o5a2raqh310%40group.calendar.google.com/public/basic.ics",
    "Tuesday" => "https://www.google.com/calendar/ical/iceoasis.com_q8n339llu90rk02tprosrqs7e8%40group.calendar.google.com/public/basic.ics",
    "Wednesday" => "https://www.google.com/calendar/ical/iceoasis.com_iq922dhg1rtem9r4hs1d2i2d6c%40group.calendar.google.com/public/basic.ics",
    "Thursday" => "https://www.google.com/calendar/ical/iceoasis.com_vfjj2ef3u46uqi3ifuu0iv0i14%40group.calendar.google.com/public/basic.ics",
    "Friday" => "https://www.google.com/calendar/ical/iceoasis.com_62ao3hk8v84q4da41d7ofio6r0%40group.calendar.google.com/public/basic.ics",
    "Saturday" => "https://www.google.com/calendar/ical/iceoasis.com_ahr9tvq1tjg0pdcdsg8p61p9jc%40group.calendar.google.com/public/basic.ics",
    "Sunday" => "https://www.google.com/calendar/ical/iceoasis.com_kln360a6pjk655mvbdgufnoct8%40group.calendar.google.com/public/basic.ics" }

league_urls_fall_winter_2012 = { 
    "Monday" => "https://www.google.com/calendar/ical/iceoasis.com_gdo27qkf68da1n9o5a2raqh310%40group.calendar.google.com/public/basic.ics",
    "Tuesday" => "https://www.google.com/calendar/ical/iceoasis.com_q8n339llu90rk02tprosrqs7e8%40group.calendar.google.com/public/basic.ics",
    "Wednesday" => "https://www.google.com/calendar/ical/iceoasis.com_iq922dhg1rtem9r4hs1d2i2d6c%40group.calendar.google.com/public/basic.ics",
    "Thursday" => "https://www.google.com/calendar/ical/iceoasis.com_vfjj2ef3u46uqi3ifuu0iv0i14%40group.calendar.google.com/public/basic.ics",
    "Friday" => "https://www.google.com/calendar/ical/iceoasis.com_iq922dhg1rtem9r4hs1d2i2d6c%40group.calendar.google.com/public/basic.ics",
    "Saturday" => "https://www.google.com/calendar/ical/iceoasis.com_ahr9tvq1tjg0pdcdsg8p61p9jc%40group.calendar.google.com/public/basic.ics",
    "Sunday" => "https://www.google.com/calendar/ical/iceoasis.com_kln360a6pjk655mvbdgufnoct8%40group.calendar.google.com/public/basic.ics" }



# the dates for the fall/winter 2011-2012 season:
#games = filter_daterange(games, "2011-08-01", "2012-02-17")

# the dates for the spring/summer 2012 season:
#games = filter_daterange(games, "2012-02-18", "2012-07-13")

# the dates for the fall/winter 2012-2013 season:
#games = filter_daterange(games, "2012-08-06", nil)

# all games
#games = filter_daterange(games, nil, nil)

#
# Change this to determine whether this script opens a file
# or expects input as a cgi-bin script.
#
cgi = 1

if cgi == 0
  games = ics_entries_to_games(ics_parser(get_ics_text_from_web(league_urls_thru_2012["Tuesday"])))
# the dates for the spring/summer 2012 season:
  games = filter_daterange(games, "2012-02-18", "2012-07-13")
  generate_report(games, true)
  exit true
else
  cgi = CGI.new
  puts "Content-type: text/plain; charset=iso-8859-1"
  puts ""

### 
### Test an uploaded text file
### 

  if cgi.has_key?("ics_file_text")
    ics_contents = cgi['ics_file_text'].read().split(/[\r\n]/).map {|l| l.chomp.chomp}
    if ics_contents.size < 3
      puts "Error: Did not get an ics file.  Got this:  \n\n#{ics_contents}"
      exit true
    end
    ics_entries = ics_parser(ics_contents)
    if ics_entries.size == 0
      puts "Error: Did not get a valid ics file.  Got this:  \n\n#{ics_contents}"
      exit true
    end
    games = ics_entries_to_games(ics_entries)
    if games.size == 0
      puts "Error: Could not convert ics entries to games, based on this text:\n\n#{ics_contents}"
      exit true
    end

    start_date=""
    end_date=""
    if cgi.has_key?("startdate")
      start_date = cgi['startdate'].read.chomp.chomp
      if start_date !~ /20[012]\d-[01]\d-[0-3]\d/
        start_date = ""
      end
    end
    if cgi.has_key?("enddate")
      end_date = cgi['enddate'].read.chomp.chomp
      if end_date !~ /20[012]\d-[01]\d-[0-3]\d/
        end_date = ""
      end
    end

    games = filter_daterange(games, start_date, end_date)


    printf("Report for uploaded .ics / iCalendar formatted file.  ")
    if start_date != "" && end_date != ""
      printf("Filtered by start date #{start_date} and end date #{end_date}.")
    elsif start_date != ""
      printf("Filtered by start date #{start_date}.")
    elsif end_date != ""
      printf("Filtered by end date #{end_date}.")
    end
    puts ""
    puts ""
    puts ""

    verbose = false
    if cgi.has_key?("verbose")
      verbose = true
    end
    generate_report(games, verbose)
    exit true
  end

### 
### Test an Ice Oasis calendar for a specific season
### 

  league_urls = league_urls_thru_2012
  if cgi.has_key?("io-calendar-check") && cgi.has_key?("league")
    season_to_test = cgi["io-calendar-check"]
    league = cgi["league"]
    if season_to_test == "fall2017"
      league_urls = league_urls_2014_and_later
      start_date = "2017-10-01"
      end_date = "2017-03-10"
    elsif season_to_test == "spring2017"
      league_urls = league_urls_2014_and_later
      start_date = "2017-04-01"
      end_date = "2017-09-10"
    elsif season_to_test == "fall2016"
      league_urls = league_urls_2014_and_later
      start_date = "2016-09-28"
      end_date = "2017-03-10"
    elsif season_to_test == "spring2016"
      league_urls = league_urls_2014_and_later
      start_date = "2016-03-27"
      end_date = "2016-09-25"
    elsif season_to_test == "fall2014"
      league_urls = league_urls_2014_and_later
      start_date = "2014-09-26"
      end_date = "2015-03-08"
    elsif season_to_test == "spring2014"
      league_urls = league_urls_2014_and_later
      start_date = "2014-03-14"
      end_date = "2014-09-04"
    elsif season_to_test == "fall2013"
      start_date = "2013-09-03"
      end_date = "2014-03-13"
    elsif season_to_test == "spring2013"
      start_date = "2013-03-06"
      end_date = "2013-09-02"
    elsif season_to_test == "fall2012"
      start_date = "2012-08-06"
      end_date = "2013-02-12"
    elsif season_to_test == "spring2012"
      start_date = "2012-02-18"
      end_date = "2012-07-13"
    elsif season_to_test == "fall2011"
      start_date = "2011-08-01"
      end_date = "2012-02-17"
    elsif season_to_test == "fall2012"
      start_date = "2012-08-06"
      end_date = "2013-01-25"    # just a guess
     league_urls = league_urls_fall_winter_2012
    end
    if league_urls.has_key?(league)
      puts "Report for #{league} night schedule start date #{start_date} end date #{end_date}."
      puts ""
      puts ""
      games = ics_entries_to_games(ics_parser(get_ics_text_from_web(league_urls[league])))
      games = filter_daterange(games, start_date, end_date)
      verbose = false
      if cgi.has_key?("verbose")
          verbose = true
      end
      generate_report(games, verbose)
      exit true
    end
  end

### 
### Test an ics file at a URL
### 

  if cgi.has_key?("url")
    url = cgi["url"]
    ics_contents = get_ics_text_from_web(url)
    if ics_contents.size < 3
      STDERR.puts "Error: Did not get an ics file.  Got this:  \n\n#{ics_contents}"
      exit true
    end
    ics_entries = ics_parser(ics_contents)
    if ics_entries.size == 0
      STDERR.puts "Error: Did not get a valid ics file.  Got this:  \n\n#{ics_contents}"
      exit true
    end
    games = ics_entries_to_games(ics_entries)
    if games.size == 0
      STDERR.puts "Error: Could not convert ics entries to games, based on this text:\n\n#{ics_contents}"
      exit true
    end

    start_date=""
    end_date=""
    if cgi.has_key?("startdate")
      start_date = cgi['startdate']
      if start_date !~ /20[012]\d-[01]\d-[0-3]\d/
        start_date = ""
      end
    end
    if cgi.has_key?("enddate")
      end_date = cgi['enddate']
      if end_date !~ /20[012]\d-[01]\d-[0-3]\d/
        end_date = ""
      end
    end

    games = filter_daterange(games, start_date, end_date)

    printf("Report for uploaded .ics / iCalendar formatted file.  ")
    if start_date != "" && end_date != ""
      printf("Filtered by start date #{start_date} and end date #{end_date}.")
    elsif start_date != ""
      printf("Filtered by start date #{start_date}.")
    elsif end_date != ""
      printf("Filtered by end date #{end_date}.")
    end
    puts ""
    puts ""
    puts ""

    verbose = false
    if cgi.has_key?("verbose")
        verbose = true
    end
    generate_report(games, verbose)
    exit true
  end


end 
exit true 
