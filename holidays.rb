#! /usr/bin/ruby
require 'date'
require 'set'

module HolidayDates

    # provides a Set of holidays where games should not be scheduled.
    # The objects in the set are Date objects of the holidays, for
    # simple testing.
    def self.get_holiday_schedule ()
        holidays = [
            "2017-01-01",  # new year's 
            "2017-05-29",  # memorial day
            "2017-07-04",  # 4th of july
            "2017-09-04",  # labor day
            "2017-11-23",  # thanksgiving
            "2017-11-24",  # day after thanksgiving
            "2017-12-23",  # xmas break
            "2017-12-24",  # xmas break
            "2017-12-25",  # xmas break
            "2017-12-26",  # xmas break
            "2017-12-27",  # xmas break
            "2017-12-28",  # xmas break
            "2017-12-29",  # xmas break
            "2017-12-30",  # xmas break
            "2017-12-31",  # xmas break

            "2018-01-01",  # new year's
            "2018-05-28",  # memorial day
            "2018-07-04",  # 4th of july
            "2018-09-03",  # labor day
            "2018-11-22",  # thanksgiving day
            "2018-11-23",  # day after thanksgiving day
            "2018-12-24",  # xmas break
            "2018-12-25",  # xmas break
            "2018-12-26",  # xmas break
            "2018-12-27",  # xmas break
            "2018-12-28",  # xmas break
            "2018-12-29",  # xmas break
            "2018-12-30",  # xmas break
            "2018-12-31",  # xmas break
        ]

        return holidays.map {|h| Date.parse(h)}.to_set
    end
end

if __FILE__ == $0
    holidays = HolidayDates.get_holiday_schedule()
    holidays.sort.each do |date|
        puts date
    end
end