   require 'rubygems'
   require 'json/pure'
   require 'uri'
   require 'time'
   require 'open-uri'
   require 'net/http'
   require 'date'
   require 'pp'
   require 'cgi'
   gem 'dbi'
   require "dbi"
   gem 'dbd-mysql'


# Creates a list of schedule urls
   def get_urls_to_retrieve(d1)
              urls = {}

              if (d1==nil || d1 =="")
                 t = DateTime.now
                 d = t.strftime("%Y/%m/%d")
              else
                 d = d1
              end
              pt1 = "http://www.bbc.co.uk/"
              pt2 = "/programmes/schedules/"

              channel = "bbcone"
              url = "#{pt1}#{channel}#{pt2}london/#{d}.json"
              urls[channel]=url

              channel = "bbctwo"
              url = "#{pt1}#{channel}#{pt2}england/#{d}.json"
              urls[channel]=url

              channel = "bbcthree"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "bbcfour"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "bbchd"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "cbeebies"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "cbbc"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "parliament"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "bbcnews"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel = "radio4"
              url = "#{pt1}#{channel}#{pt2}fm/#{d}.json"
              urls[channel]=url

              channel = "radio1"
              url = "#{pt1}#{channel}#{pt2}england/#{d}.json"
              urls[channel]=url

              channel =  "1xtra"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "radio7"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "radio2"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "radio3"
              urls[channel]=url
              url = "#{pt1}#{channel}#{pt2}#{d}.json"

              channel = "5live" 
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "5livesportsextra"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "6music"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "asiannetwork"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              channel =  "worldservice"
              url = "#{pt1}#{channel}#{pt2}#{d}.json"
              urls[channel]=url

              return urls
   end

# get a json schedule url, first checking the cache, and parsing the json
   def get_u(url,channel,d,fmt)

           cache = checkChannelCache(channel, d,fmt)
           cache_url = generateChannelCacheFN(channel, d,fmt)
           if(cache)
              puts "found cache url #{cache_url}"
           else
              puts "no cache found for #{d} #{channel}"
           end

           data = nil
           if(!cache)
              useragent = "NotubeMiniCrawler/0.1"
              u =  URI.parse url  
              req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
              begin    
                res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
                data = res2.body
                puts data #...
              rescue Timeout::Error=>e
                puts "uri error #{e}"
              end
           else
              data = File.read(cache_url)
           end
           
           j = nil
           begin
                 j = JSON.parse(data)

                 fn = cache_url
                 aFile = File.new(fn, "w")
                 aFile.write(data)
                 aFile.close

           rescue JSON::ParserError=>e
                 puts "Error #{url} "+e.to_s
           rescue OpenURI::HTTPError=>e
                 case e.to_s        
                    when /^404/
                       raise 'Not Found'
                    when /^304/
                       raise 'No Info'
                    end
           end
           return j
   end


# Get the url and process it
   def get_urls(url,channel,d,fmt)

           j = get_u(url,channel,d,fmt)
           txt = ""
           arr2 = Array.new
           pids = Array.new
           if(j)
             service=j["schedule"]["service"]["key"]
             serviceTitle=j["schedule"]["service"]["title"]
             arr = j["schedule"]["day"]["broadcasts"]
             arr.each do |x|
                  pid = x["programme"]["pid"]
                  tt1 = x["programme"]["display_titles"]["title"]
                  tt2 = x["programme"]["display_titles"]["subtitle"]
                  pidTitle = "#{tt1}: #{tt2}"
                  # fix up &amps;
                  pidTitle.gsub!("&","&amp;")
                  startd = x["start"]
                  endd = x["end"]
                  #puts ".. #{startd} ,, #{d} ''"
                  if (startd.match(d))
                    pids.push(pid)
                    service_name = get_service_name(service)
                    arr2.push({"pid"=>pid,"displayTitle"=>pidTitle,"startd"=>startd,"endd"=>endd,"service"=>service,"serviceTitle"=>serviceTitle,"DVBServiceName"=>service_name})
                  end
             end
           end
           return arr2,pids
   end

# hardcoded mapping for DVB EIT names

   def get_service_name(service)
     names={
       "cbbc"=>"CBBC Channel",
       "cbeebies"=>"CBeebies",
       "bbctwo"=>"BBC TWO",
       "bbcone"=>"BBC ONE",
       "worldservice"=>"BBC World Sv.",
       "parliament"=>"BBC Parliament",
       "6music"=>"BBC 6 Music",
       "radio1"=>"BBC Radio 1",
       "bbcnews"=>"BBC NEWS",
       "5live"=>"BBC R5L",
       "radio2"=>"BBC Radio 2",
       "5livesportsextra"=>"BBC R5SX",
       "radio4"=>"BBC Radio 4",
       "bbcfour"=>"BBC FOUR",
       "bbchd"=>"BBC HD",
       "bbcthree"=>"BBC THREE",
       "asiannetwork"=>"BBC Asian Net.",
       "radio7"=>"BBC Radio 7",
       "radio3"=>"BBC Radio 3"
     }
     n = names[service]
     if(n)
       return n
     else
       return nil
     end
   end


# save (for cache)

   def save(dir, data, filename)
            FileUtils.mkdir_p dir
            fn = dir+"/"+filename 
            puts fn
            open(fn, 'w') { |f|
              f.puts data
              f.close
            }
   end


# utility methods

# generate a cache filename

   def generatePidCacheFN(pid,fmt)
      return "cache/#{pid}.#{fmt}"
   end


   def generateChannelCacheFN(channel, dt,fmt)
      return "cache/#{channel}#{dt}.#{fmt}"
   end

   def checkChannelCache(channel, dt,fmt)
        puts "checking cache"
        fn = generateChannelCacheFN(channel, dt,fmt)
        ex = FileTest.exists?(fn)
        puts "#{fn} exists? #{ex}"
        return ex
   end

   def checkPidCache(pid, fmt)
        puts "checking cache"
        fn = generatePidCacheFN(pid,fmt)
        ex = FileTest.exists?(fn)
        puts "#{fn} exists? #{ex}"
        return ex
   end


   def connect_to_mysql()
        puts "\nConnecting to MySQL..."
        # hardcoded!
        return DBI.connect('DBI:Mysql:epgs', 'user', 'pass')
   end


# main stuff begins here

   begin
     
     urls =  get_urls_to_retrieve(nil)

     #pp urls

     arrs = Array.new
     allprogs = Array.new

     t = DateTime.now
     d = t.strftime("%Y-%m-%d") #today

# for each channel json url, get it, stash it, and wait 2 secs before 
# the next one checking the cache as we go
   
     urls.each do |channel,u|
        arr,pids = get_urls(u,channel,d,"json")
        puts "sleeping 2 #{u} ... #{arr.class}"
        sleep 2
        arrs.push(pids)
        allprogs.push(arr)
     end

     #insert into database

     dbh = connect_to_mysql()

     sth = dbh.prepare("insert into pid_data values (?,?,?,?,?,?,?)")
     allprogs.each do |a|
       a.each do |ar|
         pid = ar["pid"]
         pT = ar["displayTitle"]
         s = ar["startd"]
         e = ar["endd"]
         se = ar["service"]
         sT = ar["serviceTitle"]
         sD = ar["DVBServiceName"]
         sth.execute(pid,pT,s,e,se,sT,sD)
       end
     end
     sth.finish
     dbh.disconnect

     allpids = arrs.flatten
     save("crawler/#{d.to_s}", allpids,"pids.txt")     

   end
