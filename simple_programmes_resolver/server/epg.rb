require 'rubygems'
require 'json/pure'
require 'net/http'
require 'uri'
gem 'dbi'
require "dbi"
gem 'dbd-mysql'
require 'pp'
#require 'classify'
require 'rubygems'
#require 'riddle'
require 'pp'

def connect_to_mysql()
        return DBI.connect('DBI:Mysql:epgs', 'user', 'pass')
end

# what's on now on a channel
def on_now_exact(channel)
       arr = []

       q0 = "select distinct title,crid,channel,start from todays_epg where channel=? and start < (NOW()) && end > (NOW()) order by chan_num;"
#tz+1       q0 = "select title,crid,channel,start from todays_epg where channel=? and start < (NOW() + INTERVAL 1 HOUR) && end > (NOW() + INTERVAL 1 HOUR) order by chan_num;"
       puts q0

       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute(channel)
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[3].to_s})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end

# what's on now on a channel
def on_now(channel)
       arr = []

       q0="select distinct todays_epg.title,crid,channel,todays_epg.start,pid 
from todays_epg left join pid_data on (todays_epg.start = pid_data.start 
and todays_epg.channel = pid_data.dvb_service_title) where channel like 
'%#{channel}%' and todays_epg.start < NOW() && todays_epg.end > NOW() 
order by chan_num;"

       puts q0

       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute()
#       sth.execute(channel)
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[3].to_s,'pid'=>row[4].to_s})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end



##pid

# what's on now on a channel
def pid_on_now(channel)
       arr = []

       q0="select distinct pid 
from todays_epg left join pid_data on (todays_epg.start = pid_data.start 
and todays_epg.channel = pid_data.dvb_service_title) where service like 
'%#{channel}%' and todays_epg.start < NOW() && todays_epg.end > NOW() 
order by chan_num;"

       puts q0

       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute()
       pid=""
       sth.fetch do |row|
          pid = row[0]
       end
       sth.finish
       dbh.disconnect
       return pid
end


# what's on now on a channel
def on_now_multiple(channels_str)
       arr = []
       arr3 = []
       arr2 = []

       arr3 = channels_str.split(",")
       arr3.each do |a|
         str = "pid_data.service = '#{a}'"
         arr2.push(str)
       end
       ss = arr2.join(" or ")
       q0="select distinct todays_epg.title,crid,channel,todays_epg.start,pid, service,description  
from todays_epg left join pid_data on (todays_epg.start = pid_data.start 
and todays_epg.channel = pid_data.dvb_service_title) where (#{ss}) and todays_epg.start < NOW() && todays_epg.end > NOW() 
order by chan_num;"

       puts q0

       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute()
#       sth.execute(channel)
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'service'=>row[2],'start'=>row[3].to_s,'pid'=>row[4].to_s,'channel'=>row[5].to_s,"description"=>row[6].to_s})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end



# what's on now given a search string
def on_now_search(str)
       arr = []
#tz+1       q0 = "select title,crid,channel,start from todays_epg where match(title) against (?)  and start < NOW() + INTERVAL 1 HOUR  && end > NOW() + INTERVAL 1 HOUR order by chan_num;"

       q0 = "select distinct title,crid,channel,start from todays_epg 
where match(title) against (?)  and start < NOW() && end > NOW() order 
by chan_num;"

       puts q0
       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute(str)
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[3].to_s})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end

def best_match_search(str)
       arr = []
#      q0 = "select title,crid,channel,start, TIMEDIFF(start, NOW() + INTERVAL 1 HOUR) as foo,start from todays_epg where match(title) against (?) order by foo desc limit 10;"

##best       q0 = "select title,crid,channel,ABS(TIMEDIFF(NOW(), start)) as foo,start from todays_epg where start > NOW() and match(title) against (?) order by foo, chan_num limit 10;"

##with pids

       q0="select distinct 
todays_epg.title,crid,channel,ABS(TIMEDIFF(NOW(), todays_epg.start)) as 
foo,todays_epg.start,pid from todays_epg left join pid_data on 
(todays_epg.start = pid_data.start and todays_epg.channel = 
pid_data.dvb_service_title) where match(todays_epg.title) against (?) 
order by foo, chan_num limit 10;";

##for tz+1
##       q0 = "select title,crid,channel,ABS(TIMEDIFF(NOW() + INTERVAL 1 HOUR , start)) as foo,start from todays_epg where start > NOW() + INTERVAL 1 HOUR and match(title) against (?) order by foo, chan_num limit 10;"
# abs gives younones in the past too
#      q0 = "select title,crid,channel,ABS(TIMEDIFF(NOW() + INTERVAL 1 HOUR , start)) as foo from todays_epg where match(title) against (?) order by chan_num, foo limit 10;"
       puts q0
       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute(str)
       sth.fetch do |row|
#          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[4].to_s,"foo"=>row[3].to_s})
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[4].to_s,'pid'=>row[5]})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end


def desc_best_match_search(str)
       arr = []

##with pids

       q0="select distinct todays_epg.title,crid,channel,ABS(TIMEDIFF(NOW(), 
todays_epg.start)) as foo,todays_epg.start,pid,todays_epg.description from todays_epg left join 
pid_data on (todays_epg.start = pid_data.start and todays_epg.channel = 
pid_data.dvb_service_title) where match(todays_epg.title,todays_epg.description) against (?) 
order by foo, chan_num limit 10;";

       puts q0
       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute(str)
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[4].to_s,'pid'=>row[5],'description'=>row[6]})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end



# search given channel and time
def search_for(channel,ti)
       arr = []

       q0 = "select distinct todays_epg.title,crid,channel,todays_epg.start,description,pid from todays_epg left join pid_data on (todays_epg.start = pid_data.start and todays_epg.channel = pid_data.dvb_service_title) where channel=? and todays_epg.start= ?;"

       puts q0
       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute(channel,ti)
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[3].to_s,'description'=>row[4].to_s,'pid'=>row[5].to_s})
       end
       sth.finish
       dbh.disconnect
       pp arr
       return arr
end


#best_match_search("news")
#on_now_search("news")
#on_now("BBC ONE")

