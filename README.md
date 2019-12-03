# ZipVersa-SSDP

## Overview


## TL;DR
- Connect the FPGA (using the inner port) to a router with 1Gbps LAN ports using Cat5e or higher grade cables (I used Cat6). 
- Set up a static IP for the FPGA. 
- Update configure.sh with i) host IP, ii) device IP, iii) subnet mask, iv) device MAC address, and v) router IP. 
- Run "source configure.sh" as super user
- Once all dependencies have been downloaded/configured/installed, the FFT example will execute and the graphs for results will be displayed. 
 

## OS
Fedora Release 30

## Board
Lattice ECP-5G Versa Board with Micron Flash 
(support for Macronix flash is under development)


## Hardware Setup 
The ZipVersa design currently supports UDP based networking using Ethernet Port 1 of the Lattice board (i.e. the port closer to the USB cable). There are two major limitations to this support: 1) no DHCP support i.e. requires a static IP to be assigned for the FPGA, and 2) no Tri-Speed Ethernet MAC i.e. it can only operate at 1Gbps. If you have a router with 1Gbps LAN ports, simply connect the board and host machine to it, set up the DNS, and you should be good to go. 

In my case, the router had 100Mbps LAN ports. Since only the FPGA has a hard requirement for a 1Gbps link, I simply cascaded the router with a switch (instead of buying a new router) as shown in the figure below. Now, the FPGA and host talk to the switch over a 1Gbps link, while the link to the router is 100Mbps. 

