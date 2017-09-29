#! /usr/bin/ruby

$LOAD_PATH << File.dirname(__FILE__)
require 'team-matchups-circular'
require 'team-matchups-randomization'

# Schedules are created in 4 steps, in this order:
#
# 1. Team versus Team pairings
# 2. Timeslot assignments
# 3. Home/away assignment
# 4. Rink assignments (if multiple rinks)


module TimeslotAssignmentScoreBased

    # This method takes a schedule argument with the expectation that these fields are
    # already filled in:
    #
    # schedule[:teamcount]
    # schedule[:gamecount]
    # schedule[:weekcount]
    #
    # schedule[:timeslots]
    # schedule[:rinks]
    #
    # schedule[:weeks]
    # schedule[:weeks][weeknum][:bye]
    # schedule[:weeks][weeknum][:team_matchups]
    # schedule[:weeks][weeknum][:games]
    # schedule[:weeks][weeknum][:games][gamenum][:timeslot_id]
    # schedule[:weeks][weeknum][:games][gamenum][:rink_id]
    #
    #
    # It will fill in the teampair entries for each game:
    #
    # schedule[:weeks][weeknum][:games][gamenum][:teampair]

    def self.order_game_times (schedule, debug)

        teamcount = schedule[:teamcount]
        weekcount = schedule[:weekcount]

        if !schedule.has_key?(:rinkcount)
            puts "ERROR: schedule is missing a :rinkcount key"
            exit true
        end

        if !schedule.has_key?(:weeks)
            puts "ERROR: schedule is missing a :weeks key"
            exit true
        end
        if schedule[:weeks].size() != schedule[:weekcount]
            puts "ERROR: schedule's :weeks array should have #{schedule[:weekcount]} entries with the timeslot_ids and rink_ids filled in"
            exit true
        end
        schedule[:weeks].each_index do |wknum|
            if !schedule[:weeks][wknum].has_key?(:games)
                puts "schedule[:weeks][#{wknum}] does not have the :games key"
                exit true
            end
            if schedule[:weeks][wknum][:games].size() != schedule[:gamecount]
                puts "schedule[:weeks][#{wknum}][:games].size() should be #{schedule[:gamecount]} but it is #{schedule[:weeks][wknum][:games].size()} exiting."
                exit true
            end
            if !schedule[:weeks][wknum].has_key?(:team_matchups)
                puts "schedule[:weeks][#{wknum}] does not have a :team_matchups key"
                exit true
            end
            if schedule[:weeks][wknum][:team_matchups].size() != schedule[:gamecount]
                puts "schedule[:weeks][#{wknum}][:team_matchups].size() should be #{schedule[:gamecount]} but it is #{schedule[:weeks][wknum][:team_matchups].size()}"
                exit true
            end
            schedule[:weeks][wknum][:games].each_index do |gamenum|
                if !schedule[:weeks][wknum][:games][gamenum].has_key?(:timeslot_id)
                    puts "schedule[:weeks][#{wknum}][:games][#{gamenum}] is missing a :timeslot_id key"
                    exit true
                end
                tid = schedule[:weeks][wknum][:games][gamenum][:timeslot_id]
                rid = schedule[:weeks][wknum][:games][gamenum][:rink_id]
                if !schedule[:timeslots].has_key?(tid)
                    puts "schedule[:timeslots] does not have a timeslot_id entry for '#{tid}' from schedule[:weeks][#{wknum}][:games][#{gamenum}][:timeslot_id]"
                    exit true
                end
                if !schedule[:rinks].has_key?(rid)
                    puts "schedule[:rinks] does not have a rink_id entry for '#{rid}' from schedule[:weeks][#{wknum}][:games][#{gamenum}][:rink_id]"
                    exit true
                end
                if tid == nil
                    puts "Got a null timeslot id for schedule[:weeks][#{wknum}][:games][#{gamenum}][:timeslot_id]"
                    exit true
                end
                if rid == nil
                    puts "Got a null timeslot id for schedule[:weeks][#{wknum}][:games][#{gamenum}][:rink_id]"
                    exit true
                end
            end
        end

        list_of_all_timeslot_ids = schedule[:timeslots].keys.sort.uniq

        # total_number_of_weeks_for_each_timeslot is a hash with the key is timeslot_id's
        # the value is the # of weeks that have that game.
        total_number_of_games_in_each_timeslot = Hash.new
        schedule[:weeks].each do |w| 
            w[:games].each do |g|
                tid = g[:timeslot_id]
                if !total_number_of_games_in_each_timeslot.has_key?(tid)
                    total_number_of_games_in_each_timeslot[tid] = 0
                end
                total_number_of_games_in_each_timeslot[tid] += 1
            end
        end
    
        # Calculate the max numbers of games each team should have to play in each timeslot
        #
        max_num_games_for_each_team_in_each_timeslot = Hash.new
        total_number_of_games_in_each_timeslot.keys.each do |timeslot_id|
            max_num_games_for_each_team_in_each_timeslot[timeslot_id] = (total_number_of_games_in_each_timeslot[timeslot_id].to_f / teamcount).ceil
        end

        scheduled_games_with_timeslots = Array.new

        # key == team number
        # value == Hash
        #          key = timeslot_id
        #          value = # of games this team has scheduled there already
        #
        number_of_games_scheduled_for_each_team_in_each_timeslot = Hash.new
        (1..teamcount).each do |t| 
            number_of_games_scheduled_for_each_team_in_each_timeslot[t] = Hash.new
            list_of_all_timeslot_ids.each do |timeslot_id|
                number_of_games_scheduled_for_each_team_in_each_timeslot[t][timeslot_id] = 0
            end
        end

        already_scheduled_games = Array.new

        (1..weekcount).each do |wknum|
            puts "" if debug
            puts "Week #{wknum}" if debug
            puts "" if debug
            this_week_timeslots = schedule[:weeks][wknum - 1][:games].map {|g| g[:timeslot_id]}
            this_week_team_pairs = schedule[:weeks][wknum - 1][:team_matchups]
            bye = schedule[:weeks][wknum - 1][:bye]

            debug = false
            verbose = false

            this_week = TimeslotAssignmentScoreBased.compute_timeslot_scores(this_week_team_pairs, this_week_timeslots, schedule[:timeslots], already_scheduled_games, number_of_games_scheduled_for_each_team_in_each_timeslot, max_num_games_for_each_team_in_each_timeslot, debug, verbose)

            t = Hash.new
            this_week.each_index do |timeslot_idx|
                team_pair = this_week[timeslot_idx][:teams]
                schedule[:weeks][wknum - 1][:games][timeslot_idx][:teampair] = team_pair
                score = this_week[timeslot_idx][:score]
                timeslot_id = this_week[timeslot_idx][:timeslot_id]
                t1, t2 = team_pair[0], team_pair[1]
                t[t1] = timeslot_id
                t[t2] = timeslot_id
                number_of_games_scheduled_for_each_team_in_each_timeslot[t1][timeslot_id] += 1
                number_of_games_scheduled_for_each_team_in_each_timeslot[t2][timeslot_id] += 1
            end
            already_scheduled_games.push(t)
        end

        return scheduled_games_with_timeslots
    end 




    # team_matchups is a 0-based Array.  The number of elements is the # of timeslots we are scheduling this week.
    # Each element in the array is an array pair of team numbers for the games in a given week.
    #
    # timeslot_ids is a 0-based Array.  The number of elements is the # of timeslots we are scheduling this week.
    # Each element in the array is the timeslot_id for this timeslot.
    #
    # all_timeslot_attributes is a Hash.  The keys are timeslot_id's.  The values are a Hash with k/v pairs:
    #    :late_game     true/false   # priority is to limit extraneous late games, back-to-backs not allowed
    #    :early_game    true/false   # try to avoid extraneous / back-to-back games
    #    :alternate_day true/false   # if this league holds a timeslot on an alternate day, avoid extraneous / back-to-backs
    #    :timeslot_id   int          # each timeslot gets a unique integer value assigned.
    #                                # if a league plays on 7:00 + 8:15 one week, 9:30 + 10:45 next week,
    #                                # you would use 4 different ID #'s. One week will have timeslot_id's 1 & 2
    #                                # the next week will have timeslot_id's 3 & 4
    #                                # if a league has a 10:45pm Thursday and 10:45pm Friday gameslots, they will
    #                                # have different timeslot_id's.
    #    :description   str          # description of timeslot (e.g. "10:45pm")
    # all_timeslot_attributes has the details for ALL timeslot_id's, not just the ones scheduled this week.
    #
    #
    # already_scheduled_games is a 0-based Array, one entry per week we've already scheduled.  The previous week's
    # schedule will be the last entry in the Array.
    # Each week's entry in already_scheduled_games is a Hash.  The key is a team number that was scheduled last
    # week.  The value is the timeslot_id of the game they played last week.
    #
    # number_of_games_scheduled_for_each_team_in_each_timeslot is a Hash, one entry per team.  Key is the
    # team number (1..n).  The value is a Hash.  The key of that is a timeslot_id.  The value is the # of games.
    # e.g. 
    #    number_of_games_scheduled_for_each_team_in_each_timeslot[teamnum][timeslot_id] = number_of_games_in_timeslot
    #   
    # max_num_games_for_each_team_in_each_timeslot is a Hash.  The key is the timeslot_id.  The value is the
    # maximum number of games a team SHOULD have in that timeslot.
    # 
    # debug is a boolean.
    #
    # Returns an Array, 0-based, with the # of timeslots this week as the size.
    # Each element in the Array is a Hash with two kv pairs:
    #   :timeslot_id    int     # the timeslot_id for this game
    #   :teams          Array   # the two teams that are playing in this timeslot
    #   :score          int     # the score that this pairing had (used for diagnostics? feedback-based reshuffle?)
    #
    def self.compute_timeslot_scores(team_matchups, timeslot_ids, all_timeslot_attributes, already_scheduled_games, number_of_games_scheduled_for_each_team_in_each_timeslot, max_num_games_for_each_team_in_each_timeslot, debug, verbose)


        # sanity check: No team appears more than once in this week's team_matchups
        teams_seen = Hash.new
        team_matchups.each do |pair|
            pair.each do |t|
                if !teams_seen.has_key?(t)
                    teams_seen[t] = 0
                end
                teams_seen[t] += 1
            end
        end
        teams_seen.keys.select { |t| teams_seen[t] > 1 }.each do
            puts "ERROR: Team #{t} occurs more than once in a single week!"
            puts "Team matchup pairs:"
            print team_matchups
            puts ""
        end

        if team_matchups.size() != timeslot_ids.size()
            puts "ERROR: team_matchups has #{team_matchups.size()} elems which is not equal to the timeslot_ids elem count  #{timeslot_ids.size()}"
        end

        # timeslot_scores is a 0-bsaed Array.  The number of elements in the Array are the # of 
        # timeslots we have this week.  Note that the index is NOT a timeslot_id.
        #
        # Each timeslot_scores element is an Array.  Each element in the Array is an Array pair --
        # [team_pair_idx, score].
        #
        # e.g.
        #
        #     timeslot_scores[timeslot_idx].push([team_pair_idx, score])
        #
        timeslot_scores = Array.new
        0.upto(timeslot_ids.size() - 1).each do |timeslot_idx| 
            timeslot_scores[timeslot_idx] = Array.new
        end

        timeslot_count = timeslot_ids.size()

        # complete list of all teams that we will see in team_matchups
        teams = team_matchups.flatten().sort.uniq()

        #  Iterate over all timeslots, calculate score for each teampair in that timeslot
        #
        0.upto(timeslot_count - 1).each do |timeslot_idx|
            timeslot_id = timeslot_ids[timeslot_idx]
            timeslot_is_late_game = all_timeslot_attributes[timeslot_id][:late_game]
            timeslot_is_early_game = all_timeslot_attributes[timeslot_id][:early_game]
            timeslot_is_alternate_day = all_timeslot_attributes[timeslot_id][:alternate_day]
            team_matchups.each_index do |team_pair_idx|
                t1, t2 = team_matchups[team_pair_idx][0], team_matchups[team_pair_idx][1]

                score = 0

                t1_last_week_attribs = nil
                t2_last_week_attribs = nil
                t1_two_weeks_ago_attribs = nil
                t2_two_weeks_ago_attribs = nil
                if already_scheduled_games.size() > 0
                    last_week_games = already_scheduled_games[-1]
                    if last_week_games.has_key?(t1)
                        t1_last_week_attribs = all_timeslot_attributes[last_week_games[t1]]
                    end
                    if last_week_games.has_key?(t2)
                        t2_last_week_attribs = all_timeslot_attributes[last_week_games[t2]]
                    end
                end
                if already_scheduled_games.size() > 1
                    two_weeks_ago_games = already_scheduled_games[-2]
                    if two_weeks_ago_games.has_key?(t1)
                        t1_two_weeks_ago_attribs = all_timeslot_attributes[two_weeks_ago_games[t1]]
                    end
                    if two_weeks_ago_games.has_key?(t2)
                        t2_two_weeks_ago_attribs = all_timeslot_attributes[two_weeks_ago_games[t2]]
                    end
                end

                # The number of games each team has played in this timeslot previously is the base score
                score += (number_of_games_scheduled_for_each_team_in_each_timeslot[t1][timeslot_id] * 5) + 
                         (number_of_games_scheduled_for_each_team_in_each_timeslot[t2][timeslot_id] * 5)
    
                # Avoid teams having more than their fair share of any given timeslot
                if number_of_games_scheduled_for_each_team_in_each_timeslot[t1][timeslot_id] >= max_num_games_for_each_team_in_each_timeslot[timeslot_id] \
                    || number_of_games_scheduled_for_each_team_in_each_timeslot[t2][timeslot_id] >= max_num_games_for_each_team_in_each_timeslot[timeslot_id]
                    score = score + 70
                    # too many late games???   no no no.
                    if timeslot_is_late_game == true
                        score += 50
                    end
                end

                # Back to back 10:45's are very bad.
                if timeslot_is_late_game == true &&
                    ((t1_last_week_attribs != nil && t1_last_week_attribs[:late_game] == true) ||
                     (t2_last_week_attribs != nil && t2_last_week_attribs[:late_game] == true))
                    score = score + 70
                end

                #  Multiple 10:45's in three weeks are bad.
                if timeslot_is_late_game == true &&
                    ((t1_two_weeks_ago_attribs != nil && t1_two_weeks_ago_attribs[:late_game] == true) ||
                     (t2_two_weeks_ago_attribs != nil && t2_two_weeks_ago_attribs[:late_game] == true))
                    score = score + 50
                end

                # The early game (7:00pm) in a 4-timeslot league is a little inconvenient to have too many of
                if timeslot_is_early_game == true
                    score = score + 10
                end
    
                if already_scheduled_games.size() > 0
                    last_week_games = already_scheduled_games.last()
                    last_week_t1_timeslot_id = nil
                    last_week_t2_timeslot_id = nil
                    if last_week_games.has_key?(t1)
                        last_week_t1_timeslot_id = last_week_games[t1]
                    end
                    if last_week_games.has_key?(t2)
                        last_week_t2_timeslot_id = last_week_games[t2]
                    end
                    if timeslot_is_late_game == true
                        # Back to back late games are very bad.
                        if (!last_week_t1_timeslot_id.nil? && all_timeslot_attributes[last_week_t1_timeslot_id][:late_game] == true) \
                        || (!last_week_t2_timeslot_id.nil? && all_timeslot_attributes[last_week_t2_timeslot_id][:late_game] == true)
                            score = score + 70 
                        end
                    elsif timeslot_is_alternate_day == true
                        # Try to avoid back-to-back games on the league alternate-night
                        if (!last_week_t1_timeslot_id.nil? && all_timeslot_attributes[last_week_t1_timeslot_id][:alternate_day] == true) \
                            || (!last_week_t2_timeslot_id.nil? && all_timeslot_attributes[last_week_t2_timeslot_id][:alternate_day] == true)
                            score = score + 10
                        end
                    elsif timeslot_is_early_game == true
                        # try to avoid back to back early games, but not super critical.
                        if (!last_week_t1_timeslot_id.nil? && all_timeslot_attributes[last_week_t1_timeslot_id][:early_game] == true) \
                            || (!last_week_t2_timeslot_id.nil? && all_timeslot_attributes[last_week_t2_timeslot_id][:early_game] == true)
                            score = score + 15 
                        end
                    else
                        # Try to avoid back-to-back times for other timeslots too but it's not so critical
                        if (!last_week_t1_timeslot_id.nil? && last_week_t1_timeslot_id == timeslot_id) \
                            || (!last_week_t2_timeslot_id.nil? && last_week_t2_timeslot_id == timeslot_id)
                            score = score + 10
                        end
                    end
                end

                # 3 games in a row in the same timeslot is extra bad news
                if already_scheduled_games.size() > 1
                    last_week_games = already_scheduled_games[-1]
                    two_week_ago_games = already_scheduled_games[-2]
                    if last_week_games.has_key?(t1) && two_week_ago_games.has_key?(t1) \
                    && last_week_games[t1] == timeslot_id && two_week_ago_games[t1] == timeslot_id
                        score = score + 150
                    elsif last_week_games.has_key?(t2) && two_week_ago_games.has_key?(t2) \
                        && last_week_games[t2] == timeslot_id && two_week_ago_games[t2] == timeslot_id
                        score = score + 150
                    end
                end
    
                timeslot_scores[timeslot_idx].push([timeslot_idx, team_pair_idx, score])
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
        #
        # Give the lowest scoring team pairs the correct timeslots.
    
        if debug == true
            puts "timeslot scores:"
            print "            "
            team_matchups.each do |pair|
                print "teams #{pair[0]}+#{pair[1]}  "
            end
            puts ""
            timeslot_scores.each_index do |idx|
                print "timeslot #{idx}    "
                timeslot_scores[idx].each do |teamscore|
                    timeslot_idx = team_matchups[teamscore[0]]
                    team_pair = team_matchups[teamscore[1]]
                    score = teamscore[2]
                    printf "%3d        ", score
                end
                puts ""
            end
            puts ""
        end
    
        # Sort the timeslots by which timeslot has a team with the worst score. 
        # The timeslots where the teams have the worst (highest) score we want to
        # settle first, so that those can go to teams with low scores.  If we leave
        # those timeslots for last, we may end up having to schedule a team with a
        # high score into a bad timeslot.
        # 
        # The line below is a little tricky.  It sorts the timeslots by the teampair
        # with the highest score.  Then it returns the timeslot index #'s for those
        # timeslots in that order.  So we can first solve the timeslot with a team that
        # has the worst score, then we solve the timeslot with the team that has the
        # second worst score, etc.

        schedule_order = timeslot_scores.
                            sort { |x,y| x.map {|e| e[2]}.max <=> y.map {|e| e[2]}.max }.
                            reverse.map { |e| e[0][0] }

        puts "Will schedule the timeslots in order of: #{schedule_order.join(', ')}" if debug
        result = Array.new

        teams_scheduled = Hash.new

        schedule_order.each do |idx|
            puts "Scheduling timeslot #{idx}" if debug && verbose
            timeslot_scores[idx].sort do  |x,y| 
                    # compare the scores
                    xval = x[2]
                    yval = y[2]
                    # Introduce some randomness if team pairs have the same score for a timeslot
                    # so we don't end up with the same team (e.g. team 1) getting certain timeslots
                    # always.
                    if xval == yval
                        puts "team pairs #{x[1] + 1} & #{y[1] + 1} have the same score #{xval} - random" if debug && verbose
                        if rand(1..2) == 1
                            -1
                        else
                            1
                        end
                    else
                        xval <=> yval
                    end
            end.each do |ent|
                timeslot_idx = ent[0]
                team_pair_idx = ent[1]
                score = ent[2]
                next if teams_scheduled.has_key?(team_pair_idx)
                teams_scheduled[team_pair_idx] = true
                puts "team pair #{team_pair_idx + 1} is assigned to timeslot #{timeslot_idx} with score #{score}" if debug
                result[timeslot_idx] = { :timeslot_id => timeslot_ids[timeslot_idx], 
                                        :teams => team_matchups[team_pair_idx],
                                        :score => score
                                    }
                break
            end
        end

        if debug
            result.each_index do |timeslot_idx|
                team_pair = result[timeslot_idx][:teams]
                score = result[timeslot_idx][:score]
                puts "Timeslot #{timeslot_idx} team pair #{team_pair} with score #{score}"
            end
        end

        return result
    end # def self.compute_timeslot_scores

