#!/bin/bash

function info(){
    echo -e "\x1B[34m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[34m $($2) \x1B[0m"
    fi
}
function error(){
    echo -e "\x1B[31m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[31m $($2) \x1B[0m"
    fi
}
function success(){
    echo -e "\x1B[32m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[32m $($2) \x1B[0m"
    fi
}

# Determine if we're using bash or zsh
if [[ $SHELL == '/bin/bash' ]]; then
	SHELLRC=~/.bashrc
elif [[ $SHELL == '/bin/zsh' ]]; then
	SHELLRC=~/.zshrc
else
	error "Unsupported command-line shell ($SHELL)"
	exit 1
fi

# Backup the shell config
cat $SHELLRC > "$SHELLRC.orig"

###############################################################
# curl

which curl > /dev/null
if [[ $? != 0 ]]; then
	error "You must have the command-line tool 'curl' installed to use this script"
	exit 1
fi

###############################################################
# Homebrew
which brew > /dev/null
if [[ $? != 0 ]]; then
	info "Installing Homebrew (https://brew.sh/)"
	info "Enter your password when prompted. Accept the defaults at all other prompts."

	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	which brew > /dev/null
	if [[ $? != 0 ]]; then
		error "Homebrew installation failed!"
		exit 1
	fi

	# Add /opt/homebrew/bin to $PATH if it's not there already
	egrep "PATH=.*?\/opt\/homebrew\/bin" ~/.zshrc > /dev/null
	if [[ $? != 0 ]]; then
		echo 'export PATH="/opt/homebrew/bin:$PATH' >> $SHELLRC
		. $SHELLRC
	fi
else
	info "Homebrew is already installed."
fi

###############################################################
# git
which git > /dev/null
if [[ $? != 0 ]]; then
	info "Installing git"

	brew install git

	which git > /dev/null
	if [[ $? != 0 ]]; then
		error "git installation failed!"
		exit 1
	fi
else
	info "git is already installed."
fi

###############################################################
# fnm (node/npm version manager)
which fnm > /dev/null
if [[ $? != 0 ]]; then
	info "Installing fnm"

	brew install fnm

	which fnm > /dev/null
	if [[ $? != 0 ]]; then
		error "fnm installation failed!"
		exit 1
	fi

	# Configure fnm for the shell
	egrep "eval.*?fnm env --use-on-cd" ~/.zshrc > /dev/null
	if [[ $? != 0 ]]; then
		echo 'eval "$(fnm env --use-on-cd)"' >> $SHELLRC
		. $SHELLRC
	fi
else
	info "fnm is already installed."
fi

###############################################################
# node/npm
info "Installing node v16"
fnm install v16 >> /dev/null 2>&1

which node > /dev/null
if [[ $? != 0 ]]; then
	error "node installation failed!"
	exit 1
fi

fnm list | egrep v16 > /dev/null
if [[ $? != 0 ]]; then
	error "Could not find node v16!"
	exit 1
fi

###############################################################
# yarn
which yarn > /dev/null
if [[ $? != 0 ]]; then
	info "Installing yarn"

	corepack enable
	corepack prepare yarn@stable --activate

	which yarn > /dev/null
	if [[ $? != 0 ]]; then
		error "yarn installation failed!"
		exit 1
	fi
else
	info "yarn is already installed."
fi
