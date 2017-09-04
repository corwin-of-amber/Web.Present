{EventEmitter} = require 'events'



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
      ctx = canvas.0.getContext('2d')
      canvas.0.width = viewport.width ; canvas.0.height = viewport.height

      page.render do
        canvasContext: ctx
        viewport: viewport
      .then ~>
      #  canvas.0.toBlob (@blob) ~> @emit('rendered')
        canvas

  goto-page: (page-num) ->
    @selected-page = page-num
    @canvas[page-num] ?= @render-page(page-num)
      ..then (canvas) ~> @containing-element
        ..find 'canvas' .remove!
        ..append canvas
        @blob <~ canvas.0.toBlob
        @emit 'displayed' canvas

  flush: -> @canvas = {}

  refresh: -> @flush! ; if @selected-page then @goto-page that


/**
 * Builds an index of page number -> slide number, based on a heuristic
 * that slide number captions exist on (most) pages and do not move
 * during build animations.
 */
SlideIndex =   # mixin
  prepare-slide-index: ->
    pages = [@pdf.getPage(i) for i from 1 to @pdf.numPages]
    slide-index = {}
    pages.reduce (promise, page) ->
      promise.then (prev) -> page.then (page) ->
        page.getTextContent!then ({items: text-items}) ->
          old-witnesses = text-items.filter ((x) -> prev.possible-captions.some (=== x))
          new-witnesses = text-items.filter (.str ~= prev.slide-num + 1)
          slide-num = if old-witnesses.length then prev.slide-num else prev.slide-num + 1
          possible-captions = if old-witnesses.length then old-witnesses else new-witnesses
          slide-index[page.pageNumber] = slide-num
          {slide-num, possible-captions}
    , Promise.resolve slide-num: 0, possible-captions: []
    .then ~> @slide-index = slide-index

Nav =   # mixin
  nav-bind-ui: ->
    $ 'body' .click ~> @next-page!
    $ 'body' .keydown (ev) ~>
      switch ev.key
        case "ArrowRight" => @next-page!
        case "ArrowLeft" => @prev-page!
    @on 'close' ->
      $ 'body' .off 'click'    /* @@@ removing all handlers */
      $ 'body' .off 'keydown'

  next-page: ->
    @goto-page ++@selected-page

  prev-page: ->
    if @selected-page > 1
      @goto-page --@selected-page

Annotate =   # mixin
  annotate-start: ->
    @overlay = new Overlay @containing-element
    @page-overlay-state = {}
    @on 'displayed' (canvas) ~>
      @overlay.cover canvas
      slide-num = @slide-index?[@selected-page] ? @selected-page
      @overlay.set-state @page-overlay-state[slide-num] ? []
    @containing-element.mousedown (ev) !~>
      if ev.button == 2 && $(ev.target).is('canvas')  # right button
        @overlay.add-annotation ev.offsetX, ev.offsetY
        @annotate-changed!

  annotate-changed: ->
    slide-num = @slide-index?[@selected-page] ? @selected-page
    @page-overlay-state[slide-num] = @overlay.get-state!
    server.broadcast "refresh"


class Viewer extends ViewerCore

Viewer.prototype <<<< SlideIndex <<<< Nav <<<< Annotate


viewer = undefined

Viewer.open = (uri) ->
  viewer?emit 'close'
  PDFJS.getDocument(uri).then (pdf) ->
    viewer := new Viewer(pdf)
      ..annotate-start!
      ..nav-bind-ui!
      ..prepare-slide-index!
      ..on 'displayed' -> server.broadcast "refresh"
      ..goto-page 1
      $(window).resize -> ..refresh!
      ..on 'close' -> $(window).off 'resize'

    localStorage.last-uri = uri

    export viewer


export Viewer, viewer


$ ->
  $ 'body' .on 'contextmenu'/*, 'canvas'*/,  (.preventDefault!)
  Viewer.open(localStorage.last-uri ? URI)

  window.open('/src/client.html', 'client')
