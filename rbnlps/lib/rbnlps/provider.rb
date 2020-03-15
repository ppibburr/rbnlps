module RbNLPS
  class Provider
    attr_reader :name
    def initialize name; @name = name; end
    
    def query q, opts={}; [];end
    def play where, item
      where.load item
    end
    
    def append where, item
      where.append item
    end
  end

  class LocalProvider < Provider
  end

  class HttpFileProvider < Provider
    attr_reader :addr
    
    def initialize name, addr: nil
      @addr = addr
      super name
    end
    
    def list uri="#{addr}/list"
      JSON.parse(open(uri).read, symbolize_names: true)
    end
    
    def get_file file
      "#{addr}/get-file?file=#{CGI.escape(file)}"
    end
  end

  require 'json'
  require 'open-uri'
  require 'cgi'

  class YouTubeProvider < Provider
    LIVE = "&sp=EgJAAQ%253D%253D"

    def initialize; super :YouTube; end

    def query q, opts={}
      puts cmd = "youtube-dl 'https://www.youtube.com/results?search_query=#{q}' --yes-playlist --flat-playlist -J"
      resp  = JSON.parse(`#{cmd}`, symbolize_names: true)[:entries]
    rescue => e
      p e
      []
    end
  end
end
