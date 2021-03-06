#!/usr/bin/env bash

# Abort if any of the following commands fails or variables are undefined
set -eu

# default DOCKER_REGISTRY to the docker bind address and port if using docker driver
if [ "$(minikube config get driver)" = "docker" ]; then
  DOCKER_REGISTRY="${DOCKER_REGISTRY:-$(docker port minikube 5000)}"
else
  # otherwise default to the minikube IP and port 5000
  DOCKER_REGISTRY="${DOCKER_REGISTRY:-"$(minikube ip):5000"}"
fi

ILLUMINATIO_IMAGE="${DOCKER_REGISTRY}/illuminatio-runner:dev"

docker build -t "${ILLUMINATIO_IMAGE}" .

# Use minikube docker daemon to push to the insecure registry

docker push "${ILLUMINATIO_IMAGE}"

if [[ -n "${CI:-}" ]];
then
  echo "Prepull: ${ILLUMINATIO_IMAGE} to ensure image is available"
  sudo docker pull "${ILLUMINATIO_IMAGE}"
fi

if ! coverage run setup.py test --addopts="-m e2e";
then
  kubectl -n illuminatio get po -o yaml
fi
