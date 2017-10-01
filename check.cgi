#! /usr/bin/ruby
require 'open-uri'
require 'cgi'

$LOAD_PATH << File.dirname(__FILE__)

require 'parse-ics'
require 'analyze-schedule'

cgi = CGI.new
puts "Content-type: text/plain; charset=iso-8859-1"
puts ""

if !cgi.has_key?("url")
    puts "<html><body>"
    puts "ERROR: Could not find url to check"
    puts "</body></html>"
    exit true
end

if cgi.has_key?("url")
    url = cgi["url"]

    fake_user_agent="Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1"
    ics_text = Array.new
    if url =~ /^http:\/\/www.google.com/
        url.gsub!(/^http:\/\//, "https://")
    end
    open(url, "User-Agent" => fake_user_agent).read.each_line do |l|
        ics_text.push(l.strip)
    end

    schedule = ParseICS.ics_to_schedule(ics_text)

    puts "<html><body>"
    puts "<pre>"
    AnalyzeSchedule.analyze_schedule(schedule, true)
    puts "</pre>"
    puts "</body></html>"
end
