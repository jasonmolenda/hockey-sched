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
                                            :date => schedule[:weeks][wknum][:date], 
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
        all_games_for_each_team.keys.each do |tnum|
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
                    game_time_strs.push("bye")
                    opponent_name_strs.push("bye")
                    rink_name_strs.push("bye")
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

            puts "</blockquote>" if html
        end

    end
end

if __FILE__ == $0
    require 'simple-schedule-analysis'
    require 'parse-ics'

    ics_text = %x[./test-ics.rb]
    schedule = ParseICS.ics_to_schedule(ics_text)
    AnalyzeSchedule.analyze_schedule(schedule, true)
end

