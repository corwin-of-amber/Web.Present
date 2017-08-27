/* This code runs in a regular browser (no NWjs API access) */
/* -and- in NWjs on the server side */

class Overlay

  (@container-element) ->
    @div = $ '<div>' .add-class 'overlay'
      ..append-to @container-element
    @box = {left: 0, top: 0, width: 800, height: 600}
    @annotations = []

  normx: (x) -> (x/* - @box.left*/) / @box.width
  normy: (y) -> (y/* - @box.top*/) / @box.height
  denormx: (x) -> x * @box.width # + @box.left
  denormy: (y) -> y * @box.height # + @box.top

  cover: ($el) -> $el.0   #
    @box =
      left: ..clientLeft #..offsetLeft - @container-element.0.offsetLeft
      top: ..clientTop #..offsetTop - @container-element.0.offsetTop
      width: ..width
      height: ..height

  add-annotation: (x, y, classes=['centered', 'circle']) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: x + @box.left, top: y + @box.top}
      ..append @_create-inner classes
      @annotations.push {x: @normx(x), y: @normy(y), classes, $el: ..}
      @div.append ..

  add-annotation-client: (x, y, classes=['centered', 'circle']) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: x, top: y}
      ..append @_create-inner classes
      @annotations.push {x: @normx(x - @box.left), y: @normy(y - @box.top), classes, $el: ..}
      @div.append ..

  add-annotation-norm: (x, y, classes=['centered', 'circle']) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: @denormx(x) + @box.left, top: @denormy(y) + @box.top}
      ..append @_create-inner classes
      @annotations.push {x, y, classes, $el: ..}
      @div.append ..
  _create-inner: (classes) -> $ '<a>'
    for c in classes then ..add-class c

  clear: ->
    @div.empty!
    @annotations = []

  get-state: -> [{..x, ..y, ..classes} for @annotations]

  set-state: (state) ->
    @clear!
    for {x, y, classes} in state
      @add-annotation-norm x, y, classes



export Overlay
