require 'slidefield'
require 'minitest/autorun'

# Pretty Print objects in MiniTest diffs
require 'pp'

module MiniTest
  module Assertions
    def mu_pp(obj)
      obj.pretty_inspect
    end
  end
end
