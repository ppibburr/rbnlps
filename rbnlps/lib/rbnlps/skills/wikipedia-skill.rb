require 'wikipedia'
class WikiSkill < RbNLPS::Skill
  def initialize
    super({
      name: "askwiki"
    })

    intent "/what is/:query" do |params, resp|
      page = Wikipedia.find(params[:query])
      say "#{s=page.summary}"
      resp[:summary] = s
    end
  end
  self
end.new
