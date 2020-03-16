module RbNLPS
  module UI
    class Builder
      attr_reader :ins
      def initialize ins
        @ins = ins
      end
      
      def id
        @id ||= ins.hash.abs
      end
      
      def ui_class
        ins.class.ancestors.find_all do |a| a.name =~ /RbNLPS/ end.map do |c|
          c.name.split("::").join("-").downcase
        end.join(" ")
      end
      
      def render type, data
        """
        <div class='#{type}' id=#{type}>
        #{
        
          if data.is_a?(Array)
            data.map do |a|
              "  <div data-field='#{a}' data-name='#{ins.name}' class='#{a} #{ins.state.has_key?(a) ? 'state-value' : 'device-info'}' id='state-#{a}-#{id}'>#{a}: #{(ins.state.has_key?(a.to_sym) ? ins.state[a.to_sym] : ins.send(a)) || " --- "}</div>"
            end.join("\n        ")
          else
            data.map do |k,v|
              "  <div class='#{k}' id='#{k}'>\n    "+
              v.map do |kk,vv|
                send vv[:type], kk,vv        
              end.join("\n    ")+
              "\n          </div>\n"
            end.join("\n        ")
          end
        }
        
        </div>
        """
      end
      
      def parse(s)
        s.gsub('%name',ins.name)
      end
      
      def slider kk,vv
        "<input type=range min=#{0} max=#{ins.max_volume} data-field='#{vv[:state]}' class='control slider #{kk}' id='#{kk}-#{id}' oninput=\"slide(this,'#{parse(vv[:action])}')\"></input>"
      end
      
      def toggle kk,vv
        "<div data-field='#{vv[:state]}' class='control #{kk} #{vv[:type]}' id='#{kk}-#{id}' onclick=\"toggle(this,'#{parse(vv[:action])}')\" data-name=\"#{ins.name}\">#{vv[:value]}</div>"
      end
      
      def button kk,vv
        "<div class='control #{kk} #{vv[:type]}' id='#{kk}-#{id}' onclick=\"speak('#{parse(vv[:action])}')\" data-name=\"#{ins.name}\">#{vv[:value]}</div>" 
      end
      
      def to_s
        "<link rel=stylesheet href=/css/ui.css />"+
        "<meta name='viewport' content='width=device-width, initial-scale=1'>"+
        "\n<script src=/js/core.js></script>\n"+      
        "<div id=#{id} data-name='#{ins.name}' class='#{ui_class}'>"+
        ins.class.ui.map do |k,v|
          render k,v
        end.join+
        "</div>"
      end
    end
  
    def ui opts={}
      @ui ||= opts
     
      opts.each_pair do |k,v|
        if @ui[k]
          if v.is_a?(Array)
            @ui[k].push(*v.find_all do |q| !@ui[k].index(q) end)
          elsif v.is_a?(Hash)
            v.each_pair do |a,b|
              @ui[k][a] = b
            end
          end
        else
          @ui[k] = v
        end 
      end
      
      return @ui
    end
    
    def self.extended cls
      cls.singleton_class.send :define_method, :included do |s|
        s.ui cls.ui
        super s
      end if !cls.is_a?(Class)
      
      cls.singleton_class.send :define_method, :inherited do |s|
        s.class_eval do @ui = Skill.ui.clone end
        s.ui cls.ui
        
        super s
      end if cls.is_a?(Class)
      
      super cls
    end
  end
  
  class Skill
    extend UI
    ui header: [
      :name,
      :type
     ]
     
    def type
      self.class.name.gsub("::",'-')
    end
  end    
    
  module Media
    extend UI
    ui state: [
        :title,
        :remaining,
      ], controls: {
        media: {
          prev: {action: "", type: :button},        
          playback: {action: "toggle %name", type: :toggle, state: :state},
          next: {action: "", type: :button}
        }
      }
  end      
  
  module Speaker
    extend UI
    ui controls: {
         speaker: {
           mute: {action: "toggle mute %name", type: :toggle, state: :muted},
           volume: {action: "set volume to %lvl on %name", type: :slider, state: :volume}
         }
       }
  end

  class Test < Skill
    include Media
    include Speaker
  end
  
  class Test2 < Skill
    include Media
    #include Speaker
  end  
  
   class Test3 < Skill
    #include Media
    include Speaker
  end 
  
  #puts UI::Builder.new(Test.new(name: 'foo')).to_s

  p Media.ui
  p Skill.ui
  #p Device.ui

end
