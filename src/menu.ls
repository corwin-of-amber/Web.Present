
# Menu actions
dialog = require 'nw-dialog'
dialog.setContext document

open = ->
  dialog.openFileDialog -> Viewer.open "file://#{it}" #console.log it

# Create an empty menubar
menu = new nw.Menu({type: 'menubar'})

menu.createMacBuiltin 'web-present'  # TODO skip this for non-Mac
menu.items[*-1].submenu.append new nw.MenuItem do
  label: "Devtools"
  key: 'i'
  modifiers: 'alt+cmd'
  click: -> nw.Window.get(global.activeWindow).showDevTools!
menu.items[*-1].submenu.append new nw.MenuItem do
  label: "Reload"
  key: 'r'
  modifiers: 'cmd'
  click: -> window._rebuildAndReload!
menu.items[*-1].submenu.append new nw.MenuItem do
  label: "Client"
  key: 'c'
  modifiers: 'cmd+shift'
  click: -> window.open('/src/client.html', 'client')

# Create a submenu as the 2nd level menu
submenu = new nw.Menu()
submenu.append(new nw.MenuItem({label: "Open...", click: open}))

# Create and append the 1st level menu to the menubar
menu.insert(new nw.MenuItem({
  label: 'File',
  submenu: submenu
}), 1)

# Assign it to `window.menu` to get the menu displayed
nw.Window.get().menu = menu
