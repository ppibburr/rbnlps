module RbNLPS
  module UI
    def self.list type
      "<title>#{'Skill list'} | RbNLPS</title>"+
      "<link rel=stylesheet href=/css/ui.css />"+
      "<meta name='viewport' content='width=device-width, initial-scale=1'>"+
      "\n<script src=/js/core.js></script>\n"+ 
      "<div class=speak><div class=speak-controls><input id=speak type=text class=input-speak placeholder='...'></input><span class='control button' onclick=\"speak(document.getElementById('speak').value)\">?</span></div></div>" +    
      "<div class=device-list>"+
      Skill.skills.find_all do |s| s.is_a?(type) end.map do |s|
        b=Builder.new(s)
        "  <div class=rbnlps-skill data-name='#{s.name}'>"+
        (s.ui[:summary]||={}).map do |k,v|
          b.render(k,v)
        end.join("\n")+
        "</div>"
      end.join("\n")+
      "</div>"
    end
  
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
        <div class='#{type}-container' id=#{type}>
        #{
        
          if data.is_a?(Array)
            data.map do |a|
              "  <div data-field='#{a}' data-name='#{ins.name}' class='#{a} #{ins.state[:state].has_key?(a) ? 'state-value' : 'device-info'}' id='state-#{a}-#{id}'>#{a}: <span class='value value-#{a}'>#{(ins.state[:state].has_key?(a.to_sym) ? ins.state[:state][a.to_sym] : ins.send(a)) || " --- "}</span></div>"
            end.join("\n        ")
          else
            data.map do |k,v|
              "  <div class='#{k}' id='#{k}'>\n    "+
              v.map do |kk,vv|
              p a: [k,v, kk,vv]
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
        "<div class='slider-container slider-#{vv[:state]}'><input type=range min=#{0} max=#{ins.send("max_#{vv[:state]}")} data-field='#{vv[:state]}' class='control slider #{kk}' id='#{kk}-#{id}' oninput=\"slide(this,'#{parse(vv[:action])}')\"></input></div>"
      end
      
      def toggle kk,vv
        "<div data-field='#{vv[:state]}' class='control #{kk} #{vv[:type]}' id='#{kk}-#{id}' onclick=\"toggle(this,'#{parse(vv[:action])}')\" data-name=\"#{ins.name}\">#{vv[:value]}</div>"
      end
      
      def button kk,vv
        "<div class='control #{kk} #{vv[:type]}' id='#{kk}-#{id}' onclick=\"speak('#{parse(vv[:action])}')\" data-name=\"#{ins.name}\">#{vv[:value]}</div>" 
      end
      
      def to_s
        "<title>#{ins.name} | RbNLPS</title>"+
        "<link rel=stylesheet href=/css/ui.css />"+
        "<meta name='viewport' content='width=device-width, initial-scale=1'>"+
        "\n<script src=/js/core.js></script>\n"+ 
        "<div class=speak><div class=speak-controls><input id=speak type=text class=input-speak placeholder='...'></input><span class='control button' onclick=\"speak(document.getElementById('speak').value)\">?</span></div></div>" +    
        "<div id=#{id} data-name='#{ins.name}' class='#{ui_class}'>"+
        ins.ui.map do |k,v|
          next if k == :summary
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
  end
  
  class Skill
    extend UI
    ui header: [
      :name,
      :type
     ], summary: {
       header: [:name]
     }
     
    def type
      self.class.name.gsub("::",'-')
    end
    
    def ui opts={}
      unless @ui
        @ui = aui = {}
    
        self.class.ancestors.find_all do |a| a.is_a?(UI) end.reverse.each do |a|
          a.ui.each_pair do |k,v|
            if aui[k]
              if v.is_a?(Array)
                aui[k].push(*v.find_all do |q| !aui[k].index(q) end)
              elsif v.is_a?(Hash)
                v.each_pair do |a,b|
                  aui[k][a] = b.clone
                end
              end
            else
              aui[k] = v.clone
            end 
          end
        end
      end
      
      opts.each_pair do |k,v|
        if @ui[k]
          if v.is_a?(Array)
            @ui[k].push(*v.find_all do |q| !@ui[k].index(q) end)
          elsif v.is_a?(Hash)
            v.each_pair do |a,b|
              @ui[k][a] = b.clone
            end
          end
        else
          @ui[k] = v.clone
        end 
      end
      
      p opts: opts
      return @ui
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
      }, summary: {
        state: [:title],
        controls: {
          media: {
            playback: {action: "toggle %name", type: :toggle, state: :state}
          }
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
       }, summary: {
         controls: {
           speaker: {
             volume: {action: "set volume to %lvl on %name", type: :slider, state: :volume}
           }
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

