module TermApp
  class Stream
    include EventHandler
    include Keys

    @io : IO::FileDescriptor

    delegate \
      :encoding,
      :puts,
      :raw,
      :write,
      :tty?,
      to: @io

    # TODO:
    # :pause

    def initialize(@io)
      at_exit { @io.cooked!  }
    end

    def writable?
      true
    end

    def emit_data
      @io.raw do |io|
        loop do
          bytes = Bytes.new 1024^2 # A whole megabight
          while len = io.read bytes
            next if len == 0
            emit ::TermApp::DataEvent, bytes, len

            # Check if there are any listeners, and do not go
            # processing the string if not.
            # Not sure if this is desired or not.
            #if @_event_keypressevent.size > 0
              emit_keys String.new e.data[...e.len]
            #end
          end
        end
      end
    end
  end
end
