#! /usr/bin/ruby
require 'date'

module IceOasisLeagues

    def self.get_timeslots()
        timeslots = Hash.new { |hsh, key| hsh[key] = {:late_game=>false, :early_game=>false, :alternate_day=>false} }

        entries_to_add = {
            # 2017 Sunday league
            0  => {:description => "5:30pm",  :hour => 17, :minute => 30},
            1  => {:description => "6:45pm",  :hour => 18, :minute => 45},
            2  => {:description => "8:00pm",  :hour => 20, :minute => 00},
            # 2017 Monday league
            3  => {:description => "8:45pm",  :hour => 20, :minute => 45},
            4  => {:description => "10:00pm", :hour => 22, :minute => 00},

            # 2017 Tuesday league(s)
            5  => {:description => "8:45pm",  :hour => 20, :minute => 45},
            6  => {:description => "10:00pm", :hour => 22, :minute => 00},
            
            # 2017 Wednesday league
            10 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            11 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            12 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            13 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},
            # 2017 Thursday league
            15 => {:description => "8:00pm",  :hour => 20, :minute => 00},
            16 => {:description => "9:15pm",  :hour => 21, :minute => 15},
            17 => {:description => "10:30pm", :hour => 22, :minute => 30, :late_game => true},
            # 2017 Friday league
            21 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            22 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            23 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},
            # 2017 Saturday league
            25 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            26 => {:description => "10:15pm", :hour => 22, :minute => 15},
        }

        entries_to_add.keys.each do |tid|
            if timeslots.has_key?(tid)
                puts "ERROR: timeslots already has a #{tid} entry!"
                exit true
            end
            entries_to_add[tid].keys.each do |key|
                value = entries_to_add[tid][key]
                timeslots[tid][key] = value
            end
        end

        return timeslots
    end

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

    def self.get_ice_oasis_leagues()
        fall2017 = Hash.new
        fall2017[:name] = "Fall-Winter 2017-18"
        fall2017[:start_date] = Date.parse("2017-10-01")
        fall2017[:end_date] = Date.parse("2018-03-24")
        fall2017[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [0, 1, 2],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "Desert Fleas", "Dates", "SuperEvil", "Desert Storm", "Sand Lizards"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [3, 4, 3, 4],
              :rink_ids => [1, 1, 2, 2],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Desert Hawks", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [5, 6],
              :rink_ids => [1, 1],
              :team_names => [
                  "Molson", "Kobra Kai", "Hard to Watch", "Kanter"
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday SM",
              :timeslot_ids => [5, 6],
              :rink_ids => [2, 2],
              :team_names => [
                  "Sotasticks", "KingFishers", "Toucans", "O'Neill's"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [10, 11, 12, 13],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [15, 16, 17, 15, 16, 17],
              :rink_ids => [1, 1, 1, 2, 2, 2],
              :team_names => [
                  "Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", "Geckos", "Tarantulas"
                ]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [21, 22, 23],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Lightning", "Intangibles", "Old Timers", "Otters", "Polars", "Shamrocks"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [25, 26],
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
                puts "league is mising a :#{key} key"
                exit true
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
                    puts "Team name '#{t}' occured in more than one league!"
                    exit true
                end
                team_names_seen[t] = true
            end
            teamcount = l[:team_names].size()
            gamecount = teamcount / 2
            if l[:timeslot_ids].size() % gamecount != 0
                puts ":timeslot_ids array is not evenly divisible by # of games (#{gamecount}): #{l[:timeslot_ids]}"
                exit true
            end
            if l[:rink_ids].size() % gamecount != 0
                puts ":rink_ids array is not evenly divisible by # of games (#{gamecount}): #{l[:rink_ids]}"
                exit true
            end
            l[:timeslot_ids].each do |tid|
                if !timeslots.has_key?(tid)
                    puts "Timeslots array does not have an entry for #{tid}"
                    exit true
                end
            end
            l[:rink_ids].each do |rid|
                if !rinks.has_key?(rid)
                    puts "inks array does not have an entry for #{rid}"
                    exit true
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
