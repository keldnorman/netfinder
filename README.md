# Netfinder
#
# Find all RFC1918 (private networks) gateway (if it answers ping) 
#

# PRE - Just install parallel (Thanks Ole Tange i LOVE this utility ) and fping
apt-get install parallel fping 

# Run the scanner
./netfinder.sh  | tee found_nets_alive.txt

# Example:

[image]

# Note:
# - if the gateway does not answers icmp echo / ping then you will not "see" it 
# - if the networks gateways are not .1 but .2 or something else you will have to alter the script.
#
# Disclamer:
# - Running this script will affect network performance but only for some minutes..
#
