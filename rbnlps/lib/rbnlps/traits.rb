require "rbnlps/traits/searchable"
require "rbnlps/traits/device"
require "rbnlps/traits/media"
require "rbnlps/traits/media-device"
require "rbnlps/traits/smart-box"

module RbNLPS
  module Contacts
    attr_reader :contacts
    def initialize *o
      super
    
      @contacts = {matt: {
        phone: {number: 8149524599, carrier: "messaging.sprintpcs.com"},
        email: 'tulnor33@gmail.com'
      }, kate: {
        phone: {number: 7249912200, carrier: "messaging.sprintpcs.com"},
        email: "kjheigley@gmail.com"
      }}
    end
  end
end
