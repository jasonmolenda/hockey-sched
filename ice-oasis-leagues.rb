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
            # 2021 and 2022 Monday league
            120  => {:description => "8:00pm",  :hour => 20, :minute => 00, :early_game => true},
            121  => {:description => "9:15pm",  :hour => 21, :minute => 15},
            122  => {:description => "10:30pm",  :hour => 22, :minute => 30, :late_game => true},

            # 2022 Wednesday league
            140 => {:description => "8:00pm",  :hour => 20, :minute => 00, :early_game => true},
            141 => {:description => "9:15pm",  :hour => 21, :minute => 15},
            142 => {:description => "10:30pm", :hour => 22, :minute => 30, :late_game => true},

            # 2021 and 2022 Thursday league
            150 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            151 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            152 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            153 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 and 2021 and 2022 Saturday league
            170 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            171 => {:description => "10:15pm", :hour => 22, :minute => 15},
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
        winter2022 = Hash.new
        winter2022[:name] = "Winter-Spring 2022"
        winter2022[:short_name] = "winter2022"
        winter2022[:start_date] = Date.parse("2022-01-03")
        winter2022[:end_date] = Date.parse("2022-05-31")
        winter2022[:leagues] = [
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122],
              :rink_ids => [2, 2, 2],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Toasters", "Sphinx", "Desert Rats"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142],
              :rink_ids => [2, 2, 2],
              :team_names => [
                  "Camels", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [150, 151, 152, 153],
              :rink_ids => [2, 2, 2, 2],
              :team_names => ["Desert Ravens", "Desert Tribe", "Oasis Owls", "Flyers", "Danger", "Geckos", "Sultans", "Desert Foxes"]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [2, 2],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]

        verify_league(winter2022)
        return winter2022
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

    def self.hand_entered_times_to_timeslots(hand_entered)
        timeslots = Hash.new { |hsh, key| hsh[key] = {:late_game=>false, :early_game=>false, :overflow_day=>false, :overflow_day_offset => 0} }

        hand_entered.keys.each do |tid|
            if timeslots.has_key?(tid)
                puts "ERROR: timeslots already has a #{tid} entry!"
                exit false
            end
            if !hand_entered[tid].has_key?(:hour) && !hand_entered[tid].has_key?(:minute)
                if hand_entered[tid][:description] =~ /(\d+):(\d+)([ap]m)/i
                    hour = $1.to_i
                    minute = $2.to_i
                    meridian = $3
                    if meridian.downcase() == "pm"
                        hour += 12
                    end
                    hand_entered[tid][:hour] = hour
                    hand_entered[tid][:minute] = minute
                elsif hand_entered[tid][:description] =~ /(\d+):(\d+)$/
                    hour = $1.to_i
                    minute = $2.to_i
                    hand_entered[tid][:hour] = hour
                    hand_entered[tid][:minute] = minute
                end
            end

            hand_entered[tid].keys.each do |key|
                value = hand_entered[tid][key]
                timeslots[tid][key] = value
            end
        end
        return timeslots
    end

    def self.get_old_seasons()
        old_seasons = Hash.new

        winter2022_timeslosts = {
            # 2021 and 2022 Monday league
            120  => {:description => "8:00pm",  :hour => 20, :minute => 00, :early_game => true},
            121  => {:description => "9:15pm",  :hour => 21, :minute => 15},
            122  => {:description => "10:30pm",  :hour => 22, :minute => 30, :late_game => true},

            # 2022 Wednesday league
            140 => {:description => "8:00pm",  :hour => 20, :minute => 00, :early_game => true},
            141 => {:description => "9:15pm",  :hour => 21, :minute => 15},
            142 => {:description => "10:30pm", :hour => 22, :minute => 30, :late_game => true},

            # 2021 and 2022 Thursday league
            150 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            151 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            152 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            153 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 and 2021 and 2022 Saturday league
            170 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            171 => {:description => "10:15pm", :hour => 22, :minute => 15},
        }

        winter2022 = Hash.new
        winter2022[:name] = "Winter-Spring 2022"
        winter2022[:short_name] = "winter2022"
        winter2022[:start_date] = Date.parse("2022-01-03")
        winter2022[:end_date] = Date.parse("2022-05-31")
        winter2022[:leagues] = [
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122],
              :rink_ids => [2, 2, 2],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Toasters", "Sphinx", "Desert Rats"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142],
              :rink_ids => [2, 2, 2, 2],
              :team_names => [
                  "Camels", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [150, 151, 152, 153],
              :rink_ids => [2, 2, 2, 2],
              :team_names => ["Desert Ravens", "Desert Tribe", "Oasis Owls", "Flyers", "Danger", "Geckos", "Sultans", "Desert Foxes"]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [2, 2],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]

        summer2021_timeslots = {
            # 2021 Monday league
            120  => {:description => "8:00pm",  :hour => 20, :minute => 00, :early_game => true},
            121  => {:description => "9:15pm",  :hour => 21, :minute => 15},
            122  => {:description => "10:30pm",  :hour => 22, :minute => 30, :late_game => true},

            # 2017 and 2018 and 2021 Wednesday league
            140 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            141 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            142 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            143 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2021 Thursday league
            150 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            151 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            152 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            153 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 and 2021 Saturday league
            170 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            171 => {:description => "10:15pm", :hour => 22, :minute => 15},
        }

        summer2021 = Hash.new
        summer2021[:name] = "Summer 2021"
        summer2021[:short_name] = "summer2021"
        summer2021[:start_date] = Date.parse("2021-07-12")
        summer2021[:end_date] = Date.parse("2021-09-30")
        summer2021[:leagues] = [
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122],
              :rink_ids => [2, 2, 2],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Toasters", "Sphinx", "Desert Rats"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142, 143],
              :rink_ids => [2, 2, 2, 2],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [150, 151, 152, 153],
              :rink_ids => [2, 2, 2, 2],
              :team_names => ["Desert Ravens", "Desert Tribe", "Oasis Owls", "Flyers", "Danger", "Geckos", "Sultans", "Desert Foxes"]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [2, 2],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]

        verify_league(summer2021)

        old_seasons["summer2021"] = Hash.new
        old_seasons["summer2021"][:timeslots] = self.hand_entered_times_to_timeslots(summer2021_timeslots)
        old_seasons["summer2021"][:league_schedule] = summer2021




        fall2019_timeslots = {
            # 2018 Sunday league
            110  => {:description => "4:30pm",  :hour => 16, :minute => 30},
            111  => {:description => "5:45pm",  :hour => 17, :minute => 45},
            112  => {:description => "7:00pm",  :hour => 19, :minute => 00},

            # 2017 and 2018 Monday league
            120  => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            121  => {:description => "8:15pm",  :hour => 20, :minute => 15},
            122  => {:description => "9:30pm",  :hour => 21, :minute => 30},
            123  => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 Tuesday league
            130  => {:description => "9:00pm",  :hour => 21, :minute => 00},
            131  => {:description => "10:15pm", :hour => 22, :minute => 15},
            
            # 2017 and 2018 Wednesday league
            140 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            141 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            142 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            143 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 Thursday league
            # RWC times
            150 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            151 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            152 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},
            # SM times
            153 => {:description => "8:00pm",  :hour => 20, :minute => 00},
            154 => {:description => "9:15pm",  :hour => 21, :minute => 15},
            155 => {:description => "10:30pm", :hour => 22, :minute => 30, :late_game => true},

            # 2018 Friday league
            160 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            161 => {:description => "10:15pm",  :hour => 22, :minute => 15},

            # 2017 and 2018 Saturday league
            170 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            171 => {:description => "10:15pm", :hour => 22, :minute => 15},
        }

        fall2019 = Hash.new
        fall2019[:name] = "Fall-Winter 2019-2020"
        fall2019[:short_name] = "fall2019"
        fall2019[:start_date] = Date.parse("2019-10-10")
        fall2019[:end_date] = Date.parse("2020-03-05")
        fall2019[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [110, 111, 112],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "SuperEvil", "Desert Storm", "Sand Lizards", "Coyotes", "Badgers"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122, 123],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Specials", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [130, 131],
              :rink_ids => [1, 1],
              :team_names => [
                  "Stanford", "Cobra Kai", "PURPLE", "Kanter"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142, 143],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday South",
              :timeslot_ids => [150, 151, 152],
              :rink_ids => [1, 1, 1],
              :team_names => ["Desert Ravens", "Desert Tribe", "Oasis Owls", "Flyers", "Danger", "Geckos"]
            },
            { :day_of_week => 4,
              :name => "Thursday North",
              :timeslot_ids => [153, 154, 155],
              :rink_ids => [2, 2, 2],
              :team_names => ["Sultans", "Desert Foxes", "Cobras", "Scorpions", "Genies", "Tarantulas"]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [160, 161],
              :rink_ids => [1, 1],
              :team_names => [
                  "Shamrocks", "Intangibles", "Old Timers", "Polars"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [1, 1],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]

        verify_league(fall2019)

        old_seasons["fall2019"] = Hash.new
        old_seasons["fall2019"][:timeslots] = self.hand_entered_times_to_timeslots(fall2019_timeslots)
        old_seasons["fall2019"][:league_schedule] = fall2019


        summer2019_timeslots = {
            # 2018 Sunday league
            110  => {:description => "4:30pm",  :hour => 16, :minute => 30},
            111  => {:description => "5:45pm",  :hour => 17, :minute => 45},
            112  => {:description => "7:00pm",  :hour => 19, :minute => 00},

            # 2017 and 2018 Monday league
            120  => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            121  => {:description => "8:15pm",  :hour => 20, :minute => 15},
            122  => {:description => "9:30pm",  :hour => 21, :minute => 30},
            123  => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 Tuesday league
            130  => {:description => "9:00pm",  :hour => 21, :minute => 00},
            131  => {:description => "10:15pm", :hour => 22, :minute => 15},
            
            # 2017 and 2018 Wednesday league
            140 => {:description => "7:00pm",  :hour => 19, :minute => 00, :early_game => true},
            141 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            142 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            143 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},

            # 2017 and 2018 Thursday league
            # RWC times
            150 => {:description => "8:15pm",  :hour => 20, :minute => 15},
            151 => {:description => "9:30pm",  :hour => 21, :minute => 30},
            152 => {:description => "10:45pm", :hour => 22, :minute => 45, :late_game => true},
            # SM times
            153 => {:description => "8:00pm",  :hour => 20, :minute => 00},
            154 => {:description => "9:15pm",  :hour => 21, :minute => 15},
            155 => {:description => "10:30pm", :hour => 22, :minute => 30, :late_game => true},

            # 2018 Friday league
            160 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            161 => {:description => "10:15pm",  :hour => 22, :minute => 15},

            # 2017 and 2018 Saturday league
            170 => {:description => "9:00pm",  :hour => 21, :minute => 00},
            171 => {:description => "10:15pm", :hour => 22, :minute => 15},
        }

        summer2019 = Hash.new
        summer2019[:name] = "Spring-Summer 2019"
        summer2019[:short_name] = "summer2019"
        summer2019[:start_date] = Date.parse("2019-04-07")
        summer2019[:end_date] = Date.parse("2019-09-07")
        summer2019[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [110, 111, 112],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "SuperEvil", "Desert Storm", "Sand Lizards", "Coyotes", "Badgers"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122, 123],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Specials", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [130, 131],
              :rink_ids => [1, 1],
              :team_names => [
                  "Stanford", "Cobra Kai", "PURPLE", "Kanter"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142, 143],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday South",
              :timeslot_ids => [150, 151, 152],
              :rink_ids => [1, 1, 1],
              :team_names => ["Desert Ravens", "Desert Tribe", "Oasis Owls", "Waves", "Danger", "Geckos"]
            },
            { :day_of_week => 4,
              :name => "Thursday North",
              :timeslot_ids => [153, 154, 155],
              :rink_ids => [2, 2, 2],
              :team_names => ["Sultans", "Desert Foxes", "Cobras", "Scorpions", "Genies", "Tarantulas"]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [160, 161],
              :rink_ids => [1, 1],
              :team_names => [
                  "Shamrocks", "Intangibles", "Old Timers", "Polars"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [1, 1],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]

        verify_league(summer2019)

        old_seasons["summer2019"] = Hash.new
        old_seasons["summer2019"][:timeslots] = self.hand_entered_times_to_timeslots(summer2019_timeslots)
        old_seasons["summer2019"][:league_schedule] = summer2019


        fall2018_timeslots = {
            # 2018 Sunday league
            110  => {:description => "5:45pm"},
            111  => {:description => "7:00pm"},

            # 2018 Monday league
            120  => {:description => "7:00pm", :early_game => true},
            121  => {:description => "8:15pm"},
            122  => {:description => "9:30pm"},
            123  => {:description => "10:45pm", :late_game => true},

            # 2018 Tuesday league
            130  => {:description => "9:00pm"},
            131  => {:description => "10:15pm"},
            
            # 2018 Wednesday league
            140 => {:description => "7:00pm",  :early_game => true},
            141 => {:description => "8:15pm"},
            142 => {:description => "9:30pm"},
            143 => {:description => "10:45pm", :late_game => true},

            # 2018 Thursday league
            # RWC times
            150 => {:description => "8:15pm"},
            151 => {:description => "9:30pm"},
            152 => {:description => "10:45pm", :late_game => true},
            # SM times
            153 => {:description => "8:00pm"},
            154 => {:description => "9:15pm"},
            155 => {:description => "10:30pm", :late_game => true},

            # 2018 Friday league
            160 => {:description => "9:00pm"},
            161 => {:description => "10:15pm"},

            # 2018 Saturday league
            170 => {:description => "9:00pm"},
            171 => {:description => "10:15pm"},
        }

        fall2018 = Hash.new
        fall2018[:name] = "Fall-Winter 2018-2019"
        fall2018[:short_name] = "fall2018"
        fall2018[:start_date] = Date.parse("2018-09-30")
        fall2018[:end_date] = Date.parse("2019-03-30")
        fall2018[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [110, 111],
              :rink_ids => [1, 1],
              :team_names => [
                  "Night Owls", "SuperEvil", "Desert Storm", "Sand Lizards", "Coyotes"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122, 123],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Specials", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [130, 131],
              :rink_ids => [1, 1],
              :team_names => [
                  "Stanford", "Cobra Kai", "PURPLE", "Kanter"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142, 143],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday South",
              :timeslot_ids => [150, 151, 152],
              :rink_ids => [1, 1, 1],
              :team_names => ["Desert Ravens", "Desert Tribe", "Oasis Owls", "Waves", "Danger", "Geckos"]
            },
            { :day_of_week => 4,
              :name => "Thursday North",
              :timeslot_ids => [153, 154, 155],
              :rink_ids => [2, 2, 2],
              :team_names => ["Sultans", "Desert Foxes", "Cobras", "Scorpions", "Genies", "Tarantulas"]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [160, 161],
              :rink_ids => [1, 1],
              :team_names => [
                  "Shamrocks", "Intangibles", "Old Timers", "Polars"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [1, 1],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]
        verify_league(fall2018)

        old_seasons["fall2018"] = Hash.new
        old_seasons["fall2018"][:timeslots] = self.hand_entered_times_to_timeslots(fall2018_timeslots)
        old_seasons["fall2018"][:league_schedule] = fall2018


        spring2018_timeslots = {
            # 2018 Sunday league
            110  => {:description => "5:30pm"},
            111  => {:description => "6:45pm"},
            112  => {:description => "8:00pm"},

            # 2018 Monday league
            120  => {:description => "7:00pm", :early_game => true},
            121  => {:description => "8:15pm"},
            122  => {:description => "9:30pm"},
            123  => {:description => "10:45pm", :late_game => true},

            # 2018 Tuesday league
            130  => {:description => "9:00pm"},
            131  => {:description => "10:15pm"},
            
            # 2018 Wednesday league
            140 => {:description => "7:00pm",  :early_game => true},
            141 => {:description => "8:15pm"},
            142 => {:description => "9:30pm"},
            143 => {:description => "10:45pm", :late_game => true},

            # 2018 Thursday league
            # RWC times
            150 => {:description => "8:15pm"},
            151 => {:description => "9:30pm"},
            152 => {:description => "10:45pm", :late_game => true},
            # SM times
            153 => {:description => "7:45pm"},
            154 => {:description => "9:00pm"},
            155 => {:description => "10:15pm", :late_game => true},

            # 2018 Friday league
            160 => {:description => "8:15pm"},
            161 => {:description => "9:30pm"},
            162 => {:description => "10:45pm", :late_game => true},

            # 2018 Saturday league
            170 => {:description => "9:00pm"},
            171 => {:description => "10:15pm"},
        }

        spring2018 = Hash.new
        spring2018[:name] = "Spring-Summer 2018"
        spring2018[:short_name] = "spring2018"
        spring2018[:start_date] = Date.parse("2018-04-01")
        spring2018[:end_date] = Date.parse("2018-10-01")
        spring2018[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [110, 111, 112],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "Desert Fleas", "Dates", "SuperEvil", "Desert Storm", "Sand Lizards"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122, 123],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Desert Hawks", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday",
              :timeslot_ids => [130, 131],
              :rink_ids => [1, 1],
              :team_names => [
                  "Molson", "Kobra Kai", "Hard to Watch", "Kanter"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142, 143],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [150, 151, 152, 153, 154, 155],
              :rink_ids => [1, 1, 1, 2, 2, 2],
              :team_names => [
                  "Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", "Geckos", "Tarantulas"
                ]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [160, 161, 162],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Lightning", "Intangibles", "Old Timers", "Otters", "Polars", "Shamrocks"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [1, 1],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]
        verify_league(spring2018)

        old_seasons["spring2018"] = Hash.new
        old_seasons["spring2018"][:timeslots] = self.hand_entered_times_to_timeslots(spring2018_timeslots)
        old_seasons["spring2018"][:league_schedule] = spring2018

        fall2017_timeslots = {
            # 2017 Sunday league
            110  => {:description => "5:30pm"},
            111  => {:description => "6:45pm"},
            112  => {:description => "8:00pm"},

            # 2017 Monday league
            120  => {:description => "7:00pm", :early_game => true},
            121  => {:description => "8:15pm"},
            122  => {:description => "9:30pm"},
            123  => {:description => "10:45pm", :late_game => true},

            # 2017 Tuesday league(s)
            130  => {:description => "9:00pm"},
            131  => {:description => "10:15pm"},
            
            # 2017 Wednesday league
            140 => {:description => "7:00pm",  :early_game => true},
            141 => {:description => "8:15pm"},
            142 => {:description => "9:30pm"},
            143 => {:description => "10:45pm", :late_game => true},

            # 2017 Thursday league
            # RWC times
            150 => {:description => "8:15pm"},
            151 => {:description => "9:30pm"},
            152 => {:description => "10:45pm", :late_game => true},
            # SM times
            153 => {:description => "7:45pm"},
            154 => {:description => "9:00pm"},
            155 => {:description => "10:15pm", :late_game => true},

            # 2017 Friday league
            160 => {:description => "8:15pm"},
            161 => {:description => "9:30pm"},
            162 => {:description => "10:45pm", :late_game => true},

            # 2017 Saturday league
            170 => {:description => "9:00pm"},
            171 => {:description => "10:15pm"},
        }

        fall2017 = Hash.new
        fall2017[:name] = "Fall-Winter 2017-2018"
        fall2017[:short_name] = "fall2017"
        fall2017[:start_date] = Date.parse("2017-10-01")
        fall2017[:end_date] = Date.parse("2018-03-10")
        fall2017[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [110, 111, 112],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "Desert Fleas", "Dates", "SuperEvil", "Desert Storm", "Sand Lizards"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [120, 121, 122, 123],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Desert Hawks", "Toasters", "Sphinx", "Desert Rats", "Mirage" 
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [130, 131],
              :rink_ids => [1, 1],
              :team_names => [
                  "Molson", "Kobra Kai", "M I T", "Kanter"
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday SM",
              :timeslot_ids => [130, 131],
              :rink_ids => [2, 2],
              :team_names => [
                  "Sotasticks", "KingFishers", "Toucans", "O'Neill's"
                ]
            },
            { :day_of_week => 3,
              :name => "Wednesday",
              :timeslot_ids => [140, 141, 142, 143],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Camels", "Desert Dogs", "Pink Cactus", "Oasis", "Road Runners", "Sahara Desert", "Suns", "Arabian Knights"
                ]
            },
            { :day_of_week => 4,
              :name => "Thursday",
              :timeslot_ids => [150, 151, 152, 153, 154, 155],
              :rink_ids => [1, 1, 1, 2, 2, 2],
              :team_names => [
                  "Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", "Geckos", "Tarantulas"
                ]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [160, 161, 162],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Lightning", "Intangibles", "Old Timers", "Otters", "Polars", "Shamrocks"
                ]
            },
            { :day_of_week => 6,
              :name => "Saturday",
              :timeslot_ids => [170, 171],
              :rink_ids => [1, 1],
              :team_names => [
                  "Gryphons", "Anubis", "Hydra", "Minotaurs"
                ]
            },
        ]
        verify_league(fall2017)

        old_seasons["fall2017"] = Hash.new
        old_seasons["fall2017"][:timeslots] = self.hand_entered_times_to_timeslots(fall2017_timeslots)
        old_seasons["fall2017"][:league_schedule] = fall2017

        spring_2017_timeslots = {
            # Spring 2017 Sunday league
            10  => {:description => "5:00pm"},
            11  => {:description => "6:15pm"},
            12  => {:description => "7:30pm"},

            # Spring 2017 Monday league
            21  => {:description => "8:15pm"},
            22  => {:description => "9:30pm"},
            23  => {:description => "10:45pm", :late_game => true},

            # Spring 2017 Tuesday leagues
            30 => {:description => "7:00pm",  :early_game => true},
            31 => {:description => "8:15pm"},
            32 => {:description => "9:30pm"},
            33 => {:description => "10:45pm", :late_game => true},
            
            # Spring 2017 Wednesday league
            40 => {:description => "7:00pm",  :early_game => true},
            41 => {:description => "8:15pm"},
            42 => {:description => "9:30pm"},
            143 => {:description => "10:45pm", :late_game => true},

            # Spring 2017 Thursday league
            50 => {:description => "7:00pm",  :early_game => true},
            51 => {:description => "8:15pm"},
            52 => {:description => "9:30pm"},
            53 => {:description => "10:45pm", :late_game => true},

            54 => {:description => "7:00pm",  :early_game => true, :overflow_day => true, :overflow_day_offset => 1},
            55 => {:description => "10:45pm", :late_game => true, :overflow_day => true, :overflow_day_offset => 1},

            # Spring 2017 Friday league
            60 => {:description => "7:00pm",  :early_game => true},
            61 => {:description => "8:15pm"},
            62 => {:description => "9:30pm"},
            63 => {:description => "10:45pm", :late_game => true},

            # Spring 2017 Saturday league
            70 => {:description => "9:00pm"},
            71 => {:description => "10:15pm"},
        }

        spring2017 = Hash.new
        spring2017[:name] = "Spring 2017"
        spring2017[:short_name] = "spring2017"
        spring2017[:start_date] = Date.parse("2017-04-01")
        spring2017[:end_date] = Date.parse("2017-09-02")
        spring2017[:leagues] = [
            { :day_of_week => 0,
              :name => "Sunday",
              :timeslot_ids => [10, 11, 12],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Night Owls", "Desert Fleas", "Dates", "SuperEvil MEGACorp", "Desert Storm", "Sand Lizards"
               ]
            },
            { :day_of_week => 1,
              :name => "Monday",
              :timeslot_ids => [21, 22, 23],
              :rink_ids => [1, 1, 1],
              :team_names => [
                  "Flying Carpets", "Blue Martini", "Desert Owls", "Desert Hawks", "Toasters", "Sphinx"
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday RWC",
              :timeslot_ids => [30, 31, 32, 33],
              :rink_ids => [1, 1, 1, 1],
              :team_names => [
                  "Molson", "Kobra Kai", "Hard to Watch", "Kanter"
                ]
            },
            { :day_of_week => 2,
              :name => "Tuesday SM",
              :timeslot_ids => [32, 33, 30, 31],
              :rink_ids => [1, 1, 1, 1],
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
              :timeslot_ids => [50, 51, 52, 53, 54, 50, 51, 52, 53, 55],
              :rink_ids => [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
              :team_names => [
                  "Desert Tribe", "Genies", "Cobras", "Sultans", "Waves", "Oasis Owls", "Desert Ravens", "Scorpions", "Danger", "Desert Foxes", 
                ]
            },
            { :day_of_week => 5,
              :name => "Friday",
              :timeslot_ids => [61, 62, 63, 60, 61, 612],
              :rink_ids => [1, 1, 1, 1, 1, 1],
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
        verify_league(spring2017)

        old_seasons["spring2017"] = Hash.new
        old_seasons["spring2017"][:timeslots] = self.hand_entered_times_to_timeslots(spring2017_timeslots)
        old_seasons["spring2017"][:league_schedule] = spring2017

    end
end

if __FILE__ == $0
    puts IceOasisLeagues.get_timeslots()
    puts ""
    puts IceOasisLeagues.get_rinks()
    puts ""
    puts IceOasisLeagues.get_ice_oasis_leagues()

end
