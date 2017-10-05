#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)

module AnalyzeSchedule

    def self.team_name(schedule, tnum)
        if schedule.has_key?(:team_names)
            return schedule[:team_names][tnum - 1]
        end
        return tnum.to_s
    end

    def self.analyze_schedule(schedule, html)
        all_games_for_each_team = Hash.new { |hsh, key| hsh[key] = [] }
        schedule[:weeks].each do |week|
            bye_t = week[:bye]
            if bye_t != nil
                all_games_for_each_team[bye_t].push({ 
                                            :bye => true, 
                                            :date => week[:date],
                                            :opponent => nil, 
                                            :home => false, 
                                            :start_time => nil, 
                                            :timeslot_id => nil, 
                                            :rink_id => nil 
                                            })
            end
            week[:games].each do |game|
                #puts "<br>#{team_name(schedule, game[:home])} v. #{team_name(schedule, game[:away])}"
                t = game[:home]
                all_games_for_each_team[t].push({
                                            :bye => false,
                                            :date => game[:datetime].to_date,
                                            :opponent => game[:away],
                                            :home => true,
                                            :start_time => game[:start_time],
                                            :timeslot_id => game[:timeslot_id],
                                            :rink_id => game[:rink_id]
                                                })
                t = game[:away]
                all_games_for_each_team[t].push({
                                            :bye => false,
                                            :date => game[:datetime].to_date,
                                            :opponent => game[:home],
                                            :home => false,
                                            :start_time => game[:start_time],
                                            :timeslot_id => game[:timeslot_id],
                                            :rink_id => game[:rink_id]
                                                })
            end
        end

        teams_seen = all_games_for_each_team.keys.map {|t| team_name(schedule, t) }.sort

        puts "#{teams_seen.size()} teams seen in this calendar: "
        puts "<pre>" if html
        puts "     #{teams_seen.join(', ')}"
        puts "</pre>" if html
        puts ""
        puts ""
        all_games_for_each_team.keys.sort {|x,y| team_name(schedule, x) <=> team_name(schedule, y)}.each do |tnum|
            team_name = team_name(schedule, tnum)
            if html
                puts "<h3>#{team_name}</h3>"
            else
                puts team_name
            end

            puts "<blockquote>" if html

            gamecount = all_games_for_each_team[tnum].select {|g| g[:bye] == false }.size()
            puts "Number of games: #{gamecount}"
            home_game_count = all_games_for_each_team[tnum].select {|g| g[:home] == true }.size()
            away_game_count = all_games_for_each_team[tnum].select {|g| g[:home] == false && g[:bye] == false}.size()
            bye_game_count = all_games_for_each_team[tnum].select {|g| g[:bye] == true }.size()
            puts "<br />" if html
            printf("Number of home games: #{home_game_count} (%d%%)\n", 100.0 * home_game_count / gamecount)
            puts "<br />" if html
            printf("Number of away games: #{away_game_count} (%d%%)\n", 100.0 * away_game_count / gamecount)
            if bye_game_count > 0
                puts "<br />" if html
                printf("Number of byes: #{bye_game_count} (%d%%)\n", 100.0 * bye_game_count / gamecount)
            end
            game_time_strs = Array.new
            opponent_name_strs = Array.new
            rink_name_strs = Array.new
            all_games_for_each_team[tnum].each do |g|
                if g[:bye] != false
                    if html
                        game_time_strs.push("<b>bye</b>")
                        opponent_name_strs.push("<b>bye</b>")
                        rink_name_strs.push("<b>bye</b>")
                    else
                        game_time_strs.push("bye")
                        opponent_name_strs.push("bye")
                        rink_name_strs.push("bye")
                    end
                    next
                end
                game_time_strs.push(schedule[:timeslots][g[:timeslot_id]][:description])
                opponent_name_strs.push(team_name(schedule, g[:opponent]))
                rink_name_strs.push(schedule[:rinks][g[:rink_id]][:short_name])
            end
            puts "<p />" if html
            print "<b>" if html
            print "Game times"
            print "</b>" if html
            print ": "
            puts game_time_strs.join(', ')
            puts "<p />" if html
            print "<b>" if html
            print "Opponents"
            print "</b>" if html
            print ": "
            puts opponent_name_strs.join(', ')
            if schedule[:rinkcount] > 1
                puts "<p />" if html
                print "<b>" if html
                print "Rinks"
                print "</b>" if html
                print ": "
                puts rink_name_strs.join(', ')
            end

            game_times = Hash.new(0)
            opponents = Hash.new(0)
            rinks = Hash.new(0)
            all_games_for_each_team[tnum].each do |g|
                next if g[:bye] != false
                opponents[team_name(schedule, g[:opponent])] += 1
                hr = schedule[:timeslots][g[:timeslot_id]][:hour]
                min = schedule[:timeslots][g[:timeslot_id]][:minute]
                time = "%02d:%02d" % [hr, min]
                game_times[time] += 1
                rinks[schedule[:rinks][g[:rink_id]][:short_name]] += 1
            end
            puts "<p />" if html
            print "Number of "
            print "<b>" if html
            print "games at each timeslot"
            print "</b>" if html
            puts ":"
            puts "<tt>" if html
            game_times.keys.sort {|x,y| x <=> y}.each do |t|
                puts "<br />" if html
                printf "        #{t} - #{game_times[t]} games (%d%%)\n", 100.0 * game_times[t] / gamecount
            end
            puts "</tt>" if html

            timeslot_attribs = all_games_for_each_team[tnum].map do |g|
                                    tid = g[:timeslot_id]
                                    schedule[:timeslots][tid]
                                end
            if timeslot_attribs.count {|ts| ts[:late_game] == true || ts[:early_game] == true || ts[:alternate_day] == true} > 0
                puts "<p />" if html
                print "Number of "
                print "<b>" if html
                print "games at undesirable timeslots"
                print "</b>" if html
                puts ":"
                puts "<tt>" if html
                late_games = timeslot_attribs.select {|ts| ts[:late_game]}
                early_games = timeslot_attribs.select {|ts| ts[:early_game]}
                alternate_day_games = timeslot_attribs.select {|ts| ts[:alternate_day]}
                if late_games.size() > 0
                    games = late_games.size()
                    puts "<br />" if html
                    printf "        #{games} - late games (%d%%)\n", 100.0 * games / gamecount
                end
                if early_games.size() > 0
                    games = early_games.size()
                    puts "<br />" if html
                    printf "        #{games} - early games (%d%%)\n", 100.0 * games / gamecount
                end
                if alternate_day_games.size() > 0
                    games = alternate_day_games.size()
                    puts "<br />" if html
                    printf "        #{games} - alternate day games (%d%%)\n", 100.0 * games / gamecount
                end
                puts "</tt>" if html
            end

            puts "<p />" if html
            print "Number of "
            print "<b>" if html
            print "times playing against opposing teams"
            print "</b>" if html
            puts ":"
            puts "<tt>" if html
            opponents.keys.sort {|x,y| opponents[y] <=> opponents[x]}.each do |o|
                puts "<br />" if html
                printf "        #{opponents[o]} games: #{o} (%d%%)\n", 100.0 * opponents[o] / gamecount
            end
            puts "</tt>" if html

            if schedule[:rinkcount] > 1
                puts "<p />" if html
                print "Number of "
                print "<b>" if html
                print "times playing at each rink"
                print "</b>" if html
                puts ":"
                puts "<tt>" if html
                rinks.keys.sort {|x,y| rinks[y] <=> rinks[x]}.each do |r|
                    puts "<br />" if html
                    printf "        #{rinks[r]} games: #{r} (%d%%)\n", 100.0 * rinks[r] / gamecount
                end
                puts "</tt>" if html
            end


            opponent_list = all_games_for_each_team[tnum].select {|g| g[:bye] == false}.map {|g| team_name(schedule, g[:opponent])}
            times_list = all_games_for_each_team[tnum].select {|g| g[:bye] == false}.map {|g| g[:timeslot_id]}
            rink_list = all_games_for_each_team[tnum].select {|g| g[:bye] == false}.map {|g| g[:rink_id]}

            opponent_streaks = opponent_list.chunk{|y| y}.map{|y, ys| [y, ys.length]}.select{|v| v[1] > 1}
            time_streaks = times_list.chunk{|y| y}.map{|y, ys| [y, ys.length]}.select{|v| v[1] > 1}.
                                select do |v| 
                                    tid = v[0]
                                    ts = schedule[:timeslots][tid]
                                    ts[:late_game] == true || ts[:early_game] == true || ts[:alternate_day] == true
                                end.
                                map {|v| [schedule[:timeslots][v[0]][:description], v[1]]}
            rink_streaks = rink_list.chunk{|y| y}.map{|y, ys| [y, ys.length]}.select{|v| v[1] > 1}.
                                map {|v| [schedule[:rinks][v[0]][:long_name], v[1]]}

            puts "<p />" if html
            print "Back-to-back "
            print "<b>" if html
            print "games against the same opponent"
            print "</b>" if html
            puts ":"
            if opponent_streaks.size() > 0
                puts "<br /><tt>" if html
                opponent_streaks.sort {|x,y| y[1] <=> x[1]}.each do |v|
                    opponent = v[0]
                    count = v[1]
                    puts "        #{count} games in a row against #{opponent}"
                    puts "<br />" if html
                end
                puts "</tt>" if html
            end

            puts "<p />" if html
            print "Back-to-back "
            print "<b>" if html
            print "games in the same timeslot"
            print "</b>" if html
            puts ":"
            if time_streaks.size() > 0
                puts "<br /><tt>" if html
                time_streaks.sort {|x,y| y[1] <=> x[1]}.each do |v|
                    timeslot = v[0]
                    count = v[1]
                    puts "        #{count} games in a row at #{timeslot}"
                    puts "<br />" if html
                end
                puts "</tt>" if html
            end

            if rink_streaks.size() > 0 && schedule[:rinkcount] > 1
                puts "<p />" if html
                print "Back-to-back "
                print "<b>" if html
                print "games at the same rink"
                print "</b>" if html
                puts ":"
                puts "<br /><tt>" if html
                rink_streaks.sort {|x,y| y[1] <=> x[1]}.each do |v|
                    rink = v[0]
                    count = v[1]
                    puts "        #{count} games in a row at rink #{rink}"
                    puts "<br />" if html
                end
                puts "</tt>" if html
            end


            if html
                puts "</blockquote>"
                puts "<p />"
            else
                puts ""
            end

        end

    end
end

if __FILE__ == $0
    require 'parse-ics'

    ics_text = %x[./test-ics.rb]
    schedule = ParseICS.ics_to_schedule(ics_text)
    AnalyzeSchedule.analyze_schedule(schedule, false)
end

