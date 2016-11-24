RABBIT_PASS="leo7_woo"
MYSQL_PASS="leo7_woo"
KEYSTONE_DBPASS="leo7_woo"
ADMIN_PASS="leo7_woo"
DEMO_PASS="leo7_woo"
GLANCE_DBPASS="leo7_woo"
GLANCE_PASS="leo7_woo"
NOVA_DBPASS="leo7_woo"
NOVA_PASS="leo7_woo"
NEUTRON_DBPASS="leo7_woo"
CINDER_DBPASS="leo7_woo"
CINDER_PASS="leo7_woo"
HOST_CONTROLLER="daplab-cn-8.fri.lan"
##########################################
#functions
##########################################

# $1 -- comment je veux ce fichier (output final)
# $2 -- le fichier à changer
function makediff { 
	diff -e $2 $1 > $3.txt
	echo "w" >> $3.txt
	echo "ed - $2 < $3.txt"
}

# copy and save before delete the distintion for file 
function mcp { 
	mv $2 $2.org 
	cp $1 $2

	owners=$(ls -l $2.org |awk '{print $3"."$4}'|tail 1)
	chown $owners $2
}

function mysqlrequest {
	echo "mysql -u root -p\"$1\" -e \"$2\" "|bash
}
function runOS {

	echo "runuser -l  openstack -c \"$1\"" | bash
}
 
##########################################
#script
##########################################

# echo checks config reseau
echo "checks config reseau"

echo "stop firewalld"
systemctl disable firewalld
systemctl stop firewalld

echo "stop ntp"
systemctl disable ntpd
systemctl stop ntpd

echo "install centos-release-openstack-newton"
yum install centos-release-openstack-newton qemu* kvm qemu-kvm-tools.x86_64 qemu-kvm-tools-ev.x86_64 qemu-kvm.x86_64 qemu-kvm-common.x86_64 qemu-kvm-common-ev.x86_64  virt-v2v.x86_64 -y 


echo "yum install python-openstackclient"
yum install python-openstackclient -y 


echo "disable selinux"
echo 0 >/selinux/enforce
setenforce 0
#mcp /etc_back/sysconfig/selinux /etc/sysconfig/selinux

echo "yum upgrade"
yum upgrade -y 

