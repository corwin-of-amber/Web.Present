

class Overlay

  (@container-element) ->
    @div = $ '<div>' .add-class 'overlay'
      ..append-to @container-element
    @annotations = []

  add-annotation: (x, y, classes=['centered', 'circle']) ->
    $ '<a>' .add-class 'annotation'
      ..offset {left: x, top: y}
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
      @add-annotation x, y, classes



export Overlay

