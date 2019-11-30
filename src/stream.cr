module TermApp
  class Stream
    include EventHandler

    @io : IO::FileDescriptor

    delegate \
      :encoding,
      :puts,
      :raw,
      :write,
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
            #emit_keys @input, bytes, len
            emit ::TermApp::DataEvent, bytes, len
          end
        end
      end
    end
  end
end
