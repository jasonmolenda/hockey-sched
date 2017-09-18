#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'team-matchups-randomization'
require 'timeslot-assignment.rb'
require 'home-away-assignment.rb'

def dump_scheduled_games(schedule, all_timeslot_attributes)

    opponents_faced_count = Hash.new
    timeslots_played_count = Hash.new

    opponents_faced = Hash.new
    timeslots_played = Hash.new

    byes_count = Hash.new

    teams_seen = Hash.new

    home_games = Hash.new
    away_games = Hash.new

    schedule.each_index do |wknum|
        puts "wknum #{wknum + 1}"
        schedule[wknum][:matchups].each_index do |i|
            timeslot_id = schedule[wknum][:timeslot_ids][i]
            team_pair = schedule[wknum][:matchups][i]
            timeslot_desc = all_timeslot_attributes[timeslot_id][:description]
            printf "   %8s #{team_pair[:home]} v. #{team_pair[:away]}\n", timeslot_desc

            t1 = team_pair[:home]
            t2 = team_pair[:away]
            if !opponents_faced.has_key?(t1)
                opponents_faced[t1] = Array.new
            end
            if !timeslots_played.has_key?(t1)
                timeslots_played[t1] = Array.new
            end
            if !opponents_faced_count.has_key?(t1)
                opponents_faced_count[t1] = Hash.new
            end
            if !opponents_faced_count[t1].has_key?(t2)
                opponents_faced_count[t1][t2] = 0
            end
            if !timeslots_played_count.has_key?(t1)
                timeslots_played_count[t1] = Hash.new
            end
            if !timeslots_played_count[t1].has_key?(timeslot_id)
                timeslots_played_count[t1][timeslot_id] = 0
            end
            if !opponents_faced.has_key?(t2)
                opponents_faced[t2] = Array.new
            end
            if !timeslots_played.has_key?(t2)
                timeslots_played[t2] = Array.new
            end

            if !opponents_faced_count.has_key?(t2)
                opponents_faced_count[t2] = Hash.new
            end
            if !opponents_faced_count[t2].has_key?(t1)
                opponents_faced_count[t2][t1] = 0
            end
            if !timeslots_played_count.has_key?(t2)
                timeslots_played_count[t2] = Hash.new
            end
            if !timeslots_played_count[t2].has_key?(timeslot_id)
                timeslots_played_count[t2][timeslot_id] = 0
            end

            opponents_faced[t1].push(t2)
            opponents_faced[t2].push(t1)
            timeslots_played[t1].push(timeslot_id)
            timeslots_played[t2].push(timeslot_id)
            opponents_faced_count[t1][t2] += 1
            opponents_faced_count[t2][t1] += 1
            timeslots_played_count[t1][timeslot_id] += 1
            timeslots_played_count[t2][timeslot_id] += 1

            if !home_games.has_key?(team_pair[:home])
                home_games[team_pair[:home]] = 0
            end
            if !away_games.has_key?(team_pair[:away])
                away_games[team_pair[:away]] = 0
            end
            home_games[team_pair[:home]] += 1
            away_games[team_pair[:away]] += 1

            teams_seen[t1] = true
            teams_seen[t2] = true

        end

        bye = schedule[wknum][:bye]
        if bye != nil
            puts "     bye:  team #{bye}"
            if !byes_count.has_key?(bye)
                byes_count[bye] = 0
            end
            byes_count[bye] += 1
            if !opponents_faced.has_key?(bye)
                opponents_faced[bye] = Array.new
            end
            opponents_faced[bye].push(nil)
            teams_seen[bye] = true
        end
    end

    puts ""
    puts ""
    teams_seen.keys.sort.each do |tnum|
        puts "Report for team # #{tnum}"

        puts "  Opponents: #{opponents_faced[tnum].map {|o| (o == nil) ? "bye" : o }.join(', ')}"
        puts "  Timeslots: #{timeslots_played[tnum].map {|t| all_timeslot_attributes[t][:description]}.join(', ')}"
        puts "  Number of home games: #{home_games[tnum]}"
        puts "  Number of away games: #{away_games[tnum]}"
        if (byes_count.size() > 0)
            puts "  # of byes: #{byes_count[tnum]}"
        end

        puts "  # of times playing against opponent:"
        opponents_faced_count[tnum].keys.sort.each { |opponent|  puts "    team ##{opponent}:  #{opponents_faced_count[tnum][opponent]}" }
        puts "  # of times playing in each timeslot:"
        timeslots_played_count[tnum].keys.sort.each do |timeslot_id| 
            printf "    %7s: %d\n", 
                all_timeslot_attributes[timeslot_id][:description], 
                timeslots_played_count[tnum][timeslot_id]
        end
        puts ""
    end
end

def schedule_one_season_four_team_league(all_timeslot_attributes)
    number_of_teams = 4
    number_of_timeslots = 2
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    season_schedule = Array.new
    teamcount = number_of_teams

    (1..number_of_weeks).each do |wknum|
        season_schedule[wknum - 1] = Hash.new
        season_schedule[wknum - 1][:matchups] = results[wknum - 1][:matchups]
        season_schedule[wknum - 1][:timeslots] = [70, 80]
        season_schedule[wknum - 1][:bye] = nil
    end
    debug = false
    results = TimeslotAssignmentScoreBased.order_game_times(season_schedule, teamcount, all_timeslot_attributes, debug)
    results = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)
    return results
end


