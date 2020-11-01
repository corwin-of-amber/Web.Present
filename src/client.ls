/* This code runs in a regular browser (no NWjs API access) */


host =
  if window.location.protocol == 'http:'
    window.location.host
  else
    'localhost:8008'   # default host for testing


class PresentConn extends EventEmitter

  ->
    super!
    @ws = new WebSocket("ws://#{host}/ws", 'present-protocol')
      ..addEventListener 'open' @~connected
      ..addEventListener 'message' @~handle
      ..addEventListener 'close' @~disconnected
    window.addEventListener 'unload' ~> @ws.close!

  connected: (ev) ->
    console.log "Connected to server.", ev

  handle: (ev) ->
    #console.log "Message", ev
    @emit 'refresh'

  disconnected: (ev) ->
    console.log "Disconnected from server.", ev


pc = new PresentConn

export pc


# --- display part

class PresenterUI

  (@container-element ? $('body')) ->
    @overlay = new Overlay $ 'body'  # note: overlay should come first #sorry
    @img = $ '<img>' .attr 'src' "http://#{host}/image.png" #-#{Math.random!}.png"
      ..append-to @container-element
    @img-aspect-ratio = undefined
    @toolbar = @create-toolbar!append-to @container-element
    @use-touch = false
    @img.on 'load' ~> @fit-in-window!
    $(window).on 'resize' ~> @fit-in-window!

  create-toolbar: ->
    $ '<div>' .add-class 'toolbar'
        ..append ($ '<button>' .attr \id 'clear' .text '⊘')
        ..append ($ '<button>' .attr \id 'prev' .text '◀︎')
        ..append ($ '<button>' .attr \id 'next' .text '▶︎')
        ..append ($ '<button>' .attr \id 'reload' .text '⟳')
        ..append ($ '<button>' .attr \id 'bell' .text '!!')
        ..append ($ '<button>' .attr \id 'last' .text '>>|')
        ..append ($ '<img>' .attr \id 'tool' .add-class 'laser')
        ..on 'click' '#clear' ~> @overlay.clear!; @put!
        ..on 'click' '#reload' -> window.location.reload!
        ..on 'click' '#tool' ~> @rotate-tool!

  fit-in-window: ->
    aspect-ratio = @img.0.naturalWidth / @img.0.naturalHeight
    [w, h] = [@container-element.width!, @container-element.height!]
    @img.height Math.min h, w / aspect-ratio
    @img.width Math.min w, aspect-ratio * h
    @overlay.cover @img
    @overlay.set-state @overlay.get-state!

  put: ->
    $.ajax do
      url: "http://#{host}/overlay.json"
      method: 'POST'
      contentType: 'application/json'
      data: JSON.stringify(@overlay.get-state!)

  refresh: ->
    # preload to avoid flicker
    @preload-image "http://#{host}/image.png" .then ~>
      @img.attr 'src' it
    $.get "http://#{host}/overlay.json" .then ~>
      @overlay.set-state it

  preload-image: (img-src) ->  /* returns a Promise to a data URI (common recipe) */
    new Promise (resolve, reject) -> new Image
      ..onload = -> document.createElement 'canvas'
        [..width, ..height] = [@naturalWidth, @naturalHeight]
        ..getContext('2d').drawImage @, 0, 0
        resolve ..toDataURL('image/png')
      ..src = img-src

  rotate-tool: ->
    tool = @toolbar.find '#tool'
    next = switch
      | tool.has-class('laser') => 'marker'
      | otherwise => 'laser'
    [tool.remove-class .. for ['laser', 'marker']]
    tool.add-class next

  preview-tool: (gesture) ->
    @apply-tool gesture, false

  apply-tool: (gesture, commit=true) ->
    tool = @toolbar.find '#tool'
    {x, y} = gesture.start
    switch
    | tool.has-class('laser') =>
      for trend in ['left', 'right']
        @overlay.remove-annotations "finger-#{trend}"
      trend = if ui.overlay.normx(x) > 0.3 then 'left' else 'right'
      @overlay.add-annotation x, y, ["finger-#{trend}"], gesture.angle
    | tool.has-class('marker') =>
      @overlay.add-annotation x, y, ['centered', 'star']

    if commit then @put!


