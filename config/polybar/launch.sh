#!/bin/sh

# Terminate already running bar instances
killall -q polybar

for m in $(polybar --list-monitors | cut -d":" -f1);
do
    MONITOR=$m polybar --reload top &
done

for m in $(polybar --list-monitors | cut -d":" -f1);
do
    MONITOR=$m polybar --reload bottom &
done

echo "Bars launched..."
