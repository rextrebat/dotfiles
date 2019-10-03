#!/bin/bash

xrdb -merge ~/.Xresources

start-pulseaudio-x11&
echo "Started pulseaudio"

(nitrogen --restore)&
echo "Restored wallaper"

compton &
echo "Started compton"

redshift &
echo "Started redshift"

