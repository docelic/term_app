require "logger"
require "event_handler"
require "tput"

require "./events"
require "./mouse"
require "./keys"
require "./stream"

module TermApp

  include EventHandler
  include Keys
  include Mouse

  getter input : ::TermApp::Stream
  getter output : ::TermApp::Stream
  getter term : String

  #getter _title : String = ""
  #@ret = false
  getter tput : ::Tput::Data

  @cursor_hidden = false

  def initialize(input, output)
    initialize(input: input, output: output)
  end
  def initialize(
    @term = ::Tput::Terminal.find_terminal,
    input = STDIN,
    output = STDOUT,
    zero_based = true,
    use_buffer = false,
    use_padding = false,
    extended = true,
    use_unicode = true,
    #termcap = 
  )

    @input = ::TermApp::Stream.new input
    @output = ::TermApp::Stream.new output

    super()

    @tput = ::Tput::Data.new(
      term: @term,
      use_padding: use_padding,
      extended: extended,
      use_printf: true,
      use_buffer: use_buffer,
      use_cache: true,
      use_unicode: use_unicode,
      zero_based: zero_based,
    )

    listen
  end

  def listen
    # Potentially reset window title on exit:
    # if !@rxvt?
    #   if !@vte?
    #     this.setTitleModeFeature(3)
    #   end
    #   manipulateWindow(21) { |err,data|
    #     if (err)
    #       return
    #     end
    #     @_originalTitle = data["text"]
    #   })
    # }

    _listen_input
    #spawn do loop do _listen_output end end
  end

  def _listen_input
    spawn do @input.emit_data end
    #@input.on(KeypressEvent) { |e|
    #}
  end
  def _listen_output
    sleep 1
  end

  def pause
    lsave_cursor :pause

    #this.csr(0, screen.height - 1);
    if @is_alt
      normal_buffer
    end
    show_cursor
    disable_mouse if @mouse_enabled

    # TODO
    #write = this.output.write
    #this.output.write = function() {};
    # How to set/unset raw mode on IO::FileDescriptor?
    #if (this.input.setRawMode) {
    #  this.input.setRawMode(false);
    #}
    #@input.pause

    @_paused = true
  end

  def resume
    @_paused = false

    # TODO
    # Set back to raw mode
    #if (self.input.setRawMode) {
    #  self.input.setRawMode(true);
    #}
    #@input.resume
    # Restore output write function
    #self.output.write = write;

    # Switch to alt buffer if it was in alt buffer before pause
    if @is_alt
      alternate_buffer
    end

    #self.csr(0, screen.height - 1);
    enable_mouse if @mouse_enabled
    lrestore_cursor(:pause, true)

    # TODO
    #if (callback) callback();
  end

  # CSI Ps ; Ps ; Ps ; Ps ; Ps T
  #   Initiate highlight mouse tracking.  Parameters are
  #   [func;startx;starty;firstrow;lastrow].  See the section Mouse
  #   Tracking.
  def init_mouse_tracking(*arguments)
    _write("\x1b[" + arguments.join(";") + "T")
  end


  class MouseType
    # XXX can it be a record?
    # XXX Why nils allowed?
    property? normal                : Bool? = nil
    property? all_motion            : Bool? = nil
    property? vt200                 : Bool? = nil
    property? vt200_hilite_tracking : Bool? = nil
    property? x10                   : Bool? = nil
    property? cell_motion           : Bool? = nil
    property? send_focus            : Bool? = nil
    property? utf                   : Bool? = nil
    property? sgr                   : Bool? = nil
    property? urxvt                 : Bool? = nil
    property? dec                   : Bool? = nil
    property? pterm                 : Bool? = nil
    property? jsbterm               : Bool? = nil
    property? gpm                   : Bool? = nil

    def initialize(
     @normal = nil,
     @all_motion = nil,
     @vt200 = nil,
     @vt200_hilite_tracking = nil,
     @x10 = nil,
     @cell_motion = nil,
     @send_focus = nil,
     @utf = nil,
     @sgr = nil,
     @urxvt = nil,
     @dec = nil,
     @pterm = nil,
     @jsbterm = nil,
     @gpm = nil,
    )
      unless @normal.nil?
        @vt200 = @normal
        @allMotion = @normal
      end
    end

    def disable!
     @normal = false
     @all_motion = false
     @vt200 = false
     @vt200_hilite_tracking = false
     @x10mouse = false
     @cell_motion = false
     @send_focus = false
     @utf = false
     @sgr = false
     @urxvt = false
     @dec = false
     @pterm = false
     @jsbterm = false
     @gpm = false
    end
  end

  class Data
    include ::TermApp
  end
end

