os = require 'os'

# Menu actions
dialog = require 'nw-dialog'
dialog.setContext document

open = ->
  dialog.openFileDialog true ->
    Viewer.open ["file://#{..}" for it.split(';')]

$ -> # hack to prevent 'click' from dialog.openFileDialog to reach body eh
  $ 'body' .on 'click' '#open-file-dialog' (ev) ->
    ev.stopPropagation!

# Create an empty menubar
menu = new nw.Menu({type: 'menubar'})

if os.platform! == 'darwin'
  cmd = 'cmd'
  menu.createMacBuiltin 'web-present'
  menu-window = menu.items[*-1]
else
  cmd = 'ctrl'
  menu.append do
    menu-window = new nw.MenuItem do
      label: "Window"
      submenu: new nw.Menu()

menu-window.submenu.append new nw.MenuItem do
  label: "Devtools"
  key: 'i'
  modifiers: 'alt+'+cmd
  click: -> nw.Window.get(global.activeWindow).showDevTools!
menu-window.submenu.append new nw.MenuItem do
  label: "Reload"
  key: 'r'
  modifiers: cmd
  click: -> window._rebuildAndReload!
menu-window.submenu.append new nw.MenuItem do
  label: "Client"
  key: 'c'
  modifiers: cmd+'+shift'
  click: -> nw.Window.open('/src/client.html')

# Create the File menu
submenu = new nw.Menu()
submenu.append(new nw.MenuItem({label: "Open...", click: open}))

menu.insert(new nw.MenuItem({
  label: 'File',
  submenu: submenu
}), 1)

# Assign it to `window.menu` to get the menu displayed
nw.Window.get!
  hide-menu = -> ..menu = null
  show-menu = -> ..menu = menu
  
  show-menu!
  # hide menu on fullscreen
  if os.platform! != 'darwin'  # (on Mac this happens automatically)
    ..on 'enter-fullscreen' hide-menu
    ..on 'restore' show-menu

  window <<< {hide-menu, show-menu}
