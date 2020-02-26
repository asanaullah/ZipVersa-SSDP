
UBP=$(ls /dev/ | grep "ttyUSB1")

git submodule update --init --recursive

if [ ! -f config ]; then
  cat <<EOF > config
DEVIP=(192 168 8 10)
HOSTIP=(192 168 8 100)
ROUTERIP=(192 168 8 1)
DEVMAC="a25345b6fb5e"
MASK=("FF" "FF" "FF" "00")
EOF
fi
. config

cat <<EOF > zipversa/config.h
#define DEFAULTMAC		0x${DEVMAC}ul
#define DEFAULTIP		IPADDR(${DEVIP[0]},${DEVIP[1]},${DEVIP[2]},${DEVIP[3]})
#define LCLNETMASK		0xffffff00
#define DEFAULT_ROUTERIP	IPADDR(${ROUTERIP[0]},${ROUTERIP[1]},${ROUTERIP[2]},${ROUTERIP[3]})
#define HOSTIPSTR		"${HOSTIP[0]}.${HOSTIP[1]}.${HOSTIP[2]}.${HOSTIP[3]}"
#define DEVIPSTR		"${DEVIP[0]}.${DEVIP[1]}.${DEVIP[2]}.${DEVIP[3]}"
EOF
