# ZipVersa-SSDP

## Overview


## TL;DR
- Connect the FPGA (using the inner port) to a router with 1Gbps LAN ports. 
- Set up a static IP for the FPGA. 
- Update configure.sh with i) host IP, ii) device IP, iii) subnet mask, iv) device MAC address, and v) router IP. 
- Run "source configure.sh" as super user
- Once all dependencies have been downloaded/configured/installed, the FFT example will execute and the graphs for results will be displayed. 
 
## Hardware Setup 
The ZipVersa design currently supports UDP based networking using Ethernet Port 1 of the Lattice board (i.e. the port closer to the USB cable). There are two major limitations to this support: 1) no DHCP support i.e. requires a static IP to be assigned for the FPGA, and 2) no Tri-Speed Ethernet MAC i.e. it can only operate at 1Gbps. If you have a router with 1Gbps LAN ports, simply connect the board and host machine to it, set up the DNS, and you should be good to go. 

In my case, the router had 100Mbps LAN ports. 
![alt text](https://github.com/asanaullah/ZipVersa-SSDP/blob/master/hardware_overview.png)

## OS
Fedora Release 30


## Before You Begin



## Script Description




## Example Designs

1. Gettysburg


2. Ping Test


3. FFT Test


## Simulation


## Known Issues
 - If python3 is not found when running cmake for projtrellis, update line 28 by checking /usr/lib64 (currently 1.69.0)