![alt text](https://github.com/asanaullah/ZipVersa-SSDP/blob/master/hardware_overview.png)

Link status can be easily verified by running "./netstat" from "zipversa/sw/host" once the design has been loaded. 

## Before You Begin

### Verify Jumper Placement
From  https://github.com/SymbiFlow/prjtrellis/blob/master/examples/versa5g/README.md:
"If your Versa board is new, you will need to change J50 to bypass the iSPclock. Re-arrange the jumpers to connect pins 1-2 and 3-5 (leaving one jumper spare). See p19 of the Versa Board user guide."

### Verify Flash Device
The flash controller is configured to run in QUAD I/O XIP mode and uses commands specific to the Micron N25Q128A flash device. While the Macronix flash device has similar commands, it does not support XIP mode. Therefore, the design currently only works with Micron N25Q128A flash devices (or a device with XIP support and the same commands as Micron)

### Verify Network Connectivity
Verify IP addresses of the testbed, as well as MAC address of the board. 

## Script Description


### Super User
```c
if [ $(id -u) != "0" ]; then
echo "You must be the superuser to run this script" >&2
exit 1
fi
```

### IP and MAC Addresses
```c
DEVIP=(192 168 8 10)
HOSTIP=(192 168 8 100)
ROUTERIP=(192 168 8 1)
DEVMAC="a25345b6fb5e"
MASK=("FF" "FF" "FF" "00")
```


### Select TTY Device
```c
UBP=$(ls /dev/ | grep "ttyUSB1")
if [ -z "$UBP" ]
then
      UBP=$(ls /dev/ | grep "ttyUSB")
      if [ -z "$UBP" ]
      then
      	echo "FPGA not found"
      	exit 1
      fi
fi
```

### YOSYS
```c
dnf -y groupinstall "Development Tools" "Development Libraries"
dnf -y install cmake clang bison flex mercurial gperf tcl-devel libftdi-devel python-xdot graphviz
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make -j$(nproc)
make install
cd ..
```


### Boost.Python 3
```c
dnf -y install boost-python3
ln -s /usr/lib64/libboost_python37.so.1.69.0  /usr/lib64/libboost_python37.so
```



### Project Trellis
```c
git clone --recursive https://github.com/SymbiFlow/prjtrellis
cd prjtrellis
rm -rf database
git clone https://github.com/SymbiFlow/prjtrellis-db database
cd libtrellis
cmake -DCMAKE_INSTALL_PREFIX=/usr .
make
make install
cd ../..
```


### Nextpnr
```c
dnf -y install eigen3-devel qt5-devel
git clone https://github.com/YosysHQ/nextpnr.git
cd nextpnr
cmake -DARCH=ecp5 -DTRELLIS_ROOT=/usr/share/trellis
make -j$(nproc)
make install
cd ..
```

### OpenOCD
```c
tar -xf openocd-0.10.0.tar.bz2
cd openocd-0.10.0
./configure  --enable-ft2232_libftdi --enable-libusb0 --disable-werror
make
make install
cd ..
```


### RISCV GNU Toolchain
```c
dnf -y install autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd  riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
make        
export PATH="$PATH:/opt/riscv/bin"
cd ..
```


### Simulation Tools
```c
dnf -y install verilator
dnf -y install gtkwave
```


### AutoFPGA
```c
git clone https://github.com/ZipCPU/autofpga
cd autofpga/
make
export PATH="$PATH:$PWD/sw"
cd ..
```



### ELF Utils
```c
git clone git://sourceware.org/git/elfutils.git
cd elfutils
autoreconf -i -f
./configure --enable-maintainer-mode --disable-debuginfod
make
make check
make install
cd ..
```


### NCURSES
```c
dnf -y install ncurses-devel
```


### Zipversa

#### Clone Git
```c
git clone https://github.com/asanaullah/zipversa
cd zipversa/
```


#### Update Network Addresses
```c
sed -i "58d" sw/rv32/etcnet.h
sed -i "58i #define	DEFAULTMAC	0x${DEVMAC}ul" sw/rv32/etcnet.h
sed -i "66d" sw/rv32/etcnet.h
sed -i "66i #define	DEFAULTIP	IPADDR(${DEVIP[0]},${DEVIP[1]},${DEVIP[2]},${DEVIP[3]})" sw/rv32/etcnet.h
sed -i "72d" sw/rv32/etcnet.h
sed -i "72i #define	LCLNETMASK 0x${MASK[0]}${MASK[1]}${MASK[2]}${MASK[3]}" sw/rv32/etcnet.h
sed -i "77d" sw/rv32/etcnet.h
sed -i "77i #define	DEFAULT_ROUTERIP	IPADDR(${ROUTERIP[0]},${ROUTERIP[1]},${ROUTERIP[2]},${ROUTERIP[3]})" sw/rv32/etcnet.h
sed -i "148d" sw/host/udpsocket.cpp
sed -i "148i 	getaddrinfo(\"${HOSTIP[0]}.${HOSTIP[1]}.${HOSTIP[2]}.${HOSTIP[3]}\", portstr, &hints, &res);" sw/host/udpsocket.cpp
sed -i "208d" sw/host/testfft.cpp
sed -i "208i 	UDPSOCKET *skt = new UDPSOCKET(\"${DEVIP[0]}.${DEVIP[1]}.${DEVIP[2]}.${DEVIP[3]}\");" sw/host/testfft.cpp
```


#### Bugfixes + Updates
```c
\cp  ../Makefile .
\cp -f ../chkfftresults.m sw/host/
\cp -f ../custom_ops.S sw/rv32/
\cp -f ../Makefile_rv32 sw/rv32/Makefile
\cp rtl/fft/*.hex rtl/
```

#### Build Project
```c
make
```


#### Program Board
```c
openocd -f ecp5-versa.cfg -c "transport select jtag; init; svf rtl/zipversa.svf; exit"
```


#### Start UART Connection
```c
dnf -y install xterm
cd sw/host
xterm -hold  -e ./netuart /dev/$UBP&
```


#### Load FFT design for PicoRV
```c
./zipload ../rv32/fftmain
```

#### Run FFT Application
```c
./testfft
```

#### Display results returned by FPGA
```c
dnf -y install octave
octave ./chkfftresults.m 
```

## Example Designs

1. Gettysburg


2. Ping Test


3. FFT Test


## Simulation


## Known Issues
 - If python3 is not found when running cmake for projtrellis, update line 28 by checking /usr/lib64 (currently 1.69.0)
