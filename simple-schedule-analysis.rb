#! /usr/bin/ruby

module SimpleScheduleAnalysis

    def self.raw_text(schedule)

        opponents_faced_count = Hash.new
        timeslots_played_count = Hash.new
        rinks_played_count = Hash.new

        opponents_faced = Hash.new
        timeslots_played = Hash.new
        rinks_played = Hash.new

        home_games = Hash.new(0)
        away_games = Hash.new(0)

        byes_count = Hash.new(0)

        teams_seen = Hash.new(0)

        schedule[:weeks].each_index do |wknum|
            puts "wknum #{wknum + 1}"
            schedule[:weeks][wknum][:games].each_index do |gamenum|
                timeslot_id = schedule[:weeks][wknum][:games][gamenum][:timeslot_id]
                rink_id = schedule[:weeks][wknum][:games][gamenum][:rink_id]
                team_pair = schedule[:weeks][wknum][:games][gamenum][:teampair]
                home = schedule[:weeks][wknum][:games][gamenum][:home]
                away = schedule[:weeks][wknum][:games][gamenum][:away]
                timeslot_desc = schedule[:timeslots][timeslot_id][:description]
                if schedule[:rinkcount] > 1
                    printf "  %-4s %8s #{team_pair.join(' v ')}\n", schedule[:rinks][rink_id][:short_name], timeslot_desc
                else
                    printf "   %8s #{team_pair.join(' v ')}\n", timeslot_desc
                end

                t1, t2 = team_pair
                if !opponents_faced.has_key?(t1)
                    opponents_faced[t1] = Array.new
                end
                if !timeslots_played.has_key?(t1)
                    timeslots_played[t1] = Array.new
                end
                if !rinks_played.has_key?(t1)
                    rinks_played[t1] = Array.new
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
                if !rinks_played_count.has_key?(t1)
                    rinks_played_count[t1] = Hash.new
                end
                if !rinks_played_count[t1].has_key?(rink_id)
                    rinks_played_count[t1][rink_id] = 0
                end
                if !opponents_faced.has_key?(t2)
                    opponents_faced[t2] = Array.new
                end
                if !rinks_played.has_key?(t2)
                    rinks_played[t2] = Array.new
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
                if !rinks_played_count.has_key?(t2)
                    rinks_played_count[t2] = Hash.new
                end
                if !rinks_played_count[t2].has_key?(rink_id)
                    rinks_played_count[t2][rink_id] = 0
                end

                if away != nil && home != nil
                    away_games[away] += 1
                    home_games[home] += 1
                end
                
                opponents_faced[t1].push(t2)
                opponents_faced[t2].push(t1)
                rinks_played[t1].push(rink_id)
                rinks_played[t2].push(rink_id)
                timeslots_played[t1].push(timeslot_id)
                timeslots_played[t2].push(timeslot_id)
                opponents_faced_count[t1][t2] += 1
                opponents_faced_count[t2][t1] += 1
                timeslots_played_count[t1][timeslot_id] += 1
                timeslots_played_count[t2][timeslot_id] += 1
                rinks_played_count[t1][rink_id] += 1
                rinks_played_count[t2][rink_id] += 1

                teams_seen[t1] = true
                teams_seen[t2] = true

            end

            bye = schedule[:weeks][wknum][:bye]
            if bye != nil
                puts "     bye:  team #{bye}"
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
            team_name = "# #{tnum}"
            if schedule.has_key?(:team_names)
                team_name = schedule[:team_names][tnum - 1]
            end
            puts "Report for team #{team_name}"

            opponents = []
            if schedule.has_key?(:team_names)
                opponents = opponents_faced[tnum].map {|o| (o == nil) ? "bye" : schedule[:team_names][o - 1] }
            else
                opponents = opponents_faced[tnum].map {|o| (o == nil) ? "bye" : o }
            end

            puts "  Opponents: #{opponents.join(', ')}"
            puts "  Timeslots: #{timeslots_played[tnum].map {|t| schedule[:timeslots][t][:description]}.join(', ')}"
            if schedule[:rinkcount] > 1
                puts "  Rinks: #{rinks_played[tnum].map {|r| schedule[:rinks][r][:short_name]}.join(', ')}"
            end
            if (byes_count.size() > 0)
                puts "  # of byes: #{byes_count[tnum]}"
            end

            puts "  # of times playing against opponent:"
            opponents_faced_count[tnum].keys.sort.each { |opponent|  puts "    team ##{opponent}:  #{opponents_faced_count[tnum][opponent]}" }
            puts "  # of times playing in each timeslot:"
            timeslots_played_count[tnum].keys.sort.each do |timeslot_id| 
                printf "    %7s: %d\n", 
                    schedule[:timeslots][timeslot_id][:description], 
                    timeslots_played_count[tnum][timeslot_id]
            end
            puts "  # of times playing at each rink:"
            rinks_played_count[tnum].keys.sort.each do |rink_id| 
                printf "    %10s: %d\n", 
                    schedule[:rinks][rink_id][:long_name], 
                    rinks_played_count[tnum][rink_id]
            end

            # the caller may not have done home/away assignments yet
            if home_games.size() > 0
                puts "  # of home games: #{home_games[tnum]}"
                puts "  # of away games: #{away_games[tnum]}"
            end

            puts ""
        end
    end
end
