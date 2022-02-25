#!/bin/bash

# Disable firewall 
/usr/sbin/netfilter-persistent stop
/usr/sbin/netfilter-persistent flush

systemctl stop netfilter-persistent.service
systemctl disable netfilter-persistent.service

# END Disable firewall

apt-get update
apt-get install -y software-properties-common jq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  python3 python3-pip
pip install oci-cli

local_ip=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/vnics/ | jq -r '.[0].privateIp')
flannel_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')

export OCI_CLI_AUTH=instance_principal
first_instance=$(oci compute instance list --compartment-id ${compartment_ocid} --availability-domain ${availability_domain} --lifecycle-state RUNNING --sort-by TIMECREATED  | jq -r '.data[]|select(."display-name" | endswith("k3s-servers")) | .["display-name"]' | tail -n 1)
instance_id=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance | jq -r '.displayName')
first_last="last"

%{ if install_nginx_ingress } 
disable_traefik="--disable traefik"
%{ endif }

if [[ "$first_instance" == "$instance_id" ]]; then
    echo "I'm the first yeeee: Cluster init!"
    first_last="first"
    until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --cluster-init $disable_traefik --node-ip $local_ip --advertise-address $local_ip --flannel-iface $flannel_iface --tls-san ${k3s_tls_san}); do
        echo 'k3s did not install correctly'
        sleep 2
    done
else
    echo ":( Cluster join"
    until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --server https://${k3s_url}:6443 $disable_traefik --node-ip $local_ip --advertise-address $local_ip --flannel-iface $flannel_iface --tls-san ${k3s_tls_san}); do
        echo 'k3s did not install correctly'
        sleep 2
    done
fi

%{ if is_k3s_server }
until kubectl get pods -A | grep 'Running'; do
    echo 'Waiting for k3s startup'
    sleep 5
done

%{ if install_longhorn }
if [[ "$first_last" == "first" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux
    systemctl enable iscsid.service
    systemctl start iscsid.service
    kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/deploy/longhorn.yaml
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/examples/storageclass.yaml
fi
%{ endif }

%{ if install_nginx_ingress }
if [[ "$first_last" == "first" ]]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
    kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/nginx-ingress-config/all-resources.yml
fi

%{ endif }

%{ endif }