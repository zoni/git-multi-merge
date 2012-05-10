#!/bin/sh

# Git Multi Merge (gmm) - Easily merge one git branch into one or more other branches
# Author: Nick Groenen
# Email: zoni@zoni.nl
# Version: 1.0
# License: Public domain

# {{{ Colored output

# ANSI escape sequences for pretty colors
black='\E[30m'
red='\E[31m'
green='\E[32m'
yellow='\E[33m'
blue='\E[34m'
magenta='\E[35m'
cyan='\E[36m'
white='\E[37m'
reset='\E[0m'

# Color echo
# $1 = color
# $2 = message
cecho()
{
	color=${1:-""} # Default to no color, if not specified.
	echo -en "${color}"
	echo -n "${2}"
	echo -e "${reset}"
}
# }}}

# {{{ Argument parsing 

if [ $# -lt 2 ]
then
	cecho ${red} "Error: Insufficient arguments"
	echo "Usage: gmm sourcebranch targetbranch1 targetbranch2 targetbranchN"
	exit 1
fi

SOURCEBRANCH=${1} # Branch we'll merge from
shift
DESTINATIONBRANCHES=${@} # Branches we'll merge to

# }}}

# Ensure we have git installed
which git > /dev/null || { cecho ${red} "Error: Git not found"; exit 1; }

# Ensure we're in a git repository
git rev-parse > /dev/null 2>&1 || { cecho ${red} "Error: This isn't a valid git repository"; exit 1; }

# Store the current branch so we can switch back to it later
STARTBRANCH=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)

cecho ${green} "Fetching upstream repository data (git fetch)"
git fetch
if [ $? -ne 0 ]
then
	cecho ${red} "Error: git fetch failed"
	while true
	do
		echo -n "Continue anyway? [Yes/No] "
		read answer
		case "${answer}" in 
			"Y"|"y"|"Yes"|"yes" )
				break
                ;;
			"N"|"n"|"No"|"no" )
                exit 1
                ;;
			*)
				echo "Please answer yes or no"
				;;
		esac
	done
fi

for BRANCH in ${DESTINATIONBRANCHES}
do
	cecho ${green} "Switching to branch ${BRANCH}"
	git checkout ${BRANCH} || { cecho ${red} "Error: Failed to switch to branch ${BRANCH}"; exit 1; }
	cecho ${green} "Merging origin/${BRANCH} into ${BRANCH} to ensure your local branch is fully up-to-date"
	git merge origin/${BRANCH} || { cecho ${red} "Error: Merge failed"; exit 1; }
	cecho ${magenta} "Merging master into ${BRANCH}"
	git merge master || { cecho ${red} "Error: Merge failed"; exit 1; }
done

cecho ${green} "Switching back to your starting branch (${STARTBRANCH})"
git checkout ${STARTBRANCH} || exit 1;
