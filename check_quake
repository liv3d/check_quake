#!/bin/bash
HOST=$1
PORT=$2
STATE=`quakestat -default q2s ${HOST}:${PORT} | grep "q2"`
if [[ $? == 0 ]]; then
printf "${PORT} - OK\n"
exit 0
elif [[ $? == 1 ]]; then
printf "${PORT} - DOWN\n"
exit 2
fi