end


def schedule_one_week_of_games(all_timeslot_attributes)
    team_matchups = [[1,3], [4,2], [7,5], [6,8]]
    timeslot_ids = [10, 20, 30, 40]

    already_scheduled_games = [
        { 1 => 10, 2 => 10, 3 => 20, 4 => 20, 5 => 30, 6 => 30, 7 => 40, 8 => 40},
        { 1 => 30, 2 => 40, 3 => 10, 4 => 30, 5 => 20, 6 => 40, 7 => 10, 8 => 20},

    ]

    number_of_games_scheduled_for_each_team_in_each_timeslot = { 
        1 => { 10 => 1, 20 => 0, 30 => 0, 40 => 0, 50 => 0, 60 => 0},
        2 => { 10 => 1, 20 => 0, 30 => 0, 40 => 0, 50 => 0, 60 => 0},
        3 => { 10 => 0, 20 => 2, 30 => 0, 40 => 0, 50 => 0, 60 => 0},
        4 => { 10 => 0, 20 => 2, 30 => 0, 40 => 0, 50 => 0, 60 => 0},
        5 => { 10 => 0, 20 => 0, 30 => 3, 40 => 0, 50 => 0, 60 => 0},
        6 => { 10 => 0, 20 => 0, 30 => 3, 40 => 0, 50 => 0, 60 => 0},
        7 => { 10 => 0, 20 => 0, 30 => 0, 40 => 4, 50 => 0, 60 => 0},
        8 => { 10 => 0, 20 => 0, 30 => 0, 40 => 4, 50 => 0, 60 => 0},
    }

    max_num_games_for_each_team_in_each_timeslot =  {
        10 => 5,
        20 => 5,
        30 => 5,
        40 => 5,
        50 => 5,
        60 => 5,
    }

    debug = true
    verbose = false

    result =TimeslotAssignmentScoreBased.compute_timeslot_scores(team_matchups, timeslot_ids, all_timeslot_attributes, already_scheduled_games, number_of_games_scheduled_for_each_team_in_each_timeslot, max_num_games_for_each_team_in_each_timeslot, debug, verbose)

    if debug == false
        result.each_index do |timeslot_idx|
            team_pair = result[timeslot_idx][:teams]
            score = result[timeslot_idx][:score]
            puts "Timeslot #{timeslot_idx} team pair #{team_pair} with score #{score}"
        end
    end
