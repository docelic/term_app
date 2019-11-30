require "socket"

module TermApp
  class GpmClient
    include EventHandler

    GPM_USE_MAGIC = false

    GPM_MOVE = 1
    GPM_DRAG = 2
    GPM_DOWN = 4
    GPM_UP = 8

    GPM_DOUBLE = 32
    GPM_MFLAG = 128

    GPM_REQ_NOPASTE = 3
    GPM_HARD = 256

    GPM_MAGIC = 0x47706D4C
    GPM_SOCKET = "/dev/gpmctl"

    getter io : UNIXSocket
    getter pid : Int32
    getter tty : String
    getter vc : Int16
    getter socket_file : String

    property emit_parsed_events : Bool
    property emit_raw_events : Bool

    record Config,
      event_mask : UInt16,
      default_mask : UInt16,
      min_mod : UInt16,
      max_mod : UInt16,
      pid : Int32,
      vc : Int32
    getter config : Config

    def initialize(start=true, @emit_parsed_events=true, @emit_raw_events=true, @socket_file=GPM_SOCKET, config=nil)
      super()

      @pid = Process.pid

      # check tty for /dev/tty[n]
      path= begin
        File.readlink "/proc/" + pid.to_s + "/fd/0"
      rescue e : Exception
        return
      end

      # TODO check for /dev/pts/X
      if m= /tty[0-9]+$/.match path
        @tty = m[0].not_nil!
        @vc = @tty[3..].to_i16
      # TODO if failed then check for /dev/input/...
      # elsif ...
      else
        raise Exception.new "No tty (terminal is not on /dev/tty*)"
      end

      # typedef struct Gpm_Connect {
      #   unsigned short event_mask, default_mask;
      #   unsigned short min_mod, max_mod;
      #   int pid;
      #   int vc;
      # } Gpm_Connect;

      @config = config || create_config
      @io = connect @socket_file
      send_config

      if start
        self.start
      end

      self
    end

    # Creates default config data for Gpm_Connect
    def create_config
      Config.new(
        pid: @pid.to_i32,
        vc: @vc.to_i32,
        # Disable all:
        #event_mask: 0xffffu16,
        #default_mask: GPM_MOVE | GPM_HARD,
        #min_mod: 0u16,
        #max_mod: 0xffffu16,
        # Enable all:
        event_mask: 0xffffu16,
        max_mod: 0xffffu16,
        default_mask: 0u16,
        min_mod: 0u16
      )
    end

    def connect(socket_file)
      #info = File.info socket_file
      UNIXSocket.new socket_file
    end

    protected def send_config(config=nil, io=@io)
      c = config || (@config ||= create_config)

      #buffer= IO::Memory.new (GPM_USE_MAGIC ? 20 : 16)
      if GPM_USE_MAGIC
        io.write_bytes(GPM_MAGIC.to_u32,          IO::ByteFormat::LittleEndian) # 0)
        io.write_bytes(c.event_mask.to_u16,   IO::ByteFormat::LittleEndian) # 4)
        io.write_bytes(c.default_mask.to_u16, IO::ByteFormat::LittleEndian) # 6)
        io.write_bytes(c.min_mod.to_u16,      IO::ByteFormat::LittleEndian) # 8)
        io.write_bytes(c.max_mod.to_u16,      IO::ByteFormat::LittleEndian) # 10)
        io.write_bytes(c.pid.to_i32,         IO::ByteFormat::LittleEndian) # 12)
        io.write_bytes(c.vc.to_i32,          IO::ByteFormat::LittleEndian) # 16)
      else
        io.write_bytes(c.event_mask.to_u16,   IO::ByteFormat::LittleEndian) # 0)
        io.write_bytes(c.default_mask.to_u16, IO::ByteFormat::LittleEndian) # 2)
        io.write_bytes(c.min_mod.to_u16,      IO::ByteFormat::LittleEndian) # 4)
        io.write_bytes(c.max_mod.to_u16,      IO::ByteFormat::LittleEndian) # 6)
        io.write_bytes(c.pid.to_i32,         IO::ByteFormat::LittleEndian) # 8)
        io.write_bytes(c.vc.to_i32,          IO::ByteFormat::LittleEndian) # 12)
      end
      #io.write buffer.to_slice

      # XXX Why would we need this?
      #@config.pid = 0
      #@config.vc = GPM_REQ_NOPASTE

      self
    end

    def start
      type = :gpm

      loop do
        e = get_event

        emit GpmEvent, e if @emit_raw_events
        next unless @emit_parsed_events

        x= e.x
        y= e.y
        dx=e.dx
        dy=e.dy
        wdx=e.wdx
        wdy=e.wdy
        button = e.button
        shift = e.shift?
        meta = e.meta?
        ctrl = e.ctrl?

        case e.type & 15

          when GPM_MOVE
            #if e.dx!=0 || e.dy!=0 emit MouseMoveEvent, e end
            #if e.wdx!=0 || e.wdy!=0 emit MouseWheelEvent, e end
            if e.wdy!=0 || e.wdx!=0 # Wheel move
              action = e.dy > 0 ? :wheelup : :wheeldown
            #elsif e.dx!=0 || e.dy!=0 # Mouse move
            else
              x-=1
              y-=1
              action = :move
            #else
            #  raise Exception.new "Unknown type of mouse move (dx/dy/wdx/wdy are all 0)"
            end

          when GPM_DRAG
            #if e.dx!=0 || e.dy!=0 emit MouseDragEvent, e end
            #if e.wdx!=0 || e.wdy!=0 emit MouseWheelEvent, e end
            x-=1
            y-=1
            # TODO support drag by action=:drag, or by action=:move
            # and flag drag:true ?
            action = :move

          when GPM_DOWN
            #emit MouseButtonDownEvent, e
            #if e.type & GPM_DOUBLE emit MouseDoubleClickEvent, e end
            x-=1
            y-=1
            action = :down

          when GPM_UP
            #emit MouseButtonUpEvent, e
            #if !(e.type & GPM_MFLAG) emit MouseClickEvent, e end
            x-=1
            y-=1
            action = :up
        end

        raise "Unsupported GPM event (couldn't recognize 'action')" if action.nil?

        em = MouseEvent.new(
          type: type,
          action: action,
          button: button,
          x: x,
          y: y,
          dx: dx,
          dy: dy,
          wdx: wdx,
          wdy: wdy,
          shift: shift,
          meta: meta,
          ctrl: ctrl,
          raw: e,
        )

        emit MouseEvent, em
      end
    end

    def get_event
      # typedef struct Gpm_Event {
      #   unsigned char buttons, modifiers;  // try to be a multiple of 4
      #   unsigned short vc;
      #   short dx, dy, x, y; // displacement x,y for this event, and absolute x,y
      #   enum Gpm_Etype type;
      #   // clicks e.g. double click are determined by time-based processing
      #   int clicks;
      #   enum Gpm_Margin margin;
      #   // wdx/y: displacement of wheels in this event. Absolute values are not
      #   // required, because wheel movement is typically used for scrolling
      #   // or selecting fields, not for cursor positioning. The application
      #   // can determine when the end of file or form is reached, and not
      #   // go any further.
      #   // A single mouse will use wdy, "vertical scroll" wheel.
      #   short wdx, wdy;
      # } Gpm_Event;

      GpmEvent.new(
        buttons=   @io.read_bytes(UInt8, IO::ByteFormat::LittleEndian),
        modifiers= @io.read_bytes(UInt8, IO::ByteFormat::LittleEndian),
        vc=        @io.read_bytes(UInt16, IO::ByteFormat::LittleEndian),

        dx=        @io.read_bytes(Int16, IO::ByteFormat::LittleEndian),
        dy=        @io.read_bytes(Int16, IO::ByteFormat::LittleEndian),
        x=         @io.read_bytes(Int16, IO::ByteFormat::LittleEndian),
        y=         @io.read_bytes(Int16, IO::ByteFormat::LittleEndian),

        type=      @io.read_bytes(Int32, IO::ByteFormat::LittleEndian),
        clicks=    @io.read_bytes(Int32, IO::ByteFormat::LittleEndian),
        margin=    @io.read_bytes(Int32, IO::ByteFormat::LittleEndian),

        wdx=       @io.read_bytes(Int16, IO::ByteFormat::LittleEndian),
        wdy=       @io.read_bytes(Int16, IO::ByteFormat::LittleEndian),
      )
    end

    def stop
      if io = @io
        io.close unless io.closed?
      end
      self
    end

  end
end
