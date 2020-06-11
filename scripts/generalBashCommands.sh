#!/bin/bash
###########################################################
# Script which contains all general bash commands that can be sourced
###########################################################o

###########################################################
# Function: err
# Description: log error message
###########################################################
err()
{
	local TEXT=${1}
	printf "ERROR: %s\n" "${TEXT}"
	return 1
}

###########################################################
# Function: log
# Description: log message
###########################################################
info()
{
	local TEXT=${1}
	printf "INFO: %s\n" "${TEXT}"
	return 0
}

###########################################################
# Function: warn 
# Description: warn message
###########################################################
warn()
{
	local TEXT=${1}
	printf "WARN: %s\n" "${TEXT}"
	return 0
}

###########################################################
# Function: printHeader
# Description: print Double Lines
###########################################################
printHeader()
{
	printf "=======================================\n"
	return 0
}

###########################################################
# Function: printLines 
# Description: print Single Lines 
###########################################################
printLines()
{
	printf "+-------------------------------------+\n"
	return 0
}

FUNCTIONS=`declare -F | awk -F "-f" '{print $2}'`
printHeader
info "GENERAL BASH SCRIPT"
printHeader
info "Loading following functions"
printf "$FUNCTIONS \n"
export -f $FUNCTIONS
info "All required functions loaded"
return 0
