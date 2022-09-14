#!/bin/bash

wait_lb() {
while [ true ]
do
  curl --output /dev/null --silent -k https://${k3s_url}:6443
  if [[ "$?" -eq 0 ]]; then
    break
  fi
  sleep 5
  echo "wait for LB"
done
}

if test -f /etc/lsb-release; then
  operating_system="ubuntu"
else
  operating_system="oraclelinux"
fi

if [[ "$operating_system" == "ubuntu" ]]; then
  # Disable firewall 
  /usr/sbin/netfilter-persistent stop
  /usr/sbin/netfilter-persistent flush

  systemctl stop netfilter-persistent.service
  systemctl disable netfilter-persistent.service

  # END Disable firewall

  apt-get update
  apt-get install -y software-properties-common jq
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  %{ if install_nginx_ingress }
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python3 python3-pip nginx
  systemctl enable nginx
  pip install oci-cli
  %{ endif }
fi

if [[ "$operating_system" == "oraclelinux" ]]; then
  # Disable firewall
  systemctl disable --now firewalld
  # END Disable firewall

  # Fix iptables/SELinux bug
  echo '(allow iptables_t cgroup_t (dir (ioctl)))' > /root/local_iptables.cil
  semodule -i /root/local_iptables.cil

  dnf -y update
  dnf -y install jq curl
  %{ if install_nginx_ingress }
  if grep -q "el9" /etc/os-release; then
    dnf -y install python39-oci-cli python3-jinja2 nginx-all-modules
  else
    dnf -y module enable nginx:1.20 python36:3.6
    dnf -y install python36-oci-cli python3-jinja2 nginx-all-modules
  fi
  %{ endif }

  # Nginx Selinux Fix
  setsebool httpd_can_network_connect on -P
fi

local_ip=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/vnics/ | jq -r '.[0].privateIp')
flannel_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')

k3s_install_params=("--node-ip $local_ip")
k3s_install_params+=("--flannel-iface $flannel_iface")

if [[ "$operating_system" == "oraclelinux" ]]; then
  k3s_install_params+=(="--selinux")
fi

INSTALL_PARAMS="$${k3s_install_params[*]}"

wait_lb

until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} K3S_URL=https://${k3s_url}:6443 sh -s - $INSTALL_PARAMS); do
  echo 'k3s did not install correctly'
  sleep 2
done

%{ if install_nginx_ingress }
cat << 'EOF' > /root/find_ips.sh
export OCI_CLI_AUTH=instance_principal
private_ips=()

# Fetch the OCID of all the running instances in OCI and store to an array
instance_ocids=$(oci search resource structured-search --query-text "QUERY instance resources where lifeCycleState='RUNNING'"  --query 'data.items[*].identifier' --raw-output | jq -r '.[]' ) 

# Iterate through the array to fetch details of each instance one by one
for val in $${instance_ocids[@]} ; do
  
  echo $val

  # Get name of the instance
  instance_name=$(oci compute instance get --instance-id $val --raw-output --query 'data."display-name"')
  echo $instance_name


  # Get Public Ip of the instance
  public_ip=$(oci compute instance list-vnics --instance-id $val --raw-output --query 'data[0]."public-ip"')
  echo $public_ip

  private_ip=$(oci compute instance list-vnics --instance-id $val --raw-output --query 'data[0]."private-ip"')
  echo $private_ip
  private_ips+=($private_ip)
done

for i in "$${private_ips[@]}"
do
  echo "$i" >> /tmp/private_ips
done
EOF

if [[ "$operating_system" == "ubuntu" ]]; then
  NGINX_MODULE=/usr/lib/nginx/modules/ngx_stream_module.so
  NGINX_USER=www-data
fi

if [[ "$operating_system" == "oraclelinux" ]]; then
  NGINX_MODULE=/usr/lib64/nginx/modules/ngx_stream_module.so
  NGINX_USER=nginx
fi

cat << EOD > /root/nginx-header.tpl
load_module $NGINX_MODULE;

user $NGINX_USER;
worker_processes auto;
pid /run/nginx.pid;

EOD

cat << 'EOF' > /root/nginx-footer.tpl
events {
  worker_connections 768;
  # multi_accept on;
}

stream {
  upstream k3s-http {
    {% for private_ip in private_ips -%}
    server {{ private_ip }}:${nginx_ingress_controller_http_nodeport} max_fails=3 fail_timeout=10s;
    {% endfor -%}
  }
  upstream k3s-https {
    {% for private_ip in private_ips -%}
    server {{ private_ip }}:${nginx_ingress_controller_https_nodeport} max_fails=3 fail_timeout=10s;
    {% endfor -%}
  }

  log_format basic '$remote_addr [$time_local] '
    '$protocol $status $bytes_sent $bytes_received '
    '$session_time "$upstream_addr" '
    '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';

  access_log /var/log/nginx/k3s_access.log basic;
  error_log  /var/log/nginx/k3s_error.log;

  proxy_protocol on;

  server {
    listen ${https_lb_port};
    proxy_pass k3s-https;
    proxy_next_upstream on;
  }

  server {
    listen ${http_lb_port};
    proxy_pass k3s-http;
    proxy_next_upstream on;
  }
}
EOF

cat /root/nginx-header.tpl /root/nginx-footer.tpl > /root/nginx.tpl

cat << 'EOF' > /root/render_nginx_config.py
from jinja2 import Template
import os

RAW_IP = open('/tmp/private_ips', 'r').readlines()
IPS = [i.replace('\n','') for i in RAW_IP]

nginx_config_template_path = '/root/nginx.tpl'
nginx_config_path = '/etc/nginx/nginx.conf'

with open(nginx_config_template_path, 'r') as handle:
    nginx_config_template = handle.read()

new_nginx_config = Template(nginx_config_template).render(
    private_ips = IPS
)

with open(nginx_config_path, 'w') as handle:
    handle.write(new_nginx_config)
EOF

chmod +x /root/find_ips.sh
./root/find_ips.sh

python3 /root/render_nginx_config.py

nginx -t

systemctl restart nginx
%{ endif }

%{ if install_longhorn }
if [[ "$operating_system" == "ubuntu" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux
fi

systemctl enable --now iscsid.service
%{ endif }