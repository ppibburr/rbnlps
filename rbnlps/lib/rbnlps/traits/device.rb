module RbNLPS
  module Device
    def on resp={};end
    def off resp={};end
    def key resp={};end
    def status resp={};end
        
    def initialize *o
      super
   
      intent "/turn/on/the/:name", name: @name do |params, resp={}|
        on resp
      end
      
      intent "/turn/off/the/:name", name: @name do |params, resp={}|
        off resp
      end
      
      intent "/toggle/the/:name", name: @name do |params, resp={}|
        toggle resp
      end
      
      intent "/status/of/the/:name", name: @name do |params, resp={}|
        status resp
      end    
      
      intent "/turn/on/:name", name: @name do |params, resp={}|
        on resp
      end
      
      intent "/turn/off/:name", name: @name do |params, resp={}|
        off resp
      end
      
      intent "/toggle/:name", name: @name do |params, resp={}|
        toggle resp
      end
      
      intent "/status/of/:name", name: @name do |params, resp={}|
        status resp
      end              
    end
    
    class UI
      attr_reader :name, :device, :klass,:idx
      def initialize d,idx=0
        @name  = d.name
        @klass = d.class
        @device = d
        @idx=idx
      end
      
      def self.script
        """
        <script>
  function speak(txt, after) {
    fetch('/spoke', {
      method: 'post',
      body: txt
    }).then(function(response) {
      return response.json();
    }).then(function(data) {
      console.log(data);
      after(data);
    });
  }        
  
  function toggle(id,a,c) {
    speak(a, function() {
      speak('status of '+id.dataset.name, function(j) {
        document.getElementById('text-'+id.id).innerText = j['status'];
        if (j['status']) {
          id.classList.add('active');
        } else {
          id.classList.remove('active');
        }
      })
    });
  }
  </script>
        """
      end
      
      def self.style
      """
      <style>
      .res-circle {
        width: 20%;
        border-radius: 50%;
        line-height: 0;
        background: #bcd6ff;
        /* NECESSARY FOR TEXT */
        position: relative;
      }
      .res-circle:after {
        content: \"\";
        display: block;
        padding-bottom: 100%;
      }
      .circle-txt {
        position: absolute;
        bottom: 50%;
        width: 100%;
        text-align: center;
        /* NOT IMPORTANT */
        font-family: arial, sans-serif;
        font-size: 1.5em;
        font-weight: bold;
      }

      .toggle {

    border: solid 1px black;

    text-align: center;

    background-color: #cecece;

    align-self:center;
      }
      
      .active {
        background-color:yellow;
      }
      
      .header { 
      
      }
      
      body {
        background-color: #14192a;
        color: cadetblue;
      }
      
      .device {
      display:flex;
      flex-direction: column;
      align-self: center;text-align:center;
          border: solid 1px aliceblue;
          padding: 0.6em;
          border-radius: 0.3em;
          margin: auto;
          min-width:50vw;
          width:2;
          margin-bottom: 0.3em;
      
      }
      .controls {
        display: flex;
        flex-direction:column;
      }
      </style>
      """
      end
      
      def toggle action: "toggle #{@name}",id: nil, klass: ''
        device.status r={}; s = r[:status] ? :active : ""
        """
        <div id='#{idx}-#{id}' data-name=\"#{@name}\" class='toggle res-circle #{(klass+=" #{s}").strip}' onclick=\"toggle(this,'#{action}', 'active')\">
          <div class=circle-txt id='text-#{idx}-#{id}'> #{r[:status]} </div>
        </div>
        """
      end
      
      def slider action: "set #{@name} to :value percent", klass: '', id: ''
        property=id.to_sym
        min=device.controls[property][:min]
        max=device.controls[property][:max]
        v = device.send property rescue (min+((max-min)/2.0)).to_i
       """
         <div class='device-#{property}'>
           <span class='device-#{property}-label'>#{property}</span>
           <input class='#{"slider #{klass}".strip}' id='#{@idx}-#{property}-slider' type=range min=#{min} max=#{max} value=#{v}>
         </div>
       """
      end
      
      def to_s
        """
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        #{Device::UI.script}
        #{Device::UI.style}
        
        <div class=device>
          #{header}
          <div class=controls>
            #{controls.join}
          </div>
        </div>
        """
      end 
      
      def controls
        ["#{toggle(id: :state)}",slider(id: :brightness)]
      end
      
      def header
"""
        <div class='header'>
          <h1 onclick=\"window.location='/device?device=#{@name}'\"> #{@name} </h1>
          <small>#{@klass}</small>
        </div>
"""       
      end
      
      def list_item
        """
        <div class='device device-item'>
          #{header}
          #{controls[0]}
        </div>
        """
      end
      
      def self.list
        i=-1
        """
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        #{Device::UI.script}
        #{Device::UI.style}
        
        #{skill=RbNLPS::Skill.skills.find_all do |s|
          s.is_a?(RbNLPS::Device)
        end.map do |s| i+=1;new(s,i).list_item end.join}
        """      
      end
    end
    
    def ui
      (self.class.ui rescue UI).new(self).to_s
    end
  end
end
