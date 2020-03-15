class List < RbNLPS::Skill
  def initialize
    super({
      name: "list"
    })
    
    @path = File.expand_path("~/.list-skill.json")
    
    File.exist?(@path) || `echo "{}" > #{@path}`
    
    @lists = JSON.parse(open(@path).read)

    intent "/add/:blank/to/:list/list" do |params, resp|
      unless list = @lists[l=params[:list].to_s.downcase]
        say "No such list: #{l}"
        resp[:detail] = {
          message: "no such list #{l}"
        }
        next
      end
      i = params[:blank].to_s.downcase
      if !list.index(i)
        list << i
        save
        say "O K, I have added #{i} to #{l}"
        
      else
        say "#{i} is already in list, #{l}"
      end
    end
    
    intent "/create/:name/list" do |params, resp|
      @lists[params[:name]] ||= []
      save
      say "O K, list #{params[:name]} created."
    end
    
    intent "/read/:name/list" do |params, resp|
      unless list=@lists[l=params[:name]]
        say "List, #{l} does not exist."
        resp[:detail] = {
          message: "No such list, #{l}."
        }
        next
      end
      
      resp[:items] = list
      
      say "O K, here is your list. #{list.join(", ")}" 
    end 
    
    intent "/remove/:blank/from/:list/list" do |params, resp|
      unless list=@lists[l=params[:list]]
        say "List, #{l} does not exist."
        resp[:detail] = {
          message: "No such list, #{l}."
        }
        next
      end
      
      list.delete(i=params[:blank].to_s.downcase)
      save
      say "O K, item, #{i} removed from, #{l} list." 
    end 
    
    intent "/clear/:list/list" do |params, resp|
      unless list=@lists[l=params[:list]]
        say "List, #{l} does not exist."
        resp[:detail] = {
          message: "No such list, #{l}."
        }
        next
      end           
       
     @lists[l] = []
     save
     say "O K, list #{l}, cleared."  
    end
  end
  
  def save
    File.open(@path, 'w') do |f| f.puts @lists.to_json end
  end
  
  self
end.new


