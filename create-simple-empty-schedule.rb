#! /usr/bin/ruby

module CreateSimpleEmptySchedule

    def self.create_simple_four_team_empty_schedule ()
        teamcount = 4
        gamecount = 2
        weekcount = (teamcount - 1) * 3
        return create_simple_empty_schedule(teamcount, weekcount, gamecount, [70, 80], [1, 1], nil, nil)
    end

    def self.create_simple_six_team_empty_schedule ()
        teamcount = 6
        gamecount = 3
        weekcount = (teamcount - 1) * 3
        return create_simple_empty_schedule(teamcount, weekcount, gamecount, [20, 30, 40], [1, 1, 1], nil, nil)
    end

    def self.create_simple_seven_team_empty_schedule ()
        teamcount = 7
        gamecount = 3
        weekcount = (teamcount - 1) * 3
        return create_simple_empty_schedule(teamcount, weekcount, gamecount, [20, 30, 40], [1, 1, 1], nil, nil)
    end

    def self.create_simple_eight_team_empty_schedule ()
        teamcount = 8
        gamecount = 4
        weekcount = (teamcount - 1) * 3
        return create_simple_empty_schedule(teamcount, weekcount, gamecount, [10, 20, 30, 40], [1, 1, 1, 1], nil, nil)
    end

    def self.create_simple_twelve_team_empty_schedule ()
        teamcount = 12
        gamecount = 6 
        weekcount = (teamcount - 1) * 3
        return create_simple_empty_schedule(teamcount, weekcount, gamecount, [120, 130, 140, 120, 130, 140], [1, 1, 1, 2, 2, 2], nil, nil)
    end

    def self.create_simple_empty_schedule (teamcount, weekcount, gamecount, timeslot_ids, rink_ids, timeslots, rinks)
        if timeslots == nil
            timeslots = {
                # weeknight leagues
                10 => { :late_game => false, :early_game => true, :overflow_day => false, :timeslot_id => 10, :description => "7:00pm", :hour => 19, :minute => 0},
                20 => { :late_game => false, :early_game => false, :overflow_day => false, :timeslot_id => 20, :description => "8:15pm", :hour => 20, :minute => 15},
                30 => { :late_game => false, :early_game => false, :overflow_day => false, :timeslot_id => 30, :description => "9:30pm", :hour => 21, :minute => 30},
                40 => { :late_game => true, :early_game => false, :overflow_day => false, :timeslot_id => 40, :description => "10:45pm", :hour => 22, :minute => 45},

                # the thursday league where games were sched fri 7 & 10:45 alternating
                50 => { :late_game => false, :early_game => true, :overflow_day => true, :timeslot_id => 50, :description => "Fri 7:00pm", :hour => 19, :minute => 0},
                60 => { :late_game => true, :early_game => false, :overflow_day => true, :timeslot_id => 60, :description => "Fri 10:45pm", :hour => 22, :minute => 45},

                # weekend saturday
                70 => { :late_game => false, :early_game => false, :overflow_day => false, :timeslot_id => 70, :description => "9:00pm", :hour => 21, :minute => 0},
                80 => { :late_game => false, :early_game => false, :overflow_day => false, :timeslot_id => 80, :description => "10:15pm", :hour => 22, :minute => 15},


                # Thursday Redwood City / San Mateo split league
                120 => { :late_game => false, :early_game => false, :overflow_day => false,  :description => "7:45pm", :hour => 19, :minute => 45 },
                130 => { :late_game => false, :early_game => false, :overflow_day => false,  :description => "9:00pm", :hour => 21, :minute => 00 },
                140 => { :late_game => true, :early_game => false, :overflow_day => false,  :description => "10:15pm", :hour => 22, :minute => 15 },
            }
        end
        if rinks == nil
            rinks = {
                1 => { :short_name => "RWC", 
                       :long_name => "Redwood City Ice Oasis", 
                       :address => "3140 Bay Rd, Redwood City, CA 94063",
                       :location => "LOCATION:3140 Bay Rd\\nRedwood City\\, CA 94063\\, United States", 
                       :structured_location => "X-APPLE-STRUCTURED-LOCATION;VALUE=URI;X-APPLE-RADIUS=68.20933622731799;X-TITLE=\"3140 Bay Rd\\nRedwood City, CA 94063, United States\":geo:37.481956,-122.200339"
                     },
                2 => { :short_name => "SM", 
                       :long_name => "San Mateo Ice Oasis", 
                       :address => "2202 Bridgepointe Pkwy, San Mateo, CA 94404",
                       :location => "LOCATION:2202 Bridgepointe Pkwy\\nSan Mateo\\, CA 94404\\, United States",
                       :structured_location => "X-APPLE-STRUCTURED-LOCATION;VALUE=URI;X-APPLE-RADIUS=68.20933622731799;X-TITLE=\"2202 Bridgepointe Pkwy\\nSan Mateo, CA 94404, United States\":geo:37.561887,-122.281446"
                     }
            }
        end

        schedule = Hash.new
        schedule[:teamcount] = teamcount
        schedule[:weekcount] = weekcount
        schedule[:gamecount] = gamecount
        schedule[:timeslots] = timeslots
        schedule[:rinks] = rinks
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

end
