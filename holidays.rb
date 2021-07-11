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

            "2019-01-01",  # new year's
            "2019-05-27",  # memorial day
            "2019-07-04",  # 4th of july
            "2019-09-02",  # labor day
            "2019-11-28",  # thanksgiving
            "2019-11-29",  # thanksgiving
            "2019-12-23",  # xmas break
            "2019-12-24",  # xmas break
            "2019-12-25",  # xmas break
            "2019-12-26",  # xmas break
            "2019-12-27",  # xmas break
            "2019-12-28",  # xmas break
            "2019-12-29",  # xmas break
            "2019-12-30",  # xmas break
            "2019-12-31",  # xmas break

            "2020-01-01",  # new year's
            "2020-05-25",  # memorial day
            "2020-07-04",  # 4th of july
            "2020-09-07",  # labor day
            "2020-11-26",  # thanksgiving
            "2020-11-27",  # day after thanksgiving
            "2020-12-24",  # xmas break
            "2020-12-25",  # xmas break
            "2020-12-26",  # xmas break
            "2020-12-27",  # xmas break
            "2020-12-28",  # xmas break
            "2020-12-29",  # xmas break
            "2020-12-30",  # xmas break
            "2020-12-31",  # xmas break

            "2021-01-01",  # new year's
            "2021-05-31",  # memorial day
            "2021-07-04",  # 4th of july
            "2021-09-04",  # labor day
            "2021-09-06",  # labor day
            "2021-11-25",  # thanksgiving
            "2021-11-26",  # day after thanksgiving
            "2021-12-24",  # xmas break
            "2021-12-25",  # xmas break
            "2021-12-26",  # xmas break
            "2021-12-27",  # xmas break
            "2021-12-28",  # xmas break
            "2021-12-29",  # xmas break
            "2021-12-30",  # xmas break
            "2021-12-31",  # xmas break

            "2022-01-01",  # new year's
            "2021-05-30",  # memorial day
            "2021-07-04",  # 4th of july
            "2021-09-05",  # labor day
            "2021-11-24",  # thanksgiving
            "2021-11-25",  # day after thanksgiving
            "2021-12-24",  # xmas break
            "2021-12-25",  # xmas break
            "2021-12-26",  # xmas break
            "2021-12-27",  # xmas break
            "2021-12-28",  # xmas break
            "2021-12-29",  # xmas break
            "2021-12-30",  # xmas break
            "2021-12-31",  # xmas break

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