end

def dump_scheduled_games(schedule, all_timeslot_attributes, all_rink_attributes)

    opponents_faced_count = Hash.new
    timeslots_played_count = Hash.new
    rinks_played_count = Hash.new

    opponents_faced = Hash.new
    timeslots_played = Hash.new
    rinks_played = Hash.new

    byes_count = Hash.new

    teams_seen = Hash.new

    schedule[:weeks].each_index do |wknum|
        puts "wknum #{wknum + 1}"
        schedule[:weeks][wknum][:games].each_index do |gamenum|
            timeslot_id = schedule[:weeks][wknum][:games][gamenum][:timeslot_id]
            rink_id = schedule[:weeks][wknum][:games][gamenum][:rink_id]
            team_pair = schedule[:weeks][wknum][:games][gamenum][:teampair]
            timeslot_desc = all_timeslot_attributes[timeslot_id][:description]
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
                all_timeslot_attributes[timeslot_id][:description], 
                timeslots_played_count[tnum][timeslot_id]
        end
        puts "  # of times playing at each rink:"
        rinks_played_count[tnum].keys.sort.each do |rink_id| 
            printf "    %10s: %d\n", 
                schedule[:rinks][rink_id][:long_name], 
                rinks_played_count[tnum][rink_id]
        end
        puts ""
    end
