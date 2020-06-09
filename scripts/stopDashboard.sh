#!/bin/bash
###########################################################
# Script to stop dashboard
###########################################################

###########################################################
# Function: failCheck
# Description: Check if previous command ran successfully
###########################################################

failCheck()
{
	if [[ $? > 0 ]]
	then 
		printf "ERROR: Previous command failed, fail to load script"
		exit 1
	fi
}

###########################################################
# Function: sourceGeneralScript
# Description: source for general script
###########################################################

sourceGeneralScript()
{
	if [[ $(find ~ -name generalBashCommands.sh) ]]
	then 
		source $(find ~ -name generalBashCommands.sh)
	else 
		printf "ERROR: Unable to local generalBashCommands.sh, fail to load script"
		return 1
	fi	
}

###########################################################
# Function: sourceConfig
# Description: source for environmental config
###########################################################

sourceConfig()
{
	printLines
	info "Sourcing for env.config before starting Kx Dashboards"
	printLines
	info "Running find command"
	if [[ $(find ~ -name env.config) ]]
	then
		info "Found env.config, sourcing it"
		source $(find ~ -name env.config)
	else
		err "Failed to find env.config"
		return 1
	fi
	return 0
}

###########################################################
# Function: stopDash
# Description: stops kx Dashboard q process
###########################################################

stopDash()
{
	printLines
	info "Stopping Kx Dashboards"
	printLines
	info "Check for existing PID"
	if [[ -f $KXDASHPID ]]
	then
		PID=`cat $KXDASHPID`
		if [[ $(ps -ef | grep q | grep $PID | grep -v grep) ]]
		then
			info "Existing Kx Dashboard started under PID: $PID"
			info "Stopping Kx Dashboard"
			kill -9 $PID
			rm $KXDASHPID
			return 0
		else
			warn "Kx Dashboard was already stopped, removing PID file"
			rm $KXDASHPID
			return 0
		fi
	else 
		warn "Kx Dashboard was never started"
	fi
	return 0
}

sourceGeneralScript
failCheck
sourceConfig
failCheck
stopDash
