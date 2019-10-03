#! /bin/zsh

ANS="$(printf " Lock\n Shutdown\n Reboot\n Exit" | rofi -lines 4 -width 20 -dmenu -p 'System')"
case "$ANS" in
	\ Lock) i3lock;;
	\ Shutdown) shutdown now;;
	\ Reboot) reboot;;
	\ Exit) i3-msg exit
esac
