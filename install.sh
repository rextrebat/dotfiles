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

#
# i3 + polybar
# https://github.com/regolith-linux/speed-ricer

echo "[*] Installing i3-gaps and polybar"

sudo add-apt-repository -y ppa:kgilmer/speed-ricer
sudo apt install i3-gaps polybar -y

echo "[*] Linking configs"

ln -sf /home/kdasgupta/workspace/dotfiles/config/i3 ~/.config/i3
ln -sf /home/kdasgupta/workspace/dotfiles/config/polybar ~/.config/polybar

echo "[*] Installing compton"
sudo apt install compton -y

echo "[*] Linking configs"
ln -sf /home/kdasgupta/workspace/dotfiles/config/compton ~/.config/compton

#
# Xresources

echo "[*] Linking .Xresources"

ln -sf /home/kdasgupta/workspace/dotfiles/_Xresources ~/.Xresources

#
# gnupg

echo "[*] Linking gnupg"

ln -sf /home/kdasgupta/workspace/dotfiles/_gnupg ~/.gnupg

###################################################

# Older installer
function link_file {
    source="${PWD}/$1"
    target="${HOME}/${1/_/.}"

    if [ -e "${target}" ]; then
        mv $target $target.bak
    fi

    ln -sf ${source} ${target}
}

# for i in _*
# do
#     link_file $i
# done

# git submodule sync
# git submodule init
# git submodule update
# git submodule foreach git pull origin master
# git submodule foreach git submodule init
# git submodule foreach git submodule update

