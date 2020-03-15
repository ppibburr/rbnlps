require 'readline'
require 'yaml'

module PBR  
  def self.init_readline save: './pbr_rl_hist.txt', completions: [], prompt: ">"
    File.open(save, "a").close
    Readline::HISTORY.push *(open(save).read.strip.split("\n"))
    @save = save
    comp = proc { |s| completions.grep( /^#{Regexp.escape(s)}/ ) }
    @prompt = prompt
    Readline.completion_append_character = " "
    Readline.completion_proc = comp
  end
    
  def self.readline
    line = Readline.readline("#{@prompt} ", true)
    if Readline::HISTORY.to_a[-2] != line
      File.open(@save, "a") do |f| f.puts line end 
    else
      Readline::HISTORY.pop
    end
    line
  end
end

if __FILE__ == $0
  PBR.init_readline completions: ["set volume", "say hello", "broadcast", "pause", "resume" "next", "back", "play", "turn on", "turn off"]
  while l = PBR.readline
    p l
  end
end
