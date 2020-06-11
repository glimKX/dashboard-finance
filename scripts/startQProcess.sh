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
	if [[ -f $SECRET_KEYS ]]
	then
		info "Secret key is present, loading it"
		source $SECRET_KEYS
	fi
	return 0
}

###########################################################
# Function: startDash
# Description: starts kx Dashboard q process
###########################################################

startQProcess()
{
	printLines
	info "Starting Q Process $1"
	printLines
	info "Check for existing PID"
	if [[ -f $QPROCESSESPID ]]
	then
		PID=`grep $1 $QPROCESSESPID | awk -F "=" '{print $2}'`
		if [[ $PID != "" ]] 
		then
			if [[ $(ps -ef | grep q | grep $PID | grep -v grep) ]]
			then
				warn "Existing Q Process $1 started under PID: $PID"
				warn "Not starting Q Process"
				return 0
			fi
		fi
	else
		info "No PID File"
	fi
	sed -i "/^${1}/d" $QPROCESSESPID
	info "No Existing Q Process $1"
	info "Checking against valid process and port"
	VALIDPORT=\${$(echo ${1}_PORT | tr [a-z] [A-Z])}
	VALIDPORT=$(eval echo $VALIDPORT)
	if [[ $VALIDPORT == "" ]] 
	then 
		err "Process is not valid as it does not have an accompanied port"
		return 1
	fi
	info "Starting Q Process $1"
	cd $QSCRIPTS_DIR > /dev/null
	#echo $PWD
	if [ ! -f ${QSCRIPTS_DIR}/${1}.q ] 
	then
		err "Process is not valid as qscript is missing"
		return 1
	fi
	$Q ${QSCRIPTS_DIR}/${1}.q -p $VALIDPORT 2>&1 /dev/null &
	echo ${1}=$! >> $QPROCESSESPID
	info "Started Q Process $1 under PID: `grep $1 $QPROCESSESPID`"
	cd - > /dev/null
	return 0
}

sourceGeneralScript
failCheck
sourceConfig
failCheck
startQProcess $1
