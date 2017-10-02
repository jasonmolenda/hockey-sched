# hockey-sched
A set of scripts to create a hockey league game schedule.  This is so specific to the one league/rink I threw it together for, 
it won't be of use to anyone else.  And the code is just thrown together, I'm not taking the time to write it nicely.  It's only
on github so it's under version control.

# File Organization

The scheduler is broken apart into discrete programs to introduce API boundaries between them, make it easy to test individual components, and to have multiple implementations of a part & switch between them.  Most of these programs can be run from the command line and it will run a test data set through its algorithm and print a simple summary.  It's an easy way to test each component separately and debug as you go along.

### create.cgi / create.rb

The top level program that creates an ice oasis game schedule for a specific league.  The `.cgi` program is the one that is run on the web sever; `.rb` is equivalent but for running from the command line with simple text output.

`create` uses the following modules:

`ice-oasis-leagues.rb` provides the information about the leagues.  The current season start & end date, the number of teams, the game times, the rink locations, the team names.

`holidays.rb` provides the holidays which need to be skipped when scheduling games.

`team-matchups-circular.rb` takes the `schedule` object that `create` set up and decides which teams will be play which other teams in every game slot for the season.  It will put the team with a bye in a separate bye slot.  For certain # of teams, having the same pattern of teams facing each other over & over throughout the season can result in dramatically unbalanced time schedules.  For those leagues, `team-matchups-circular.rb` will play the teams in different order each set of games.  (for a 6 team league, a set of games takes 5 weeks to complete, where each team has played each other team once.)

`timeslot-assignment.rb` is the second pass when filling out a `schedule`.  It looks at the team matchups that have been scheduled and assigns the team pairs to timeslots.  It has a scoring scheme so that teams will avoid having back to back late games, or play too many games in one specific slot.  It isn't perfect - sometimes near the end of a season you'll have two teams playing each other, team A and team B, and team A has already had all the late games it should have this season but team B is deficient on late games; it can be difficult to find a great solution to this.  The scoring system specifically tries to avoid back to back late games, it tries to avoid back to back early games, and has a slight preference against back to back other timeslots.

`home-away-assignment.rb` the third pass, a simple one which determines which of the teams will be home versus away.  Currently based only on which of the teampair has fewer home games.

`create-ics-file.rb` once the `schedule` internal object has been completed, `create-ics-file.rb` is called to create an iCal file which can be uploaded to google calendar or imported into a mac calendar app.

`parse-ics.rb` parses an iCal file back into a `schedule` object as best it can, for analysis.  We want to analyze the `.ics` file that we generated as that's what everyone will actually be seeing.

`analyze-schedule.rb` generates a text report (html or plain text) of the schedule, pointing out how many times each team has played each other, how many times they play in each timeslot, how many late/early games they have, how many back to back timeslots / opponents they have.  This is the phase where a human can spot a bad schedule and debug / regenerate as necessary.

### other files

The most important among the other files is `create-webpage.rb`.  It reads the current season information from `ice-oasis-leagues.rb` and creates a web page detailing what is going into each league and giving a link to run `create.cgi` from the webserver.

The remaining files `test.rb`, `test-ics.rb`, `simple-schedule-analysis.rb`, `create-simple-empty-schedule.rb`, were mainly for early testing and I may remove them at some point.  They are not necessary at this point.




# Data Structures

The schedule is built up in stages by separate ruby modules.  They all contribute to/use a data structure.  

## schedule

`schedule` is a `Hash`.  It has the following entries:

`:teamcount` => integer number of teams

`:weekcount` => integer number of weeks

`:gamecount` => integer number of games played each week (assume we lpay the same # of games every week)

`:rinkcount` => integer number of different rinks this league plays at (usually 1)

`:timeslots` => `Hash` of descriptions of all the timeslots seen in this schedule (may include additional timeslots).  Keys in this hash are the `timeslot_id`s, values are the attributes & descriptions of those `timeslot_id`s.

`:rinks` => `Hash` of descriptions of all the rinks seen in this schedule (may include additional rink descriptions).  Keys in this hash are the `rink_id`s, values are the attributes and description of those `rink_id`s.

`:team_names` *[optional]* Only guaranteed to be present when analyzing an existing schedule, so we can show human-readable names for the analysis report.

`:weeks` => An `Array`, one element per week, 0-based (size of `:weeks` array is `:weekcount`).  Each element of the array is a `Hash`.  The hash has two keys:

### :weeks array entries

`:bye` => If this schedule / week has a bye team, this is the team # that has the bye this week. If no bye this week, this will have a nil value.

`:team_matchups` => An array (`:gamecount` large, 0-based) of teams that are playing each other this week.  Each element of this 

`:gamecount` array is a 2-elem Array of team numbers. This structure is used before timeslots are assigned -- the array is in no particular order.  The order of the teams in each element is not significant; home and away have not yet been set.

`:date` *[optional]*  Date object of this week's date.  Only present when analyzing an existing schedule with dates in it.  If a league has games on the main day and an alternate day, this will be the main day's Date.

`:games` => An  `Array`, 0-based, the size of the array is the number of games played that week.  Each entry in this games array is a `Hash`.  It has these entries:

### :games array entries

`:teampair` => An array of two team numbers playing in this timeslot.  Home and away have not yet been assigned for this data structure; the order of the team numbers is not significant.

`:home` => If this key is present, it has the team # of the home team. (early in the schedule process this may not yet be assigned)

`:away` => If this key is present, it has the team # of the away team. (early in the schedule process this may not yet be assigned)

`:timeslot_id` => the `timeslot_id` of this game.

`:rink_id` => the `rink_id` of this game.

`:datetime` => *[optional]* The time and date of the start of this game.  This field will only appear when analyzing an existing schedule, and may be useful for distinguishing games that are played on the primary day for the league versus an alternate overflow day.


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