#!/bin/bash
# Requires the wakeonlan package (sudo dnf install wakeonlan)

#MAC="E0-75-26-89-AB-BB"
MAC="E0:75:26:89:AB:BB"
IP="192.168.1.44"
BROADCAST="192.168.1.255"

echo "Attempting to wake PC at $IP with MAC $MAC..."

# Try multiple methods
echo "Method 1: Direct IP with wakeonlan"
wakeonlan -i $IP $MAC

echo "Method 2: Broadcast with wakeonlan"
wakeonlan -i $BROADCAST $MAC

echo "Method 3: Default broadcast with wakeonlan"
wakeonlan $MAC

echo "Method 4: Port 7 with wakeonlan"
wakeonlan -p 7 $MAC

echo "Wake-on-LAN packets sent. Waiting 40 seconds before pinging $IP"
sleep 40 && ping -c 3 $IP
