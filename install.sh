#!/bin/bash

#==============================
# Script to install mic files
# Only required for those who do not know how to deploy
#==============================

#==============================
# Helper Functions
#==============================

#==============================
# logTitle
#=============================

logTitle()
{
	local x=${1}
	printf "=========================================\n"
        printf "==== $x ====\n"
	printf "=========================================\n"
}

#==============================
# logOut
#=============================

logOut()
{
	local x=${1}
	printf "INFO: $x\n"
}

#==============================
# logWarn
#==============================

logWarn()
{
	local x=${1}
	printf "WARNING: $x\n"
}

#===============================
source config/env.config
printf "=========================================\n"
printf "=== Installation of dashboard finance ===\n"
printf "=========================================\n"
printf "INFO: Checking if secretkey is present...\n"
if [ ! -f $SECRET_KEYS ]; then
    printf "WARNING: secretkey is missing, creating file\n"
    mkdir -p $SECRET_KEYS_DIR
    touch $SECRET_KEYS
fi

#TODO 
#HDB FOLDER CREATION
logOut "Checking if HDB Folder is present..."
if [ ! -f $HDB_DIR ] ; then
	logWarn "$HDB_DIR is missing, creating folder"
	mkdir -p $HDB_DIR
fi

logOut "Checking if HDB Daily Folder is present..."
if [ ! -f $HDB_DAILY_DIR ] ; then
	logWarn "$HDB_DAILY_DIR is missing, creating folder"
	mkdir -p $HDB_DAILY_DIR
fi 

printf "INFO:Current release support installation of 2 API KEYS\n Please select what are you trying to install\n 1)Alphavantage \n 2)Finnhub\n"
read choice
case $choice in
	1)
		printf "INFO: You have chosen Alphavantage, please provide the APIKEY\n"
		read apikey
		sed -i '/ALPHAVANTAGEAPI/d' $SECRET_KEYS
		echo "export ALPHAVANTAGEAPI="$apikey >> $SECRET_KEYS
		;;
	2)
		printf "INFO: You have chose Finnhub, please provide the APIKEY\n"
		read apikey
		sed -i '/FINNHUBAPI/d' $SECRET_KEYS
		echo "export FINNHUBAPI="$apikey >> $SECRET_KEYS
		;;
	*)
		printf "WARNING: Invalid Input, skipping installation\n"
		;;
esac
printf "===================================\n"
printf "=== INFO: Installation Complete ===\n"
printf "===================================\n"
exit 0