def schedule_one_season_six_team_league(all_timeslot_attributes)
    number_of_teams = 6
    number_of_timeslots = 3
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)
#    results, message = TeamMatchupsRandomization.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    season_schedule = Array.new
    teamcount = number_of_teams

    (1..number_of_weeks).each do |wknum|
        season_schedule[wknum - 1] = Hash.new
        season_schedule[wknum - 1][:matchups] = results[wknum - 1][:matchups]
        season_schedule[wknum - 1][:timeslots] = [20, 30, 40]
        season_schedule[wknum - 1][:bye] = results[wknum - 1][:bye]
    end
    debug = false
    results = TimeslotAssignmentScoreBased.order_game_times(season_schedule, teamcount, all_timeslot_attributes, debug)
    results = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)
    return results
end


def schedule_one_season_seven_team_league(all_timeslot_attributes)
    number_of_teams = 7
    number_of_timeslots = 3
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)
#    results, message = TeamMatchupsRandomization.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    season_schedule = Array.new
    teamcount = number_of_teams

    (1..number_of_weeks).each do |wknum|
        season_schedule[wknum - 1] = Hash.new
        season_schedule[wknum - 1][:matchups] = results[wknum - 1][:matchups]
        season_schedule[wknum - 1][:timeslots] = [20, 30, 40]
        season_schedule[wknum - 1][:bye] = results[wknum - 1][:bye]
    end
    debug = false
    results = TimeslotAssignmentScoreBased.order_game_times(season_schedule, teamcount, all_timeslot_attributes, debug)
    results = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)
    return results
end



def schedule_one_season_eight_team_league(all_timeslot_attributes)
    number_of_teams = 8
    number_of_timeslots = 4
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    season_schedule = Array.new
    teamcount = number_of_teams

    (1..number_of_weeks).each do |wknum|
        season_schedule[wknum - 1] = Hash.new
        season_schedule[wknum - 1][:matchups] = results[wknum - 1][:matchups]
        season_schedule[wknum - 1][:timeslots] = [10, 20, 30, 40]
        season_schedule[wknum - 1][:bye] = nil
    end
    debug = false
    results = TimeslotAssignmentScoreBased.order_game_times(season_schedule, teamcount, all_timeslot_attributes, debug)
    results = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)
    return results
end

def schedule_one_season_twelve_team_league(all_timeslot_attributes)
    number_of_teams =12 
    number_of_timeslots = 6
    number_of_weeks = (number_of_teams - 1) * 3
    results, message = TeamMatchupsCircular.get_team_matchups(number_of_teams, number_of_timeslots, number_of_weeks)

    season_schedule = Array.new
    teamcount = number_of_teams

    (1..number_of_weeks).each do |wknum|
        season_schedule[wknum - 1] = Hash.new
        season_schedule[wknum - 1][:matchups] = results[wknum - 1][:matchups]
#        season_schedule[wknum - 1][:timeslots] = [20, 30, 40, 20, 30, 40]
        season_schedule[wknum - 1][:timeslots] = [120, 130, 140, 220, 230, 240]
        season_schedule[wknum - 1][:bye] = nil
    end
    debug = false
    results = TimeslotAssignmentScoreBased.order_game_times(season_schedule, teamcount, all_timeslot_attributes, debug)
    results = HomeAwayAssignment.assign_home_away(results, number_of_teams, false)
    return results
end



if __FILE__ == $0

    all_timeslot_attributes = {
        # weeknight leagues
        10 => { :late_game => false, :early_game => true, :alternate_day => false, :timeslot_id => 10, :description => "7:00pm"},
        20 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 20, :description => "8:15pm"},
        30 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 30, :description => "9:30pm"},
        40 => { :late_game => true, :early_game => false, :alternate_day => false, :timeslot_id => 40, :description => "10:45pm"},

        # the thursday league where games were sched fri 7 & 10:45 alternating
        50 => { :late_game => false, :early_game => true, :alternate_day => true, :timeslot_id => 50, :description => "Fri 7:00pm"},
        60 => { :late_game => true, :early_game => false, :alternate_day => true, :timeslot_id => 60, :description => "Fri 10:45pm"},

        # weekend saturday
        70 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 70, :description => "9:00pm"},
        80 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 80, :description => "10:15pm"},


        # Thursday Redwood City / San Mateo split
        120 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 120, :description => "RWC 8:00pm", :rink => "RWC"},
        130 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 130, :description => "RWC 9:15pm", :rink => "RWC"},
        140 => { :late_game => true, :early_game => false, :alternate_day => false, :timeslot_id => 140, :description => "RWC 10:30pm", :rink => "RWC"},
        220 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 220, :description => "SM 8:00pm", :rink => "SM"},
        230 => { :late_game => false, :early_game => false, :alternate_day => false, :timeslot_id => 230, :description => "SM 9:15pm", :rink => "SM"},
        240 => { :late_game => true, :early_game => false, :alternate_day => false, :timeslot_id => 240, :description => "SM 10:30pm", :rink => "SM"},
    }

    number_of_teams_to_schedule = 12
    if ARGV.size() > 0
        number_of_teams_to_schedule = ARGV[0].to_i
    end

    if number_of_teams_to_schedule == 4
        results = schedule_one_season_four_team_league(all_timeslot_attributes)
    elsif number_of_teams_to_schedule == 6
        results = schedule_one_season_six_team_league(all_timeslot_attributes)
    elsif number_of_teams_to_schedule == 7
        results = schedule_one_season_seven_team_league(all_timeslot_attributes)
    elsif number_of_teams_to_schedule == 8
        results = schedule_one_season_eight_team_league(all_timeslot_attributes)
    elsif number_of_teams_to_schedule == 12
        results = schedule_one_season_twelve_team_league(all_timeslot_attributes)
    else
        puts "Unrecognized number of teams to schedule, doing nothing."
        exit
    end

dump_scheduled_games(results, all_timeslot_attributes)

end
