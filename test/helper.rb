require 'simplecov'
require 'coveralls'

Coveralls::Output.silent = true

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
]

SimpleCov.start {
  project_name 'SlideField'
  add_filter '/test/'

  add_group 'Objects', '/lib/slidefield/objects/'
}

require 'minitest/autorun'

# use awesome_print for objects diff
module MiniTest
  module Assertions
    def mu_pp(obj)
      obj.awesome_inspect
    end
  end
end

require 'slidefield'
