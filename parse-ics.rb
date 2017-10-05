#! /usr/bin/ruby
require 'date'
require 'time'
require 'set'

$LOAD_PATH << File.dirname(__FILE__)

require 'ice-oasis-leagues'

module ParseICS

    def self.ics_to_schedule (text)
        events = inital_ics_parse(text)
        day_of_week_hash = Hash.new(0)
        events.map { |e| day_of_week_hash[e[:start_time].wday] += 1 }
        primary_day_of_week = day_of_week_hash.keys.sort {|x,y| a[x] <=> a[y]}.last
        
        rinks = IceOasisLeagues.get_rinks()
        timeslots = IceOasisLeagues.get_timeslots()

        team_names_seen = Set.new
        team_numbers_seen = Set.new
        dates_seen = Set.new
        rinks_seen = Set.new

        events.each_index do |idx|
            if events[idx][:location] =~ /Redwood City/
                events[idx][:rink_id] = 1
                rinks_seen.add(1)
            end
            if events[idx][:location] =~ /San Mateo/
                events[idx][:rink_id] = 2
                rinks_seen.add(2)
            end
            time_desc = events[idx][:start_time].strftime("%l:%M%p").downcase.gsub(/ /, '')
            tid = timeslots.keys.select {|t| time_desc == timeslots[t][:description]}.first
            if tid == nil
                puts "Could not find a timeslot matching time #{time_desc}"
            end
            events[idx][:timeslot_id] = tid

            summary = events[idx][:summary].gsub(/^SM /, '').gsub(/^RWC /, '')
            if summary =~ /(.+) v[.] (.+)/
                home = $1
                away = $2
                if home != nil && away != nil && home != "" && away != ""
                    events[idx][:home_team_name] = home
                    events[idx][:away_team_name] = away
                    team_names_seen.add(home)
                    team_names_seen.add(away)
                end
            end

            events[idx][:date] = events[idx][:start_time].to_date
            if events[idx][:start_time].wday == primary_day_of_week
                dates_seen.add(events[idx][:date])
            end
        end

        tnum = 1
        team_names_to_team_numbers = Hash.new
        team_names_seen.to_a.sort.each do |tname|
            team_names_to_team_numbers[tname] = tnum
            team_numbers_seen.add(tnum)
            tnum += 1
        end
        team_numbers_seen = team_numbers_seen.to_a
        events.each do |e|
            t1 = team_names_to_team_numbers[e[:home_team_name]]
            t2 = team_names_to_team_numbers[e[:away_team_name]]
            e[:home] = t1
            e[:away] = t2
            e[:teampair] = [t1, t2]
        end

        schedule = Hash.new
        schedule[:teamcount] = team_names_seen.size()
        schedule[:weekcount] = dates_seen.size()
        schedule[:gamecount] = team_names_seen.size() / 2
        schedule[:timeslots] = timeslots
        schedule[:rinks] = rinks
        schedule[:rinkcount] = rinks_seen.size()
        schedule[:weeks] = Array.new
        schedule[:team_names] = team_names_seen.to_a.sort

        weeks_in_order = dates_seen.to_a.sort()
        0.upto(schedule[:weekcount] - 1).each do |wknum|
            this_week = weeks_in_order[wknum]
            next_week = weeks_in_order[wknum + 1]
            if next_week == nil
                next_week = Date.parse('2070-01-01')
            end
            events_this_week = events.select {|e| this_week <= e[:date] && e[:date] < next_week}
            # Set the bye team

            teams_with_games_this_week = Set.new
            events_this_week.each do |e| 
                teams_with_games_this_week.add(e[:home])
                teams_with_games_this_week.add(e[:away])
            end
            teams_with_no_games = Set.new team_numbers_seen
            teams_with_no_games.subtract(teams_with_games_this_week)
            teams_with_no_games = teams_with_no_games.to_a
            if teams_with_no_games.size > 1
                puts "ERROR: too many teams without a game this week #{wknum}: #{teams_with_no_games}"
                exit true
            end
            schedule[:weeks][wknum] = Hash.new
            schedule[:weeks][wknum][:bye] = teams_with_no_games[0]
            schedule[:weeks][wknum][:date] = this_week
            schedule[:weeks][wknum][:games] = Array.new
            events_this_week.sort {|x,y| x[:start_time] <=> y[:start_time]}.each do |event|
                schedule[:weeks][wknum][:games].push( { :timeslot_id => event[:timeslot_id],
                                                 :rink_id => event[:rink_id],
                                                 :home => event[:home],
                                                 :away => event[:away],
                                                 :teampair => event[:teampair],
                                                 :datetime => event[:start_time]
                                              } )
            end
        end
        return schedule
    end

    def self.inital_ics_parse (text)
        if text.is_a?(String)
            text = text.lines
        end
        text = text.map(&:chomp)

        events = Array.new
        processing_an_event = false
        cur_event_lines = Array.new

        text.each do |l|
            l = l.strip
            if l =~ /BEGIN:VEVENT/
                processing_an_event = true
                cur_event_lines = Array.new
                next
            end
            if l =~ /END:VEVENT/
                processing_an_event = false
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
        return events
    end
end

if __FILE__ == $0
    require 'simple-schedule-analysis'

    ics_text = %x[./test-ics.rb]
    schedule = ParseICS.ics_to_schedule(ics_text)
    SimpleScheduleAnalysis.raw_text(schedule)
#    puts schedule
end
