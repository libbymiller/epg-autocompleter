   require 'webrick'
   require 'webrick/accesslog'
   include WEBrick

   class EPGServlet < HTTPServlet::AbstractServlet

      def do_OPTIONS(req, res)
# Specify domains from which requests are allowed
        res["Access-Control-Allow-Origin"]="*"

# Specify which request methods are allowed
        res["Access-Control-Allow-Methods"] = "GET, POST"

# Additional headers which may be sent along with the CORS request
# The X-Requested-With header allows jQuery requests to go through
        res["Access-Control-Allow-Headers"]="X-Requested-With, Origin"

# Set the age to 1 day to improve speed/caching.
        res["Access-Control-Max-Age"]="86400"
        res.body=""
        res.status = 200

      end
      def do_POST(req, res)
        return do_GET(req, res)
      end
      def do_GET(req, res)
       begin
         q = req.query["q"]
         nn = req.query["now"]
         channel = req.query["channel"]
         random = req.query["random"]
         fmt = req.query["fmt"]
         if fmt == nil || fmt == ""
           fmt = "txt"
         end

#best_match_search("news")
#on_now_search("news")
#on_now("BBC ONE")

         r = []
         if(nn)
           if(q)
             puts "on now query for string #{q}"
             r = on_now_search(q)
           elsif(channel)
             puts "on now query for channel #{channel}"
             r = on_now(channel)
           elsif(random)
             puts "on now service"
             channels = ["bbcone","bbctwo","bbcthree","bbcnews",
"bbcfour","parliament","5live","6music","radio7",
"asiannetwork","worldservice","radio1","radio2","radio4"]

             ra = 1+rand(13)
             ra1 = 1+rand(13)
             ra2 = 1+rand(13)
             multiple = channels[ra]+","+channels[ra1]+","+channels[ra2] 
             puts multiple
             r = on_now_multiple(multiple)
           end
         else
           if(q)
             r = best_match_search(q)
             puts "best match search for #{q}"
           else
             puts "no suitable query"
           end
         end
         puts r.class

         if (fmt =="html")
             res['Content-Type'] = 'text/html'
             res.body = r.to_s
         elsif (fmt=="json")
             res['Content-Type'] = 'text/javascript'
             res.body = "search_results("+JSON.pretty_generate(r)+")"
         elsif (fmt=="js")
             res['Content-Type'] = 'text/javascript'
             res.body = JSON.pretty_generate(r)
         elsif (fmt=="txt")
             res['Content-Type'] = 'text/plain'
             s=""
             r.each do |t|
               ti = t["title"]
               ch = t["channel"]
               cr = t["crid"]
               st = t["start"]
               f = Time.parse(st)
               ff = f.strftime("%I:%M%p")
               ff.gsub!(/^0/,"")
               pid = t["pid"]
               if(pid && pid!="")
                 pid="http://www.bbc.co.uk/programmes/#{pid}"
               end
               s="#{s}
#{ti}, #{ch}, #{ff}, #{pid} #{cr}|#{st}|#{ch}"
             end
             res.body = s
         end
       rescue Exception=>e
          puts e.inspect
          puts e.backtrace
       end
# Specify domains from which requests are allowed
       res["Access-Control-Allow-Origin"]="*"

# Specify which request methods are allowed
       res["Access-Control-Allow-Methods"] = "GET, POST"

# Additional headers which may be sent along with the CORS request
# The X-Requested-With header allows jQuery requests to go through
       res["Access-Control-Allow-Headers"]="X-Requested-With, Origin"

# Set the age to 1 day to improve speed/caching.
       res["Access-Control-Max-Age"]="86400"

      end

      # cf. http://www.hiveminds.co.uk/node/244, published under the
      # GNU Free Documentation License, http://www.gnu.org/copyleft/fdl.html

      @@instance = nil
      @@instance_creation_mutex = Mutex.new


      def EPGServlet.get_instance( config, *options )
         load __FILE__
         EPGServlet.new config, *options
      end

      def self.get_instance(config, *options)
         #pp @@instance
         @@instance_creation_mutex.synchronize {
            @@instance = @@instance || self.new(config, *options) }
      end

   end


