#!/bin/bash
#########################
# Script is used to provide 
# a flow for how we want to 
# start up the framework
#########################
./stopQProcess.sh gateway
sleep 5
./stopQProcess.sh dailyHDB
sleep 5
./stopQProcess.sh scrapper
