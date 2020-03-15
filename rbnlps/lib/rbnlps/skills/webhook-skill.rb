$: << File.expand_path("#{File.dirname(__FILE__)}/../../")

require "rbnlps/skill"
require "rbnlps/skills/default"

class WebHook < RbNLPS::Skill
  def initialize *o
    super
    
    config[:phrases].each do |phr|
      intent "/#{phr.split(" ").join("/")}" do |params, resp={}|
        body = nil
        
        if config[:body]
          body=config[:body][:content].map do |part|
            if part[:value]
              part[:value]
            else
              params[part[:param].to_sym]
            end
          end.join(config[:body][:delim]).strip
        end
        
        query = nil
        if config[:query]
          query = config[:query].map do |q|
            v = ''
            if prm = q[:value][:param]
              v = params[prm.to_sym]
            else
              v = q[:value][:text]
            end
            "#{q[:name]}=#{v}"
          end.join("&")
        end
        
        if (uri = config[:uri]) =~ /\?/
          uri = uri + "&" + query
        else
          uri = uri + "?#{query}"
        end
        
        r = ''
        if body
          puts cmd: cmd = "curl -d \"#{body}\" #{uri}".strip
          r = `#{cmd}`
        else
          r = open(uri).read.strip
        end
        
        resp[:response] = JSON.parse(r)
      end
    end
  end
end

WebHook.new(eval(DATA.read))
 
if __FILE__ == $0
  r=RbNLPS::Skill.get_matches("every 1 second toggle kitchen")[-1]
  p r[:intent].invoke(r[:params])
  sleep 5
end

__END__
{
  name: 'test',
  uri: 'localhost:4567/spoke',
  query: [{
    name: "state",
    value: {
      param: "state"
    }
  }, {
    name: "foo",
    value: {
      "text": "bar"
    }
  }],
  
  body: {
    content: [{
      value: "toggle"
    },{
      param: 'device'
    }, {
      value: ""
    }],
    delim: ' '
  },
  
  phrases: [
    "please turn :state the :device"
  ]
}
