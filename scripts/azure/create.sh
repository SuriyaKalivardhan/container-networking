#!/bin/bash

location='eastus'
subscription='ea4faa5b-5e44-4236-91f6-5483d5b17d14'
resourcegroup='suriyak-cni'


if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
    echo "Using defaults location:"$location ", subscription:"$subscription ", resourcegroup:"$resourcegroup
else
    location=$1
    subscription=$2
    resourcegroup=$3
fi

az configure -d location=$location subscription=$subscription group=$resourcegroup
az account set --subscription $subscription
if [ $? != 0 ]; then
    exit 1
fi

az group create -n $resourcegroup --tags owner=suriyak@microsoft.com SkipAutoDeleteTill=2024-10-01


set -x
nsgname=$resourcegroup"-nsg"
vnetname=$resourcegroup"-vnet"
subnetname=$resourcegroup"-subnet"
master=$resourcegroup"-master"
node1=$resourcegroup"-node1"
node2=$resourcegroup"-node2"
set +x


az network nsg create -n $nsgname
az network nsg rule create --nsg-name $nsgname -n AllowCorp --priority 4000  --access Allow --protocol Tcp --source-address-prefixes CorpNetPublic --destination-address-prefixes '*' --destination-port-ranges 22 --direction Inbound
az network nsg rule create --nsg-name $nsgname -n kube-apiserver --priority 4001  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 6443 --direction Inbound
az network nsg rule create --nsg-name $nsgname -n kubelet --priority 4002  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 10250 --direction Inbound
az network nsg rule create --nsg-name $nsgname -n kube-scheduler --priority 4003  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 10251 --direction Inbound
az network nsg rule create --nsg-name $nsgname -n kube-controller-manager --priority 4004  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 10252 --direction Inbound
az network nsg rule create --nsg-name $nsgname -n etcd --priority 4005  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges '2379-2380' --direction Inbound
az network nsg rule create --nsg-name $nsgname -n kube-proxy --priority 4006  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges 10256 --direction Inbound
az network nsg rule create --nsg-name $nsgname -n nodeport-service --priority 4007  --access Allow --protocol Tcp --source-address-prefixes '*' --destination-address-prefixes '*' --destination-port-ranges '30000-32767' --direction Inbound
nsgid=$(az network nsg show -n $nsgname --query id -o tsv)

az network vnet create -n $vnetname --address-prefix 10.0.0.0/16 --subnet-name $subnetname --subnet-prefix 10.0.0.0/24 --nsg $nsgid
subnetid=$(az network vnet subnet show --vnet-name $vnetname -n $subnetname --query id -o tsv)

az vm create -n $master  --image Ubuntu2204  --size Standard_DS2_v2 --data-disk-sizes-gb 10 --admin-username suriyak --ssh-key-value ~/.ssh/id_rsa.pub --public-ip-address-dns-name "ip-"$master --nsg "" --subnet $subnetid
az vm create -n $node1   --image Ubuntu2204  --size Standard_DS2_v2 --data-disk-sizes-gb 10 --admin-username suriyak --ssh-key-value ~/.ssh/id_rsa.pub --public-ip-address-dns-name "ip-"$node1  --nsg "" --subnet $subnetid
az vm create -n $node2   --image Ubuntu2204  --size Standard_DS2_v2 --data-disk-sizes-gb 10 --admin-username suriyak --ssh-key-value ~/.ssh/id_rsa.pub --public-ip-address-dns-name "ip-"$node2  --nsg "" --subnet $subnetid