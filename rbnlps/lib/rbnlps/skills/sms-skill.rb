class SMS < RbNLPS::Skill
  include RbNLPS::Contacts
    
  def initialize  
    super name: "sms"
    
    intent "/text/message/:to/that/:body" do |params, resp={}|
      phn = nil
      
      if params[:to].strip =~ /^([0-9]+)$/
        phn = $1.to_i
      end
    
      if !phn and c = contacts[params[:to].downcase.to_sym]
        if phn=c[:phone]
        else
          say "Contact, #{params[:to]}, does not have a phone number listed."
        end
      end
      
      carrier = ''
      
      if phn
        if phn.is_a?(Hash)
          num = phn[:number]
          carrier = "--carrier='#{phn[:carrier]}' "
        else
          num = phn
        end
      
        `ruby ./rbnlps/vendor/pbr/sms.rb #{carrier}#{num} "#{params[:body]}"`
        say "Message sent."
      else
        say "No such contact, #{params[:to]}"
      end
    end 
  end
  
  self
end.new

class GMail < RbNLPS::Skill
  include RbNLPS::Contacts
    
  def initialize  
    super name: "gmail"
    
    intent "/gmail/:to/that/:body" do |params, resp={}|
      email = nil
      
      if c = contacts[params[:to].downcase.to_sym]
        if email = c[:email]
        else
          say "Contact, #{params[:to]}, does not have a email listed."
        end
      end
      
      if email
        `ruby ./rbnlps/vendor/pbr/gmail.rb compose --to=#{email} --from='RbSendMail' --subject='From RbNLPS' "#{params[:body]}"`
        say "Message sent."
      else
        say "No such contact, #{params[:to]}"
      end
    end 
    
    intent "/how/many/messages" do
      o = JSON.parse(`ruby ./rbnlps/vendor/pbr/gmail.rb unread --json`.strip)
      say "There are #{o["unread"]} unread messages"
    end
    
    intent "/read/last/message/from/:contact" do |params, resp={}|
      if c=contacts[params[:contact].downcase.to_sym]
        e = c[:email]
        n = c[:phone][:number]
        resp[:messages] = r = JSON.parse(`ruby ./rbnlps/vendor/pbr/gmail.rb read --from='#{e}|#{n}' --json`.strip, symbolize_names: true)
        if r=r[0]
          say "Recieved on, "+(r[:date]||'no date').split("+")[0]
          say "Subject, "+(r[:subject] || "No Subject")
          say "The following. #{r[:body]}"
        end 
      end
    end
  end
  
  self
end.new
