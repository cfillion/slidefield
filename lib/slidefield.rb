require 'slidefield/version'

require 'ap'
require 'gosu'
require 'logger'
require 'parslet'
require 'pathname'

require 'slidefield/animator'
require 'slidefield/errors'
require 'slidefield/interpreter'
require 'slidefield/object_data'
require 'slidefield/object_manager'
require 'slidefield/object_rules'
require 'slidefield/parser'
require 'slidefield/viewer'

require 'slidefield/objects/_base.rb'
require 'slidefield/objects/_root.rb'
require 'slidefield/objects/animation.rb'
require 'slidefield/objects/debug.rb'
require 'slidefield/objects/image.rb'
require 'slidefield/objects/include.rb'
require 'slidefield/objects/layout.rb'
require 'slidefield/objects/rect.rb'
require 'slidefield/objects/slide.rb'
require 'slidefield/objects/song.rb'
require 'slidefield/objects/text.rb'

module SlideField
  @logger = Logger.new STDERR
  @logger.datetime_format = '%Y-%m-%d %H:%M:%S.%L '
  @logger.level = Logger::WARN

  def self.log
    @logger
  end
end
