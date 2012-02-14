#!/bin/bash

################################################################################
#                                                                              #
#  Copyright (C) 2012 Jack-Benny Persson <jack-benny@cyberinfo.se>             #
#                                                                              #
#   This program is free software; you can redistribute it and/or modify       #
#   it under the terms of the GNU General Public License as published by       #
#   the Free Software Foundation; either version 2 of the License, or          #
#   (at your option) any later version.                                        #
#                                                                              #
#   This program is distributed in the hope that it will be useful,            #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#   GNU General Public License for more details.                               #
#                                                                              #
#   You should have received a copy of the GNU General Public License          #
#   along with this program; if not, write to the Free Software                #
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  #
#                                                                              #
################################################################################

###############################################################################
#                                                                             # 
# Nagios plugin to monitor a Quake II server.                                 #
# The plugin exit with a CRICITAL error code if the server is down.           #
# This behavior can be changed with the --warning argument.                   # 
# Written in Bash (and uses standard tools such as grep and awk).             #
#                                                                             #
###############################################################################

VERSION="0.1"
AUTHOR="(c) 2012 Jack-Benny Persson (jack-benny@cyberinfo.se)"

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Some default values
PORT=27919

shopt -s extglob

#### Functions ####

# Print version information
print_version()
{
	printf "\n\n$0 - $VERSION\n"
}

#Print help information
print_help()
{
	print_version
	printf "$AUTHOR\n"
	printf "Monitor a Quake II server\n"
/bin/cat <<EOT

Options:
-h
   Print detailed help screen
-V
   Print version information
-H 
   Set the host/IP of the server to watch
-P
   Set the port number of the Quake server to watch
   Default is 27910
--warning
   Issue a warning state instead of a critical state 
   Default is critical

EOT
}


# Parse command line options
while [[ -n "$1" ]]; do 
   case "$1" in

       -h | --help)
           print_help
           exit $STATE_OK
           ;;

       -V | --version)
           print_version
           exit $STATE_OK
           ;;

       -\?)
	   print_help
           exit $STATE_OK
           ;;

       -H)
	   if [[ -z "$2" ]]; then
		printf "\nOption $1 requires an argument\n"
		print_help
		exit $STATE_UNKNOWN
	   fi
		HOST=$2
           shift 2
           ;;

       -P)
           if [[ -z "$2" ]]; then
                printf "\nOption $1 requires an argument\n"
		print_help
                exit $STATE_UNKNOWN
           fi
                PORT=$2
           shift 2
           ;;

       --warning)
           warning="yes"
	   shift 1
	   ;;

	*)
           printf "\nInvalid option $1"
           print_help
           exit $STATE_UNKNOWN
           ;;


   esac
done

### Check if we provided a host and a port number ###

if [[ -z "$HOST" ]]; then
	# No host specfied
	printf "\nNo host specified"
	print_help
	exit $STATE_UNKNOWN
fi

if [[ -z "$PORT" ]]; then
	# No port specified
	printf "\nNo port number specified"
	print_help
	exit $STATE_UNKNOWN
fi


### MAIN ###

#Test if the server is up and running
QSTAT_TEST=`quakestat -u -default q2s ${HOST}:${PORT} | grep "${HOST}"`

#Let's see if the above command was succesful or not
if [[ $? == 0 ]]; then
	printf "Q2 on port $PORT - OK\n" 
	exit $STATE_OK

#See if we wanted a warning instead of a critical
elif [[ "$warning" == "yes" ]]; then
		printf "Q2 on port $PORT - WARNING\n"
		exit $STATE_WARNING
#Critical
else	

  printf "Q2 on port $PORT - CRITICAL\n"
  exit $STATE_CRITICAL
fi

exit 3
