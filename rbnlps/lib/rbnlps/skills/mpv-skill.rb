$: << File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "..", "vendor")
require "pbr/mpv-player"

# A Skill that plays music onboard from local storage and web resources
class MPVSkill < RbNLPS::Skill
  include RbNLPS::Media
  include RbNLPS::HasMediaProviders
  include PBR::MPVPlayer
  
  class LocalProvider < RbNLPS::LocalProvider
    def query item, opts={}
      o=Dir.glob("*"+item+"*").map do |f| {path: f} end
      p o
      o
    end
    
    def play d, item
      return unless File.exist?(item[:path])
      d.load(item[:path])
      true
    end
  end
  
  class YouTubePlayer < RbNLPS::YouTubeProvider
    def play where, item
      where.load "https://youtube.com/watch?v=#{item[:id]}"
    end
    
    def append where, item
      where.append "https://youtube.com/watch?v=#{item[:id]}"
    end    
  end

  def initialize
    super({
      name: 'mpv'
    })
    
    add_provider LocalProvider.new("local")
    add_provider YouTubePlayer.new()    
  end
  skill multi: false
  def self.default; @default ||= new; end
  default
end
