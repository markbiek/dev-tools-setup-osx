#!/bin/bash

function info(){
    echo -e "\x1B[34m $1 \x1B[0m"
    if [ -n "${2}" ]; then
    echo -e "\x1B[34m $($2) \x1B[0m"
    fi
}
function error(){
    echo -e "\x1B[31m $1 \x1B[0m"
    if [ -n "${2}" ]; then
    echo -e "\x1B[31m $($2) \x1B[0m"
    fi
}
function success(){
    echo -e "\x1B[32m $1 \x1B[0m"
    if [ -n "${2}" ]; then
    echo -e "\x1B[32m $($2) \x1B[0m"
    fi
}

UNAME=`uname -s`
if [[ $UNAME -ne "Darwin" ]]; then
	error "This script can only run on OSX."
	exit 1
fi

###############################################################
# curl
if ! which curl > /dev/null; then
	error "You must have the command-line tool 'curl' installed to use this script"
	exit 1
fi

###############################################################
# Determine if we're using bash or zsh
if [[ $SHELL == '/bin/bash' ]]; then
	SHELLRC=~/.bashrc
elif [[ $SHELL == '/bin/zsh' ]]; then
	SHELLRC=~/.zshrc
else
	error "Unsupported command-line shell ($SHELL)"
	exit 1
fi

if [ ! -f $SHELLRC ]; then
	# Create the shell rc file if it doesn't exist
	touch $SHELLRC
else 
	# Backup the shell config
	cat $SHELLRC > "$SHELLRC.orig.$(date "+%Y%m%d%H%M%S")"
fi

###############################################################
# Homebrew
if ! which brew > /dev/null; then
	info "Installing Homebrew (https://brew.sh/)"
	info "Enter your password when prompted. Accept the defaults at all other prompts."

	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# Add /opt/homebrew/bin to $PATH if it's not there already
	if ! grep -E "PATH=.*?\/opt\/homebrew\/bin" $SHELLRC > /dev/null; then
		echo 'export PATH="/opt/homebrew/bin:$PATH"' >> $SHELLRC
		source $SHELLRC
	fi

	if ! which brew > /dev/null; then
		error "Homebrew installation failed!"
		exit 1
	fi
else
	info "Homebrew is already installed."
fi

###############################################################
# git
if ! which git > /dev/null; then
	info "Installing git"

	brew install git

	if ! which git > /dev/null; then
		error "git installation failed!"
		exit 1
	fi
else
	info "git is already installed."
fi

###############################################################
# fnm (node/npm version manager)
which fnm > /dev/null
HAS_FNM=$?
which nvm > /dev/null
HAS_NVM=$?

if [[ $HAS_FNM != 0 && $HAS_NVM != 0 ]]; then
	# If we don't have fnm or nvm, default to fnm
	info "Installing fnm"

	brew install fnm

	if ! which fnm > /dev/null; then
		error "fnm installation failed!"
		exit 1
	fi

	# Configure fnm for the shell
	if ! grep -E "eval.*?fnm env --use-on-cd" $SHELLRC > /dev/null; then
		echo 'eval "$(fnm env --use-on-cd)"' >> $SHELLRC
		source $SHELLRC
	fi

	info "Using fnm to install node 16"
	fnm install v16 >> /dev/null 2>&1

	if ! fnm list | grep -E v16 > /dev/null; then
		error "Could not find node v16!"
		exit 1
	fi
elif [[ $HAS_NVM == 0 ]]; then
	# nvm is installed so we use that to install node v16
	info "Using nvm to install node 16"
	nvm install 16
fi

###############################################################
# node/npm

if ! which node > /dev/null; then
	error "node installation failed!"
	exit 1
fi

###############################################################
# yarn
if ! which yarn > /dev/null; then
	info "Installing yarn"

	corepack enable
	corepack prepare yarn@stable --activate

	if ! which yarn > /dev/null; then
		error "yarn installation failed!"
		exit 1
	fi
else
	info "yarn is already installed."
fi
