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
    @img = $ '<img>' .attr 'src' "http://#{host}/image-#{Math.random!}.png"
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
        ..on 'click' '#clear' ~> @overlay.clear!; @put!
        ..on 'click' '#reload' -> window.location.reload!

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
    @img.attr 'src' "http://#{host}/image-#{Math.random!}.png"
    $.get "http://#{host}/overlay.json" .then ~>
      @overlay.set-state it


$ ->
  ui = new PresenterUI

  pc.on 'refresh' ui~refresh
  ui.img.mousedown (ev) ->
    if !ui.use-touch
      if ev.button == 2 && $(ev.target).is('img')  # right button
        ui.overlay.add-annotation ev.offsetX, ev.offsetY
        ui.put!
      else
        pc.ws.send 'next'

  $ 'body' .contextmenu (.preventDefault!)

  ui.img.on 'touchstart' (ev) ->
    ui.use-touch = true
    rect = ev.originalEvent.target.getBoundingClientRect()
    for touch in ev.originalEvent.targetTouches
      ui.overlay.add-annotation-client touch.pageX - rect.left, touch.pageY - rect.top
    ui.put!
    #pc.ws.send 'next'
    ui.img.add-class 'touched'
    setTimeout -> ui.img.remove-class 'touched'
    , 1000
  ui.img.on 'touchend'    -> ui.img.remove-class 'touched'
  ui.img.on 'touchcancel' -> ui.img.remove-class 'touched'

  ui.toolbar.on 'click' '#next' -> pc.ws.send 'next'
  ui.toolbar.on 'click' '#prev' -> pc.ws.send 'prev'

  window.onmessage = ->
    if it.data == "\x3f\x3e\x3d"   /* 61,62,63 */
      pc.ws.send 'prev'
    else
      pc.ws.send 'next'

  export ui
