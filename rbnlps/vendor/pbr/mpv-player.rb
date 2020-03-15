require 'mpv'
require '/home/ppibburr/git/0RB/lib/orb/utils.rb'

module PBR
  module MPVPlayer
    attr_reader :session
    def event(e)
      p({ media_player_event: e})
      if e['event'] == "playback-restart"
        Notify.send("Now playing...\n#{state[:title]}", image: 'media-playback-start')
      end
    end

    def initialize *o
      super
      Thread.new do
        @session = MPV::Session.new(user_args: ['--no-video', '--ytdl-format=251,171,bestaudio'])
        session.callbacks << method(:event)
      end.join
    end
    
    def load file
      session.command "loadfile", file, "append-play"
    end
    
    def get_property prop; session.get_property(prop); end
    def command *o; session.command(*o); end
    
    def state
      {
        state:     get_property("pause"),
        n_items:   get_property("playlist-count"),
        nth_item:  get_property("playlist-pos"),
        title:     get_property("media-title"),
        path:      get_property("path"),
        position:  get_property("time-pos"),
        remaining: get_property("time-remaining")
      }
    end
    
    def pause;   session.client.set_property "pause", true; end
    def resume;  session.client.set_property "pause", false; end
    def toggle;  command "cycle","pause"; end
    def stop;    command "stop"; end
    def next;    command "playlist-next"; end
    def prev;    command "playlist-prev"; end
    def back; prev; end
    def shuffle; command "playlist-shuffle"; end    
    def clear;   command "playlist-clear"; end 
  
    def [] i
      get_property()
    end
    
    def << f
      append f
    end
    
    def append f
      session.command "loadfile", f, "append"
    end    
    
    def each &b; for i in 0..(length-1); b.call(self[i]); end; end
    def map &b; a=[]; each do |f| a << b.call(f) end; a; end
    def to_a; map do |f| f end; end
  end
end

if __FILE__ == $0
  mpv = class Player
    include PBR::MPVPlayer
    self
  end.new
  mpv.load ARGV[0]

  Thread.new do 
    loop do p mpv.state; sleep 0.333;end
  end
  
  while c=STDIN.gets
    case c.strip
    when 'p'
      mpv.pause
    when 'r'
      mpv.resume
    when 'n'
      mpv.next
    when 's'
      mpv.stop
    end  
  end
end
