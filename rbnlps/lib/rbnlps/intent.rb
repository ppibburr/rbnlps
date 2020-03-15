module RbNLPS
  class Intent
    def match? text
      s="^"
      params = {}
      i = 0
      
      l=nil
      @route.split("/")[1..-1].map do |q|
        sp = ''
        sp=" " if l and l != "(.*?)"
        s << l=((q =~ /^\:/) ? "#{sp}(.*?)" : "#{sp}(#{q})")
        params[q.gsub(":",'').to_sym] = i+1 if q =~ /^\:/
        i+=1
      end
      
      r=Regexp.new(s+"$")

      if text.downcase =~ r 
        params.each do |k,v| params[k]=$~[v].strip end
        
        values.each_pair do |k,v|
          if v.is_a?(Array)
            v=v.map do |q| q.to_s.downcase end
            return {count: 0, intent: self} unless v.index(params[k].to_s.downcase)
          
          else
            return {count: 0, intent: self} unless v.to_s.downcase == params[k].to_s.downcase
          end
        end

        return({
          intent: self,
          params: params,
          count:  (params.empty? ? $~.length-1 : $~.length-1)+priority#params.keys.length
        })
      end
      
      {count: 0, intent: self}
    end
    
    def self.sort *results
      ra=results.flatten.find_all do |r| r and r[:count] > 0 end.sort do |a,b| a[:count] <=> b[:count] end.reverse
    end

    attr_reader :route, :values, :skill, :block, :priority
    def initialize skill, route, values={}, &b
      @route = route
      @values = values
      @priority = (values.delete(:priority) || 0)
      @skill = skill
      @block = b
    end
    
    def invoke params={},resp={}; @block.call params, resp end
    
    def to_h
      {
        route: route,
        skill: skill.config
      }  
    end
    
    def to_json *o
      JSON.pretty_generate(to_h)
    end
  end
end
