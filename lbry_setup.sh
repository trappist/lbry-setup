#!/bin/bash

exec >  >(tee -a setup.log)
exec 2> >(tee -a setup.log >&2)

ROOT=.
GIT_URL_ROOT="https://github.com/lbryio/"
CONF_DIR=~/.lbrycrd
CONF_PATH=$CONF_DIR/lbrycrd.conf
PACKAGES="git libgmp3-dev build-essential python2.7 python2.7-dev python-pip"

#install/update requirements
if hash apt-get 2>/dev/null; then
	printf "Installing $PACKAGES\n\n"
	sudo apt-get install $PACKAGES
else
	printf "Running on a system without apt-get. Install requires the following packages or equivalents: $PACKAGES\n\nPull requests encouraged if you have an install for your system!\n\n"
fi

#create config file
if [ ! -f $CONF_PATH ]; then
	printf "Adding lbry config in $CONF_PATH\n";
	mkdir -p $CONF_DIR
	printf "rpcuser=lbryrpc" > $CONF_PATH
	printf "\nrpcpassword=" >> $CONF_PATH
	tr -dc A-Za-z0-9 < /dev/urandom | head -c ${1:-12} | xargs >> $CONF_PATH 
else
	printf "Config $CONF_PATH already exists\n";
fi

#Clone/pull repo and return true/false whether or not anything changed
#$1 : repo name
UpdateSource() 
{
	if [ ! -d "$ROOT/$1/.git" ]; then
       		printf "$1 does not exist, checking out\n";
	        git clone "$GIT_URL_ROOT$1.git"
		return 0 
	else
		cd $1
		#http://stackoverflow.com/questions/3258243/git-check-if-pull-needed
		git remote update;
		LOCAL=$(git rev-parse @{0})
		REMOTE=$(git rev-parse @{u})
		if [ $LOCAL = $REMOTE ]; then
			printf "No changes to $1 source\n"
            cd ..
			return 1 
		else
			printf "Fetching source changes to $1\n"
			git pull --rebase
            cd ..
			return 0
		fi
	fi
}

if [ ! -d bin ]; then
    printf "Creating bin\n"
    mkdir -p bin
else
    printf "bin directory already exists\n"
fi
if [ ! -e bin/lbrycrd.tar.gz ] || [ ! `md5sum bin/lbrycrd.tar.gz | awk '{print $1}'` = "1825a67d090724f955bde1b459fe6d83" ]; then
    cd bin
    wget https://github.com/lbryio/lbrycrd/releases/download/v0.1-alpha/lbrycrd.tar.gz
    tar xf lbrycrd.tar.gz
    mv lbrycrd/* .
    rm -rf lbrycrd
    cd ..
    if [ -e ~/.lbrycrddpath.conf ]; then
        if [ `cat ~/.lbrycrddpath.conf` = "`pwd`/lbrycrd/src/lbrycrdd" ]; then
            rm ~/.lbrycrddpath.conf
        fi
    fi
else
	printf "lbrycrd installed and nothing to update\n"
fi

if [ ! -e ~/.lbrycrddpath.conf ]; then
    echo `pwd`/bin/lbrycrdd > ~/.lbrycrddpath.conf
fi
#setup lbry-console
printf "\n\nInstalling/updating lbry-console\n";
if UpdateSource lbry || [ ! -d $ROOT/lbry/dist ]; then
	printf "Running lbry-console setup\n"
	cd lbry
    if [ -d dist ]; then
        if [ `stat -c "%U" dist` = "root" ]; then
            sudo rm -rf dist build ez_setup.pyc lbrynet.egg-info setuptools-4.0.1-py2.7.egg setuptools-4.0.1.zip
        fi
    fi
    python2.7 setup.py build bdist_egg
	sudo python2.7 setup.py install
	cd ..
else
	printf "lbry-console installed and nothing to update\n"
fi
