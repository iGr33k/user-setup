#!/bin/bash

set -ex

declare -A SBINS_URLS
SBINS_URLS[nvim]=https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
SBINS_URLS[htop]=https://github.com/iGr33k/static-bin/raw/master/amd64/htop
SBINS_URLS[tmux]=https://github.com/iGr33k/static-bin/raw/master/amd64/tmux
SBINS_URLS[fish]=https://github.com/mliszcz/fish-shell/releases/download/fish-3.6.0-x86_64/fish-3.6.0-x86_64.AppImage
SBINS_URLS[gdb]=https://github.com/iGr33k/static-bin/raw/master/amd64/gdb-7.10.1-x64
SBINS_URLS[gdb_server]=https://github.com/iGr33k/static-bin/raw/master/amd64/gdbserver-7.10.1-x64

declare -A FONT_URLS
FONT_URLS[hack]=https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip
FONT_URLS[hack-nerd]=https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip

USR_FONTDIR=$HOME/.fonts
USR_BIN=$HOME/bin

APT_PACKAGES=("curl" "git" "wget" "bat" "tmux" "fish" "dconf-cli" "unzip" "uuid-runtime" "ranger" "flatpak" "virt-manager" "qemu-system" "qemu-user" "python3-pip" "python3-virtualenv" "python3-ipython" "ugrep" "gdb" "gdbserver" "build-essential" "telegram-desktop" "wireguard")
FLATPACK_PACKAGES=("com.github.zadam.trilium" "com.github.Eloston.UngoogledChromium" "org.ghidra_sre.Ghidra")

install_apt_packages() {
	sudo apt update 
	for x in ${!APT_PACKAGES[@]}
	do 
		sudo apt-get -q install -y ${APT_PACKAGES[$x]}
	done
}

install_docker(){
	sudo apt-get install \
	    ca-certificates \
	    curl \
	    gnupg \
	    lsb-release
	sudo mkdir -m 0755 -p /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER
}


install_flatpak_packages() {
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	for x in ${!FLATPACK_PACKAGES[@]}
	do 
		sudo flatpak install flathub -y --noninteractive ${FLATPACK_PACKAGES[$x]}
	done
}

install_fonts(){

	mkdir_check $USR_FONTDIR/ttf
	for x in ${!FONT_URLS[@]}
	do 
		wget ${FONT_URLS[$x]} -O /tmp/temp.zip
    if [[ $x == *"nerd"* ]] 
    then
      unzip -qo  /tmp/temp.zip -d $USR_FONTDIR/ttf
    else
      unzip -qo  /tmp/temp.zip -d $USR_FONTDIR
    fi
	done
	fc-cache -fv
}

mkdir_check(){
	if [ ! -d $1 ]; then
		mkdir -p $1;
	fi
}

install_dot_files() {
	mkdir_check $USR_BIN

	wget ${SBINS_URLS[nvim]} -O $USR_BIN/nvim && chmod +x $USR_BIN/nvim

	curl -sLf https://spacevim.org/install.sh | bash

	cd
	git clone https://github.com/gpakosz/.tmux.git
	ln -s -f .tmux/.tmux.conf
	cp .tmux/.tmux.conf.local .

	bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
	
}

install_static_bins() {
	mkdir_check $USR_BIN

	for x in "${!SBINS_URLS[@]}"; do 
		printf "[%s]=%s\n" "$x" "${SBINS_URLS[$x]}" ;
		wget ${SBINS_URLS[$x]} -O $USR_BIN/$x 
		chmod +x $USR_BIN/$x
	done

}


help()
{
   echo "Add description of the script functions here."
   echo
   echo "Syntax: setup-user-env.sh [-p|s]"
   echo "options:"
   echo "-p     Portable mode, download static bins int $USR_BIN"
   echo "-s     System mode, install packages and stuff"
   echo
}

while getopts ":hps" option; do
	case $option in
		h) # display Help
			help
			exit;;
		p)
			echo portable mode
			install_static_bins
			install_dot_files
			exit;;
		s)
			echo system mode
			install_apt_packages
			install_flatpak_packages
			install_dot_files
			install_docker
			install_fonts
			exit;;
		\?)
			echo "Error: unknow option"
			exit;;
	esac
done
