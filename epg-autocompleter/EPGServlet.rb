   require 'webrick'
   require 'webrick/accesslog'
   include WEBrick
   require 'epg.rb'

   class EPGServlet < HTTPServlet::AbstractServlet

      def do_GET(req, res)
       begin
         q = req.query["q"]
         nn = req.query["now"]
         channel = req.query["channel"]
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
           end
         else
           if(q)
             r = best_match_search(q)
             puts "best match search for #{q}"
           else
             puts "no suitable query"
           end
         end

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
               s="#{s}
#{ti}: #{ch}: #{ff}: #{pid}: #{cr}|#{st}|#{ch}"
             end
             res.body = s
         end
       rescue Exception=>e
          puts e.inspect
          puts e.backtrace
       end

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


