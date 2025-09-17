#!/bin/bash

# Test script to find working lock command
echo "Testing lock commands..."

echo "1. Testing gnome-screensaver-command..."
if command -v gnome-screensaver-command >/dev/null 2>&1; then
    echo "  gnome-screensaver-command is available"
    gnome-screensaver-command --lock 2>&1 &
    echo "  Attempted to lock with gnome-screensaver-command"
    exit 0
else
    echo "  gnome-screensaver-command not found"
fi

echo "2. Testing GNOME dbus lock..."
if dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock 2>/dev/null; then
    echo "  Locked with GNOME dbus"
    exit 0
else
    echo "  GNOME dbus lock failed"
fi

echo "3. Testing loginctl lock-session..."
if loginctl lock-session 2>/dev/null; then
    echo "  Locked with loginctl"
    exit 0
else
    echo "  loginctl lock failed"
fi

echo "4. Testing xdg-screensaver..."
if command -v xdg-screensaver >/dev/null 2>&1; then
    xdg-screensaver lock
    echo "  Attempted xdg-screensaver lock"
    exit 0
else
    echo "  xdg-screensaver not found"
fi

echo "No working lock command found!"
exit 1