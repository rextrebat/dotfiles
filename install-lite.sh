#!/usr/bin/env bash

######################################################
# zsh, tmux, nvim, i3+polybar, .Xresources, gnupg    #
######################################################
#
# zsh

echo "[*] Installing zsh"

sudo apt install zsh -y

echo "[*] Downloading oh-my-zsh"

rm -rf ~/.oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

echo "[*] Linking zshrc"

ln -sf /home/kdasgupta/workspace/dotfiles/_zshrc ~/.zshrc

#
# tmux

echo "[*] Installing tmux"

sudo apt install tmux -y

echo "[*] Linking tmux.conf"

ln -sf /home/kdasgupta/workspace/dotfiles/_tmux.conf ~/.tmux.conf

#
# nvim

echo "[*] nvim installer script..."

(cd config/nvim && sh install.sh)

