$: << File.expand_path("#{File.dirname(__FILE__)}/../../")
require "rbnlps/skill"

module RbNLPS
  module SmartBox
    extend UI
    include MediaDevice
    include HasMediaProviders
  end
end
