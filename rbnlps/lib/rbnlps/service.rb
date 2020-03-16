require 'json'
require 'open-uri'

require 'sinatra'

$: << File.dirname(__FILE__)+"/../"

require 'rbnlps/utils'
require 'rbnlps/ui'

require "rbnlps/skill"
require "rbnlps/skills/default"

module RbNLPS
  class Service
    class << self
      attr_accessor :port
    end
    @port = 4567
  end
end

get "/css/:file" do
  send_file "./public/css/#{params[:file]}"
end

get "/js/:file" do
  send_file "./public/js/#{params[:file]}"
end

get "/get-file" do
  f = params[:file]
  send_file(f)
end

get "/list" do
  content_type "application/json"
  
  r = Dir.glob("/home/ppibburr/*").map do |f|
    {file: File.basename(f), path: f, mime_type: nil, ext: f.split(".")[1..-1].join("."), uri: "/get-file?file=#{CGI.escape(f)}"}
  end.to_json
end

get "/device/?" do 
  p D: d = params["device"]
  skill=RbNLPS::Skill.skills.find do |s|
    s.is_a?(RbNLPS::Device) && s.name.downcase == d.downcase
  end
  
  next "you got no skill lol" unless skill
  
  RbNLPS::UI::Builder.new(skill).to_s
end

get "/devices/?" do 
  RbNLPS::Device::UI.list()
end

get "/playback/?" do
  RbNLPS::UI::Builder.new(RbNLPS::Playback.instance).to_s
end

get "/api/status/?" do
  d=params["skill"]
  p D: d
  skill=RbNLPS::Skill.skills.find do |s|
    s.is_a?(RbNLPS::Device) && s.name.downcase == d.downcase
  end
  
  next {err: :no_skill, skill: d}.to_json unless skill
  
  `curl -X POST -d 'status of #{d}' localhost:#{RbNLPS::Service.port}/spoke`
end

def spoke app, text
  content_type 'application/json'
  
  resp = {}
  
  if r=RbNLPS::Skill.get_matches(text)[0]
    resp = {spoken: text, status: "OK", intent: r[:intent].to_h, params: r[:params], count: r[:count]}
    
  
    r[:intent].invoke(r[:params], resp)
   
    
  else 
    return(JSON.pretty_generate({
      status: :ERROR,
      error: {
        type: :UNKNOWN
      }
    })+"\n")
  end
  
  JSON.pretty_generate(resp)+"\n"
end

DEVICES = ['192.168.1.108:4567']

post "/spoke" do
  spoke self, request.body.read
end

post "/google" do
  #`catt -d "Kitchen speaker" cast http://24.23.104.26:4567/get-file?file=/home/ppibburr/ok.wav`
  spoke self, request.body.read
end

get "/converse" do 
  content_type "text/html"
  open(File.expand_path(File.join(File.dirname(__FILE__), "..","..", "www","index.html"))).read
end

class DataObject
  attr_reader :file
  def initialize file
    @file = file
  end
  
  def read
    read_all.split("__END__", 2)[-1]  
  end
  
  def src
    read_all.split("__END__", 2)[0]  
  end
  
  def read_all
    open(file).read  
  end
end


class DATA
  def self.read 
    DataObject.new(caller.first.split(":").first).read
  end
end


conf = JSON.parse(open("./rbnlps-config.json").read)
RbNLPS::Skill.load_skill(conf['playback'])
conf['skills'].each do |s|
  RbNLPS::Skill.load_skill(s)
end
#Thread.new do
RbNLPS::Skill.skills.each do |s| $s=self;s.add_routes self end
#end

require 'pbr/pbr-readline'

Thread.new do 
  PBR.init_readline prompt: "RbNLPS >", completions: ["set volume", "say hello", "broadcast", "pause", "resume" "next", "back", "play", "turn on", "turn off"]
  while l = PBR.readline
    STDOUT.puts `curl -d "#{l}" localhost:#{RbNLPS::Service.port}/spoke`
  end
end
Thread.new do
  sleep 3
  RbNLPS::Playback.instance.speak "Hi There!"
end

