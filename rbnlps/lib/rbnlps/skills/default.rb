$: << File.expand_path("#{File.dirname(__FILE__)}/../..")

Notify = Struct.new(:message, :image, :time) do
  def self.send msg, image: nil, time: nil
    ins = new(msg, image, time)
    ins.send
    ins
  end
  
  def send
    `notify-send #{image ? "-i "+image+" " : ''}"#{message}"`
  end
end

require 'rbnlps/skills/playback'


module RbNLPS
  class SaySkill < Skill
    def initialize
      super({
        name: 'say'
      })
      
      intent "/say/:message" do |params, resp|
        say t="#{params[:message]}"
        
        resp[:status] = :OK
        resp[:speak] = t
      end
    end
    
    self
  end.new

  class BroadcastSkill < Skill
    @desc = "Broadcast a message"
    def initialize
      super({
        name: 'broadcast'
      })
      
      intent "/broadcast/:message" do |params, resp|
        Remote.devices.each do |d|
          `curl -d "say #{params[:message]}" http://#{d.addr}:4567/spoke`
          resp[:status] = :OK
        end
      end
    end
    
    self
  end.new
  
  class MyIP < Skill
    @desc = "List local and public IP addresses"
    def initialize
      super name: 'myip'
    
      intent "/update/ip" do |params, resp={}|
        self.class.resolve
      end
    
      intent "/what/is/my/ip" do |params, resp={}|
        self.class.resolve
        
        l=self.class.local
        p=self.class.public
        
        say("Local i p is, "+l.gsub(".", " dot "))
        say("Public i p is, #{p.gsub(".", " dot ")}")
        
        resp[:ip] = {
          local:  l,
          public: p
        }
      end
    end
    
    def self.resolve
      @local  = `ip addr show | grep "inet "`.strip.split("\n").find do |l| l !~ / lo/ end.split(" ")[1].split("/")[0]
      @public = `dig +short myip.opendns.com @resolver1.opendns.com`.strip
    end
    
    def self.public; @public; end
    def self.local;  @local; end
    
    Thread.new do 
      resolve
      loop do; sleep 60*3; resolve; end
    end
    
    self
  end.new
  
  class Remote < Skill
    attr_reader :addr
    def initialize
      super name: 'remote',
            addr: @addr = MyIP.local
      
      intent "/:blank/on/:remote", remote: @name do |params, resp={}|
        puts `curl -d "#{params[:blank]}" http://#{addr}:4567/spoke`
      end
      
      [:stop, :pause, :resume].each do |m|
        intent "/#{m}/:name", name: @name do |params, resp={}|
          puts `curl -d "#{m}" http://#{addr}:4567/spoke`
        end
      end
      
      self.class.devices << self
    end
    
    def self.devices; @devices ||= []; end
    
    self
  end.new
end

module RbNLPS
  class Timer < Skill
    @rate = 0.33
    
    def self.queue; @queue ||= []; end
   
    @t = Thread.new do
      loop do
        sleep @rate
        
        queue.find_all do |e|
          e[:next] <= Time.now.to_f
        end.each do |e|
          if !e[:repeat]
            @queue.delete(e)
          else
            e[:next] += e[:interval]
          end

          Thread.new do 
            `curl -d "#{e[:action]}" #{MyIP.local}:4567/spoke`
          end
        end
      end
    end

    def initialize *o
      super
      
      if self.class == Timer
        intent "/set/a/timer/for/:length/:units" do |params, resp={}|
          add params
        end

        intent "/every/:length/:units/:action" do |params, resp={}|
          params[:repeat] = true
          add params
        end
      
        intent "/kill/timers" do |params, resp={}|
          Timer.kill_all; Timer.kill_all
        end
      end
    end
    
    def add params={}
      i = params[:length].to_f
      case params[:units]
      when /second/
        i = i * 1.0
      when /minute/
        i = i * 60
      when /hour/
        i = i * 60 * 60
      else
        return nil
      end
    
      t = {
        action: params[:action], 
        next: (params[:next] || Time.now.to_f+(i)),  
        interval: i,
        repeat: params[:repeat]
      }
   
      Timer.queue << t
    end
    
    def self.kill t;   @queue.delete(t); end
    def self.kill_all; @queue.each do |t| kill t end; end
    
    new name: 'timer'
  end

  class Alarm < Timer
    def initialize *o
      super
      
      intent "/set/an/alarm/for/:time" do |params, resp={}|
        params[:action] = "play alarm"
        alarm params,resp
      end
      
      intent "/:action/ at/:time", priority: 100 do |params, resp={}|
        alarm params,resp
      end
      
      intent "/play/alarm" do |params, resp={}|
        `curl -d "play *amm*webm from local" http://#{MyIP.local}:4567/spoke`
      end
    end
    
    def alarm params,resp={}
      t=params[:time]
      t = t.gsub(" : ", ":").gsub(" . ", '').gsub(" .", '')
      
      if t =~ /(.*)(am|pm)/
        t = $1.strip
        m = $2.strip

        hrs, mins = t.split(":").map do |q| q.to_i end

        if m == "pm"
          hrs = hrs + 12 unless hrs == 12
        end
        
        if m == "am"
          hrs = 0 if hrs == 12
        end
        
        tn = Time.now
        if (t = Time.local(tn.year, tn.month, tn.day, hrs, mins)) < tn
          tn = Time.now+(24*60*60)
        end
        
        t = Time.local(tn.year, tn.month, tn.day, hrs, mins).to_f
        
        add(o={
          length: 24*60*60,
          action: params[:action],
          units: 'seconds',
          repeat: true,
          next: t
        })
        
        resp['alarm'] = o    
      end
    end
    self
  end.new name: 'alarm'
end

if __FILE__ == $0
  r=RbNLPS::Skill.get_matches("set an alarm for 8:23 am")[-1]
  p r[:intent].invoke(r[:params])
  sleep 5
end

