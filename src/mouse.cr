require "./gpm_client"

module TermApp
  # Module for recognizing and sending mouse events
  module Mouse

#    # XTerm mouse events
#    # http:#invisible-island.net/xterm/ctlseqs/ctlseqs.html#Mouse%20Tracking
#    # To better understand these
#    # the xterm code is very helpful:
#    # Relevant files:
#    #   button.c, charproc.c, misc.c
#    # Relevant functions in xterm/button.c:
#    #   BtnCode, EmitButtonCode, EditorButton, SendMousePosition
#    # send a mouse event:
#    # regular/utf8: ^[[M Cb Cx Cy
#    # urxvt: ^[[ Cb ; Cx ; Cy M
#    # sgr: ^[[ Cb ; Cx ; Cy M/m
#    # vt300: ^[[ 24(1/3/5)~ [ Cx , Cy ] \r
#    # locator: CSI P e ; P b ; P r ; P c ; P p & w
#    # motion example of a left click:
#    # ^[[M 3<^[[M@4<^[[M@5<^[[M@6<^[[M@7<^[[M#7<
#    # mouseup, mousedown, mousewheel
#    # left click: ^[[M 3<^[[M#3<
#    # mousewheel up: ^[[M`3>
#
#    def bind_mouse
#      return if @_bound_mouse
#      @_boundMouse = true
#
#      on(DataEvent) { |e|
#        text = e.data
#        return if !text or text.size==0
#        _bind_mouse text, data
#      }
#    end
#
#    def _bind_mouse(s, buf)
#      key
#      parts
#      b
#      x
#      y
#      mod
#      params
#      down
#      page
#      button
#
#      key = {
#        name: nil,
#        ctrl: false,
#        meta: false,
#        shift: false
#      }
#
#      # XXX Same commented code exists in emit_keys. Unify?
#      ## See if we need this or only the line from 'else' is needed.
#      #if len==1 && bytes[0]>127
#      #  bytes[0]-=128
#      #  # 27 == \e[ == ^[ == \x1b == ESC
#      #  string = String.new Bytes[27, bytes[0]]
#      #else
#        string = String.new bytes[0,len]
#      #end
#      #emit_keys(stream, string)
#
#      # if (@8bit) {
#      #   s = s.replace(/\233/g, "\x1b[")
#      #   buf = new Buffer(s, "utf8")
#      # }
#
#      # XTerm / X10 for buggy VTE
#      # VTE can only send unsigned chars and no unicode for coords. This limits
#      # them to 0xff. However, normally the x10 protocol does not allow a byte
#      # under 0x20, but since VTE can have the bytes overflow, we can consider
#      # bytes below 0x20 to be up to 0xff + 0x20. This gives a limit of 287. Since
#      # characters ranging from 223 to 248 confuse javascript's utf parser, we
#      # need to parse the raw binary. We can detect whether the terminal is using
#      # a bugged VTE version by examining the coordinates and seeing whether they
#      # are a value they would never otherwise be with a properly implemented x10
#      # protocol. This method of detecting VTE is only 99% reliable because we
#      # can't check if the coords are 0x00 (255) since that is a valid x10 coord
#      # technically.
#      bx = s.charCodeAt(4)
#      by = s.charCodeAt(5)
#      if (buf[0] === 0x1b && buf[1] === 0x5b && buf[2] === 0x4d
#          && (::TermApp::Terminal.vte?
#          || bx >= 65533 || by >= 65533
#          || (bx > 0x00 && bx < 0x20)
#          || (by > 0x00 && by < 0x20)
#          || (buf[4] > 223 && buf[4] < 248 && buf.length === 6)
#          || (buf[5] > 223 && buf[5] < 248 && buf.length === 6))) {
#        b = buf[3]
#        x = buf[4]
#        y = buf[5]
#
#        # unsigned char overflow.
#        if (x < 0x20) x += 0xff
#        if (y < 0x20) y += 0xff
#
#        # Convert the coordinates into a
#        # properly formatted x10 utf8 sequence.
#        s = "\x1b[M"
#          + String.fromCharCode(b)
#          + String.fromCharCode(x)
#          + String.fromCharCode(y)
#      }
#
#      # XTerm / X10
#      if (parts = /^\x1b\[M([\x00\u0020-\uffff]{3})/.exec(s)) {
#        b = parts[1].charCodeAt(0)
#        x = parts[1].charCodeAt(1)
#        y = parts[1].charCodeAt(2)
#
#        key.name = "mouse"
#        key.type = "X10"
#
#        key.raw = [b, x, y, parts[0]]
#        key.buf = buf
#        key.x = x - 32
#        key.y = y - 32
#
#        if (@zero) key.x--, key.y--
#
#        if (x === 0) key.x = 255
#        if (y === 0) key.y = 255
#
#        mod = b >> 2
#        key.shift = !!(mod & 1)
#        key.meta = !!((mod >> 1) & 1)
#        key.ctrl = !!((mod >> 2) & 1)
#
#        b -= 32
#
#        if ((b >> 6) & 1) {
#          key.action = b & 1 ? "wheeldown" : "wheelup"
#          key.button = "middle"
#        } else if (b === 3) {
#          # NOTE: x10 and urxvt have no way
#          # of telling which button mouseup used.
#          key.action = "mouseup"
#          key.button = @_lastButton || "unknown"
#          delete @_lastButton
#        } else {
#          key.action = "mousedown"
#          button = b & 3
#          key.button =
#            button === 0 ? "left"
#            : button === 1 ? "middle"
#            : button === 2 ? "right"
#            : "unknown"
#          @_lastButton = key.button
#        }
#
#        # Probably a movement.
#        # The *newer* VTE gets mouse movements comepletely wrong.
#        # This presents a problem: older versions of VTE that get it right might
#        # be confused by the second conditional in the if statement.
#        # NOTE: Possibly just switch back to the if statement below.
#        # none, shift, ctrl, alt
#        # gnome: 32, 36, 48, 40
#        # xterm: 35, _, 51, _
#        # urxvt: 35, _, _, _
#        # if (key.action === "mousedown" && key.button === "unknown") {
#        if (b === 35 || b === 39 || b === 51 || b === 43
#            || (::TermApp::Terminal.vte? && (b === 32 || b === 36 || b === 48 || b === 40))) {
#          delete key.button
#          key.action = "mousemove"
#        }
#
#        self.emit("mouse", key)
#
#        return
#      }
#
#      # URxvt
#      if (parts = /^\x1b\[(\d+;\d+;\d+)M/.exec(s)) {
#        params = parts[1].split(";")
#        b = +params[0]
#        x = +params[1]
#        y = +params[2]
#
#        key.name = "mouse"
#        key.type = "urxvt"
#
#        key.raw = [b, x, y, parts[0]]
#        key.buf = buf
#        key.x = x
#        key.y = y
#
#        if (@zero) key.x--, key.y--
#
#        mod = b >> 2
#        key.shift = !!(mod & 1)
#        key.meta = !!((mod >> 1) & 1)
#        key.ctrl = !!((mod >> 2) & 1)
#
#        # XXX Bug in urxvt after wheelup/down on mousemove
#        # NOTE: This may be different than 128/129 depending
#        # on mod keys.
#        if (b === 128 || b === 129) {
#          b = 67
#        }
#
#        b -= 32
#
#        if ((b >> 6) & 1) {
#          key.action = b & 1 ? "wheeldown" : "wheelup"
#          key.button = "middle"
#        } else if (b === 3) {
#          # NOTE: x10 and urxvt have no way
#          # of telling which button mouseup used.
#          key.action = "mouseup"
#          key.button = @_lastButton || "unknown"
#          delete @_lastButton
#        } else {
#          key.action = "mousedown"
#          button = b & 3
#          key.button =
#            button === 0 ? "left"
#            : button === 1 ? "middle"
#            : button === 2 ? "right"
#            : "unknown"
#          # NOTE: 0/32 = mousemove, 32/64 = mousemove with left down
#          # if ((b >> 1) === 32)
#          @_lastButton = key.button
#        }
#
#        # Probably a movement.
#        # The *newer* VTE gets mouse movements comepletely wrong.
#        # This presents a problem: older versions of VTE that get it right might
#        # be confused by the second conditional in the if statement.
#        # NOTE: Possibly just switch back to the if statement below.
#        # none, shift, ctrl, alt
#        # urxvt: 35, _, _, _
#        # gnome: 32, 36, 48, 40
#        # if (key.action === "mousedown" && key.button === "unknown") {
#        if (b === 35 || b === 39 || b === 51 || b === 43
#            || (::TermApp::Terminal.vte? && (b === 32 || b === 36 || b === 48 || b === 40))) {
#          delete key.button
#          key.action = "mousemove"
#        }
#
#        self.emit("mouse", key)
#
#        return
#      }
#
#      # SGR
#      if (parts = /^\x1b\[<(\d+;\d+;\d+)([mM])/.exec(s)) {
#        down = parts[2] === "M"
#        params = parts[1].split(";")
#        b = +params[0]
#        x = +params[1]
#        y = +params[2]
#
#        key.name = "mouse"
#        key.type = "sgr"
#
#        key.raw = [b, x, y, parts[0]]
#        key.buf = buf
#        key.x = x
#        key.y = y
#
#        if (@zero) key.x--, key.y--
#
#        mod = b >> 2
#        key.shift = !!(mod & 1)
#        key.meta = !!((mod >> 1) & 1)
#        key.ctrl = !!((mod >> 2) & 1)
#
#        if ((b >> 6) & 1) {
#          key.action = b & 1 ? "wheeldown" : "wheelup"
#          key.button = "middle"
#        } else {
#          key.action = down
#            ? "mousedown"
#            : "mouseup"
#          button = b & 3
#          key.button =
#            button === 0 ? "left"
#            : button === 1 ? "middle"
#            : button === 2 ? "right"
#            : "unknown"
#        }
#
#        # Probably a movement.
#        # The *newer* VTE gets mouse movements comepletely wrong.
#        # This presents a problem: older versions of VTE that get it right might
#        # be confused by the second conditional in the if statement.
#        # NOTE: Possibly just switch back to the if statement below.
#        # none, shift, ctrl, alt
#        # xterm: 35, _, 51, _
#        # gnome: 32, 36, 48, 40
#        # if (key.action === "mousedown" && key.button === "unknown") {
#        if (b === 35 || b === 39 || b === 51 || b === 43
#            || (::TermApp::Terminal.vte? && (b === 32 || b === 36 || b === 48 || b === 40))) {
#          delete key.button
#          key.action = "mousemove"
#        }
#
#        self.emit("mouse", key)
#
#        return
#      }
#
#      # DEC
#      # The xterm mouse documentation says there is a
#      # `<` prefix, the DECRQLP says there is no prefix.
#      if (parts = /^\x1b\[<(\d+;\d+;\d+;\d+)&w/.exec(s)) {
#        params = parts[1].split(";")
#        b = +params[0]
#        x = +params[1]
#        y = +params[2]
#        page = +params[3]
#
#        key.name = "mouse"
#        key.type = "dec"
#
#        key.raw = [b, x, y, parts[0]]
#        key.buf = buf
#        key.x = x
#        key.y = y
#        key.page = page
#
#        if (@zero) key.x--, key.y--
#
#        key.action = b === 3
#          ? "mouseup"
#          : "mousedown"
#
#        key.button =
#          b === 2 ? "left"
#          : b === 4 ? "middle"
#          : b === 6 ? "right"
#          : "unknown"
#
#        self.emit("mouse", key)
#
#        return
#      }
#
#      # vt300
#      if (parts = /^\x1b\[24([0135])~\[(\d+),(\d+)\]\r/.exec(s)) {
#        b = +parts[1]
#        x = +parts[2]
#        y = +parts[3]
#
#        key.name = "mouse"
#        key.type = "vt300"
#
#        key.raw = [b, x, y, parts[0]]
#        key.buf = buf
#        key.x = x
#        key.y = y
#
#        if (@zero) key.x--, key.y--
#
#        key.action = "mousedown"
#        key.button =
#          b === 1 ? "left"
#          : b === 2 ? "middle"
#          : b === 5 ? "right"
#          : "unknown"
#
#        self.emit("mouse", key)
#
#        return
#      }
#
#      if (parts = /^\x1b\[(O|I)/.exec(s)) {
#        key.action = parts[1] === "I"
#          ? "focus"
#          : "blur"
#
#        self.emit("mouse", key)
#        self.emit(key.action)
#
#        return
#      }
#    }
#
#    # gpm support for linux vc
#    def enableGpm = function() {
#      self = @
#      gpmclient = require("./gpmclient")
#
#      if (@gpm) return
#
#      @gpm = gpmclient()
#
#      @gpm.on("btndown", function(btn, modifier, x, y) {
#        x--, y--
#
#        key = {
#          name: "mouse",
#          type: "GPM",
#          action: "mousedown",
#          button: self.gpm.ButtonName(btn),
#          raw: [btn, modifier, x, y],
#          x: x,
#          y: y,
#          shift: self.gpm.hasShiftKey(modifier),
#          meta: self.gpm.hasMetaKey(modifier),
#          ctrl: self.gpm.hasCtrlKey(modifier)
#        }
#
#        self.emit("mouse", key)
#      })
#
#      @gpm.on("btnup", function(btn, modifier, x, y) {
#        x--, y--
#
#        key = {
#          name: "mouse",
#          type: "GPM",
#          action: "mouseup",
#          button: self.gpm.ButtonName(btn),
#          raw: [btn, modifier, x, y],
#          x: x,
#          y: y,
#          shift: self.gpm.hasShiftKey(modifier),
#          meta: self.gpm.hasMetaKey(modifier),
#          ctrl: self.gpm.hasCtrlKey(modifier)
#        }
#
#        self.emit("mouse", key)
#      })
#
#      @gpm.on("move", function(btn, modifier, x, y) {
#        x--, y--
#
#        key = {
#          name: "mouse",
#          type: "GPM",
#          action: "mousemove",
#          button: self.gpm.ButtonName(btn),
#          raw: [btn, modifier, x, y],
#          x: x,
#          y: y,
#          shift: self.gpm.hasShiftKey(modifier),
#          meta: self.gpm.hasMetaKey(modifier),
#          ctrl: self.gpm.hasCtrlKey(modifier)
#        }
#
#        self.emit("mouse", key)
#      })
#
#      @gpm.on("drag", function(btn, modifier, x, y) {
#        x--, y--
#
#        key = {
#          name: "mouse",
#          type: "GPM",
#          action: "mousemove",
#          button: self.gpm.ButtonName(btn),
#          raw: [btn, modifier, x, y],
#          x: x,
#          y: y,
#          shift: self.gpm.hasShiftKey(modifier),
#          meta: self.gpm.hasMetaKey(modifier),
#          ctrl: self.gpm.hasCtrlKey(modifier)
#        }
#
#        self.emit("mouse", key)
#      })
#
#      @gpm.on("mousewheel", function(btn, modifier, x, y, dx, dy) {
#        key = {
#          name: "mouse",
#          type: "GPM",
#          action: dy > 0 ? "wheelup" : "wheeldown",
#          button: self.gpm.ButtonName(btn),
#          raw: [btn, modifier, x, y, dx, dy],
#          x: x,
#          y: y,
#          shift: self.gpm.hasShiftKey(modifier),
#          meta: self.gpm.hasMetaKey(modifier),
#          ctrl: self.gpm.hasCtrlKey(modifier)
#        }
#
#        self.emit("mouse", key)
#      })
#    }
#
#    def disableGpm = function() {
#      if (@gpm) {
#        @gpm.stop()
#        delete @gpm
#      }
#    }
#

    @_current_mouse : MouseType? = nil
    @gpm : GpmClient? = nil

    def enable_mouse
      if ENV["CRYSTERM_FORCE_MODES"]?
        modes = ENV["BLESSED_FORCE_MODES"].split ','
        mouse = MouseType.new
        # XXX isn't this just bad and too drawn out?
        modes.each do |mode|
          pair = mode.split '='
          v = pair[1] != '0'
          case pair[0].upcase
            when "SGRMOUSE"
              mouse.sgr = v
            when "UTFMOUSE"
              mouse.utf = v
            when "VT200MOUSE"
              mouse.vt200 = v
            when "URXVTMOUSE"
              mouse.urxvt = v
            when "X10MOUSE"
              mouse.x10 = v
            when "DECMOUSE"
              mouse.dec = v
            when "PTERMMOUSE"
              mouse.pterm = v
            when "JSBTERMMOUSE"
              mouse.jsbterm = v
            when "VT200HILITE", "VT200HILITETRACKING"
              mouse.vt200_hilite_tracking = v
            when "GPMMOUSE"
              mouse.gpm = v
            when "CELLMOTION"
              mouse.cell_motion = v
            when "ALLMOTION"
              mouse.all_motion = v
            when "SENDFOCUS"
              mouse.send_focus = v
          end
        end
        return set_mouse mouse, true
      end

      # NOTE:
      # Cell Motion isn't normally needed for anything below here, but we'll
      # activate it for tmux (whether using it or not) in case our all-motion
      # passthrough does not work. It can't hurt.

      if (term("rxvt-unicode"))
        return set_mouse(MouseType.new(
          urxvt: true,
          cell_motion: true,
          all_motion: true
        ), true)
      end

      # rxvt does not support the X10 UTF extensions
      if (term("rxvt"))
        return set_mouse(MouseType.new(
          vt200: true,
          x10: true,
          cell_motion: true,
          all_motion: true
        ), true)
      end

      # libvte is broken. Older versions do not support the
      # X10 UTF extension. However, later versions do support
      # SGR/URXVT.
      if (::TermApp::Terminal.vte?)
        return set_mouse(MouseType.new(
          # NOTE: Could also use urxvtMouse here.
          sgr: true,
          cell_motion: true,
          all_motion: true
        ), true)
      end

      if (term("linux"))
        return set_mouse(MouseType.new(
          vt200: true,
          gpm: true
        ), true)
      end

      if term("xterm") || term("screen") # TODO || ( @tput && ::TermApp::Tput::Strings["key_mouse"] )
        return set_mouse(MouseType.new(
          vt200: true,
          utf: true,
          cell_motion: true,
          all_motion: true
        ), true)
      end
    end

    # Sets Mouse
    def set_mouse(mouse : MouseType, enable=false)

      if enable
        @_current_mouse = mouse
        @mouse_enabled = true
        return
      else
        # TODO can we just go with if @_current_mouse, without
        # separate enabled variable?
        # TODO can _current_mouse be named mouse?
        @_current_mouse = nil
        @mouse_enabled = false
      end

      # XXX how about turning all these below into case/when

      #     Ps = 9  -> Send  X & Y on button press.  See the sec-
      #     tion  Tracking.
      #     Ps = 9  -> Don"t send  X & Y on button press.
      # x10
      unless mouse.x10?.nil?
        if mouse.x10?
          set_mode("?9")
        else
          reset_mode("?9")
        end
      end

      #     Ps = 1 0 0 0  -> Send  X & Y on button press and
      #     release.  See the section  Tracking.
      #     Ps = 1 0 0 0  -> Don"t send  X & Y on button press and
      #     release.  See the section  Tracking.
      # vt200
      unless mouse.vt200?.nil?
        if mouse.vt200?
          set_mode("?1000")
        else
          reset_mode("?1000")
        end
      end

      #     Ps = 1 0 0 1  -> Use Hilite  Tracking.
      #     Ps = 1 0 0 1  -> Don"t use Hilite  Tracking.
      unless mouse.vt200_hilite_tracking?.nil?
        if mouse.vt200_hilite_tracking?
          set_mode("?1001")
        else
          reset_mode("?1001")
        end
      end

      #     Ps = 1 0 0 2  -> Use Cell Motion  Tracking.
      #     Ps = 1 0 0 2  -> Don"t use Cell Motion  Tracking.
      # button event
      unless mouse.cell_motion?.nil?
        if mouse.cell_motion?
          set_mode("?1002")
        else
          reset_mode("?1002")
        end
      end

      #     Ps = 1 0 0 3  -> Use All Motion  Tracking.
      #     Ps = 1 0 0 3  -> Don"t use All Motion  Tracking.
      # any event
      unless mouse.all_motion?.nil?
        # NOTE: Latest versions of tmux seem to only support cellMotion (not
        # allMotion). We pass all motion through to the terminal.
        # TODO where are tmux vars now?
        if false #@is_tmux && @tmux_version>= 2
          if mouse.all_motion?
            _twrite("\x1b[?1003h")
          else
            _twrite("\x1b[?1003l")
          end
        else
          if mouse.all_motion?
            set_mode("?1003")
          else
            reset_mode("?1003")
          end
        end
      end

      #     Ps = 1 0 0 4  -> Send FocusIn/FocusOut events.
      #     Ps = 1 0 0 4  -> Don"t send FocusIn/FocusOut events.
      unless mouse.send_focus?.nil?
        if mouse.send_focus?
          set_mode("?1004")
        else
          reset_mode("?1004")
        end
      end

      #     Ps = 1 0 0 5  -> Enable Extended  Mode.
      #     Ps = 1 0 0 5  -> Disable Extended  Mode.
      unless mouse.utf?.nil?
        if mouse.utf?
          set_mode("?1005")
        else
          reset_mode("?1005")
        end
      end

      # sgr
      unless mouse.sgr?.nil?
        if mouse.sgr?
          set_mode("?1006")
        else
          reset_mode("?1006")
        end
      end

      # urxvt
      unless mouse.urxvt?.nil?
        if mouse.urxvt?
          set_mode("?1015")
        else
          reset_mode("?1015")
        end
      end

      # dec
      unless mouse.dec?.nil?
        if mouse.dec?
          _write("\x1b[1;2\"z\x1b[1;3\"{")
        else
          _write("\x1b[\"z")
        end
      end

      # pterm
      unless mouse.pterm?.nil?
        if mouse.pterm?
          _write("\x1b[>1h\x1b[>6h\x1b[>7h\x1b[>1h\x1b[>9l")
        else
          _write("\x1b[>1l\x1b[>6l\x1b[>7l\x1b[>1l\x1b[>9h")
        end
      end

      # jsbterm
      unless mouse.jsbterm?.nil?
        # + = advanced mode
        if mouse.jsbterm?
          _write("\x1b[0~ZwLMRK+1Q\x1b\\")
        else
          _write("\x1b[0~ZwQ\x1b\\")
        end
      end

      # gpm
      unless mouse.gpm?.nil?
        if mouse.gpm?
          enable_gpm
        else
          disable_gpm
        end
      end
    end
    def disable_mouse
      return unless @_current_mouse
      @_current_mouse.disable!
    end

    def enable_gpm
      # TODO just run it? event parsing and emitting is already correct in gpm client now
    end
    def disable_gpm
      if @gpm
        @gpm.try &.stop
      end
    end
  end
end
