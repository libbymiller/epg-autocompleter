drop table if exists todays_epg;

create table todays_epg(crid varchar(64),dvb varchar(128),start
datetime,end datetime,chan_num varchar(10),channel varchar(20),title
varchar(128),subtitle varchar(128),description text);

load data local infile '/home/tvdata/latest_data.txt' into table
todays_epg fields terminated by '|'
(crid,dvb,start,end,chan_num,channel,title,subtitle,description);

create fulltext index t on todays_epg (title);
create fulltext index td on todays_epg (title,description);

delete from pid_data;

