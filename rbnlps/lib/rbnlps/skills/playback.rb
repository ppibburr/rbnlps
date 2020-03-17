$: << File.expand_path("#{File.dirname(__FILE__)}/../../")

require "rbnlps/skill"
require "rbnlps/provider"

module RbNLPS
  # Default playback control skill
  # Supports onboard, and last active media skill control
  class Playback < Skill
    include Media
    include Speaker
    
    def current_sink
      sink.class.name.gsub("::",'-')
    end
    
    def initialize *o
      super(name: 'playback')
      
      ui[:header] << :current_sink
      
      ['/mute',
      '/toggle/mute',
      '/unmute',
      '/pause',
      '/resume', '/toggle',
      '/stop',
      '/next',
      '/back'].each do |r|
        [r,d="#{r}/playback"].each do |r|
          p d: d
          intent(r) do
            m = r.gsub("/",'').gsub("playback",'').to_sym
            send m
          end
        end
      end
      
      intent "/play/:item" do |params, resp|
        r = send :play, i=params[:item]
        resp[:provider] = n=r[:provider] if r
        say "O K, playing #{i} from #{n}" if r 
      end
      
      intent "/status" do |params, resp={}|
        resp[:status] = sink.state[:state]
        resp[:state]  = state[:state]
      end

      intent "/status/of/playback" do |params, resp={}|
        resp[:status] = sink.state[:state]
        resp[:state]  = state[:state]
      end

      intent "/what/is/playing" do |params, resp={}|
        say "You are listening to, "+(resp[:playing] = sink.state[:title])
      end
    end
    
    # @return [Array<Media>] of media player skills 
    def sinks
      Skill.skills.find_all do |s|
        s.is_a?(HasMediaProviders) and s.providers.find do |n, pv| pv.is_a?(LocalProvider) end
      end
    end
    
    # @return [Media] of active media playback
    def sink; @sink ||= sinks[0]; end
    
    private
    def sink= s; @sink = s; end
    
    public
    [:load, :play, :pause, :next, :stop, :prev, :resume, :toggle, :state, :append, :back].each do |m|
      define_method m do |*o|
        sink.send m, *o
      end
    end
    
    # Sets the volume level |0..100| or +|-
    # if #sink is_?(Speaker) routes to that skill,
    #   other wise sets the default 'onboard' speaker volume
    def volume lvl=nil
      if !lvl && !sink.is_a?(Speaker)
        `#{conf['onboard-speaker']['volume']['get']}` =~ /\[([0-9]+)\%\]/
        return $1.to_i
      end
      
      if sink.is_a?(Speaker)
        sink.volume lvl
      else
        puts cmd = conf['onboard-speaker']['volume']['set'].gsub("@lvl",lvl.to_s)
        `#{cmd}`
      end
    end
    
    def togglemute; mute toggle: true; end
    
    def mute bool=true, toggle: nil
      return `#{conf['onboard-speaker']['toggle']}`   if toggle
    
      #if sink.is_a?(Speaker)
        `#{conf['onboard-speaker']['mute']}`   if bool
        `#{conf['onboard-speaker']['unmute']}` if !bool
      #end
    end
    
    def state; 
      s=sink.state; 
      s[:muted] = muted?
      s[:volume] = volume
      s
      {state: s}
    end
    
    def muted?
      `pacmd list-sinks | awk '/muted/ { print $2 }'`.strip != 'no' 
    end
    
    def unmute; mute false; end
    
    def speak text, opts=[]
    p OPTS: opts
      unless !is_a?(Speaker)
        return(priority do
          `say #{opts.join(" ")} "#{text}"` 
        end) unless Service::opts[:silent]
      end
    end
    
    def conf
      JSON.parse(open("./playback-config.json").read)
    rescue
      JSON.parse({
        'onboard-speaker': {
          'volume': {
            set: "amixer -q -D pulse sset Master @lvl%",
            get: "amixer -D pulse sget Master | grep \"[[0-9+]%]\""
          },
          'mute':   'amixer -q -D pulse sset Master mute',
          'unmute': 'amixer -q -D pulse sset Master unmute',
          'toggle': 'amixer -q -D pulse sset Master toggle'
        }
      }.to_json)
    end
    
    # @return [Media] the default and onboard media player skill
    def default_sink; sinks[0]; end
  
    # Runs block between paused/resumed on onboard speaker
    def priority t=nil, &b
      p DS: default_sink
      default_sink.pause
      b.call
      default_sink.resume
    end
  
  
    class << self
      attr_reader :instance
    end
  
    @instance = new()
  end
end

if __FILE__ == $0
  pb = RbNLPS::Playback.instance
  s  = pb.sink
  r=RbNLPS::Skill.get_matches("play rammstein from youtube")[-1]
  p r[:intent].invoke(r[:params])

  while s=STDIN.gets
    case s.strip
    when 'p'
      RbNLPS::Playback.instance.pause
    when 'r'
      RbNLPS::Playback.instance.resume
    when 'n'
      pb.sink.next
    end
  end
end
