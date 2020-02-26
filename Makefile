sdfUBP=ttyUSB1

all: dependencies run check all-yosys all-trellis all-nextpnr all-gcc all-openfpga all-elfutils all-zipversa

dependecies:
	sudo dnf -y groupinstall "Development Tools" "Development Libraries"
	sudo dnf -y install cmake clang bison flex mercurial gperf tcl-devel libftdi-devel python-xdot elfutils-devel boost-python3-devel eigen3-devel qt5-devel libmpc-devel texinfo xterm verilator

check: | run
	octave ./chkfftresults.m

run: | all-zipversa
	cd zipversa/sw/host && xterm -hold -e sudo ./netuart /dev/$(UBP) &
	sleep 0.1
	cd zipversa/sw/host && ./zipload ../rv32/fftmain
	sleep 5
	cd zipversa/sw/host && ./testfft

all-zipversa: | all-autofpga
	cd zipversa && make PATH="$PATH:$PWD/../autofpga/sw:$PWD/../riscv-gnu-toolchain/installdir/riscv/bin:$PWD/../yosys:$PWD/../nextpnr:$PWD/../prjtrellis/bin"
	cd zipversa && sudo openocd -f ecp5-versa.cfg -c "transport select jtag; init; svf rtl/zipversa.svf; exit"

all-autofpga: | all-gcc
	cd autofpga && make -j$(nproc) 

all-gcc: | all-openocd
	cd  riscv-gnu-toolchain && ./configure --prefix=${PWD}/installdir/riscv --with-arch=rv32i --with-abi=ilp32 && make  -j$(nproc) 


all-nextpnr: | all-trellis
	cd nextpnr && cmake -DARCH=ecp5 -DTRELLIS_ROOT=../prjtrellis/share/trellis -DPYTRELLIS_LIBDIR=../prjtrellis/lib64/trellis && make -j$(nproc) 

all-trellis: | all-yosys
	cd prjtrellis/libtrellis && cmake -DCMAKE_INSTALL_PREFIX=../ . && make -j$(proc) && make install local

all-yosys: 
	cd yosys && make -j$(nproc) 

	
.PHONY: all dependencies run check all-yosys all-trellis all-nextpnr all-gcc all-openfpga all-zipversa
