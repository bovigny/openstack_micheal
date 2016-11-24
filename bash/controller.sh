# !/bin/bash

##########################################
## passes
##########################################
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
#script
##########################################
source All.sh

echo "install chrony"
yum install chrony -y 

ed - /etc/chrony.conf  < /home/openstack/bash/chrony.conf.diff.txt  

echo "enable chrony"
systemctl enable chronyd.service
systemctl start chronyd.service

##########################################
#script MYSQL
##########################################
echo "SQL database"
yum install mariadb mariadb-server python2-PyMySQL -y 

mv /home/openstack/bash/openstack.cnf /etc/my.cnf.d/openstack.cnf

echo "service SQL"
systemctl enable mariadb.service
systemctl start mariadb.service

mysqladmin -u root password $MYSQL_PASS

##########################################
#script Rabbitmq
##########################################
echo "install rabbitmq-server"
yum install rabbitmq-server -y 
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
 
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

##########################################
#script memecached 
##########################################
echo "install memecached"
yum install memcached python-memcached -y 
systemctl enable memcached.service
systemctl start memcached.service

##########################################
#identity - keystone
##########################################
echo "Create database for identity"
mysqlrequest $MYSQL_PASS "CREATE DATABASE keystone;"
mysqlrequest $MYSQL_PASS "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';"
mysqlrequest $MYSQL_PASS "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$HOST_CONTROLLER' IDENTIFIED BY '$KEYSTONE_DBPASS';"
mysqlrequest $MYSQL_PASS "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';"

yum install openstack-keystone httpd mod_wsgi -y 

ed - /etc/keystone/keystone.conf  < /home/openstack/bash/keystone.conf.diff.txt
#mcp /etc_back/keystone/keystone.conf /etc/keystone/keystone.conf

echo "populate"
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://daplab-cn-8.fri.lan:35357/v3/ \
  --bootstrap-internal-url http://daplab-cn-8.fri.lan:35357/v3/ \
  --bootstrap-public-url http://daplab-cn-8.fri.lan:5000/v3/ \
  --bootstrap-region-id RegionOne

ed - /etc/httpd/conf/httpd.conf < /home/openstack/bash/httpd.conf.diff.txt
#mcp /etc_back/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf 
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

echo "Finalize"
systemctl enable httpd.service
systemctl start httpd.service

ed - /etc/keystone/keystone-paste.ini < /home/openstack/bash/keystone-paste.ini.diff.txt
#mcp /etc_back/keystone/keystone-paste.ini /etc/keystone/keystone-paste.ini 

runOS "export OS_USERNAME=admin &&
export OS_PASSWORD=$ADMIN_PASS &&
export OS_PROJECT_NAME=admin &&
export OS_USER_DOMAIN_NAME=default && 
export OS_PROJECT_DOMAIN_NAME=default &&
export OS_AUTH_URL=http://daplab-cn-8.fri.lan:35357/v3 &&
export OS_IDENTITY_API_VERSION=3 &&

openstack project create --domain default --description 'Service Project' service &&
openstack project create --domain default --description 'Demo Project' demo && 
openstack user create --domain default --password $DEMO_PASS demo &&
openstack role create user &&
openstack role add --project demo --user demo user && 
openstack --os-auth-url http://daplab-cn-8.fri.lan:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue &&
openstack --os-auth-url http://daplab-cn-8.fri.lan:5000/v3  --os-project-domain-name default --os-user-domain-name default --os-project-name demo --os-username demo token issue"


echo "creating scripts"
runOS "echo 'export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://daplab-cn-8.fri.lan:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2' > admin-openrc"


runOS "echo 'export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://daplab-cn-8.fri.lan:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2' > demo-openrc" 

echo "using scripts"
runOS ". admin-openrc &&  openstack token issue"


##########################################
#identity - glance
##########################################

echo "installing glance -- image services"
mysqlrequest $MYSQL_PASS "CREATE DATABASE glance;"
mysqlrequest $MYSQL_PASS "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';"
mysqlrequest $MYSQL_PASS "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS'"
mysqlrequest $MYSQL_PASS "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$HOST_CONTROLLER' IDENTIFIED BY '$GLANCE_DBPASS';"