Annotate =     # mixin
  annotate-start: ->
    gesture = {}
    # For desktop clients, use mousedown
    @img.on 'dragstart', (.preventDefault!)
    @img.on 'mousedown' (ev) ~>
      if ! @use-touch
        if $(ev.target).is(@img)
          gesture.start = {x: ev.offsetX, y:ev.offsetY}
          @preview-tool gesture
    @img.on 'mousemove' (ev) ~>
      if ! @use-touch
        if ev.buttons && gesture.start?
          vec = {x: ev.offsetX - gesture.start.x, y: ev.offsetY - gesture.start.y}
          gesture.angle = Math.atan2(vec.y, vec.x)
          @preview-tool gesture
    @img.on 'mouseup' (ev) ~>
      if ! @use-touch
        if gesture.start?
          @apply-tool gesture
          gesture.start = undefined

    # For mobile clients, use touchstart
    # NOTICE Unlike mouse events, touch events always carry
    #        absolute page coordinates
    touches = new Map
    @img.on 'touchstart' (ev) ~>
      @use-touch = true
      for touch in ev.originalEvent.changedTouches
        t = {start: box-coord({x: touch.pageX, y: touch.pageY})}
        touches.set touch.identifier, t
        @preview-tool t
    @img.on 'touchmove' (ev) ~>
      for touch in ev.originalEvent.changedTouches
        if (t = touches.get(touch.identifier))?
          p = box-coord({x: touch.pageX, y: touch.pageY})
          vec = {x: p.x - t.start.x, y: p.y - t.start.y}
          t.angle = Math.atan2(vec.y, vec.x)
          @preview-tool t
    @img.on 'touchend' (ev) ~>
      for touch in ev.originalEvent.changedTouches
        if (t = touches.get(touch.identifier))?
          @apply-tool t
          touches.delete(touch.identifier)

    box-coord = ({x, y}) ~>
      rect = @overlay.div.0.getBoundingClientRect()  # @@@ actually always as (0, 0)
      box = @overlay.box
      {x: x - rect.left - box.left, \
       y: y - rect.top  - box.top}

AnnotateDrag =    # mixin
  annotate-drag-start: ->
    @knob = {}

    @overlay.div.on 'touchstart' (ev) ~>
      ann = @overlay.get-annotation-from-el(ev.target)
      ev.originalEvent.targetTouches[0]
        @knob = {ann, \
                 x: ..pageX - @overlay.denormx(ann.x),\
                 y: ..pageY - @overlay.denormy(ann.y)}
      @overlay.move-annotation ann, @overlay.denormx(ann.x), @overlay.denormy(ann.y)
    @overlay.div.on 'touchmove' (ev) ~>
      ev.originalEvent.targetTouches[0]
        @overlay.move-annotation @knob.ann, ..pageX - @knob.x, ..pageY - @knob.y
    @overlay.div.on 'touchend' ~>
      @put!


if typeof nw != 'undefined'
  /* NWjs does not have an accessor for currently active window?! */
  nw.Window.get!on 'focus' -> global.activeWindow = window


$ ->
  ui = new PresenterUI

  pc.on 'refresh' ui~refresh

  $ 'body' .contextmenu (.preventDefault!)

  ui <<< Annotate
  ui.annotate-start!

  ui.img.on 'touchstart' (ev) ->
    ui.img.add-class 'touched'
    setTimeout -> ui.img.remove-class 'touched'
    , 1000
  ui.img.on 'touchend'    -> ui.img.remove-class 'touched'
  ui.img.on 'touchcancel' -> ui.img.remove-class 'touched'

  ui.toolbar.on 'click' '#next' -> pc.ws.send 'next'
  ui.toolbar.on 'click' '#prev' -> pc.ws.send 'prev'
  ui.toolbar.on 'click' '#bell' -> pc.ws.send 'bell'
  ui.toolbar.on 'click' '#last' -> pc.ws.send 'last'

  ui <<< AnnotateDrag
  ui.annotate-drag-start!

  $ 'body' .keydown keydown_eh = (ev) ~>
    switch ev.key
      case "ArrowRight" => pc.ws.send 'next'
      case "ArrowLeft"  => pc.ws.send 'prev'
      case "ArrowDown" \
           "PageDown"   => pc.ws.send 'next-slide'
      case "ArrowUp" \
           "PageUp"     => pc.ws.send 'prev-slide'
      case "Home"       => pc.ws.send 'first'
      case "End"        => pc.ws.send 'last'
      case "Backspace"  => pc.ws.send 'back'
    switch ev.code
      case "KeyA"       => pc.ws.send 'applet'

  # When running in WebView inside Android app
  window.onmessage = ->
    if it.data == "\x3f\x3e\x3d"   /* 63,62,61 */
      pc.ws.send 'prev'
    else if it.data in ["\x3d\x3e\x3f",   /* 61,62,63 */
                        "\x14\x14\x14"]
      pc.ws.send 'next'
    else if it.data[0] == '{'
      ui.toolbar.addClass 'large'

  export ui