end

def create_simple_empty_schedule (teamcount, weekcount, gamecount, timeslot_ids, rink_ids, all_timeslots, all_rinks)
    schedule = Hash.new
    schedule[:teamcount] = teamcount
    schedule[:weekcount] = weekcount
    schedule[:gamecount] = gamecount
    schedule[:timeslots] = all_timeslots
    schedule[:rinks] = all_rinks
    schedule[:rinkcount] = rink_ids.sort.uniq.size()
    schedule[:weeks] = Array.new
    if timeslot_ids.size() != gamecount
        puts "create_simple_empty_schedule given bad insufficient number of timeslot id's for a #{gamecount} game schedule - only given #{timeslot_ids.size()} timeslots"
        exit true
    end
    if rink_ids.size() != gamecount
        puts "create_simple_empty_schedule given bad insufficient number of rink id's for a #{gamecount} game schedule - only given #{rink_ids.size()} rinks"
        exit true
    end
    0.upto(weekcount - 1).each do |wknum|
        schedule[:weeks][wknum] = Hash.new
        schedule[:weeks][wknum][:games] = Array.new
        0.upto(gamecount - 1).each do |gamenum|
            schedule[:weeks][wknum][:games][gamenum] = Hash.new
            schedule[:weeks][wknum][:games][gamenum][:timeslot_id] = timeslot_ids[gamenum]
            schedule[:weeks][wknum][:games][gamenum][:rink_id] = rink_ids[gamenum]
        end
    end

    return schedule
