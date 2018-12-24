# For Microsoft Surface Pen

mode = "internal"

if mode == "external"
  /*
   * use the following code to control PowerPoint or Keynote */

  robot = require 'robotjs'

  hotkeys =
    "Command+F20": -> robot.keyTap "space"
    "Command+F19": -> robot.keyTap "left"
    "Command+F18": -> robot.keyTap "left"

if mode == "internal"
  /*
   * use the following code to control the viewer on the server */
  hotkeys =
    "Command+F20": -> viewer.nextPage!
    "Command+F19": -> viewer.prevPage!
    "Command+F18": -> viewer.prevPage!




shortcuts =
  for let k, v of hotkeys
    new nw.Shortcut {key: k, \
                     active: (-> console.log "Global hotkey: #{this.key}"; v!), \
                     failed: -> console.log it}
      nw.App.registerGlobalHotKey ..


window.addEventListener 'unload' ->
  for shortcut in shortcuts then nw.App.unregisterGlobalHotKey(shortcut)
