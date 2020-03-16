class String
  def to_i!
    self =~ /([0-9]+)/
    $1.to_i
  end
end

module RbNLPS
  module Speaker
    def initialize *o
      super
      # TODO
      
      # mute
      # unmute
      
      if is_a?(MediaDevice)      
        intent("/set/volume/:level/on/:device", device: @name) do |params, resp|
          send :volume, params[:level].to_i!
        end
      else
        intent("/set/volume/to/:level") do |params, resp|
          send :volume, params[:level].to_i!
        end       
      
        intent("/set/volume/:level") do |params, resp|
          send :volume, params[:level].to_i!
        end       
        
        intent("/volume/up") do |params, resp|
          send :volume, "+5"
        end  
        
        intent("/volume/down") do |params, resp|
          send :volume, "-5"
        end                   
      end
    end
  end
end

module RbNLPS
  module MediaDevice
    extend UI

    include Media
    include Speaker
    include Device    
    def initialize *o
      super
      
      ['/mute/:name',
      '/pause/:name',
      '/resume/:name'].each do |r|
        intent(r, name: @name) do |params|
          m = r.split("/")[1].to_sym
          send m
        end
      end
    end
    
    def controls
      s=""
      s = " on #{@name}" if is_a?(MediaDevice)
      {
        volume: {type: :range, range: {min: 0, max: 100}, action: "set volume to :value#{s}"},
        mute: {type: :bool, action: "toggle mute on #{@name}"},
        playback: {type: :bool, action: "toggle playback on #{@name}"},
      }
    end
  end
end
