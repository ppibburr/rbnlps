
tc = class TuyaCloudDevice < RbNLPS::Skill
  require 'color'
  require 'tuya_cloud'  
  include RbNLPS::Device
  class << self
    attr_reader :api
  end
  

  @api = TuyaCloud::API.new('tulnor33@gmail.com', 'cassie-1', '1', 'tuya')  
  api.discover_devices


  def initialize n
    super(name: n)#'WW104/106 Smart Plug')
    
    intent "/dim/:name/by/:percent/percent", name: @name do |params, resp={}|
      dim_by(params[:percent].to_i,resp)    
    end
    
    intent "/dim/the/:name/by/:percent/percent", name: @name do |params, resp={}|
      dim_by(params[:percent].to_i,resp)
    end 
    
    intent "/brighten/:name/by/:percent/percent", name: @name do |params, resp={}|
      brighten_by(params[:percent].to_i,resp)    
    end
    
    intent "/brighten/the/:name/by/:percent/percent", name: @name do |params, resp={}|
      brighten_by(params[:percent].to_i,resp)
    end          
    
    intent "/set/:name/to/:percent/percent", name: @name do |params, resp={}|
      dim_to(params[:percent].to_i,resp)    
    end
    
    intent "/set/the/:name/to/:percent/percent", name: @name do |params, resp={}|
      dim_to(params[:percent].to_i, resp)
    end       
    
    intent "/set/:name/to/:colour", name: @name do |params, resp={}|
      colour(params[:colour],resp)    
    end
    
    intent "/set/the/:name/to/:colour", name: @name do |params, resp={}|
      colour(params[:colour],resp)
    end     
    
    #$timer << proc do api.refresh_devices end           # Refresh the states of all devices
  end
 
  api.devices.each do |d|
    self.new(d.name) unless RbNLPS::Skill.skills.find do |s| s.is_a?(TuyaCloudDevice) && s.name == d.name end
  end   
 
  Thread.new do
    loop do
      sleep 90
      api.discover_devices
      api.devices.each do |d|
        self.new(d.name) unless RbNLPS::Skill.skills.find do |s| s.is_a?(TuyaCloudDevice) && s.name == d.name end
      end      
    end
  end 
  
  def self.device n
    device = api.find_device_by_name(n)
  end
  
  def device 
    self.class.device(@name)
  end
  
  def n;@name;end
  
  def dim_by pct
    brightness brightness * (pct/100)
  end
  
  def brighten_by(pct)
    brightness (b=brightness)+ (b * (pct/100))
  end
  
  def dim_to lvl
    brightness (lvl/100)*255 
  end
  
  def state resp={}
    resp[:state] = device().controls.state         # true / false for on or off
  end
  
  def status resp={}; 
    state resp;resp[:status] = resp[:state];
    resp[:controls] = controls
    resp
  end
  
  
  def online resp={}
    resp[:online] = device().controls.online        # true / false
  end
  
  def brightness v=nil, resp={}
    unless v
      return resp[:brightness] = device().controls.brightness    # Current brightness setting (lights only)
    end
    
    device().controls.set_brightness(v=v.to_i)
    resp[:brightness] = v
  end
  
  def colour_mode resp={}
    resp[:color_mode] = device().controls.color_mode    # Current colour mode (RGB lights only)
  end
  
  def color(v,resp={})
    p V: v = [v].flatten
    return resp[:colour] = device().controls.color if v.empty?        # Current colour setting (RGB lights only)
    r=g=b=nil
    if v.length==3
      r,g,b = v
    elsif (c=v[0]).is_a?(Symbol) or c.is_a?(String)
    p Q: Color::CSS[c.to_s].to_rgb.to_a
      r,g,b = Color::CSS[c.to_s].to_rgb.to_a.map do |i| i*255 end
    end
    p RGB: resp[:color] = [r,g,b]
    device().controls.set_color(r.to_i, g.to_i, b.to_i) 
  end
  
  def colour v, resp={}; color v, resp; end
  
  def darken pct, resp={}
    r,g,b=color()
    rgb=Color::RGB.new(255.0/r,255.0,g,255.0/b).darken_by(pct)
    r,g,b = rgb.to_rgb.to_a.map do |i| i*255 end
    resp[:colour] = [r,g,b]
    colour(r,g,b)
  end
  
  def lighten pct, resp={}
    r,g,b=color()
    rgb=Color::RGB.new(r,g,b).lighten_by(pct)
    r,g,b = rgb.to_rgb.to_a.map do |i| i*100 end
    p r: r, g: g, b: b
    resp[:colour] = [r,g,b]
    colour(r,g,b)
  end
  
  def white resp={}
    resp[:white] = true
    device().controls.set_white            # Sets the light to normal white mode  
  end

  def toggle(resp={})
    resp[:state] = device().controls.toggle       # Toggles on / off
  end
  
  def off resp={}
    resp[:state] = 0
    device().controls.turn_off     # Turns device off
  end
  
  def on(resp={})
    resp[:state] = 1
    device().controls.turn_on      # Turns the device on
  end

  def scene s, resp={}
    resp[:scene] = s
    scene = device()
    scene.controls.activate
  end
  
  def controls
    b=brightness rescue -1
    {
      brightness: {min: 0, max: 100, value: b},
    }
  end
  
  self
end

class TuyaCloudDevices  < RbNLPS::Skill
  def initialize
    super name: 'tuya-cloud-devices'
    
    intent "/list/cloud/devices" do |params, resp={}|
      resp[:devices] = devices.map do |d| say d;d end
    end
    
    intent "/status/of/cloud/devices" do |params, resp={}|
      status resp
      resp[:devices].each do |d|
        say "the #{d[:name]} is #{d[:state]}"
      end
    end    
  end
  
  def devices
    TuyaCloudDevice.api.discover_devices  
    TuyaCloudDevice.api.devices.map do |d| d.name end  
  end
  
  def status resp={}
    TuyaCloudDevice.api.discover_devices  
    a=TuyaCloudDevice.api.devices.map do |d| 
      h={name: d.name, online: d.controls.online, type: d.type}
      if d.controls.is_a?(TuyaCloud::Device::ColorLight)
        h=h.merge color: d.controls.color,color_mode: d.controls.color_mode
      end
      if d.controls.is_a?(TuyaCloud::Device::Light)
        h=h.merge brightness: d.controls.brightness
      end
      if d.controls.is_a?(TuyaCloud::Device::Switchable)
        h = h.merge state: d.controls.state, status: d.controls.state
      end
      if d.controls.is_a?(TuyaCloud::Device::Scene)   
        h = h.merge({})
      end
      h
    end
    resp[:devices] = a
    resp  
  end
  
  self
end.new

