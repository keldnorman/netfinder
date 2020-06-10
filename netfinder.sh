#!/bin/bash
#set -x
clear
#-------------------------------------------------------------------------
# Description                                                 Version 0.2b
#-------------------------------------------------------------------------
# This is a script to test a local network for .1 gateways answering ping
# (C)opyleft Keld Norman, 20 Jun, 2020
#
# PRE:  apt-get update -q && apt-get install fping parallel
# parallel --citation # Type in "will site" (thank you Ole Tange) 
# 
#-------------------------------------------------------------------------
# VARIABLES
#-------------------------------------------------------------------------
PARALLEL="256"
ulimit -n 2048
#-------------------------------------------------------------------------
# Banner (A Must for 1337'ishness): 
#-------------------------------------------------------------------------
cat << "EOF"
                                 _ .--.
                                ( `    )
                             .-'      `--,
                  _..----.. (             )`-.
                .'_|` _|` _|(  .__,           )
               /_|  _|  _|  _(        (_,  .-'
              ;|  _|  _|  _|  '-'__,--'`--'
              | _|  _|  _|  _| |
          _   ||  _|  _|  _|  _|
        _( `--.\_|  _|  _|  _|/
     .-'       )--,|  _|  _|.`
    (__, (_      ) )_|  _| /
      `-.__.\ _,--'\|__|__/
                    ;____;   
                     \YT/
                      ||
                     |""|
                     '=='

       LEAN RFC1918 NETWORK GATEWAY SCANNER

EOF
#--------------------------------------------
# PRE 
#--------------------------------------------
if [ ! -x /usr/bin/parallel ];then
 printf "\n ### ERROR - The utility /usr/bin/parallel was not found (run apt-get update && apt-get install parallel)\n\n"
 exit 1
fi
if [ ! -x /usr/bin/fping ];then
 printf "\n ### ERROR - The utility /usr/bin/fping was not found (run apt-get update && apt-get install fping)\n\n"
 exit 1
fi
#--------------------------------------------
printf " $(date) - Starting RFC1918 net test..\n"
if [ ! -d ./temp ]; then mkdir ./temp ; fi
#--------------------------------------------
# TEST 192.168.0.0/16
#--------------------------------------------
printf "\n Probing 192.168.0.0/16\n\n"
for X in {0..255} ; do
 echo "192.168.${X}.1"
done | parallel --gnu -j${PARALLEL} "fping -4 --name -a -c1 -q {} >/dev/null 2>/dev/null && echo {}"
#--------------------------------------------
# TEST 172.16.0.0/12
#--------------------------------------------
printf "\n Probing 172.16.0.0/12\n\n"
for X in {16..31} ; do
 for Y in {0..255} ; do
  echo 172.${X}.${Y}.1 
 done > ./temp/172.${X}.0-255.1.rangefile
done 
for X in {0..31} ; do
 echo ./temp/172.${X}.0-255.1.rangefile 
done | parallel --gnu -j${PARALLEL} "fping -4 -naq -c1 -f {} 2>&1|grep "/0%,"|cut -d ' ' -f -1"
#--------------------------------------------
# TEST 10.0.0.0/8
#--------------------------------------------
printf "\n Probing 10.0.0.0/8 (this will take a couple of minutes..)\n\n"
for X in {0..255} ; do
 for Y in {0..255} ; do
  echo 10.${X}.${Y}.1 
 done > ./temp/10.${X}.0-255.1.rangefile
done 
for X in {0..255} ; do
 echo ./temp/10.${X}.0-255.1.rangefile 
done | parallel --gnu -j${PARALLEL} "fping -4 -naq -c1 -f {} 2>&1|grep "/0%,"|cut -d ' ' -f -1"
#--------------------------------------------
if [ -d ./temp ]; then rm -Rf ./temp ; fi
printf "\n $(date) - Stopped RFC1918 net test..\n\n"
#-------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------
