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
}

require 'minitest/autorun'

require 'slidefield'
