module TermApp
  # Module for recognizing and sending keypresses
  module Keys

    # TODO maybe do meta=true if s[0].ord==195?

    # Some patterns seen in terminal key escape codes, derived from combos seen
    # at http://www.midnight-commander.org/browser/lib/tty/key.c

    # ESC letter
    # ESC [ letter
    # ESC [ modifier letter
    # ESC [ 1 ; modifier letter
    # ESC [ num char
    # ESC [ num ; modifier char
    # ESC O letter
    # ESC O modifier letter
    # ESC O 1 ; modifier letter
    # ESC N letter
    # ESC [ [ num ; modifier char
    # ESC [ [ 1 ; modifier letter
    # ESC ESC [ num char
    # ESC ESC O letter

    # - char is usually ~ but $ and ^ also happen with rxvt
    # - modifier is 1 +
    #               (shift     * 1) +
    #               (left_alt  * 2) +
    #               (ctrl      * 4) +
    #               (right_alt * 8)
    # - two leading ESCs apparently mean the same as one leading ESC
    #

    # Regexes used for ansi escape code splitting:

    MetaKey = "(?:\x1b)([a-zA-Z0-9])"
    MetaKeyCodeAnywhereRegex = Regex.new MetaKey
    MetaKeyCodeRegex = Regex.new "^" + MetaKey + "$"

    FunctionKey = "(?:\x1b+)(O|N|\\[|\\[\\[)(?:" +
    [
      "(\\d+)(?:;(\\d+))?([~^$])",
      "(?:M([@ #!a`CBA\"])(.)(.))", # mouse # XXX Added CBA" after ` # TODO why not just M[
      "(?:1;)?(\\d+)?([a-zA-Z])"
    ].join("|") +
    ")"
    FunctionKeyCodeAnywhereRegex = Regex.new FunctionKey
    FunctionKeyCodeRegex = Regex.new "^" + FunctionKey

    EscapeCodeAnywhereRegex = Regex.new [ FunctionKey, MetaKey, "\x1b."].join("|")

    # Functions:

    #def emit_keys(stream, bytes, len)
    #  # TODO can String and Bytes share same memory buffer?

    #  # XXX
    #  ## See if we need this or only the line from 'else' is needed.
    #  #if len==1 && bytes[0]>127
    #  #  bytes[0]-=128
    #  #  # 27 == \e[ == ^[ == \x1b == ESC
    #  #  string = String.new Bytes[27, bytes[0]]
    #  #else
    #    string = String.new bytes[0,len]
    #  #end

    #  emit_keys(stream, string)
    #end

    # TODO Work needed here:
    # Meta isn't quite OK recognized?
    # C-<key> gives results like C-111 instead of C-o
    # Ctrl+Shift doesn't produce different sequence than Ctrl alone?
    # Ctrl+Meta does not recognize neither ctrl nor meta
    # Compose or F keys cause Exception
    def emit_keys(string)
      #Log.debug string.inspect

      #if string.size == 1 && string.bytesize == 1 && string[0].ord > 127
      if string.bytesize == 1 && string[0].ord > 127
        s = String.new Bytes[27, string[0].ord-128] # 27 == \xb1
      end

      # TODO
      # Also, should this be here or in the buffer.each loop below
      #if mouse? string
      #  #Log.debug true, :emit_keys__mouse?
      #  next
      #end
      ##Log.debug false, :emit_keys__mouse?

      buffer = [] of String
      start = 0
      last = 0
      matches = 0
      #append_end = true
      while m = EscapeCodeAnywhereRegex.match string, start
        matches += 1

        if m.begin.not_nil! > last
          buffer += string[last, m.begin.not_nil!].split("")
        end

        # These 2 are equivalent:
        #buffer.push string[m.begin.not_nil!...m.end.not_nil!]
        buffer.push m[0]

        start = m.end.not_nil!
        last = m.end.not_nil!
      end
      if start < string.size
        buffer += string[start..].split("")
      end
      
      STDERR.puts buffer.inspect

      #Log.debug buffer.inspect, :emit_keys__buffer

      buffer.each do |s|
        #p "SIZE #{s.size}, BYTESIZE #{s.bytesize}, BYTES: #{s.to_slice}, CODEPOINTS #{s.codepoints}"

        sequence = s
        name, code = nil, nil
        ctrl, meta, shift = false, false, false

        #p "Examining '#{s}', #{s.class}"

        if s == "\r"
          # carriage return
          #name = "return"
          name = "enter" # XXX Let's see what happens with this approach

        elsif s == "\n"
          # XXX
          name = "linefeed" # Or "enter"?

        elsif s == "\t"
          # tab
          name = "tab"

        elsif s == "\b" || s == "\x7f" || s == "\x1b\x7f" || s == "\x1b\b"
          # backspace or ctrl+h
          name = "backspace"
          meta = (s[0].ord == 27) # 27 == \x1b

        elsif s == "\x1b" || s == "\x1b\x1b"
          # escape key
          name = "escape"
          # TODO .bytesize or .size? (Here and in this whole function)
          meta = (s.bytesize == 2)

        elsif s == " " || s == "\x1b "
          name = "space"
          meta = (s.bytesize == 2)

        elsif s.bytesize == 1 && s <= "\x1a"
          # ctrl+letter
          name = (s[0].ord + 'a'.ord - 1).to_s # or .chr.to_s
          ctrl = true

        elsif s.bytesize == 1 && s >= "a" && s <= "z"
          # lowercase letter
          name = s

        elsif s.size == 1 && s >= "A" && s <= "Z"
          # shift+letter
          name = s.downcase
          shift = true

        elsif parts = MetaKeyCodeRegex.match(s)
          # meta+character key
          name = parts[1].downcase
          meta = true
          shift = !!(/^[A-Z]$/.match(parts[1]))

        elsif parts = FunctionKeyCodeRegex.match(s)
          # ansi escape sequence

          # reassemble the code leaving out leading \x1b"s,
          # the modifier key bitflag and any meaningless "1;" sequence
          code2 = (parts[1]? || "") + (parts[2]? || "") + (parts[4]? || "") + (parts[9]? || "")
          modifier = (parts[3]? || parts[8]? || 1).to_i - 1

          # Parse the key modifier
          ctrl = !!(modifier & 4)
          meta = !!(modifier & 10)
          shift = !!(modifier & 1)
          code = code2

          # Parse the key itself
          case code
            # xterm/gnome ESC O letter */
            when "OP"; name = "f1"
            when "OQ"; name = "f2"
            when "OR"; name = "f3"
            when "OS"; name = "f4"

            # xterm/rxvt ESC [ number ~ */
            when "[11~"; name = "f1"
            when "[12~"; name = "f2"
            when "[13~"; name = "f3"
            when "[14~"; name = "f4"

            # from Cygwin and used in libuv */
            when "[[A"; name = "f1"
            when "[[B"; name = "f2"
            when "[[C"; name = "f3"
            when "[[D"; name = "f4"
            when "[[E"; name = "f5"

            # common */
            when "[15~"; name = "f5"
            when "[17~"; name = "f6"
            when "[18~"; name = "f7"
            when "[19~"; name = "f8"
            when "[20~"; name = "f9"
            when "[21~"; name = "f10"
            when "[23~"; name = "f11"
            when "[24~"; name = "f12"

            # xterm ESC [ letter */
            when "[A"; name = "up"
            when "[B"; name = "down"
            when "[C"; name = "right"
            when "[D"; name = "left"
            when "[E"; name = "clear"
            when "[F"; name = "end"
            when "[H"; name = "home"

            # xterm/gnome ESC O letter */
            when "OA"; name = "up"
            when "OB"; name = "down"
            when "OC"; name = "right"
            when "OD"; name = "left"
            when "OE"; name = "clear"
            when "OF"; name = "end"
            when "OH"; name = "home"

            # xterm/rxvt ESC [ number ~ */
            when "[1~"; name = "home"
            when "[2~"; name = "insert"
            when "[3~"; name = "delete"
            when "[4~"; name = "end"
            when "[5~"; name = "pageup"
            when "[6~"; name = "pagedown"

            # putty */
            when "[[5~"; name = "pageup"
            when "[[6~"; name = "pagedown"

            # rxvt */
            when "[7~"; name = "home"
            when "[8~"; name = "end"

            # rxvt keys with modifiers */
            when "[a"; name = "up"; shift = true
            when "[b"; name = "down"; shift = true
            when "[c"; name = "right"; shift = true
            when "[d"; name = "left"; shift = true
            when "[e"; name = "clear"; shift = true

            when "[2$"; name = "insert"; shift = true
            when "[3$"; name = "delete"; shift = true
            when "[5$"; name = "pageup"; shift = true
            when "[6$"; name = "pagedown"; shift = true
            when "[7$"; name = "home"; shift = true
            when "[8$"; name = "end"; shift = true

            when "Oa"; name = "up"; ctrl = true
            when "Ob"; name = "down"; ctrl = true
            when "Oc"; name = "right"; ctrl = true
            when "Od"; name = "left"; ctrl = true
            when "Oe"; name = "clear"; ctrl = true

            when "[2^"; name = "insert"; ctrl = true
            when "[3^"; name = "delete"; ctrl = true
            when "[5^"; name = "pageup"; ctrl = true
            when "[6^"; name = "pagedown"; ctrl = true
            when "[7^"; name = "home"; ctrl = true
            when "[8^"; name = "end"; ctrl = true

            # misc. */
            when "[Z"; name = "tab"; shift = true
            #else; name = nil # It already is nil if nothing set it

          end
        end

        full = String.build do |s|
          s << "S-" if shift
          s << "M-" if meta
          s << "C-" if ctrl
          s << name || code || sequence
        end

        name ||= ""
        code ||= ""

        # Set 'key' to nil if key name wasn't recognized
        #key = name.nil? ? nil : {
        # Or always emit, because modifier info is useful?

        emit KeyPressEvent,
          ::TermApp::Key.new \
            sequence: s,
            code: code,
            name: name,
            full: full,
            ctrl: ctrl,
            meta: meta,
            shift: shift
      end
    end
  end
end
