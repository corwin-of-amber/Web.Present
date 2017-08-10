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
    console.log "Message", ev
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
    @use-touch = false
    @img.on 'load' ~> console.log @img.0.naturalWidth; @fit-in-window!
    $(window).on 'resize' ~> @fit-in-window!

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

  ui.img.on 'touchstart' ->
    ui.use-touch = true
    pc.ws.send 'next'
    ui.img.css 'border' '1px solid black'
    setTimeout -> ui.img.css 'border' 'none'
    , 1000
  ui.img.on 'touchend' ->
    ui.img.css 'border' 'none'
  ui.img.on 'touchcancel' ->
    ui.img.css 'border' 'none'


  export ui
