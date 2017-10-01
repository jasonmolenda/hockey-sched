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
        puts "     #{teams_seen.join(', ')}"
        puts ""
        puts ""
        all_games_for_each_team.keys.each do |tnum|
            team_name = team_name(schedule, tnum)
            puts "<b>" if html
            puts team_name
            puts "</b>" if html
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

