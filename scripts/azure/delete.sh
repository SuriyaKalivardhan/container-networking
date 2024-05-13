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

az group delete -n $resourcegroup -y