#!/bin/bash
HOST=$1
PORT=$2
STATE=`quakestat -u -default q2s ${HOST}:${PORT} | grep "${HOST}"`
if [[ $? == 0 ]]; then
printf "${PORT} - OK\n"
exit 0
elif [[ $? == 1 ]]; then
printf "${PORT} - DOWN\n"
exit 2
fi

