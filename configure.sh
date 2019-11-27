if [ $(id -u) != "0" ]; then
echo "You must be the superuser to run this script" >&2
exit 1
fi

UBP=$(ls /dev/ | grep "ttyUSB")

if [ -z "$UBP" ]
then
      echo "FPGA not found"
      exit 1
fi

git clone https://github.com/asanaullah/ZipVersa-SSDP.git
cd ZipVersa-SSDP


dnf -y groupinstall "Development Tools" "Development Libraries"
dnf -y install cmake clang bison flex mercurial gperf tcl-devel libftdi-devel python-xdot graphviz
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make -j$(nproc)
make install
cd ..


dnf -y install boost-python3
ln -s /usr/lib64/libboost_python37.so.1.69.0  /usr/lib64/libboost_python37.so

git clone --recursive https://github.com/SymbiFlow/prjtrellis
cd prjtrellis
rm -rf database
git clone https://github.com/SymbiFlow/prjtrellis-db database
cd libtrellis
cmake -DCMAKE_INSTALL_PREFIX=/usr .
make
make install
cd ../..

dnf -y install eigen3-devel qt5-devel
git clone https://github.com/YosysHQ/nextpnr.git
cd nextpnr
cmake -DARCH=ecp5 -DTRELLIS_ROOT=/usr/share/trellis
make -j$(nproc)
make install
cd ..


tar -xf openocd-0.10.0.tar.bz2
cd openocd-0.10.0
./configure  --enable-ft2232_libftdi --enable-libusb0 --disable-werror
make
make install
cd ..


dnf -y install autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd  riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
make        
export PATH="$PATH:/opt/riscv/bin"
cd ..


dnf -y install verilator

git clone https://github.com/ZipCPU/autofpga
cd autofpga/
make
export PATH="$PATH:$PWD/sw"
cd ..

git clone git://sourceware.org/git/elfutils.git
cd elfutils
autoreconf -i -f
./configure --enable-maintainer-mode --disable-debuginfod
make
make check
make install
cd ..


dnf -y install ncurses-devel

git clone https://github.com/ZipCPU/zipversa
cd zipversa/
\cp  ../Makefile .
\cp -f ../custom_ops.S sw/rv32/
\cp -f ../Makefile_rv32 sw/rv32/Makefile
\cp rtl/fft/*.hex rtl/
make


openocd -f ecp5-versa.cfg -c "transport select jtag; init; svf rtl/zipversa.svf; exit"

dnf -y install xterm

cd sw/host
cd zipversa/sw/host
xterm -hold  -e ./netuart /dev/$UBP&
sleep 0.1
xterm -hold  -e ./zipload ../rv32/gettysburg 
cd ../../../..
