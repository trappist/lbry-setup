#!/bin/bash

exec >  >(tee -a script_setup.log)
exec 2> >(tee -a script_setup.log >&2)

ROOT=.
GIT_URL_ROOT="https://github.com/lbryio/"
PACKAGES="git"

#install/update requirements
if hash apt-get 2>/dev/null; then
	printf "Installing $PACKAGES\n\n"
	sudo apt-get install $PACKAGES
else
	printf "Running on a system without apt-get. Install requires the following packages or equivalents: $PACKAGES\n\nPull requests encouraged if you have an install for your system!\n\n"
fi

#Clone/pull repo and return true/false whether or not anything changed
#$1 : repo name
UpdateSource() 
{
	if [ ! -d "$ROOT/.git" ]; then
       		printf "setup script does not exist, checking out\n";
	        git clone "${GIT_URL_ROOT}lbry-setup.git" .
		return 0 
	else
		#http://stackoverflow.com/questions/3258243/git-check-if-pull-needed
		git remote update;
		LOCAL=$(git rev-parse @{0})
		REMOTE=$(git rev-parse @{u})
		if [ $LOCAL = $REMOTE ]; then
			printf "No changes to setup script\n"
			return 1 
		else
			printf "Fetching source changes to setup script\n"
			git pull --rebase
			return 0
		fi
	fi
}
UpdateSource

./update_lbry.sh
