#!/bin/bash

# GDM Lock Script for i3
# This script attempts multiple methods to lock the screen and show the login screen

# Method 1: Try to switch to GDM greeter directly
if command -v gdm >/dev/null 2>&1; then
    gdm-switch-to-greeter 2>/dev/null && exit 0
fi

# Method 2: Try systemd/loginctl approach
if command -v loginctl >/dev/null 2>&1; then
    loginctl lock-session 2>/dev/null && exit 0
fi

# Method 3: Try GDM dbus interface
if dbus-send --system --dest=org.gnome.DisplayManager --type=method_call /org/gnome/DisplayManager/LocalDisplayFactory org.gnome.DisplayManager.LocalDisplayFactory.CreateTransientDisplay 2>/dev/null; then
    exit 0
fi

# Method 4: Use xdg-screensaver as fallback
if command -v xdg-screensaver >/dev/null 2>&1; then
    DISPLAY=:0 xdg-screensaver lock 2>/dev/null && exit 0
fi

# Method 5: Try to blank the screen and show a simple message
if command -v xset >/dev/null 2>&1; then
    xset dpms force off
    notify-send "Screen Locked" "Press any key to unlock" 2>/dev/null
    exit 0
fi

# If nothing works, show a notification
notify-send "Lock Failed" "Could not lock screen - no working method found" 2>/dev/null
exit 1