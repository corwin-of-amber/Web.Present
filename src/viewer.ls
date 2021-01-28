{EventEmitter} = require 'events'

# Required PDFJS configuration
# (for correct rendering of Unicode characters)
# see https://github.com/mozilla/pdf.js/issues/9495
PDFJS_CMAP_CONFIG =
  cMapUrl: '../node_modules/pdfjs-dist/cmaps/'
  cMapPacked: true
# yeah...
pdfjsLib.GlobalWorkerOptions.workerSrc = '/node_modules/pdfjs-dist/build/pdf.worker.js'



class ViewerCore extends EventEmitter

  (@pdf, @containing-element ? $('body')) ->
    super!
    @canvas = {}
    #@canvas[1] = @render-page(1)
    @selected-page = undefined
    @resolution = 2

  render-page: (page-num) ->
    canvas = $('<canvas>')
    @pdf.getPage(page-num).then (page) ~>
      viewport = page.getViewport({scale: 1})  # get base size of page
      @get-display-size!
        scale = Math.min(..height / viewport.height, ..width / viewport.width)
      scale = scale * @resolution
      viewport = page.getViewport({scale})
      canvas.0
        ..width = viewport.width ; ..height = viewport.height
        ..style.width = "#{viewport.width / @resolution}px"
      ctx = canvas.0.getContext('2d')

      page.render do
        canvasContext: ctx
        viewport: viewport
      .promise.then ~>
        canvas
  
  get-display-size: ->
    height: @containing-element.height!
    width: if @containing-element.hasClass('slide-left') \
            then $(window).width! else @containing-element.width!

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

  toggle-fullscreen: -> nw.Window.get!
    if ..isFullscreen then ..leaveFullscreen! else ..enterFullscreen!
    @refresh!
  
  toggle-windowed-present: ->
    $ 'body' .toggle-class 'fullscreen'
      if ..has-class 'fullscreen' then hide-menu! else show-menu!
    @refresh!


  set-sled: (flag) ->
    if flag then @containing-element.addClass 'slide-left'
    else @containing-element.removeClass 'slide-left'


/**
 * Builds an index of page number -> slide number, based on a heuristic
 * that slide number captions exist on (most) pages and do not move
 * during build animations.
 */
SlideIndex =   # mixin
  prepare-slide-index: ->
    pages = [[i, @pdf.getPage(i)] for i from 1 to @pdf.numPages]
    slide-index = []
    slide-offset = 0
    trace = @_slide-index-trace = []
    pages.reduce (promise, [idx, page]) ->
      promise.then (prev) -> page.then (page) ->
        page.getTextContent!then ({items: text-items}) ->
          old-witnesses = text-items.filter ((x) -> prev.possible-captions.some (=== x))
          new-witnesses = text-items.filter (.str ~= prev.slide-num + 1)
          restart-witnesses = text-items.filter (.str == '1')
          if old-witnesses.length
            slide-num = prev.slide-num
          else if new-witnesses.length || !restart-witnesses.length
            slide-num = prev.slide-num + 1
          else
            slide-num = 1; slide-offset := prev.slide-num + slide-offset
            new-witnesses = restart-witnesses
          possible-captions = if old-witnesses.length then old-witnesses else new-witnesses
          slide-index[idx] = slide-num + slide-offset
          trace.push {idx, page, slide-num, slide-offset, old-witnesses, new-witnesses, restart-witnesses}
          {slide-num, possible-captions}
    , Promise.resolve slide-num: 0, possible-captions: []
    .then ~> @slide-index = slide-index

  get-slide-page: (slide-number) ->
    for _slide-number, page-index in @slide-index
      if _slide-number == slide-number
        return page-index

  goto-slide: (num) ->
    page = @get-slide-page num
    if page? then @goto-page page

  next-slide: ->
    @goto-slide @slide-index[@selected-page] + 1

  prev-slide: ->
    @goto-slide @slide-index[@selected-page] - 1


Nav =   # mixin
  nav-bind-ui: ->
    @nav-history = [@selected-page ? 1]
    $ 'body' .click click_eh = (ev) ~> @next-page!
    $ 'body' .keydown keydown_eh = (ev) ~>
      switch ev.key
        case "ArrowRight" => @next-page!
        case "ArrowLeft"  => @prev-page!
        case "ArrowDown" \
             "PageDown"   => @next-slide!   # these two depend on SlideIndex
        case "ArrowUp" \
             "PageUp"     => @prev-slide!
        case "Home"       => @nav-goto-first!
        case "End"        => @nav-goto-last!
        case "Backspace"  => @nav-go-back!
    @on 'close' ->
      $ 'body' .off 'click', click_eh
      $ 'body' .off 'keydown', keydown_eh

  nav-goto-page: (num) ->
    @nav-history.push @selected-page
    @goto-page num

  nav-go-back: ->
    if @nav-history.length > 0
      num = @nav-history.pop!
      @goto-page num

  nav-goto-first: -> @nav-goto-page 1
  nav-goto-last: -> @nav-goto-page @pdf.numPages

  next-page: ->
    @nav-goto-page @selected-page + 1

  prev-page: ->
    if @selected-page > 1
      @nav-goto-page @selected-page - 1


