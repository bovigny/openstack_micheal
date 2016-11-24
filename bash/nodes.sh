# !/bin/bash

source All.sh

echo "install chrony"
yum install chrony -y 

echo ""
ed - /etc/chrony.conf < /home/openstack/bash/chrony_compute.diff.txt
#mcp /etc_back/chrony.conf /etc/chrony.conf

echo "enable chrony"
systemctl enable chronyd.service
systemctl start chronyd.service
