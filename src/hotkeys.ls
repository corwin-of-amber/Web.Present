# For Microsoft Surface Pen

sp = new URLSearchParams(location.search)
mode = sp.get('hotkeys') ? "internal"


if mode == "external"
  /*
   * use the following code to control PowerPoint or Keynote
   */
  nutjs = require '@nut-tree/nut-js'

  hotkeys =
    "Command+F20": -> nutjs.keyboard.pressKey nutjs.Key.Right
    "Command+F19": -> nutjs.keyboard.pressKey nutjs.Key.Left
    "Command+F18": -> nutjs.keyboard.pressKey nutjs.Key.Left

else if mode == "internal"
  /*
   * use the following code to control the viewer on the server 
   */
  hotkeys =
    "Command+F20": -> viewer.next-page!
    "Command+F19": -> viewer.prev-page!
    "Command+F18": -> viewer.prev-page!
    "Ctrl+Alt+F":  -> viewer.toggleFullscreen!

  require! os

  if os.platform! == 'win32'
    try
      console.log 'launching pen.py'
      child_process = require('child_process')
      pen = child_process.spawn('python', ['pen.py'])
      pen.stdout.setEncoding('utf8')
      pen.stderr.setEncoding('utf8')
      pen.stderr.on 'data' console~warn
      pen.stdout.on 'data' (ln) ->
        console.log "pen: #{ln}"
        if ln.startsWith('>>') then viewer.next-page!
        if ln.startsWith('<<') then viewer.prev-page!

      window.addEventListener 'unload' ->
        pen.kill!
    catch e
      console.error e

else
  hotkeys = {}



shortcuts =
  for let k, v of hotkeys
    try
      new nw.Shortcut {key: k, \
                      active: (-> console.log "Global hotkey: #{this.key}"; v!), \
                      failed: -> console.error it}
        nw.App.registerGlobalHotKey ..
    catch e
      console.error e

window.addEventListener 'unload' ->
  for shortcut in shortcuts
    try nw.App.unregisterGlobalHotKey(shortcut)
    catch e
