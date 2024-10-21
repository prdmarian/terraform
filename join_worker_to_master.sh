#!/bin/bash

# Join the worker node to the Kubernetes cluster using the join command saved by the master
if [ -f /vagrant/join_command.sh ]; then
  sudo bash /vagrant/join_command.sh
else
  echo "Error: join_command.sh not found. Ensure the master node has generated the join command."
  exit 1
fi
