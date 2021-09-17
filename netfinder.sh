#!/bin/bash
#set -x
clear
#-------------------------------------------------------------------------
# Description                                                 Version 0.3b
#-------------------------------------------------------------------------
# This is a script to test a local network for .1 gateways answering ping
# (C)opyleft Keld Norman, 20 Jun, 2020
#
# PRE:  apt-get update -q && apt-get install fping parallel
# parallel --citation # Type in "will site" (thank you Ole Tange) 
# 
# Version 0.3: 
#  - Altered detection to grep -v instead of grep
#  - reduced parallel sessions for 10.x scannings to avoid missing targets
#  - added netcard detection
#  - removed name resolution
#-------------------------------------------------------------------------
# VARIABLES
#-------------------------------------------------------------------------
VERSION="0.3"
FPING="/usr/bin/fping"
PARALLEL="/usr/bin/parallel"
PARALLEL_SESSIONS="256"
#-------------------------------------------------------------------------
# Banner (A Must for 1337'ishness): 
#-------------------------------------------------------------------------
cat << "EOF"
#          __
#          \ \_____
#       ###[==_____>
#          /_/      __
#                   \ \_____
#                ###[==_____>
#                   /_/
#
EOF
printf "# LEAN RFC1918 NETWORK GATEWAY SCANNER VERSION ${VERSION}\n#\n"
#--------------------------------------------
# PRE 
#--------------------------------------------
if [ ! -x ${PARALLEL} ];then
 printf "\n### ERROR - The utility ${PARALLEL} was not found (run apt-get update && apt-get install parallel)\n\n"
 exit 1
fi
if [ ! -x ${FPING} ];then
 printf "\n### ERROR - The utility ${FPING} was not found (run apt-get update && apt-get install fping)\n\n"
 exit 1
fi
#----------------------------------------------------------------------
ulimit -n 101337
PROGNAME=${0##*/}
tmp_dir=$(mktemp -d -t ${PROGNAME%%.*}-XXXXXXXXXX)
#----------------------------------------------------------------------
# Trap - Remove temp directory 
#----------------------------------------------------------------------
function cleanup()
{
 if [ -d ${tmp_dir} ]; then rm -Rf ${tmp_dir} ; fi
}
trap cleanup EXIT SIGHUP
#-------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------
function select_scan_adapter {
 ADAPTERS=$(ifconfig -a|grep flags|grep -v ^lo:|grep "UP")
 ADAPTERS_COUNT=$(echo "${ADAPTERS}"|/bin/grep -c "UP")
 NETCARDS=$(echo "${ADAPTERS}"|cut -d ":" -f1)
 if [ ${ADAPTERS_COUNT} -eq 1 ]; then
  printf "# Using the only adapter found UP: ${NETCARDS}\n"
  NETCARD=${NETCARDS}
 else
 printf "# Found the following adaptors: \n\n"
 for SHOW in ${NETCARDS}; do
  SHOW_INFO=$(ip addr show ${SHOW}| grep "inet\b"|awk '{print $2}')
  printf " %-7s: %-18s\n" "${SHOW}" ${SHOW_INFO}
 done
 echo ""
  PS3="
# Please select an adapter to use for the scan: "
  select CARD in ${NETCARDS}; do
   if [ "${CARD:-empty}" != "empty" ]; then
    NETCARD="${CARD}"
    break
   else
    echo -e "\033[2A "
   fi
  done
 fi
}
#-------------------------------------------------------------------------
function find_all_active_subnets {
#-------------------------------------------------------------------------
 printf -- "#\n#-------------------------------------------------------------------------------\n"
 printf    "# $(date) - Starting RFC1918 net test using netcard ${NETCARD}..\n"
 printf -- "#-------------------------------------------------------------------------------\n"
 #-------------------------------------
 # TEST 192.168.0.0/16
 #-------------------------------------
 printf -- "# Probing 192.168.0.0/16\n"
 for A in {0..255} ; do
  echo "192.168.${A}.1"
 done | ${PARALLEL} -j${PARALLEL_SESSIONS} "${FPING} -I ${NETCARD} -A -4 -aq -c1 -q {} >/dev/null 2>/dev/null && echo {}" 
 #-------------------------------------
 # TEST 172.16.0.0/12
 #-------------------------------------
 printf -- "# Probing 172.16.0.0/12\n"
 for B in {16..31} ; do
  for C in {0..255} ; do
   echo 172.${B}.${C}.1 
  done > ${tmp_dir}/172.${B}.0-255.1.rangefile
 done
 for D in {16..31} ; do
  echo ${tmp_dir}/172.${D}.0-255.1.rangefile 
 done > ${tmp_dir}/172.rangefiles
 ${PARALLEL} -j${PARALLEL_SESSIONS} -a ${tmp_dir}/172.rangefiles "${FPING} -I ${NETCARD} -A -4 -aq -c1 -f {} 2>&1" | grep -v '/100%'|cut -d ' ' -f -1
 #-------------------------------------
 # TEST 10.0.0.0/8
 #-------------------------------------
 # reduce parallel to avoid missing targets when scanning the /8 range
 PARALLEL_SESSIONS=10
 #-------------------------------------
 printf -- "# Probing 10.0.0.0/8 (this will take a couple of minutes..)\n"
 for E in {0..255} ; do
  for F in {0..255} ; do
   echo 10.${E}.${F}.1 
  done > ${tmp_dir}/10.${E}.0-255.1.rangefile
 done
 for G in {0..255} ; do
  echo ${tmp_dir}/10.${G}.0-255.1.rangefile 
 done > ${tmp_dir}/10.rangefiles
 ${PARALLEL} -j${PARALLEL_SESSIONS} -a ${tmp_dir}/10.rangefiles "${FPING} -I ${NETCARD} -A -4 -aq -c1 -f {} 2>&1" | grep -v '/100%'|cut -d ' ' -f -1
 #-------------------------------------
 printf -- "#------------------------------------------------------------------------------\n"
 printf    "# $(date) - Stopped RFC1918 net test..\n"
 printf -- "#------------------------------------------------------------------------------\n"
}
#--------------------------------------------
# MAIN
#--------------------------------------------
select_scan_adapter
find_all_active_subnets
#-------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------
