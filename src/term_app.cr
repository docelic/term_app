require "logger"
require "event_handler"
require "tput"

require "./key"
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
    _listen_output
  end

  def _listen_input
    @input.on(DataEvent) { |e|
      emit_keys String.new e.data[...e.len]
    }

    # Make @input start emitting
    spawn do @input.emit_data end
  end
  def _listen_output
    unless @output.tty?
      STDERR.puts "Output is not a TTY."
    end
  end

  # Is this the right way to pause?
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

  class Data
    include ::TermApp
  end
end
