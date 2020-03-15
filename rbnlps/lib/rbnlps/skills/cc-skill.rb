$: << File.expand_path("#{File.dirname(__FILE__)}/../../../")

require "rbnlps/provider"
require "rbnlps/skill"

module RbNLPS
  module CC
    class CATT
      def self.command c, *o, device: nil
        d = "-d '#{device}' " if device
        p cmd="catt #{d}#{c} #{o.join(" ")}"
        `#{cmd}`
      end
      
      def self.cast uri, device: nil
        command :cast, "\"#{uri}\"", device: device
      end
      
      def self.stop device: nil
        command :stop, device: device    
      end
      
      def self.save device: nil
        command :save, device: device    
      end
      
      def self.restore device: nil
        command :restore, device: device    
      end        
      
      def self.volume i, device: nil
        command :volume, i, device: device
      end

      def self.volumedown device: nil
        command :volumedown, device: device
      end
      
      def self.volumeup device: nil
        command :volumeup, device: device
      end    
      
      def self.seek t, device: nil
        command :seek, t, device: device
      end
      
      def self.pause device: nil
        command :pause, device: device
      end
      
      def self.play device: nil
        command :play, device: device
      end
      
      def self.ffwd t, device: nil
        command :ffwd, t, device: device
      end
      
      def self.rewind t, device: nil
        command :rewind, t, device: device
      end                
      
      def self.skip device: nil
        command :skip, device: device
      end
      
      def self.status device: nil
        command :status, device: device
      end
      
      def self.info device: nil
        command :info, device: device
      end        
      
      def self.scan
        `catt scan`.split("\n")[1..-1].map do |l|
          Device.new(*l.split(" - "))
        end
      end
      
      Device = Struct.new(:ip, :name, :product) do
        def to_json *o
          JSON.pretty_generate(to_h)
        end
      end
    end

    class YouTubePlayer < YouTubeProvider
      def play device, item, opts={}
        uri = "https://www.youtube.com/watch?v=#{item[:id]}"
        
        CATT.cast uri, device: device.name
      end
    end
    
    class LocalPlayer < HttpFileProvider
      RbNLPS::MyIP.resolve
      def initialize
        super :local, addr: "http://#{RbNLPS::MyIP.public}:4567"
      end
      
      def get_file file
        super
      end
      
      def list
        super
      end
      
      def query q, opts={}
        Dir.glob("*"+q+"*").map do |f| {path: f} end
      end
    
      def play device, file
        CATT.cast get_file(file[:path]), device: device.name
      end  
    end
    
    class Skill < Skill
      require 'waveinfo'
      
      include SmartBox
      
      attr_reader :device
      def initialize *o
        super
        
        add_provider YouTubePlayer.new, LocalPlayer.new()
        
        @device = CC::CATT::Device.new(config[:name], config[:ip], config[:product])
        
        intent "/chrome/cast/message/:message" do |params, resp={}|
          Thread.new do
            say params[:message], ["-o ./tmp.wav"]
            
            CATT.save  device: device.name
            CATT.stop device: device.name
            
            wave = WaveInfo.new('./tmp.wav')          
            
            providers[:Local].play self, './tmp.wav'
            
            sleep wave.duration+2
            
            CATT.stop
            CATT.restore
          end
        end
      end
      
      def volume lvl
        CATT.volume lvl, device: device.name
      end
      
      def speak txt
      
      end
      
      def pause
        CATT.pause device: device.name
      end
      
      def resume
        CATT.resume device: device.name
      end
      
      def stop
        CATT.stop device: device.name
      end            
      
      def self.find
        CC::CATT.scan.map do |d| 
          if skill = (Skill.skills.find do |s|
            s.is_a?(CC::Skill) and s.device.ip == s[:ip]
          end)
            next skill
          else
            self.new({
              name:    d.name,
              ip:      d.ip,
              product: d.product
            }) 
          end
        end
      end
      Skill.new({
        name: "Kitchen speaker"
      })
    end
  end
end
