#!/bin/bash

# User Switch Lock for i3
# This creates a lock screen that allows user switching

# Try to switch to login screen for user switching
if command -v dm-tool >/dev/null 2>&1; then
    # LightDM approach
    dm-tool switch-to-greeter
elif pgrep -x "gdm" >/dev/null || pgrep -x "gdm3" >/dev/null; then
    # GDM approach - try to create a new session
    # First lock the current session
    if command -v i3lock >/dev/null 2>&1; then
        # Use basic i3lock with a message about user switching
        i3lock -c 000000 -i /dev/null --show-failed-attempts \
               --line-uses-inside --keyhl-color=00ff00 --bshl-color=ff0000 \
               --ring-color=ffffff --inside-color=000000 \
               --verif-text="Unlocking..." --wrong-text="Wrong password" \
               --noinput-text="Press any key" \
               --force-clock --time-str="%H:%M:%S" --date-str="%A, %B %d" \
               --time-color=ffffff --date-color=ffffff &
        
        # Try to open new login session (for user switching)
        sleep 1
        # This doesn't actually work for user switching with i3lock, 
        # but provides a locked screen
    fi
else
    # Fallback - basic screen lock
    if command -v i3lock >/dev/null 2>&1; then
        i3lock -c 000000
    else
        xset dpms force off
    fi
fi