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
                                            :skipped => false,
                                            :date => week[:date],
                                            :opponent => nil, 
                                            :home => false, 
                                            :start_time => nil, 
                                            :timeslot_id => nil, 
                                            :rink_id => nil,
                                            })

            end
            # A skipped game happens when a league plays on two nights.
            # The primary night of the league has games scheduled, but the
            # secondary night has a holiday so there are no games.  We
            # record the teams that should have played on the overflow
            # day as a skipped game.
            if week.has_key?(:skipped) && week[:skipped].size() == 2
                week[:skipped].each do |t|
                    all_games_for_each_team[t].push({ 
                                                :bye => false, 
                                                :skipped => true,
                                                :date => week[:date],
                                                :opponent => nil, 
                                                :home => false, 
                                                :start_time => nil, 
                                                :timeslot_id => nil, 
                                                :rink_id => nil,
                                                })
                end
            end
            week[:games].each do |game|
                #puts "<br>#{team_name(schedule, game[:home])} v. #{team_name(schedule, game[:away])}"
                t = game[:home]
                all_games_for_each_team[t].push({
                                            :bye => false,
                                            :skipped => false,
                                            :date => game[:datetime].to_date,
                                            :opponent => game[:away],
                                            :home => true,
                                            :start_time => game[:start_time],
                                            :timeslot_id => game[:timeslot_id],
                                            :rink_id => game[:rink_id],
                                                })
                t = game[:away]
                all_games_for_each_team[t].push({
                                            :bye => false,
                                            :skipped => false,
                                            :date => game[:datetime].to_date,
                                            :opponent => game[:home],
                                            :home => false,
                                            :start_time => game[:start_time],
                                            :timeslot_id => game[:timeslot_id],
                                            :rink_id => game[:rink_id],
                                                })
            end
        end

        teams_seen = all_games_for_each_team.keys.map {|t| team_name(schedule, t) }.sort

        puts "#{teams_seen.size()} teams seen in this calendar: "
        puts "<pre>" if html
        puts "     #{teams_seen.join(', ')}"
        puts "</pre>" if html
        puts ""

        team_number_of_games = Hash.new(0)
        team_late_games = Hash.new(0)
        team_early_games = Hash.new(0)
        team_bye_games = Hash.new(0)
        team_overflow_games = Hash.new(0)
        team_skipped_games = Hash.new(0)
        team_num_games_at_each_rink = Hash.new {|hsh, key| hsh[key] = Hash.new(0) }
        all_games_for_each_team.keys.each do |tnum|
            team_name = team_name(schedule, tnum)
            all_games_for_each_team[tnum].each do |g| 
                tid = g[:timeslot_id]
                if tid != nil
                    if schedule[:timeslots][tid][:late_game]
                        team_late_games[team_name] += 1
                    end
                    if schedule[:timeslots][tid][:late_game]
                        team_early_games[team_name] += 1
                    end
                    if schedule[:timeslots][tid][:overflow_day]
                        team_overflow_games[team_name] += 1
                    end
                    if schedule[:timeslots][tid][:overflow_day]
                        team_overflow_games[team_name] += 1
                    end
                    if g[:bye]
                        team_bye_games[team_name] += 1
                    end
                    if g[:skipped]
                        team_skipped_games[team_name] += 1
                    end
                    if g[:bye] == false && g[:skipped] == false
                        team_number_of_games[team_name] += 1
                    end
                    rink_name = schedule[:rinks][g[:rink_id]][:short_name]
                    team_num_games_at_each_rink[team_name][rink_name] += 1
                end
            end
        end

# this one would only be interesting if the schedule was having serious problems...
#
#        print "<h4>" if html
#        print "Total # of games each team has in this schedule:"
#        print "</h4>" if html
#        puts ""
#        puts "<pre>" if html
#        team_number_of_games.keys.sort {|x,y| team_number_of_games[y] <=> team_number_of_games[x]}.each do |tname|
#            puts "     #{team_number_of_games[tname]} games: #{tname}"
#        end
#        puts "</pre>" if html
#        puts ""

        if team_late_games.size() > 0
            print "<h4>" if html
            print "# of late games each team has in this schedule:"
            print "</h4>" if html
            puts ""
            puts "<pre>" if html
            team_late_games.keys.sort {|x,y| team_late_games[y] <=> team_late_games[x]}.each do |tname|
                puts "     #{team_late_games[tname]} games: #{tname}"
            end
            puts "</pre>" if html
            puts ""
        end