Annotate =   # mixin
  annotate-start: ->
    @overlay = new Overlay @containing-element
    @page-overlay-state = {}
    @on 'displayed' (canvas) ~>
      setTimeout ~>
        @overlay.cover canvas, @resolution
      , 1200  /** @todo this is a hack, canvas may not have stabilized? */
      slide-num = @slide-index?[@selected-page] ? @selected-page
      @overlay.set-state @page-overlay-state[slide-num] ? []
    @on 'close' ~> @overlay.remove!
    @containing-element.mousedown (ev) !~>
      if ev.button == 2 && $(ev.target).is('canvas')  # right button
        @overlay.add-annotation ev.offsetX, ev.offsetY
        @annotate-changed!

  annotate-changed: ->
    slide-num = @slide-index?[@selected-page] ? @selected-page
    @page-overlay-state[slide-num] = @overlay.get-state!
    server.broadcast "refresh"


Announce =   # mixin
  announce: (message) ->
    ann = $ '<div>' .addClass 'announcement' .append \
         ($ '<span>' .addClass 'caption' .text message)
      ..offset do
        left: @overlay.box.left + @overlay.box.width / 2
        top: @overlay.box.top + @overlay.box.height / 5
    viewer.overlay.div.append ann
    times = 9
    x = setInterval ->
      ann.toggle!
      if --times <= 0 then ann.remove! ; clearInterval x
    , 333


AppletIntegration =   # mixin
  applet-init: ->
    applet.set-visible false
    applet.load!
    $(document).keydown (ev) ~>
      if ev.originalEvent.code == 'KeyA' then @applet-toggle!
  applet-toggle: ->
    @applet-active = !@applet-active
    @set-sled @applet-active
    applet.set-visible @applet-active


Animations =        # mixin
  cycle-through: (page-indexes) ->>
    delay = (ms) -> new Promise(-> setTimeout(it, ms))
    while true
      for i in page-indexes
        @goto-page i
        await delay(500)
        if @selected-page != i then return  # abort
      await delay(2000)
      if @selected-page != i then return  # abort

  fast-forward: (to-page) ->>
    delay = (ms) -> new Promise(-> setTimeout(it, ms))
    i = @selected-page
    while i < to-page
      i += 1
      await @goto-page i
      await delay(10)
      if @selected-page != i then return  # abort


class Viewer extends ViewerCore

Viewer.prototype <<<< SlideIndex <<<< Nav <<<< Annotate <<<< Announce <<<< AppletIntegration <<<< Animations


viewer = undefined

Viewer.open = (uris) ->>
  viewer?emit 'close'

  if !Array.isArray(uris) then uris = [uris]
  load = (url) -> pdfjsLib.getDocument({url, ...PDFJS_CMAP_CONFIG})
  pdfs = await Promise.all([load(..).promise for uris])
  viewer := new Viewer(new MultiPDF(pdfs))
  window.viewer = viewer
  viewer
    ..annotate-start!
    ..nav-bind-ui!
    ..prepare-slide-index!
    #..applet-init!
    ..on 'displayed' -> server.broadcast "refresh"
    ..goto-page 1
    $(window).resize -> ..refresh!
    ..on 'close' -> $(window).off 'resize'

  localStorage.last-uri = uris.join(';')

  export viewer


class MultiPDF
  (@pdfs) ->
    @numPages = [..numPages for @pdfs].reduce((a,b) -> a + b)
  
  getPage: (page-no) ->
    i = page-no
    for pdf in @pdfs
      if i <= pdf.numPages then return pdf.getPage(i)
      else i -= pdf.numPages


export Viewer, viewer


$ ->
  $ 'body' .on 'contextmenu' (.preventDefault!)
  $ 'body' .on 'keydown' (ev) ->
    switch ev.key
      case "f" => viewer.toggle-fullscreen!
      case "g" => viewer.toggle-windowed-present!
      case "Escape" => nw.Window.get!leaveFullscreen!
  nw.Window.get!
    ..on 'enter-fullscreen' -> $ 'body' .add-class 'fullscreen'; $(window).resize!
    ..on 'restore' -> $ 'body' .remove-class 'fullscreen'; $(window).resize!
  if localStorage.last-uri
    Viewer.open that.split(';')

  # For development
  if localStorage.client-win-open
    window.open('/src/client.html', 'client')