runOS ". admin-openrc && 
	openstack user create --domain default --password $GLANCE_PASS glance &&
	openstack role add --project service --user glance admin &&
	openstack service create --name glance --description 'OpenStack Image' image &&
	openstack endpoint create --region RegionOne image public http://daplab-cn-8.fri.lan:9292 &&
	openstack endpoint create --region RegionOne image internal http://daplab-cn-8.fri.lan:9292 &&
	openstack endpoint create --region RegionOne image admin http://daplab-cn-8.fri.lan:9292
	"
	
echo 'Install and configure component'

yum install openstack-glance -y 
ed - /etc/glance/glance-api.conf < /home/openstack/bash/glance-api.diff.txt
ed - /etc/glance/glance-registry.conf < /home/openstack/bash/glance-registry.diff.txt
#mcp /etc_back/glance/glance-api.conf /etc/glance/glance-api.conf
#mcp /etc_back/glance/glance-registry.conf /etc/glance/glance-registry.conf

echo "Populate the Image service database"
su -s /bin/sh -c "glance-manage db_sync" glance

echo "Finalize installation"
systemctl enable openstack-glance-api.service ppenstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

echo "verif"
runOS ". admin-openrc &&
	wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img &&
	openstack image create 'cirros' --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --public &&
	openstack image list
	"

##########################################
#Nova -  controller node side 
##########################################	
echo "Compute service - controller - Nova"	

mysqlrequest $MYSQL_PASS "CREATE DATABASE nova_api; 
	CREATE DATABASE nova; 
	GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS'; 
	GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'$HOST_CONTROLLER' IDENTIFIED BY '$NOVA_DBPASS'; 
        GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS'; 
	GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
        GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$HOST_CONTROLLER' IDENTIFIED BY '$NOVA_DBPASS'; 
	GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';" 

runOS ". admin-openrc &&
openstack user create --domain default --password $NOVA_PASS nova &&
openstack role add --project service --user nova admin &&
openstack service create --name nova  --description 'OpenStack Compute' compute &&
openstack endpoint create --region RegionOne compute public http://daplab-cn-8.fri.lan:8774/v2.1/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne compute internal http://daplab-cn-8.fri.lan:8774/v2.1/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne compute admin http://daplab-cn-8.fri.lan:8774/v2.1/%\(tenant_id\)s"

echo "Install and configure components"
yum install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy  openstack-nova-scheduler -y 
ed - /etc/nova/nova.conf < /home/openstack/bash/nova.conf.diff.txt
#mcp /etc_back/nova/nova.conf /etc/nova/nova.conf

echo "Populate "
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova

echo "Finalize installation"
systemctl enable openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service 

######## check after installing compute nodes
echo "check on compute node -- on the controller"
runOS " . admin-openrc && openstack compute service list"

##########################################
# neutron - network  
##########################################	
echo "Networking service on the controller node"

mysqlrequest $MYSQL_PASS "CREATE DATABASE neutron; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS'; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';  GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'$HOST_CONTROLLER' IDENTIFIED BY '$NEUTRON_DBPASS';"

runOS ". admin-openrc && 
openstack user create --domain default --password $NEUTRON_DBPASS neutron && 
openstack role add --project service --user neutron admin && 
openstack service create --name neutron --description 'OpenStack Networking' network &&
openstack endpoint create --region RegionOne network public http://daplab-cn-8.fri.lan:9696 &&
openstack endpoint create --region RegionOne network internal http://daplab-cn-8.fri.lan:9696 &&
openstack endpoint create --region RegionOne network admin http://daplab-cn-8.fri.lan:9696"

echo "Option 2 : Self-service networks"

yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y 
ed - /etc/neutron/neutron.conf < /home/openstack/bash/neutron.conf.diff.txt
#mcp /etc_back/neutron/neutron.conf /etc/neutron/neutron.conf
ed - /etc/neutron/plugins/ml2/ml2_conf.ini < /home/openstack/bash/ml2_conf.ini.diff.txt
#mcp /etc_back/neutron/plugins/ml2/ml2_conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
ed - /etc/neutron/plugins/ml2/linuxbridge_agent.ini < /home/openstack/bash/linuxbridge_agent.ini.diff.txt
#mcp /etc_back/neutron/plugins/ml2/linuxbridge_agent.ini  /etc/neutron/plugins/ml2/linuxbridge_agent.ini
ed - /etc/neutron/l3_agent.ini < /home/openstack/bash/l3_agent.ini.diff.txt
#mcp /etc_back/neutron/l3_agent.ini /etc/neutron/l3_agent.ini 
ed - /etc/neutron/dhcp_agent.ini < /home/openstack/bash/dhcp_agent.ini.diff.txt
#mcp /etc_back/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini

echo "finish option 2"

echo "make option 1"
ed - /etc/neutron/metadata_agent.ini < /home/openstack/bash/metadata_agent.ini.diff.txt
#mcp /etc_back/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


systemctl restart openstack-nova-api.service
systemctl enable neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service   neutron-metadata-agent.service
systemctl start neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
systemctl enable neutron-l3-agent.service
systemctl start neutron-l3-agent.service

# ON EN EST Läääääääääää
######## check after installing compute nodes
echo "Verify operation on the controller"
runOS " . admin-openrc &&
neutron ext-list &&
openstack network agent list
"

##########################################
#Dashboard horizon   
##########################################	
echo "installation Dashboard"
yum install openstack-dashboard -y
ed - /etc/openstack-dashboard/local_settings < /home/openstack/bash/local_settings.diff.txt
#mcp /etc_back/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings

############# set maxmum connection mysql
in /etc/my.cnf Under the [mysqld] section and /etc/my.cnf.d/mariadb-servcer.cnf add the following setting:
max_connections = 10000 and restart the service


echo "Finalize installation"
systemctl restart httpd.service memcached.service

##########################################
# Block storage service   
##########################################	

mysqlrequest $MYSQL_PASS "CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'$HOST_CONTROLLER' IDENTIFIED BY '$CINDER_DBPASS';"

runOS ". admin-openrc &&
openstack user create --domain default --password $CINDER_PASS cinder &&
openstack role add --project service --user cinder admin &&
openstack service create --name cinder --description 'OpenStack Block Storage' volume &&
openstack service create --name cinderv2 --description 'OpenStack Block Storage' volumev2 &&
openstack endpoint create --region RegionOne  volume public http://daplab-cn-8.fri.lan:8776/v1/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne  volume internal http://daplab-cn-8.fri.lan:8776/v1/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne  volume admin http://daplab-cn-8.fri.lan:8776/v1/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne  volumev2 public http://daplab-cn-8.fri.lan:8776/v2/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne  volumev2 internal http://daplab-cn-8.fri.lan:8776/v2/%\(tenant_id\)s &&
openstack endpoint create --region RegionOne  volumev2 admin http://daplab-cn-8.fri.lan:8776/v2/%\(tenant_id\)s
"

yum install openstack-cinder -y 
ed - /etc/cinder/cinder.conf < /home/openstack/bash/cinder.conf.diff.txt
#mcp /etc_back/cinder/cinder.conf  /etc/cinder/cinder.conf 

su -s /bin/sh -c "cinder-manage db sync" cinder

###### redundant mcp /etc_back/nova/nova.conf /etc/nova/nova.conf

echo "finaluze installation"
systemctl restart openstack-nova-api.service
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service


##########################################
# check Nova - Neutron - Dash board - storage     
##########################################	

####Nova 
echo "check on compute node -- on the controller"
runOS " . admin-openrc && openstack compute service list"

####Neutron
echo "Verify operation on the controller"
runOS " . admin-openrc &&
neutron ext-list &&
openstack network agent list
"
####Dashboard 
echo "erify operation of the dashboard.
Access the dashboard using a web browser at http://daplab-cn-8.fri.lan/dashboard.
Authenticate using admin or demo user and default domain credentials.
"
####storage 
runOS ". admin-openrc && openstack volume service list"





