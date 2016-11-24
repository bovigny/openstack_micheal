# !/bin/bash

source nodes.sh 

##########################################
#Nova - compute node side  
##########################################	

echo "install and configure compute node"

yum install openstack-nova-compute kvm -y
ed - /etc/nova/nova.conf < /home/openstack/bash/nova_compute.diff.txt
#mcp /etc_back/nova/nova.conf /etc/nova/nova.conf 

echo "finalize"
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service 


##########################################
#neurton - compute node side  
##########################################	
echo "install and configure compute node"
yum install openstack-neutron-linuxbridge ebtables ipset -y 

ed - /etc/neutron/plugins/ml2/linuxbridge_agent.ini < /home/openstack/bash/linuxbridge_agent_compute.ini.txt
#mcp /etc_back/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
## redundant  mcp /etc_back/nova/nova.conf /etc/nova/nova.conf

echo "finalize installation" 
systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service

