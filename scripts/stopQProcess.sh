#!/bin/bash
###########################################################
# Script to start q process
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
	info "Sourcing for env.config and port.config before starting q process"
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
	if [[ $(find ~ -name port.config) ]]
	then
		info "Found port.config, sourcing it"
		source $(find ~ -name port.config)
	else
		err "Failed to find port.config"
		return 1
	fi
	return 0
}

###########################################################
# Function: startDash
# Description: starts kx Dashboard q process
###########################################################

stopQProcess()
{
	printLines
	info "Stopping Q Process $1"
	printLines
	info "Check for existing PID"
	if [[ -f $QPROCESSESPID ]]
	then
		PID=`grep $1 $QPROCESSESPID | awk -F "=" '{print $2}'`
		if [[ $PID != "" ]] 
		then
			if [[ $(ps -ef | grep q | grep $PID | grep -v grep) ]]
			then
				info "Existing Q Process $1 started under PID: $PID"
				info "Stopping Q Process"
				kill -9 $PID
				sed -i "/^${1}/d" $QPROCESSESPID
				return 0
			fi
		fi
	else
		warn "No PID File, nothing to stop"
	fi
	return 0
}

sourceGeneralScript
failCheck
sourceConfig
failCheck
stopQProcess $1
