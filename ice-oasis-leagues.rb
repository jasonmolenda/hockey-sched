#! /usr/bin/ruby
require 'date'

module IceOasisLeagues

    def self.get_rinks()
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
        return rinks
    end

    def self.get_timeslots()
        # If a league had a game played on a different day -- e.g. a Thursday league that plays
        # 4 games on Thursday and 1 on on Friday -- then :overflow_day => true and 
        # :overflow_day_offset => 1 (1 day offset).  We don't have any leagues scheduled like
        # this right now, but it is a supported configuration.
        timeslots = Hash.new { |hsh, key| hsh[key] = {:late_game=>false, :early_game=>false, :overflow_day=>false, :overflow_day_offset => 0} }

        entries_to_add = {
            # 2017 Sunday league
            10  => {:description => "5:30pm",  :hour => 17, :minute => 30},
            11  => {:description => "6:45pm",  :hour => 18, :minute => 45},
            12  => {:description => "8:00pm",  :hour => 20, :minute => 00},

            # 2017 Monday league
            20  => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            21  => {:description => "8:15pm",  :hour => 20, :minute => 15},
            22  => {:description => "9:30pm",  :hour => 21, :minute => 30},
            23  => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 Tuesday league(s)
            30  => {:description => "9:00pm",  :hour => 21, :minute => 00},
            31  => {:description => "10:15pm", :hour => 22, :minute => 15},
            
            # 2017 Wednesday league
            40 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            41 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            42 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            43 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 Thursday league
            # RWC times
            50 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            51 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            52 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},
            # SM times
            53 => {:description => "7:45pm",  :hour => 19, :minute => 45},
            54 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            55 => {:description => "10:15pm", :hour => 22, :minute => 15, :late_game => true},

            # 2017 Friday league
            60 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            61 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            62 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 Saturday league
            70 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            71 => {:description => "10:15pm", :hour => 22, :minute => 15},
        }

        entries_to_add.keys.each do |tid|
            if timeslots.has_key?(tid)
                puts "ERROR: timeslots already has a #{tid} entry!"
                exit false
            end
            entries_to_add[tid].keys.each do |key|
                value = entries_to_add[tid][key]
                timeslots[tid][key] = value
            end
        end

        return timeslots
    end

    def self.get_ice_oasis_leagues()
        fall2017 = Hash.new
        fall2017[:name] = "Fall-Winter 2017-2018"
        fall2017[:start_date] = Date.parse("2017-10-01")
        fall2017[:end_date] = Date.parse("2018-03-10")
        fall2017[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [10, 11, 12],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "Desert Fleas", "Dates", "SuperEvil", "Desert Storm", "Sand Lizards"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [20, 21, 22, 23],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Desert Hawks", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [30, 31],
              :rink_ids => [1, 1],
              :team_names => [
                  "Molson", "Kobra Kai", "M I T", "Kanter"
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday SM",
              :timeslot_ids => [30, 31],
              :rink_ids => [2, 2],
              :team_names => [
                  "Sotasticks", "KingFishers", "Toucans", "O'Neill's"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [40, 41, 42, 43],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [50, 51, 52, 53, 54, 55],
              :rink_ids => [1, 1, 1, 2, 2, 2],
              :team_names => [
                  "Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", "Geckos", "Tarantulas"
                ]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [60, 61, 62],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Lightning", "Intangibles", "Old Timers", "Otters", "Polars", "Shamrocks"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [70, 71],
              :rink_ids => [1, 1],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]

        verify_league(fall2017)
        return fall2017
    end

    def self.verify_league(league)
        timeslots = get_timeslots()
        rinks = get_rinks()
        team_names_seen = Hash.new
        [:name, :start_date, :end_date, :leagues].each do |key|
            if !league.has_key?(key)
                STDERR.puts "league is mising a :#{key} key"
                exit false
            end
        end
        league[:leagues].each do |l|
            [:day_of_week, :name, :timeslot_ids, :rink_ids, :team_names].each do |key|
                if !l.has_key?(key)
                    puts "One of the leagues is missing the field :#{key}:  #{l}"
                end
            end
            l[:team_names].each do |t|
                if team_names_seen.has_key?(t)
                    STDERR.puts "Team name '#{t}' occured in more than one league!"
                    exit false
                end
                team_names_seen[t] = true
            end
            teamcount = l[:team_names].size()
            gamecount = teamcount / 2
            if l[:timeslot_ids].size() % gamecount != 0
                STDERR.puts ":timeslot_ids array is not evenly divisible by # of games (#{gamecount}): #{l[:timeslot_ids]}"
                exit false
            end
            if l[:rink_ids].size() % gamecount != 0
                STDERR.puts ":rink_ids array is not evenly divisible by # of games (#{gamecount}): #{l[:rink_ids]}"
                exit false
            end
            l[:timeslot_ids].each do |tid|
                if !timeslots.has_key?(tid)
                    STDERR.puts "Timeslots array does not have an entry for #{tid}"
                    exit false
                end
            end
            l[:rink_ids].each do |rid|
                if !rinks.has_key?(rid)
                    STDERR.puts "inks array does not have an entry for #{rid}"
                    exit false
                end
            end
        end

    end
end

if __FILE__ == $0
    puts IceOasisLeagues.get_timeslots()
    puts ""
    puts IceOasisLeagues.get_rinks()
    puts ""
    puts IceOasisLeagues.get_ice_oasis_leagues()

end
