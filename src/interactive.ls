

APPLET =
  base-uri: "file://#{_process.env.HOME}/var/workspace/Teaching.Compilers.Lecture/applets/shift-reduce"
  assets: ["shift-reduce.js", "shift-reduce.css"]


class EmbeddedApplet

  (@containing-element ? $('body')) ->
    @div = $ '<div>' .addClass 'applet-container'
  
  load: ->
    for a in APPLET.assets
      @div.append @mktag("#{APPLET.base-uri}/#{a}")
    @containing-element.append @div

  mktag: (uri) ->
    if uri.endsWith('.js')
      $ '<script>' .attr src: uri
    else if uri.endsWith('.css')
      $ '<link>' .attr href: uri, rel: 'stylesheet', type: 'text/css'
    else
      throw new Error("unrecognized asset '#{uri}'")
  
  set-visible: (flag) ->
    if flag then @div.removeClass 'folded'
    else @div.addClass 'folded'



$ ->
  applet = new EmbeddedApplet

  window <<< {applet}