#        if team_early_games.size() > 0
#            print "<h4>" if html
#            print "# of early games each team has in this schedule:"
#            print "</h4>" if html
#            puts ""
#            puts "<pre>" if html
#            team_early_games.keys.sort {|x,y| team_early_games[y] <=> team_early_games[x]}.each do |tname|
#                puts "     #{team_early_games[tname]} games: #{tname}"
#            end
#            puts "</pre>" if html
#            puts ""
#        end

        if team_bye_games.size() > 0
            print "<h4>" if html
            print "# of bye games each team has in this schedule:"
            print "</h4>" if html
            puts ""
            puts "<pre>" if html
            team_bye_games.keys.sort {|x,y| team_bye_games[y] <=> team_bye_games[x]}.each do |tname|
                puts "     #{team_bye_games[tname]} games: #{tname}"
            end
            puts "</pre>" if html
            puts ""
        end

        if team_skipped_games.size() > 0
            print "<h4>" if html
            print "# of skipped games each team has in this schedule:"
            print "</h4>" if html
            puts ""
            puts "<pre>" if html
            team_skipped_games.keys.sort {|x,y| team_skipped_games[y] <=> team_skipped_games[x]}.each do |tname|
                puts "     #{team_skipped_games[tname]} games: #{tname}"
            end
            puts "</pre>" if html
            puts ""
        end

        # only print the rink summaries if there is more than one rink
        if team_num_games_at_each_rink.values.map {|v| v.keys}.flatten.sort.uniq.size() > 1
            rinks_seen = team_num_games_at_each_rink.values.map {|v| v.keys}.flatten.sort.uniq.sort()
            rinks_seen.each do |rinkname|
                team_num_games_at_each_rink.keys.each do |tname|
                    if !team_num_games_at_each_rink[tname].has_key?(rinkname)
                        team_num_games_at_each_rink[tname][rinkname] = 0
                    end
                end
                print "<h4>" if html
                print "# of games each team has at #{rinkname} in this schedule:"
                print "</h4>" if html
                puts ""
                puts "<pre>" if html
                team_num_games_at_each_rink.keys.sort {|x,y| team_num_games_at_each_rink[y][rinkname] <=> team_num_games_at_each_rink[x][rinkname]}.each do |tname|
                    puts "     #{team_num_games_at_each_rink[tname][rinkname]} games: #{tname}"
                end
                puts "</pre>" if html
                puts ""
            end
        end

        all_games_for_each_team.keys.sort {|x,y| team_name(schedule, x) <=> team_name(schedule, y)}.each do |tnum|
            team_name = team_name(schedule, tnum)
            if html
                puts "<h3>#{team_name}</h3>"
            else
                puts team_name
            end

            puts "<blockquote>" if html

            gamecount = all_games_for_each_team[tnum].select {|g| g[:bye] == false && g[:skipped] == false}.size()
            puts "Number of games: #{gamecount}"
            home_game_count = all_games_for_each_team[tnum].select {|g| g[:home] == true }.size()
            away_game_count = all_games_for_each_team[tnum].select {|g| g[:home] == false && g[:bye] == false && g[:skipped] == false}.size()
            bye_game_count = all_games_for_each_team[tnum].select {|g| g[:bye] == true }.size()
            skipped_game_count = all_games_for_each_team[tnum].select {|g| g[:skipped] == true }.size()
            puts "<br />" if html
            printf("Number of home games: #{home_game_count} (%d%%)\n", 100.0 * home_game_count / gamecount)
            puts "<br />" if html
            printf("Number of away games: #{away_game_count} (%d%%)\n", 100.0 * away_game_count / gamecount)
            if bye_game_count > 0
                puts "<br />" if html
                printf("Number of byes: #{bye_game_count} (%d%%)\n", 100.0 * bye_game_count / gamecount)
            end
            if skipped_game_count > 0
                puts "<br />" if html
                printf("Number of skipped games: #{skipped_game_count} (%d%%)\n", 100.0 * skipped_game_count / gamecount)
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
                        game_time_strs.push("BYE")
                        opponent_name_strs.push("BYE")
                        rink_name_strs.push("BYE")
                    end
                    next
                end
                if g[:skipped] == true
                    if html
                        game_time_strs.push("<b>skipped</b>")
                        opponent_name_strs.push("<b>skipped</b>")
                        rink_name_strs.push("<b>skipped</b>")
                    else
                        game_time_strs.push("SKIPPED")
                        opponent_name_strs.push("SKIPPED")
                        rink_name_strs.push("SKIPPED")
                    end
                    next
                end
                game_time_desc = schedule[:timeslots][g[:timeslot_id]][:description]
                if schedule[:timeslots][g[:timeslot_id]][:overflow_day]
                    if html
                        game_time_desc = "<b>ALT</b> #{game_time_desc}"
                    else
                        game_time_desc = "ALT #{game_time_desc}"
                    end
                end
                game_time_strs.push(game_time_desc)
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
                next if g[:skipped] == true
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
            if timeslot_attribs.count {|ts| ts[:late_game] == true || ts[:early_game] == true || ts[:overflow_day] == true} > 0
                puts "<p />" if html
                print "Number of "
                print "<b>" if html
                print "games at undesirable timeslots"
                print "</b>" if html
                puts ":"
                puts "<tt>" if html
                late_games = timeslot_attribs.select {|ts| ts[:late_game]}
                early_games = timeslot_attribs.select {|ts| ts[:early_game]}
                overflow_day_games = timeslot_attribs.select {|ts| ts[:overflow_day]}
                if early_games.size() > 0
                    games = early_games.size()
                    puts "<br />" if html
                    printf "        #{games} - early games (%d%%)\n", 100.0 * games / gamecount
                end
                if late_games.size() > 0
                    games = late_games.size()
                    puts "<br />" if html
                    printf "        #{games} - late games (%d%%)\n", 100.0 * games / gamecount
                end
                if overflow_day_games.size() > 0
                    games = overflow_day_games.size()
                    puts "<br />" if html
                    printf "        #{games} - overflow day games (%d%%)\n", 100.0 * games / gamecount
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


            opponent_list = all_games_for_each_team[tnum].select {|g| g[:bye] == false && g[:skipped] == false}.map {|g| team_name(schedule, g[:opponent])}
            times_list = all_games_for_each_team[tnum].select {|g| g[:bye] == false && g[:skipped] == false}.map {|g| g[:timeslot_id]}
            rink_list = all_games_for_each_team[tnum].select {|g| g[:bye] == false && g[:skipped] == false}.map {|g| g[:rink_id]}

            opponent_streaks = opponent_list.chunk{|y| y}.map{|y, ys| [y, ys.length]}.select{|v| v[1] > 1}
            time_streaks = times_list.chunk{|y| y}.map{|y, ys| [y, ys.length]}.select{|v| v[1] > 1}.
                                select do |v| 
                                    tid = v[0]
                                    ts = schedule[:timeslots][tid]
                                    ts[:late_game] == true || ts[:early_game] == true || ts[:overflow_day] == true
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

