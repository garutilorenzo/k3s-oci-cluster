#!/bin/bash

check_os() {
  name=$(cat /etc/os-release | grep ^NAME= | sed 's/"//g')
  clean_name=$${name#*=}

  version=$(cat /etc/os-release | grep ^VERSION_ID= | sed 's/"//g')
  clean_version=$${version#*=}
  major=$${clean_version%.*}
  minor=$${clean_version#*.}
  
  if [[ "$clean_name" == "Ubuntu" ]]; then
    operating_system="ubuntu"
  elif [[ "$clean_name" == "Oracle Linux Server" ]]; then
    operating_system="oraclelinux"
  else
    operating_system="undef"
  fi

  echo "K3S install process running on: "
  echo "OS: $operating_system"
  echo "OS Major Release: $major"
  echo "OS Minor Release: $minor"
}

install_oci_cli_ubuntu(){
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python3 python3-pip nginx
  systemctl enable nginx
  pip install oci-cli
}

install_oci_cli_oracle(){
  if [[ $major -eq 9 ]]; then
    dnf -y install oraclelinux-developer-release-el9
    dnf -y install python39-oci-cli python3-jinja2 nginx-all-modules
  else
    dnf -y install oraclelinux-developer-release-el8
    dnf -y module enable nginx:1.20 python36:3.6
    dnf -y install python36-oci-cli python3-jinja2 nginx-all-modules
  fi
}

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

check_os

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
  install_oci_cli_ubuntu
  %{ endif }

  %{ if ! disable_ingress }
  install_oci_cli_ubuntu
  %{ endif }
  
  # Fix /var/log/journal dir size
  echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
  echo "SystemMaxFileSize=100M" >> /etc/systemd/journald.conf
  systemctl restart systemd-journald
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
  install_oci_cli_oracle
  %{ endif }

  %{ if ! disable_ingress }
  install_oci_cli_oracle
  %{ endif }

  # Nginx Selinux Fix
  setsebool httpd_can_network_connect on -P
fi

k3s_install_params=()

%{ if k3s_subnet != "default_route_table" } 
local_ip=$(ip -4 route ls ${k3s_subnet} | grep -Po '(?<=src )(\S+)')
flannel_iface=$(ip -4 route ls ${k3s_subnet} | grep -Po '(?<=dev )(\S+)')

k3s_install_params+=("--node-ip $local_ip")
k3s_install_params+=("--flannel-iface $flannel_iface")
%{ endif }

if [[ "$operating_system" == "oraclelinux" ]]; then
  k3s_install_params+=("--selinux")
fi

INSTALL_PARAMS="$${k3s_install_params[*]}"

%{ if k3s_version == "latest" }
K3S_VERSION=$(curl --silent https://api.github.com/repos/k3s-io/k3s/releases/latest | jq -r '.name')
%{ else }
K3S_VERSION="${k3s_version}"
%{ endif }

wait_lb

until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=${k3s_token} K3S_URL=https://${k3s_url}:6443 sh -s - $INSTALL_PARAMS); do
  echo 'k3s did not install correctly'
  sleep 2
done

proxy_protocol_stuff(){
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
    server {{ private_ip }}:${ingress_controller_http_nodeport} max_fails=3 fail_timeout=10s;
    {% endfor -%}
  }
  upstream k3s-https {
    {% for private_ip in private_ips -%}
    server {{ private_ip }}:${ingress_controller_https_nodeport} max_fails=3 fail_timeout=10s;
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
}

%{ if install_nginx_ingress }
proxy_protocol_stuff
%{ endif }

%{ if ! disable_ingress }
proxy_protocol_stuff
%{ endif }

%{ if install_longhorn }
if [[ "$operating_system" == "ubuntu" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux
fi

systemctl enable --now iscsid.service
%{ endif }