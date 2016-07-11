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
# Nagios plugin to monitor a game server.                                     #
# All games supported by qstat works.                                         #
# The plugin exit with a CRICITAL error code if the server is down.           #
# This behavior can be changed with the --warning argument.                   # 
# Written in Bash (and uses standard tools such as grep and awk).             #
# Latest version of the script can be found at:                               #
# https://github.com/jackbenny/check_quake                                    #
#                                                                             #
###############################################################################

VERSION="0.3"
AUTHOR="(c) 2012 Jack-Benny Persson (jack-benny@cyberinfo.se)"

# Qstat binary
QSTAT=/usr/local/bin/qstat

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Some default values
PORT=27910
GAME="q2s"

shopt -s extglob

# Sanity checks
if [[ ! -x "$QSTAT" ]]; then
	printf "It appears you don't have the qstat package installed in\
 $QSTAT\n"
	exit $STATE_UNKNOWN
fi


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
	printf "Monitor a game server\n"
/bin/cat <<EOT

Options:
-h
   Print detailed help screen
-V
   Print version information
-H
   Set the host/IP of the server to watch
-p
   Set the port number of the game server to watch
   Default is 27910 (Quake 2)
--game
   Set the game to be monitored. Default is Quake 2 (q2s)
   Any game supported by qstat works. See the list below:
	a2s	       	 Half-Life 2 new server
 	ams		 America's Army v2.x server
 	bfs		 BFRIS server
 	odm		 Call of Duty Master server
 	cods		 Call of Duty server
 	crs		 Command and Conquer: Renegade server
 	d3g		 Descent3 Gamespy Protocol server
 	d3m		 Descent3 Master (PXO) server
 	d3p		 Descent3 PXO protocol server
 	d3s		 Descent3 server
 	dm3m		 Doom 3 Master server
 	dm3s		 Doom 3 server
 	efm		 Star Trek: Elite Force server
	efs		 Star Trek: Elite Force server
 	eye		 All Seeing Eye Protocol server
 	fcs		 FarCry server
 	gps		 Gamespy Protocol server
 	grs		 Ghost Recon server
 	gs2		 Gamespy V2 Protocol server
 	gs3		 Gamespy V3 Protocol server
 	gs4		 Gamespy V4 Protocol server
 	gsm		 Gamespy Master server
 	h2s		 Hexen II server
 	hl2s		 Half-Life 2 server
 	hla2s		 Half-Life server
 	hla2sm		 Steam Master server
 	hlm		 Half-Life Master server
 	hlqs		 Half-Life server
 	hls		 Half-Life server
 	hrs		 Heretic II server
 	hws		 HexenWorld server
 	jk3m		 Jedi Knight: Jedi Academy server
 	jk3s		 Jedi Knight: Jedi Academy server
 	kps		 Kingpin server
 	maqs		 Medal of Honor: Allied Assault (Q) server
 	mas		 Medal of Honor: Allied Assault server
 	mhs		 Medal of Honor: Allied Assault server
 	netp		 NetPanzer server
 	netpm		 NetPanzer Master server
 	nexuizm		 Nexuiz Master server
 	nexuizs		 Nexuiz server
 	preym		 Prey Master server
 	preys		 PREY server
 	prs		 Pariah server
 	q2m		 Quake II Master server
 	q2s		 Quake II server
 	q3m		 Quake III Master server
 	q3s		 Quake III: Arena server
 	q4m		 Quake 4 Master server
 	q4s		 Quake 4 server
 	qs		 Quake server
 	qwm		 QuakeWorld Master server
 	qws		 QuakeWorld server
 	rss		 Ravenshield server
 	rwm		 Return to Castle Wolfenstein Master server
 	rws		 Return to Castle Wolfenstein server
 	sas		 Savage server
 	sfs		 Soldier of Fortune server
 	sgs		 Shogo: Mobile Armor Division server
 	sms		 Serious Sam server
 	sns		 Sin server
 	sof2m		 SOF2 Master server
 	sof2m1.0	 SOF2 Master (1.0) server
 	sof2s		 Soldier of Fortune 2 server
 	stm		 Steam Master server
 	stma2s		 Steam Master for A2S server
 	stmhl2		 Steam Master for HL2 server
 	t2m		 Tribes 2 Master server
 	t2s		 Tribes 2 server
 	tbm		 Tribes Master server
 	tbs		 Tribes server
 	tm		 TrackMania server
 	tremulous	 Tremulous server
 	tremulousm	 Tremulous Master server
 	ts2		 Teamspeak 2 server
 	uns		 Unreal server
 	ut2004m		 UT2004 Master server
 	ut2004s		 UT2004 server
 	ut2s		 Unreal Tournament 2003 server
 	warsowm		 Warsow Master server
 	warsows		 Warsow server
 	woetm		 Enemy Territory Master server
 	woets		 Enemy Territory server
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

       -p)
           if [[ -z "$2" ]]; then
                printf "\nOption $1 requires an argument\n"
		print_help
                exit $STATE_UNKNOWN
           fi
                PORT=$2
           shift 2
           ;;

       --game)
           if [[ -z "$2" ]]; then
                printf "\nOption $1 requires an argument\n"
		print_help
                exit $STATE_UNKNOWN
           fi
                GAME=$2
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
QSTAT_TEST=`${QSTAT} -u -default ${GAME} ${HOST}:${PORT} | grep "${HOST}"`

#Let's see if the above command was succesful or not
if [[ $? == 0 ]]; then
	printf "${GAME} on port $PORT - OK\n"
	exit $STATE_OK

#See if we wanted a warning instead of a critical
elif [[ "$warning" == "yes" ]]; then
		printf "${GAME} on port $PORT - WARNING\n"
		exit $STATE_WARNING
#Critical
else

  printf "${GAME} on port $PORT - CRITICAL\n"
  exit $STATE_CRITICAL
fi

exit 3
