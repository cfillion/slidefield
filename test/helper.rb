require 'slidefield'
require 'minitest/autorun'

# use awesome_print for objects diff
module MiniTest
  module Assertions
    def mu_pp(obj)
      obj.awesome_inspect
    end
  end
end
