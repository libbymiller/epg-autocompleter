require 'rubygems'
require 'json/pure'
require 'net/http'
require 'uri'
gem 'dbi'
require "dbi"
gem 'dbd-mysql'
require 'pp'
require 'rubygems'
require 'pp'

def connect_to_mysql()
        return DBI.connect('DBI:Mysql:epgs', 'user', 'pass')
end

# what's on now on a channel
def on_now_exact(channel)
       arr = []

       q0 = "select distinct title,crid,channel,start from todays_epg 
where channel=? and start < (NOW()) && end > (NOW()) order by chan_num;"

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
       sth.fetch do |row|
          arr.push({'title'=>row[0],'crid'=>row[1],'channel'=>row[2],'start'=>row[3].to_s,'pid'=>row[4].to_s})
       end
       sth.finish
       dbh.disconnect
       #pp arr
       return arr
end


# what's on now given a search string
def on_now_search(str)
       arr = []

       q0 = "select distinct title,crid,channel,start from todays_epg 
where match(title) against (?)  and start < NOW() && end > NOW() order 
by chan_num;"

#tz+1       q0 = "select title,crid,channel,start from todays_epg where match(title) against (?)  and start < NOW() + INTERVAL 1 HOUR  && end > NOW() + INTERVAL 1 HOUR order by chan_num;"

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
       q0="select distinct todays_epg.title,crid,channel,ABS(TIMEDIFF(NOW(), todays_epg.start)) as foo,todays_epg.start,pid from todays_epg left join pid_data on (todays_epg.start = pid_data.start and todays_epg.channel = pid_data.dvb_service_title) where match(todays_epg.title) against (?) order by foo, chan_num limit 10;";
       puts q0
       dbh = connect_to_mysql()
       sth = dbh.prepare(q0)
       sth.execute(str)
       sth.fetch do |row|
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

