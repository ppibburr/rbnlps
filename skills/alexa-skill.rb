class Alexa < RbNLPS::Skill
  def self.performs t
    p cmd: cmd="curl -X POST -d 'tell alexa to #{t}' http://localhost:4567/spoke"
   
   `#{cmd}`  
  end

  def initialize  
    super name: "alexa-forward"
    @pipe = IO.popen("cd ~/git/ruby-avs/sample && ./bin/sample", "w")
    intent "/tell alexa to/:stuff" do |params, resp={}|
      p alexa: t=params[:stuff]
      resp[:status] = :OK
      resp[:alexa] = t
      exec t
    end 
  end
  
  def exec t
    @pipe.puts t
  end
  
  self
end.new
