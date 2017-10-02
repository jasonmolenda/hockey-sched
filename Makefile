all:
	ssh molenda.us 'rm -rf molenda.us/cgi-bin/hockey-sched; mkdir molenda.us/cgi-bin/hockey-sched'
	./create-webpage.rb > /tmp/create-sched.html
	scp /tmp/create-sched.html molenda.us:molenda.us/create-sched.html
	scp ice-oasis-leagues.rb \
		create-ics-file.rb \
		timeslot-assignment.rb \
		holidays.rb \
		home-away-assignment.rb \
		team-matchups-circular.rb \
		parse-ics.rb \
		analyze-schedule.rb \
		create.cgi \
		\
		molenda.com:molenda.us/cgi-bin/hockey-sched/

