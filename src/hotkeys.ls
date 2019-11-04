# For Microsoft Surface Pen

mode = "external"


if mode == "external"
  /*
   * use the following code to control PowerPoint or Keynote
   */
  robot = require 'robotjs'

  hotkeys =
    "Command+F20": -> robot.keyTap "right"
    "Command+F19": -> robot.keyTap "left"
    "Command+F18": -> robot.keyTap "left"

else if mode == "internal"
  /*
   * use the following code to control the viewer on the server 
   */
  hotkeys =
    "Command+F20": -> viewer.next-page!
    "Command+F19": -> viewer.prev-page!
    "Command+F18": -> viewer.prev-page!
    "Ctrl+Alt+F": -> viewer.toggleFullscreen!

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
  for shortcut in shortcuts then nw.App.unregisterGlobalHotKey(shortcut)
