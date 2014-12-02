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

module DoctorHelper
  def diagnostics
    # default implementation
    SF::Doctor.bag
  end

  def after_teardown
    assert_empty diagnostics
    super
  ensure
    SF::Doctor.bag.clear
  end

  def assert_diagnostic(level, message)
    error = diagnostics.shift

    assert_equal level, error.level
    assert_equal message, error.message

    error
  end
end
