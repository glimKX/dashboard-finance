#!/bin/bash
#########################
# Script is used to provide 
# a flow for how we want to 
# start up the framework
#########################
./startQProcess.sh scrapper
sleep 5
./startQProcess.sh dailyHDB
sleep 5
./startQProcess.sh gateway
