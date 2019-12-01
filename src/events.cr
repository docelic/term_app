require "event_handler"

module TermApp
  ::EventHandler.event ResizeEvent

  ## Mouse
  #::EventHandler.event MouseOverEvent
  #::EventHandler.event MouseOutEvent
  #::EventHandler.event MouseDownEvent
  #::EventHandler.event MouseUpEvent
  #::EventHandler.event WheelDownEvent
  #::EventHandler.event WheelUpEvent

  ## Gpm-specific
  #::EventHandler.event MouseMoveEvent,        data : GpmEvent
  #::EventHandler.event MouseDragEvent,        data : GpmEvent
  #::EventHandler.event MouseWheelEvent,       data : GpmEvent
  #::EventHandler.event MouseButtonDownEvent,  data : GpmEvent
  #::EventHandler.event MouseDoubleClickEvent, data : GpmEvent
  #::EventHandler.event MouseButtonUpEvent,    data : GpmEvent
  #::EventHandler.event MouseClickEvent,       data : GpmEvent

  ::EventHandler.event GpmEvent,
    buttons : UInt8,
    modifiers : UInt8,
    vc : UInt16,
    dx : Int16,
    dy : Int16,
    x : Int16,
    y : Int16,
    type : Int32,
    clicks : Int32,
    margin : Int32,
    wdx : Int16,
    wdy : Int16
  class GpmEvent < ::EventHandler::Event
    def button
      if (@buttons & 4)> 0; return :left   end
      if (@buttons & 2)> 0; return :middle end
      if (@buttons & 1)> 0; return :right  end
      nil
    end
    def shift?() (@modifiers & 1)> 0 ? true : false end
    def ctrl?()  (@modifiers & 4)> 0 ? true : false end
    def meta?()  (@modifiers & 8)> 0 ? true : false end
  end

  ::EventHandler.event MouseEvent,
    action : Symbol,
    button : Symbol?,
    x : Int16,
    y : Int16,
    dx : Int16,
    dy : Int16,
    wdx : Int16,
    wdy : Int16,
    shift : Bool,
    meta : Bool,
    ctrl : Bool,
    raw : GpmEvent,
    type : Symbol
  class MouseEvent < ::EventHandler::Event
    delegate :button, :shift?, :ctrl?, :meta?, to: @raw
  end

  ::EventHandler.event DataEvent, data : Bytes, len : Int32

  ::EventHandler.event KeyPressEvent, key : ::TermApp::Key
end
