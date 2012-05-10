#!/bin/sh

# Git Multi Merge (gmm) - Easily merge one git branch into one or more other branches
# Author: Nick Groenen
# Email: zoni@zoni.nl
# License: Public domain

# {{{ Colored output

# ANSI escape sequences for pretty colors
black='\e[1;30m'
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
magenta='\e[1;35m'
cyan='\e[1;36m'
white='\e[1;37m'
reset='\e[1;0m'

# Color echo
# $1 = color
# $2 = message
cecho()
{
	if [ $COLOR -eq 0 ]
	then
		echo "${2}"
	else
		color=${1:-""} # Default to no color, if not specified.
		printf "${color}"
		echo "${2}"
		printf "${reset}"
	fi
}
# }}}

# {{{ Argument parsing 

# Defaults and such
PROGRAM_NAME="gmm"
FETCH=0
MERGE_ORIGIN=0
COLOR=1

# Parse arguments
OPTS=$(getopt -n $PROGRAM_NAME --options fm --longoptions fetch,merge-origin,color,no-color -- "$@")
[ $? = 0 ] || { cecho ${red} "Error parsing arguments. Try $PROGRAM_NAME --help" ; exit 1; }

eval set -- "$OPTS"
while true; do
	case $1 in
	-f|--fetch)
		FETCH=1;
		shift; continue
	;;
	-m|--merge-origin)
		MERGE_ORIGIN=1;
		shift; continue
	;;
	--color)
		COLOR=1;
		shift; continue
	;;
	--no-color)
		COLOR=0;
		shift; continue
	;;
	--)
		# No more arguments to parse
		shift; break
	;;
	*)
		cecho ${red} "Error: Unknown option $1"
		exit 1
	;;
	esac
done

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

# Fetch from upstream if requested
if [ $FETCH -eq 1 ]
then
	cecho ${green} "Fetching upstream repository data (git fetch)"
	git fetch || { cecho ${red} "Error: git fetch failed"; exit 1; }
fi

# Merge the branches
for BRANCH in ${DESTINATIONBRANCHES}
do
	cecho ${green} "Switching to branch ${BRANCH}"
	git checkout ${BRANCH} || { cecho ${red} "Error: Failed to switch to branch ${BRANCH}"; exit 1; }
	if [ $MERGE_ORIGIN -eq 1 ]
	then
		cecho ${green} "Merging origin/${BRANCH} into ${BRANCH}"
		git merge origin/${BRANCH} || { cecho ${red} "Error: Merge failed"; exit 1; }
	fi
	cecho ${magenta} "Merging master into ${BRANCH}"
	git merge master || { cecho ${red} "Error: Merge failed"; exit 1; }
done

cecho ${green} "Switching back to your starting branch (${STARTBRANCH})"
git checkout ${STARTBRANCH} || exit 1;
