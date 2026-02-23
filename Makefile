.PHONY: build build-gazebo build-ardupilot help

export USER_UID=$(shell id -u)
export USER_GID=$(shell id -g)
export SKIP_AP_GRAPHIC_ENV=0

help:
	@echo "Available targets:"
	@echo "  make build           - Builda todos os contêineres"
	@echo "  make build-gazebo    - Builda o contêiner do Gazebo Harmonic para GPUs AMD"
	@echo "  make build-ardupilot - Builda o contêiner do ArduPilot SITL"

build: build-gazebo build-ardupilot
	@echo "Todos os contêineres foram gerados com sucesso!"

build-gazebo:
	podman build -t localhost/gazebo-harmonic-amd:latest gazebo-harmonic/amd/

build-ardupilot:
	if [ ! -d "ardupilot-sitl/src" ]; then git clone --recurse-submodules https://github.com/Falcon-IFSP/ardupilot.git ardupilot-sitl/src; fi
	cd ardupilot-sitl/src
	podman build ardupilot-sitl/src -t ardupilot --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg SKIP_AP_GRAPHIC_ENV=${SKIP_AP_GRAPHIC_ENV}
	cd ../../
	podman build -t localhost/ardupilot-sitl:latest ardupilot-sitl/