end


def schedule_one_season_four_team_league(all_timeslot_attributes, all_rink_attributes)
    number_of_teams = 4
    number_of_timeslots = 2
    number_of_weeks = (number_of_teams - 1) * 3
    schedule = create_simple_empty_schedule(number_of_teams, number_of_weeks, number_of_timeslots, [70, 80], [1, 1], all_timeslot_attributes, all_rink_attributes)

    TeamMatchupsCircular.get_team_matchups(schedule)

    debug = false
    TimeslotAssignmentScoreBased.order_game_times(schedule, debug)
    return schedule
end

def schedule_one_season_six_team_league(all_timeslot_attributes, all_rink_attributes)
    number_of_teams = 6
    number_of_timeslots = 3
    number_of_weeks = (number_of_teams - 1) * 3
    schedule = create_simple_empty_schedule(number_of_teams, number_of_weeks, number_of_timeslots, [20, 30, 40], [1, 1, 1], all_timeslot_attributes, all_rink_attributes)

    TeamMatchupsCircular.get_team_matchups(schedule)

    debug = false
    TimeslotAssignmentScoreBased.order_game_times(schedule, debug)
    return schedule
end

def schedule_one_season_seven_team_league(all_timeslot_attributes, all_rink_attributes)
    number_of_teams = 7
    number_of_timeslots = 3
    number_of_weeks = (number_of_teams - 1) * 3
    schedule = create_simple_empty_schedule(number_of_teams, number_of_weeks, number_of_timeslots, [20, 30, 40], [1, 1, 1], all_timeslot_attributes, all_rink_attributes)

    TeamMatchupsCircular.get_team_matchups(schedule)

    debug = false
    TimeslotAssignmentScoreBased.order_game_times(schedule, debug)
    return schedule
