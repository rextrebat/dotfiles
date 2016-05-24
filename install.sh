#!/usr/bin/env bash
function link_file {
    source="${PWD}/$1"
    target="${HOME}/${1/_/.}"

    if [ -e "${target}" ]; then
        mv $target $target.bak
    fi

    ln -sf ${source} ${target}
}

for i in _*
do
    link_file $i
done

# git submodule sync
# git submodule init
# git submodule update
# git submodule foreach git pull origin master
# git submodule foreach git submodule init
# git submodule foreach git submodule update

rm -rf ~/.oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
