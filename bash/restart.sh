systemctl restart chronyd.service
systemctl restart mariadb.service
systemctl restart rabbitmq-server.service
systemctl restart memcached.service
systemctl restart httpd.service
systemctl restart openstack-glance-api.service openstack-glance-registry.service
systemctl restart openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service 
systemctl restart neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
systemctl restart neutron-l3-agent.service
systemctl restart openstack-cinder-api.service openstack-cinder-scheduler.service