end

def schedule_one_season_eight_team_league(all_timeslot_attributes, all_rink_attributes)
    number_of_teams = 8
    number_of_timeslots = 4
    number_of_weeks = (number_of_teams - 1) * 3
    schedule = create_simple_empty_schedule(number_of_teams, number_of_weeks, number_of_timeslots, [10, 20, 30, 40], [1, 1, 1, 1], all_timeslot_attributes, all_rink_attributes)

    TeamMatchupsCircular.get_team_matchups(schedule)

    debug = false
    TimeslotAssignmentScoreBased.order_game_times(schedule, debug)
    return schedule
end

def schedule_one_season_twelve_team_league(all_timeslot_attributes, all_rink_attributes)
    number_of_teams = 12 
    number_of_timeslots = 6
    number_of_weeks = (number_of_teams - 1) * 3
    schedule = create_simple_empty_schedule(number_of_teams, number_of_weeks, number_of_timeslots, [120, 130, 140, 120, 130, 140], [1, 1, 1, 2, 2, 2], all_timeslot_attributes, all_rink_attributes)

    TeamMatchupsCircular.get_team_matchups(schedule)

    debug = false
    TimeslotAssignmentScoreBased.order_game_times(schedule, debug)
    return schedule
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


        # Thursday Redwood City / San Mateo split league
        120 => { :late_game => false, :early_game => false, :alternate_day => false,  :description => "8:00pm" },
        130 => { :late_game => false, :early_game => false, :alternate_day => false,  :description => "9:15pm" },
        140 => { :late_game => true, :early_game => false, :alternate_day => false,  :description => "10:30pm" },
    }

    all_rink_attributes = {
        1 => { :short_name => "RWC", :long_name => "Redwood City Ice Oasis", :address => "3140 Bay Road, Redwood City, CA 94063" },
        2 => { :short_name => "FC", :long_name => "Foster City Ice Oasis", :address => "Bridgepointe Shopping Center, Foster City, CA" }
    }

    number_of_teams_to_schedule = 12
    if ARGV.size() > 0
        number_of_teams_to_schedule = ARGV[0].to_i
    end

    if number_of_teams_to_schedule == 4
        results = schedule_one_season_four_team_league(all_timeslot_attributes, all_rink_attributes)
    elsif number_of_teams_to_schedule == 6
        results = schedule_one_season_six_team_league(all_timeslot_attributes, all_rink_attributes)
    elsif number_of_teams_to_schedule == 7
        results = schedule_one_season_seven_team_league(all_timeslot_attributes, all_rink_attributes)
    elsif number_of_teams_to_schedule == 8
        results = schedule_one_season_eight_team_league(all_timeslot_attributes, all_rink_attributes)
    elsif number_of_teams_to_schedule == 12
        results = schedule_one_season_twelve_team_league(all_timeslot_attributes, all_rink_attributes)
    else
        puts "Unrecognized number of teams to schedule, doing nothing."
        exit
    end

dump_scheduled_games(results, all_timeslot_attributes, all_rink_attributes)

end
