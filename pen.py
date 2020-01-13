import keyboard
keyboard.register_hotkey("command+f20", lambda: print('>>', flush=True))
keyboard.register_hotkey("command+f19", lambda: print('<<', flush=True))
keyboard.register_hotkey("command+f18", lambda: print('<<', flush=True))

# This doesn't work :(
#keyboard.register_hotkey("command+f20", lambda: keyboard.send("ctrl+alt+f1"))
#keyboard.register_hotkey("command+f19", lambda: keyboard.send("ctrl+alt+f2"))
#keyboard.register_hotkey("command+f18", lambda: keyboard.send("ctrl+alt+f2"))

input()
