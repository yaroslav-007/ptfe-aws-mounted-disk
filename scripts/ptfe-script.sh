#!/bin/bash

###Check if jq is installed
which jq  ||  (apt-get update; apt-get install jq -y)



###Check if folders exist

[ -d /var/lib/docker ]] || mkdir -p /var/lib/docker
[ -d /ptfe]] || mkdir -p /ptfe
[ -d /var/lib/replicated/snapshots ] || mkdir -p /var/lib/replicated/snapshots

### ptfe disk
until lsblk /dev/xvdi ; do
  sleep 1
done

blkid /dev/xvdi
RESULT=$?

if [ $RESULT -ne 0 ]; then
  mkfs.ext4 /dev/xvdi
  tune2fs -L Docker /dev/xvdi
fi

grep xvdi /etc/fstab  
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "/dev/xvdi /ptfe ext4 defaults 0 0" >> /etc/fstab
fi

#### docker disk
until lsblk /dev/xvdh ; do
  sleep 1
done
blkid /dev/xvdh
RESULT=$?

if [ $RESULT -ne 0 ]; then
  mkfs.ext4 /dev/xvdh
  tune2fs -L PTFE /dev/xvdh
fi

grep xvdh /etc/fstab
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "/dev/xvdh /var/lib/docker ext4 defaults 0 0" >> /etc/fstab
fi 



#### snapshots disk
until lsblk /dev/xvdj ; do
  sleep 1
done
blkid /dev/xvdj
RESULT=$?

if [ $RESULT -ne 0 ]; then
  mkfs.ext4 /dev/xvdj
  tune2fs -L PTFE /dev/xvdj
fi

grep xvdj /etc/fstab
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "/dev/xvdj /var/lib/replicated/snapshots ext4 defaults 0 0" >> /etc/fstab
fi 

###Mount all disks
mount -a


sleep 100
####Install PTFE via replicated

set -e -u -o pipefail
set -x
set fileformat=unix
path=/var/lib/replicated/snapshots/

###Installing replicated


FILE=/var/lib/replicated/snapshots/files/db.dump
if [ -f "$FILE" ]; then
  [ -f /etc/replicated.conf ] || cp /home/ubuntu/ptfe-ec2/replicated.conf /etc/replicated.conf
  curl -o install.sh https://install.terraform.io/ptfe/stable
  bash ./install.sh \
    no-proxy \
    private-address=10.0.1.161 \
    public-address=10.0.1.161

  sleep 100
  replicatedctl snapshot ls --store local --path /var/lib/replicated/snapshots -o json > /tmp/snapshots.json
  id=$(jq -r 'sort_by(.finished) | .[-1].id // ""' /tmp/snapshots.json)

  echo "Restoring snapshot: $id"
  replicatedctl snapshot restore --store local --path /var/lib/replicated/snapshots --dismiss-preflight-checks "$id"
  sleep 5
  service replicated restart
  service replicated-ui restart
  service replicated-operator restart

  sleep 40
###Start PTFE service
  replicated app $(replicated apps list | grep "Terraform Enterprise" | awk {'print $1'}) start
else 
    [ -f /etc/replicated.conf ] || cp /home/ubuntu/ptfe-ec2/replicated.conf /etc/replicated.conf
    curl -o install.sh https://install.terraform.io/ptfe/stable
    bash ./install.sh \
        no-proxy \
        private-address=10.0.1.161 \
        public-address=10.0.1.161
fi
