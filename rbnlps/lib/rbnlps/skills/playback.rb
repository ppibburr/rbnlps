$: << File.expand_path("#{File.dirname(__FILE__)}/../../")

require "rbnlps/skill"
require "rbnlps/provider"

module RbNLPS
  # Default playback control skill
  # Supports onboard, and last active media skill control
  class Playback < Skill
    include Media
    include Speaker
    def initialize *o
      super(name: 'playback')
      
      ['/mute',
      '/unmute',
      '/pause',
      '/resume', '/toggle',
      '/stop',
      '/next',
      '/back'].each do |r|
        intent(r) do
          m = r.gsub("/",'').to_sym
          send m
        end
      end
      
      intent "/play/:item" do |params, resp|
        r = send :play, i=params[:item]
        resp[:provider] = n=r[:provider] if r
        say "O K, playing #{i} from #{n}" if r 
      end
      
      intent "/status" do |params, resp={}|
        resp[:status] = sink.state
        resp[:status][:volume] = volume
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
        return $1
      end
      
      if sink.is_a?(Speaker)
        sink.volume lvl
      else
        puts cmd = conf['onboard-speaker']['volume']['set'].gsub("@lvl",lvl.to_s)
        `#{cmd}`
      end
    end
    
    def mute bool=true, toggle: nil
      `#{conf['onboard-speaker']['toggle']}`   if toggle
    
      #if sink.is_a?(Speaker)
        `#{conf['onboard-speaker']['mute']}`   if bool
        `#{conf['onboard-speaker']['unmute']}` if !bool
      #end
    end
    
    def muted?
    
    end
    
    def unmute; mute false; end
    
    def speak text, opts=[]
    p OPTS: opts
      unless !is_a?(Speaker)
        return(priority do
          `say #{opts.join(" ")} -t "#{text}"` 
        end) unless Service::opts[:silent]
      end
    end
    
    def conf
      JSON.parse(open("./playback-config.json").read)
    rescue
      JSON.parse({
        'onboard-speaker': {
          'volume': {
            set: "amixer -c 1 set 'Speaker' @lvl%",
            get: "amixer -c 1 get 'Speaker' | grep \"[[0-9+]%]\""
          },
          'mute':   'amixer -q sset Master mute',
          'unmute': 'amixer -q sset Master unmute',
          'toggle': 'amixer -q sset Master toggle'
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
