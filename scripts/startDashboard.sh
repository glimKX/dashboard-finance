#!/bin/bash
###########################################################
# Script to start dashboard
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
# Function: startDash
# Description: starts kx Dashboard q process
###########################################################

startDash()
{
	printLines
	info "Starting Kx Dashboards"
	printLines
	info "Check for existing PID"
	if [[ -f $KXDASHPID ]]
	then
		PID=`cat $KXDASHPID`
		if [[ $(ps -ef | grep q | grep $PID | grep -v grep) ]]
		then
			warn "Existing Kx Dashboard started under PID: $PID"
			warn "Not starting Kx Dashboard"
			return 0
		fi
	else
		info "No PID File"
	fi
	info "No Existing Kx Dashboard"
	info "Starting Kx Dashboard"
	cd $KXDASH
	echo "$Q dash.q -u 1 -p $KXDASHPORT > $KXDASHLOGFILE 2> $KXDASHERRFILE"
	$Q dash.q -u 1 -p $KXDASHPORT > $KXDASHLOGFILE 2> $KXDASHERRFILE < /dev/null &
	echo $! > $KXDASHPID
	cd -
	info "Started Kx Dashboard under PID: `cat $KXDASHPID`"
	return 0
}

sourceGeneralScript
failCheck
sourceConfig
failCheck
startDash
