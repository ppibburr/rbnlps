$: << File.expand_path("#{File.dirname(__FILE__)}/../../")

require 'rbnlps/intent'
require 'rbnlps/traits'



 module RbNLPS
  class Skill
    attr_reader :name, :config
    def initialize cfg={}
      @config = cfg
      @config[:class] ||= self.class
      @name   = cfg[:name]
      @matches = []
      Skill.skills << self
    end
    
    attr_reader :intents
    def intent s, values={}, &b
      (@intents ||= []) << Intent.new(self, s,values, &b)
    end

    def self.get_matches text
      Intent.sort(skills.map do |s| s.intents.map do |i| i.match?(text) end.flatten end.flatten)
    end  
    
    class << self
      @skills = []
      def add ins
        skills << ins
      end
      
      def skills; @skills ||= []; end
    end
    
    def add_routes m
      intents.each do |i|
        m.send :get, r="/skill/#{i.skill.name.to_s.downcase.gsub(" ", "%20")}"+i.route do
          content_type "application/json"
          r = i.match?(text=CGI::unescape(request.path_info.gsub("/skill/#{i.skill.name.to_s.downcase}",'').split("/").join(" ").strip))
          resp = {spoken: text, status: "OK", intent: r[:intent].to_h, params: r[:params], count: r[:count]}
          i.invoke(r[:params], resp) if r[:count] > 0
          JSON.pretty_generate(resp)+"\n"
        end
      end
    end
    
    def status resp={}; end
    
    def to_json *o
      JSON.pretty_generate(@config)
    end
    
    def say text, opts=[], resp: {}
      Playback.instance.speak text, opts
    end
  
    def self.load_by_config
      a=JSON.parse(open("./skills/#{self.class.name.gsub("::","_").downcase}.json").read)
      
      raise "Only one instance of #{self} is supported, config has multiple defined." if a.length > 1 and !mutli
      
      a.each do |c|
        new c
      end
    rescue
    end
    
    def multi; @multi ||= true; end
    
    def self.skill multi: nil
      @multi = multi
    end

    $: << File.expand_path("./")

    def self.load_skill s
      p LoadSkill: s, _: $:
      require "rbnlps/skills/#{s}"
    rescue LoadError => e
      begin 
        require "skills/#{s}"
      rescue => ee
        p SkillLoadError: ee
      end
    end
  end
end

