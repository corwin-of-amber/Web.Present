{EventEmitter} = require 'events'



URI = "/bower_components/pdfjs/examples/helloworld/helloworld.pdf"
URI = "../data/01-intro.pdf"


class ViewerCore extends EventEmitter

  (@pdf, @containing-element ? $('body')) ->
    super!
    @canvas = {}
    @canvas[1] = @render-page(1)
    @selected-page = undefined

  render-page: (page-num) ->
    canvas = $('<canvas>')
    @pdf.getPage(page-num).then (page) ~>
      viewport = page.getViewport(1)
      @containing-element
        scale = Math.min(..height! / viewport.height, ..width! / viewport.width)
      viewport = page.getViewport(scale)
      console.log viewport
      ctx = canvas.0.getContext('2d')
      canvas.0.width = viewport.width ; canvas.0.height = viewport.height

      page.render do
        canvasContext: ctx
        viewport: viewport
      .then ~>
        canvas.0.toBlob (@blob) ~> @emit('rendered')
        canvas

  goto-page: (page-num) ->
    @selected-page = page-num
    @canvas[page-num] ?= @render-page(page-num)
      ..then ~> @containing-element
        console.log it
        ..find 'canvas' .remove!
        ..append it
        @emit 'displayed' it

  flush: -> @canvas = {}

  refresh: -> @flush! ; if @selected-page then @goto-page that


Nav =   # mixin
  next-page: ->
    @goto-page ++@selected-page

  prev-page: ->
    if @selected-page > 1
      @goto-page --@selected-page



class Viewer extends ViewerCore

Viewer.prototype <<<< Nav


$ ->
  overlay = new Overlay $ 'body'

  export overlay

  PDFJS.getDocument(URI).then (pdf) ->
    viewer = new Viewer(pdf)
      ..on 'rendered' -> server.broadcast "refresh"
      ..on 'displayed' (canvas) ->
      ..goto-page 1
      $ 'body' .click -> ..next-page!
      $ 'body' .mousedown (ev) !->
        console.log ev.button
        if ev.button == 2 && $(ev.target).is('canvas')  # right button
          overlay.add-annotation ev.offsetX, ev.offsetY
      $(window).resize -> ..refresh!

      $ 'body' .on 'contextmenu'/*, 'canvas'*/,  (.preventDefault!)

    export viewer

    window.open('/src/client.html', 'client')
