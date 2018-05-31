robot = require 'robotjs'

# For Microsoft Surface Pen

hotkeys =
  "Command+F20": -> robot.keyTap "space"
  "Command+F19": -> robot.keyTap "left"
  "Command+F18": -> robot.keyTap "left"

shortcuts =
  for let k, v of hotkeys
    new nw.Shortcut {key: k, \
                     active: (-> console.log "Global hotkey: #{this.key}"; v!), \
                     failed: -> console.log it}
      nw.App.registerGlobalHotKey ..


window.addEventListener 'unload' ->
  for shortcut in shortcuts then nw.App.unregisterGlobalHotKey(shortcut)
