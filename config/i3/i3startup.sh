#!/usr/bin/env bash

# Modern i3 Startup Script
# Handles initialization of desktop environment components

# Merge X resources
if [ -f ~/.Xresources ]; then
    xrdb -merge ~/.Xresources
    echo "Loaded X resources"
fi

# Start PulseAudio
if command -v pulseaudio >/dev/null 2>&1; then
    start-pulseaudio-x11 &
    echo "Started PulseAudio"
fi

# Restore wallpaper
if command -v nitrogen >/dev/null 2>&1; then
    nitrogen --restore &
    echo "Restored wallpaper"
fi

# Start compositor (prefer picom over compton)
if command -v picom >/dev/null 2>&1; then
    picom --config ~/.config/picom/picom.conf &
    echo "Started picom compositor"
elif command -v compton >/dev/null 2>&1; then
    compton &
    echo "Started compton compositor"
fi

# Start notification daemon
if command -v dunst >/dev/null 2>&1; then
    dunst &
    echo "Started dunst notifications"
fi

# Start blue light filter
if command -v redshift >/dev/null 2>&1; then
    redshift &
    echo "Started redshift"
fi

# Start clipboard manager
if command -v clipmenud >/dev/null 2>&1; then
    clipmenud &
    echo "Started clipboard daemon"
fi

# Start auto-mounting daemon
if command -v udisks-glue >/dev/null 2>&1; then
    udisks-glue &
    echo "Started auto-mount daemon"
fi

# Set cursor theme
if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -cursor_name left_ptr
fi

# Configure touchpad (if present)
if command -v xinput >/dev/null 2>&1; then
    TOUCHPAD=$(xinput list | grep -i touchpad | head -n1 | grep -o 'id=[0-9]*' | grep -o '[0-9]*')
    if [ -n "$TOUCHPAD" ]; then
        xinput set-prop $TOUCHPAD "libinput Tapping Enabled" 1
        xinput set-prop $TOUCHPAD "libinput Natural Scrolling Enabled" 1
        echo "Configured touchpad settings"
    fi
fi

# Set keyboard repeat rate
if command -v xset >/dev/null 2>&1; then
    xset r rate 300 50
    echo "Set keyboard repeat rate"
fi

# Start xbindkeys for function key bindings
if command -v xbindkeys >/dev/null 2>&1; then
    pkill -x xbindkeys 2>/dev/null || true
    xbindkeys &
    echo "Started xbindkeys"
fi

echo "i3 startup script completed"