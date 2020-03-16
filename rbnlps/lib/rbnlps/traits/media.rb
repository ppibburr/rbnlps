require "rbnlps/traits/searchable"

module RbNLPS
  module Media
    attr_reader :state, :playlist
    def playlist= l
      stop
      @playlist = l 
    end
    def pause;end
    def play *o;end
    def resume;end
    def stop;end
    def next;end
    def prev;end
    def max_volume; 150; end
    def volume i=nil;end
    def append f; end
    def << f; append f; end
    def load f, opts={}; end
  end

  module HasMediaProviders
    include CanSearch
    def search q, opts={}
      h = {}

      providers.each do |n,pv| 
        h[n] = pv.query(q,opts) if !opts[:provider] or (n == opts[:provider])
      end
      
      h
    end
    
    def play *o
      if pv=search(*o).find do |n, items| !items.empty? end
        play_items providers[pv[0]], pv[1]
        {provider: pv[0]}
      end
    end
    
    def add_provider *pv
      @providers ||= {}
      pv.each do |pv| 
        providers[pv.name] = pv
        opts = {values: {service: pv.name}}
        if is_a?(Device)
          opts[:r] = "/play| listen to/:item/from/:service/on/:device"
          opts[:values][:device] = @name.downcase
        else
          opts[:r] = "/play|listen to/:item/from/:service"
        end
       
        intent(opts[:r], opts[:values]) do |params, resp={}|
          items = pv.query(i=params[:item])
          resp[:items] = items
          play_items pv, items
          say "o k, playing #{i} from #{pv.name}"
        end
      end
    end
    
    def play_items pv, items
      self.stop
      
      i=-1
      items.map do |item|
        pv.append self, item if (i+=1) > 0
        pv.play self, item
        item
      end    
    end
    
    def providers
      @providers ||= []
    end
  end
end
