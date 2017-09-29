# hockey-sched
A set of scripts to create a hockey league game schedule.  This is so specific to the one league/rink I threw it together for, 
it won't be of use to anyone else.  And the code is just thrown together, I'm not taking the time to write it nicely.  It's only
on github so it's under version control.

## data structures

The schedule is built up in stages by separate ruby modules.  They all contribute to/use a data structure.  

# schedule

`schedule` is a `Hash`.  It has the following entries:

`:teamcount` => integer number of teams

`:weekcount` => integer number of weeks

`:gamecount` => integer number of games played each week (assume we lpay the same # of games every week)

`:rinkcount` => integer number of different rinks this league plays at (usually 1)

`:timeslots` => `Hash` of descriptions of all the timeslots seen in this schedule (may include additional timeslots).  Keys in this hash are the `timeslot_id`s, values are the attributes & descriptions of those `timeslot_id`s.

`:rinks` => `Hash` of descriptions of all the rinks seen in this schedule (may include additional rink descriptions).  Keys in this hash are the `rink_id`s, values are the attributes and description of those `rink_id`s.

`:weeks` => An `Array`, one element per week, 0-based (size of `:weeks` array is `:weekcount`).  Each element of the array is a `Hash`.  The hash has two keys:

### :weeks array entries

`:bye` => If this schedule / week has a bye team, this is the team # that has the bye this week. If no bye this week, this will have a nil value.

`:team_matchups` => An array (`:gamecount` large, 0-based) of teams that are playing each other this week.  Each element of this `:gamecount` array is a 2-elem Array of team numbers. This structure is used before timeslots are assigned -- the array is in no particular order.  The order of the teams in each element is not significant; home and away have not yet been set.

`:games` => An  `Array`, 0-based, the size of the array is the number of games played that week.  Each entry in this games array is a `Hash`.  It has these entries:

### :games array entries

`:teampair` => An array of two team numbers playing in this timeslot.  Home and away have not yet been assigned for this data structure; the order of the team numbers is not significant.

`:home` => If this key is present, it has the team # of the home team. (early in the schedule process this may not yet be assigned)

`:away` => If this key is present, it has the team # of the away team. (early in the schedule process this may not yet be assigned)

`:timeslot_id` => the `timeslot_id` of this game.

`:rink_id` => the `rink_id` of this game.


### timeslots hash

The keys are `timeslot_id`s, the values are a hash with these keys:

`:hour` => hour (24-hour format) of the start time of this timeslot.

`:minute` => minute of the start time of this timeslot.

`:late_game` => boolean, true if this is an inconveniently late game timeslot.

`:early_game` => boolean, true if this is an inconveniently early game timeslot.

`:alternate_day` => boolean, true if this timeslot is on an alternate day.  e.g. a Thursday league that may schedule one game on Friday each week.  Should space out the Friday games in this case.

`:description` => textual description, used mostly for debugging

### :rinks hash

The keys are `rink_id`s, the values are a hash with these keys:

`:short_name` => The short name of the rink, for including in calendar titles.

`:long_name` => Longer name of the rink.

`:address` => Address of the rink for including as a Location entry in calendar entries.