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

      intent "/status/of/:name", name: @name do |params, resp={}|
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
    extend UI
    ui state: [:state,:online],
       controls: {
         switch: {
           toggle: {state: :state, action: "toggle the %name", type: :toggle}
         }
       }
  end
end

