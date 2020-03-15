require 'logger'
require 'json'

def p *o
  o.each do |m|
    RbNLPS::Utils::Log.debug { (m.is_a?(Hash) or m.is_a?(Array)) ? JSON.pretty_generate(m) : m.inspect }
  end
end

def puts *o
  o.each do |m|
    RbNLPS::Utils::Log.info { (m.is_a?(Hash) or m.is_a?(Array)) ? JSON.pretty_generate(m) : m.to_s }
  end
end

module RbNLPS
  module Utils
    module Log
      def self.log msg=nil, domain: $0, type: :info, &b
        (@logger ||= Logger.new(STDOUT))
        c = caller.find do |_| _.split(":")[0] != File.expand_path(__FILE__) end
        r = @logger.send(type) {
          STDOUT.print "\n"
          msg = b ? b.call() : msg
          msg = {
            error: msg,
            backtrace: msg.backtrace
          } if msg.is_a?(Exception)
          msg = JSON.pretty_generate msg if msg.is_a?(Hash)

          "#{c} \n( #{domain} ) :: "+msg
        }
      end
      
      def self.info  m=nil, &b; log m, type: :info, &b;  end
      def self.debug m=nil, &b; log m, type: :debug, &b; end
      def self.warn  m=nil, &b; log m, type: :warn, &b;  end
      def self.error m=nil, &b; log m, type: :error, &b; end  
      def self.fatal m=nil, &b; log m, type: :fatal, &b; end           
    end
  end
end  
