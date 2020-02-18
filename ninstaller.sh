#/bin/bash
###get the value with runme.sh token
# what this script will be doing
# script without any parameter 
# create normal nsrvs host
# create with parameter source/destination first you need to create source and add ID of the source on the destination
# ninstaller.sh migrate source
# ninstaller.sh migrate destination [ID of first command]


NSRVS_PATH=/var/tmp/.nsrvs
mkdir -p $NSRVS_PATH
NSRVS_DOCKER=$(docker run -d --privileged  -v $NSRVS_PATH:/nsrvs nsrvs/nsrvs-client --config /nsrvs/client.ovpn --auth-nocache)
if[ $1 == "source" || $1 == "destination"]
then
NSRVS_TOKEN=$(curl -s https://api.nsrvs.com/new)
echo $NSRVS_TOKEN
####create the new entry the returning value would be 
fi
curl -s https://api.nsrvs.com/tokens/$NSRVS_TOKEN >$NSRVS_PATH/$NSRVS_TOKEN
NOVPNCRT=$(grep -Po '"'"ovpncrt"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/$NSRVS_TOKEN)
NOVPNKEY=$(grep -Po '"'"ovpnkey"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/$NSRVS_TOKEN)
NSSHPUB=$(grep -Po '"'"sshpub"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/$NSRVS_TOKEN)
NSSHKEY=$(grep -Po '"'"sshkey"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/$NSRVS_TOKEN)
NOPVNSRVID=$(grep -Po '"ovpnserver_id":(\d*?,|.*?[^\\]",)' $NSRVS_PATH/$NSRVS_TOKEN|grep -o '[0-9]*')
curl -s https://api.nsrvs.com/ovpnsrvr/$NOPVNSRVID > $NSRVS_PATH/ovpn-srv.conf
NOVPNSIP=$(grep -Po '"'"serverip"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/ovpn-srv.conf)
NOVPNSPORT=$(grep -Po '"'"serverport"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/ovpn-srv.conf)
NOVPNCA=$(grep -Po '"'"ca"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/ovpn-srv.conf)
NOVPNTLS=$(grep -Po '"'"tls-auth"'"\s*:\s*"\K([^"]*)' $NSRVS_PATH/ovpn-srv.conf)
CLIENT_FILE="$(cat <<EOF
##created by ninstaller
client
nobind
dev tun
remote-cert-tls server
comp-lzo no

remote $NOVPNSIP $NOVPNSPORT udp

<key>
$NOVPNKEY
</key>
<cert>
$NOVPNCRT
</cert>
<ca>
$NOVPNCA
</ca>
key-direction 1
<tls-auth>
$NOVPNTLS
</tls-auth>

redirect-gateway def1
EOF
)"
echo "$CLIENT_FILE" >$NSRVS_PATH/client.ovpn
sed -i 's/\\n/\'$'\n''/g' $NSRVS_PATH/client.ovpn
###download monitoring
wget http://download.nsrvs.org/node_exporter -O $NSRVS_PATH/node_exporter
wget http://download.nsrvs.org/check_mk -O $NSRVS_PATH/check_mk
chmod 755 $NSRVS_PATH/check_mk /node_exporter
echo $NSSHKEY>$NSRVS_PATH/client
echo $NSSHPUB>$NSRVS_PATH/client.pub
sed -i 's/\\n/\'$'\n''/g' $NSRVS_PATH/client
chmod 600 $NSRVS_PATH/client
if [ -f /root/.ssh ];then
cat $NSRVS_PATH/client.pub>>/root/.ssh/authorized_keys
fi

######detectOS#######
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
     OS=$DISTRIB_ID
     VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
     OS=Debian
     VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
     OS=SuSE
elif [ -f /etc/redhat-release ]; then
     OS=Centos
else
     OS=$(uname -s)
     VER=$(uname -r)
fi

###download and install rkt to CENTOS or UBUNTU
if [[ $OS == *"CentOS"* ]]&&[[ $VER == *"7"* ]]; then
#   wget http://download.nsrvs.org/redhat.rpm
#   rpm -ivh redhat.rpm
    yum install -y yum-utils device-mapper-persistent-data lvm2
	yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
	yum -y install docker-ce docker-ce-cli containerd.io
	systemctl enable docker
	systemctl start docker
docker run -d --privileged  -v $NSRVS_PATH:/nsrvs nsrvs/nsrvs-client --config /nsrvs/client.ovpn --auth-nocache
elif [[ $OS == *"CentOS"* ]]&&[[ $VER == *"6"* ]]; then
#	rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	yum update -y
	yum -y install docker-io
	service docker start
	service docker on
docker run -d --privileged  -v $NSRVS_PATH:/nsrvs nsrvs/nsrvs-client --config /nsrvs/client.ovpn --auth-nocache
elif [[ $OS == *"SuSE"* ]]||[[ $OS == *"SLES"* ]]; then
#zypper -n install --force docker
#systemctl enable docker
#systemctl start docker
   wget http://download.nsrvs.org/redhat.rpm
   rpm -ivh redhat.rpm
rkt run --insecure-options=image,all-run --volume=work,kind=host,source=/tmp/.nsrvs --mount volume=work,target=/nsrvs docker://nsrvs/nsrvs-client -- --config /nsrvs/client.ovpn --auth-nocache
elif [[ $OS == *"Debian"* ]]; then
#	apt-get remove docker docker-engine docker.io containerd runc
	apt-get update -y
	apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
	apt-get update
	apt-get install -y docker-ce docker-ce-cli containerd.io
	docker run -d --privileged  -v $NSRVS_PATH:/nsrvs nsrvs/nsrvs-client --config /nsrvs/client.ovpn --auth-nocache
elif [[ $OS == *"Ubuntu"* ]]; then
	apt-get update
	apt-get install -y docker.io
	docker run -d --privileged  -v $NSRVS_PATH:/nsrvs nsrvs/nsrvs-client --config /nsrvs/client.ovpn --auth-nocache
fi
