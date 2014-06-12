# SlideField

**A presentation software that reads plain text files written in its own
    interpreted language.**

## Installation

Requirements: ruby, sdl, sdl_ttf, freeimage

    $ gem install slidefield

## Usage

    $ slidefield [options] [file ...]

### Comments

    % single-line comment
    %{ multi-line
       comment %}

### Variables

A variable can only be created once inside each object (with the `=` operator).
However they can be modified freely using any other available operator.
The type of the variable cannot be changed after the variable creation.

    variable  = value
    variable += value
    variable -= value
    variable *= value
    variable /= value


### Value types

Integers:

    variable = 42
    variable += 2  % add
    variable -= 10 % subtract
    variable *= 6  % multiply
    variable /= 10 % divide
    % variable is 20

Character strings:

    variable = "hello"
    variable += " world!\n" % append
    variable -= "!"         % remove the bang
    variable *= "3"         % multiply by 3
    % variable is "hello world\nhello world\nhello world\n"

Size or point coordinates:

    variable = 2x4
    variable += 100x80 % add
    variable -= 10x0   % subtract
    variable *= 3x4    % multiply
    variable /= 2x2    % divide
    % variable is 138x168

Colors (red, blue, green & alpha in hexadecimal notation):

    variable = #C0FF33FF
    variable += #03003300 % add
    variable -= #0C240055 % subtract
    % variable is #B7DB66AA

Booleans:

    variable = :true
    opposite = :false

Variables can also store custom objects. See the 'Templates' section below.

### Objects

Variables are bound to the object in which they are created into.
Most SlideField object have reserved variables ("*properties*")
with a predefined type.
All properties are mandatory unless otherwise specified.

Nested objects inherit their parent's variables.
All slide objects (marked as such in the list below) can be infinitely nested.

    % Syntax:
    \object_name
    \object_name { ... }
    \object_name value
    \object_name value { ... }

The shortcut syntax `\object value` assigns `value` to the first property
compatible with the value's type.

### Object List

**(Anywhere)** Load another file at the current location:

    \include "relative/path/to/file.sfp"
    \include {
      source = "relative/path/to/file.sfp"
    }

**(Anywhere)** Print debug information about any value to standard output:

    \debug any_value

**(Top-level, required, maximum 1)** Configure the output window:

    \layout 1920x1080
    \layout {
      size = 1920x1080
      fullscreen = :true % optional
    }

**(Top-level, required)** Create a slide:

    \slide { ... }

**(Slide)** Animation between slides:

    \animation "fade" { ... }
    \animation {
      name = "fade"
      %{
      other possible values are:
      name = "slide right"
      name = "slide left"
      name = "slide down"
      name = "slide up"
      name = "zoom"
      %}
      duration = 400 % in ms (optional)
    }
*Note: The animation is applied only to nested objects.*

**(Slide)** Add an image:

    \image "relative/path/to/image.png"
    \image {
      source = "relative/path/to/image.png"
      size = 0x0        % automatic if 0 (optional)
      color = #FFFFFFFF % color filter (optional)
      position = 0x0    % optional
      z_order = 0       % optional
    }

**(Slide)** Add a rectangle:

    \rect 100x100
    \rect {
      size = 100x100
      fill = #FFFFFFFF % optional
      position = 0x0   % optional
      z_order = 0      % optional
    }

**(Slide)** Play an audio file:

    \song "relative/path/to/audio.ogg"
    \song {
      source = "relative/path/to/audio.ogg"
      volume = 100 % optional
      loop = :true % optional
    }

**(Slide)** Add text:

    \text "Hello World!"
    \text {
      content = "Hello World!"
      color = #FFFFFFFF % optional
      font = "sans"     % font name or relative font path (optional)
      % font = "./my_font.ttf"
      height = 20       % font height in pixels (optional)
      width = 0         % maximum width (automatic if 0, optional)
      spacing = 0       % line spacing (optional)
      align = "left"    % optional
      %{
      other possible values are:
      align = "right"
      align = "center"
      align = "justify"
      %}
      position = 0x0 % optional
      z_order = 0    % optional
    }

### Filters
Filters are like methods in an object-oriented programming language.
They can be chained infinitely.

    variable = (filter)value
    variable = (second_filter)(first_filter)value

Point to integer:

    point = 1920x1080
    x = (x)point
    % x is 1920

    y = (y)point
    % y is 1080

Integer to point:

    point = (x)1920
    % point is 1920x0

    point += (y)1080
    % point is 1920x1080

Line count:

    lines = (lines)"Lorem\nIpsum"
    % lines is 2

### Templates
Custom objects can be created using templates.

    template_name = \object_name { ... }
    \&template_name

    % creation
    slide_template = \slide {
      \image background { size = 1920x1080; }
      \text title { height = 72; }
    }

    % usage
    \&slide_template {
      title = "Hello World!"
      background = "relative/path/to/image.png"
    }

Equivalent of the above example without using templates:

    \slide {
      title = "Hello World!"
      background = "relative/path/to/image.png"
      \image background { size = 1920x1080; }
      \text title { height = 72; }
    }

## Contributing

1. [Fork it](https://bitbucket.org/cfi30/slidefield/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
