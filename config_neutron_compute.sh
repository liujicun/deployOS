#!/bin/bash

pwd_dir=$(cd "$(dirname "$0")"; pwd)
. $pwd_dir/config_file.sh
. $pwd_dir/os_exception.sh

NEUTRON_CONF="/etc/neutron/neutron.conf"
ML2_INI="/etc/neutron/plugins/ml2/ml2_conf.ini"
NOVA_CONF="/etc/nova/nova.conf"

cp $NEUTRON_CONF $NEUTRON_CONF'.bak'`date +%Y-%m-%d-%H:%M`
cp $ML2_INI $ML2_INI'.bak'`date +%Y-%m-%d-%H:%M`
cp $NOVA_CONF $NOVA_CONF'.bak'`date +%Y-%m-%d-%H:%M`

NEUTRON_PASSWORD=$1
NEUTRON_SERVICE_AUTH_PASSWORD=$1
RABBIT_PASSWORD=$2 
COMPUTE_TUN_IP=$3

inidelete $NEUTRON_CONF database connection
iniset $NEUTRON_CONF DEFAULT verbose  True
iniset $NEUTRON_CONF DEFAULT rpc_backend  rabbit 
iniset $NEUTRON_CONF DEFAULT auth_strategy keystone
iniset $NEUTRON_CONF DEFAULT service_plugins router
iniset $NEUTRON_CONF DEFAULT allow_overlapping_ips True

iniset $NEUTRON_CONF oslo_messaging_rabbit rabbit_host  controller
iniset $NEUTRON_CONF oslo_messaging_rabbit rabbit_userid  openstack  
iniset $NEUTRON_CONF oslo_messaging_rabbit rabbit_password $RABBIT_PASSWORD 

inidelete $NEUTRON_CONF keystone_authtoken identity_uri
inidelete $NEUTRON_CONF keystone_authtoken admin_tenant_name 
inidelete $NEUTRON_CONF keystone_authtoken admin_user
inidelete $NEUTRON_CONF keystone_authtoken admin_password
inidelete $NEUTRON_CONF keystone_authtoken revocation_cache_time
iniset $NEUTRON_CONF keystone_authtoken auth_uri  http://controller:5000
iniset $NEUTRON_CONF keystone_authtoken auth_url  http://controller:35357
iniset $NEUTRON_CONF keystone_authtoken auth_plugin  password
iniset $NEUTRON_CONF keystone_authtoken project_domain_id  default
iniset $NEUTRON_CONF keystone_authtoken user_domain_id  default
iniset $NEUTRON_CONF keystone_authtoken project_name  service
iniset $NEUTRON_CONF keystone_authtoken username  neutron 
iniset $NEUTRON_CONF keystone_authtoken password  $NEUTRON_SERVICE_AUTH_PASSWORD 


iniset $ML2_INI ml2 type_drivers flat,vlan,gre,vxlan
iniset $ML2_INI ml2 tenant_network_types gre
iniset $ML2_INI ml2 mechanism_drivers openvswitch

iniset $ML2_INI ml2_type_flat flat_networks external 
iniset $ML2_INI ml2_type_gre tunnel_id_ranges  1:1000
iniset $ML2_INI securitygroup enable_security_group False 
iniset $ML2_INI securitygroup enable_ipset True
iniset $ML2_INI securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

iniset $ML2_INI ovs local_ip $COMPUTE_TUN_IP 
iniset $ML2_INI agent tunnel_types gre

iniset $NOVA_CONF neutron url  http://controller:9696
iniset $NOVA_CONF neutron auth_strategy  keystone
iniset $NOVA_CONF neutron admin_auth_url http://controller:35357/v2.0
iniset $NOVA_CONF neutron admin_tenant_name service
iniset $NOVA_CONF neutron admin_username neutron
iniset $NOVA_CONF neutron admin_password  $NEUTRON_PASSWORD


iniset $NOVA_CONF DEFAULT network_api_class nova.network.neutronv2.api.API
iniset $NOVA_CONF DEFAULT security_group_api neutron
iniset $NOVA_CONF DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver 
iniset $NOVA_CONF DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver 

service nova-compute restart
service neutron-plugin-openvswitch-agent restart
