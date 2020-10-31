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
      left: ..offsetLeft - @div.0.offsetLeft
      top: ..offsetTop - @div.0.offsetTop
      width: ..width
      height: ..height

  DEFAULT_ANNOT_CLASSES = ['centered', 'circle']

  add-annotation: (x, y, classes=DEFAULT_ANNOT_CLASSES, angle=0) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: x + @box.left, top: y + @box.top}
      ..append @_create-inner classes
      ..css '--angle' "#{angle}rad"
      @annotations.push {x: @normx(x), y: @normy(y), classes, angle, $el: ..}
      @div.append ..

  add-annotation-client: (x, y, classes=DEFAULT_ANNOT_CLASSES, angle=0) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: x, top: y}
      ..append @_create-inner classes
      ..css '--angle' "#{angle}rad"
      @annotations.push {x: @normx(x - @box.left), y: @normy(y - @box.top), classes, angle, $el: ..}
      @div.append ..

  add-annotation-norm: (x, y, classes=DEFAULT_ANNOT_CLASSES, angle=0) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: @denormx(x) + @box.left, top: @denormy(y) + @box.top}
      ..append @_create-inner classes
      ..css '--angle' "#{angle}rad"
      @annotations.push {x, y, classes, angle, $el: ..}
      @div.append ..

  move-annotation: (annot, x, y) ->
    annot <<< {x: @normx(x), y: @normy(y)}
    annot.$el.offset {left: x + @box.left, top: y + @box.top}

  get-annotation-from-el: ($el) ->
    el = $el.0 ? $el
    @annotations.find (a) -> $.contains(a.$el.0, el)

  remove-annotations: (by-class) ->
    for @annotations.filter (-> by-class in it.classes) => ..$el.remove!
    @annotations = @annotations.filter (-> by-class not in it.classes)

  _create-inner: (classes) -> $ '<a>'
    for c in classes then ..add-class c

  clear: ->
    @div.empty!
    @annotations = []

  get-state: -> [{..x, ..y, ..classes, ..angle} for @annotations]

  set-state: (state) ->
    @clear!
    for {x, y, classes, angle} in state
      @add-annotation-norm x, y, classes, angle



export Overlay
