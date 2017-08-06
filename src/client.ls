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
    @img = $ '<img>' .attr 'src' "http://#{host}/image-#{Math.random!}.png"
      ..append-to @container-element
    $(window).on 'resize' ~>
      @img.height @container-element.height!
      @img.width @container-element.width!

  refresh: ->
    @img.attr 'src' "http://#{host}/image-#{Math.random!}.png"


$ ->
  ui = new PresenterUI

  pc.on 'refresh' ui~refresh
  #ui.img.mousedown ->
  #  pc.ws.send 'next'

  ui.img.on 'touchstart' ->
    pc.ws.send 'next'

    ui.img.css 'border' '1px solid black'
    setTimeout -> ui.img.css 'border' 'none'
    , 1000
  ui.img.on 'touchend' ->
    ui.img.css 'border' 'none'
  ui.img.on 'touchcancel' ->
    ui.img.css 'border' 'none'


  export ui

