# ZipVersa - Single Source Deployment Project

## Overview
The goal of the [ZipVersa](https://github.com/ZipCPU/zipvera) project was to demonstrate how a completely open source tool chain can be used to compile HDL designs, including a RISCV core, to a Lattice ECP5-5G Versa FPGA board. This Single Source Deployment Project (SSDP) simplifies the process of setting up environment/tools by providing a script for doing so. Details are provided below for the different tools installed/configured, as well as a description of how to get example projects/simulations up and running.

Note that the ZipVersa project was forked since changes needed to be made downstream for bugfixes, customization of network parameters, addition of support for SPI flash (under development) etc. A tarball for the tested version of OpenOCD is also included.    

## TL;DR
- Connect the FPGA (using the inner port) to a router with 1Gbps LAN ports using Cat5e or higher grade cables (I used Cat6). 
- Connect the FPGA to the host using the USB cable.
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

Link status can be easily verified by running 
```bash
./netstat
```
from `zipversa/sw/host` once the design has been loaded. 

## Before You Begin
#### Verify Jumper Placement
From  [Project Trellis](https://github.com/SymbiFlow/prjtrellis/blob/master/examples/versa5g/README.md): "If your Versa board is new, you will need to change J50 to bypass the iSPclock. Rearrange the jumpers to connect pins 1-2 and 3-5 (leaving one jumper spare)."
See page 20 of the [user guide](https://www.mouser.com/catalog/additional/Lattice_EB98.pdf).
#### Verify Flash Device
The flash controller is configured to run in QUAD I/O XIP mode and uses commands specific to the Micron N25Q128A flash device. While the Macronix flash device has similar commands, it does not support XIP mode. Therefore, the design currently only works with Micron N25Q128A flash devices (or a device with XIP support and the same commands as Micron)
#### Verify Network Connectivity
Verify IP addresses of the testbed, as well as MAC address of the board. Ensure that the networking hardware, including cables, support Gigabit ethernet.
#### Verify Host Connectivity
Ensure that your machine can see the FPGA via the USB cable. Running `lsusb` should print out something along the lines of:
```bash
Bus 001 Device 003: ID 0403:6010 Future Technology Devices International, Ltd FT2232C/D/H Dual UART/FIFO IC
```

## Script Description
#### Super User
A simple check to get us started. While not everything requires super user privileges, enough does that it is just convenient to do the entire thing this way. 
```c
if [ $(id -u) != "0" ]; then
echo "You must be the superuser to run this script" >&2
exit 1
fi
```

#### IP and MAC Addresses
Next we add in our custom network parameters for the FPGA static IP4 address (`DEVIP`), host machine IP4 address (`HOSTIP`), gateway IP4 address (`ROUTERIP`), FPGA MAC address (`DEVMAC`) and the subnet mask (`MASK`). 

If you are running this project using QEMU/KVM, the `ROUTERIP` is the physical gateway and `HOSTIP` is the virtual IP4 address for the VM. 

`DEVMAC` is currently taken as is from the original ZipVersa project. 

```c
DEVIP=(192 168 8 10)
HOSTIP=(192 168 8 100)
ROUTERIP=(192 168 8 1)
DEVMAC="a25345b6fb5e"
MASK=("FF" "FF" "FF" "00")
```


#### Select TTY Device
Next we select the FPGA tty device. This will be the serial port used to communicate with the FPGA once the ZipVersa base design has been loaded. 

It was `ttyUSB1` for me  and so the script tries to set that if possible. If `ttyUSB1` cannot be found, then a wildcard search is done and the first device containing `ttyUSB` is selected. If the command fails there too, run `lsusb` and verify that the host machine can detect the FPGA. If the FPGA is detected, or if the `netuart` command below fails to open the port due to incorrect `ttyUSB` selection, try setting this value manually. 
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

#### YOSYS
Now that we are all set with specifying our testbed specific parameters, let's get to setting up the environment. First up is Yosys, an open source synthesis tool. It compiles the HDL source files and generates a netlist (JSON format in our case) for the target device. The design is optimized using the Berkley ABC optimizer.
```c
dnf -y groupinstall "Development Tools" "Development Libraries"
dnf -y install cmake clang bison flex mercurial gperf tcl-devel libftdi-devel python-xdot graphviz
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make -j$(nproc)
make install
cd ..
```

#### Boost.Python 3
Next we install Boost.Python 3, which is needed by Project Trellis. We need to install the development package.


```c
dnf -y install boost-python3-devel
```



#### Project Trellis
Project Trellis is the database containing the reverse engineered low-level layout of the Lattice ECP5 boards. This database is what allowed open source Place and Route tools, such as Nextpnr (below), to generate the FPGA bitstream from a Yosys netlist output. Installing Project Trellis requires cloning two separate repositories as shown below. The target installation directory can be specified using `-DCMAKE_INSTALL_PREFIX` when running `cmake`. 

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


#### Nextpnr
As mentioned above, Nextpnr is an open source Place&Route tool. It maps the logical layout and connectivity of the synthesized design to an actual set of Look Up Tables (LUTs) and wires/switch-fabric in the FPGA. Place & Route is more time consuming than synthesis, and a harder problem to open source since the physical layout of the FPGA boards is typically proprietary.   

Using the `-DARCH` flag, we configure it for the ECP5 board. If Project Trellis was installed in a custom folder, then modify `-DTRELLIS_ROOT` to specify this location. 

```c
dnf -y install eigen3-devel qt5-devel
git clone https://github.com/YosysHQ/nextpnr.git
cd nextpnr
cmake -DARCH=ecp5 -DTRELLIS_ROOT=/usr/share/trellis
make -j$(nproc)
make install
cd ..
```

#### OpenOCD
Finally, we install OpenOCD, which allows the bitstream, generated above, to be downloaded onto the FPGA board. Once OpenOCD is set up, one can start to deploy custom designs for the FPGA. Project Trellis has a few example you could try. 
```c
tar -xf openocd-0.10.0.tar.bz2
cd openocd-0.10.0
./configure  --enable-ft2232_libftdi --enable-libusb0 --disable-werror
make
make install
cd ..
```
The rest of this script is going to set up dependencies for the ZipVersa project and run an example design. 

#### RISCV GNU Toolchain
The example designs in Project Trellis use assembly language to code for the PicoRV RISC-V core. As designs get more sophisticated, a C/C++ compiler is needed for the RISC-V. Enter the RISCV GNU toolchain. We install the toolchain for a 32 bit integer instruction set architecture (`--with-arch=rv32i`) and a programming model with 32 bit data types ints/long/pointers (`--with-abi=ilp32`). 
```c
dnf -y install autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd  riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
make        
export PATH="$PATH:/opt/riscv/bin"
cd ..
```

#### Simulation Tools
Verilator is an open source RTL simulation tool while Gtkwave allows us to plot the signal waveforms. Of these, Verilator is required to build the ZipVersa project. 
```c
dnf -y install verilator
dnf -y install gtkwave
```

#### AutoFPGA
"The goal of AutoFPGA is to be able to run it with a list of peripheral definition files, given on the command line, and to thus be able to generate (or update?) the various board definition files."
```c
git clone https://github.com/ZipCPU/autofpga
cd autofpga/
make
export PATH="$PATH:$PWD/sw"
cd ..
```

#### ELF Utils
Libelf is needed to build the applications in `sw/host`.
```c
dnf -y install elfutils-libelf-devel
```

#### NCURSES
Needed to build `zipdbg` in `sw/host`.
```c
dnf -y install ncurses-devel
```


#### ZipVersa
Now that we have set up our environment, we can now get to building the actual ZipVersa project. 
##### Clone Git
Clone Git
```c
git clone https://github.com/asanaullah/zipversa
cd zipversa/
```

##### Update Network Addresses
Using the `sed` command, update the network parameters specified above. 
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

##### Build Project
```c
make
```

##### Program Board
Make sure that the `ecp5-versa.cfg` matches your board. If not, find the appropriate one in `/usr/share/trellis/misc/openocd` and link to that. 
```c
openocd -f ecp5-versa.cfg -c "transport select jtag; init; svf rtl/zipversa.svf; exit"
```

##### Start UART Connection
While we could have started this as a background process in the same terminal, it throws out a lot of garbage values which make it difficult to read the actual board responses. `gnome-terminal` wasn't working for me so I ran it using `xterm` instead. Note that unless `netuart` is run, the board will not respond. 
```c
dnf -y install xterm
cd sw/host
xterm -hold  -e ./netuart /dev/$UBP&
```

##### Load FFT design for PicoRV
This checks the board flash memory to see if it matches the FFT program. If so, the command completes. Otherwise, sector by sector, the memory is erased and the FFT program is written. 
```c
./zipload ../rv32/fftmain
```
Note that once the flash memory has been programmed, the design will start executing. It will send out ARP packets to determine MAC addresses of the router. This does not mean that the actual FFT has started executing. Doing so requires running the host application (shown below). The other two example designs (pingtest, gettysburg) do not require a host application.  

Also note that it is likely that there will be a couple of failed attempts to get the MAC address; this is fine. If, however, the `xterm` window opened earlier continues to print that the ARP-lookup failed, double check the network parameters specified in the beginning and run `./netstat` to verify that the link is 1000Mbps.  

##### Run FFT Application
Running `./testfft` causes the board to send out ARP-packets again, this time trying to get the MAC address of the host machine. Then the `testfft` application sends the board four impulse functions, which computes the FFT, and returns the transforms back to the host. 
```c
./testfft
```
The figure below shows an example result of loading the FFT program onto the board and running the host application. Note that the errors seen are due to a mismatch in the operating frequencies of the RISCV core and the network controller. This should not significantly impact the observed waveforms in the next step of the script. 
![alt text](https://github.com/asanaullah/ZipVersa-SSDP/blob/master/fft_uart_display.png)

##### Display results returned by FPGA
Finally, we plot the waveforms for the four returned transforms. 
```c
dnf -y install octave
octave ./chkfftresults.m 
```

##### Other Example Designs
Execute from `zipversa/sw/host`. Ensure that `netuart` is running. 
- Gettysburg:
`./zipload ../rv32/gettysburg`
This will print out the Gettysburg address on the `netuart` terminal. 

- Ping Test:
`./zipload ../rv32/pingtest`
This will ping the router and print the results on the `netuart` terminal. 


#### Simulation
From `zipversa/sim/verilated/README.md`:
"To run the simulation , first kill any `netuart`s that might be running, and then run `main_tb`.  `main_tb` may also be given an argument, which is the name of any (ELF) program to run within the CPU within.  This program will then be loaded into design memory, and the design will begin as though it were already loaded at startup.  For example, `main_tb ../../sw/rv32/fftsimtest` will run a simulated-based test of the internal FFT.  A `-d` flag may also be used to generate a `.vcd` trace file as well for debugging purposes.  Do be aware, this trace faile can become quite large.  (I usually kill the simulation before it gets to 20GB.)"

