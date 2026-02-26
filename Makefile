.PHONY: build build-gazebo build-ardupilot run run-gazebo run-ardupilot stop help

export PWD=$(CURDIR)
export USER_UID=$(shell id -u)
export USER_GID=$(shell id -g)
export SKIP_AP_GRAPHIC_ENV=0

help:
	@echo "Available targets:"
	@echo "  make build           - Builda todos os contêineres"
	@echo "  make build-gazebo    - Builda o contêiner do Gazebo Harmonic para GPUs AMD"
	@echo "  make build-ardupilot - Builda o contêiner do ArduPilot SITL"
	@echo "  make run             - Inicia a simulação completa (Gazebo + ArduPilot)"
	@echo "  make run-gazebo      - Inicia apenas o Gazebo"
	@echo "  make run-ardupilot   - Inicia apenas o ArduPilot SITL"
	@echo "  make stop            - Para todos os pods da simulação"

build: build-gazebo build-ardupilot
	@echo "Todos os contêineres foram gerados com sucesso!"

build-gazebo:
	podman build -t localhost/gazebo-harmonic-amd:latest gazebo-harmonic/amd/

build-ardupilot:
	if [ ! -d "ardupilot-sitl/src/.github" ]; then \
		git clone --recurse-submodules https://github.com/Falcon-IFSP/ardupilot.git ardupilot-sitl/src; \
	else \
		git -C ardupilot-sitl/src pull --rebase; \
	fi
	podman build ardupilot-sitl/src -t ardupilot --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg SKIP_AP_GRAPHIC_ENV=${SKIP_AP_GRAPHIC_ENV}
	podman build -t localhost/ardupilot-sitl:latest ardupilot-sitl/

run:
	@echo "Usando USER_UID=${USER_UID}, XAUTHORITY=$(XAUTHORITY) e PWD=$(PWD)"
	xhost +local:
	USER_UID=${USER_UID} XAUTHORITY="$(XAUTHORITY)" PWD="$(PWD)" envsubst < drone_sim.yaml | podman kube play --replace -

run-gazebo:
	@echo "Usando USER_UID=${USER_UID}, XAUTHORITY=$(XAUTHORITY) e PWD=$(PWD)"
	xhost +local:
	USER_UID=${USER_UID} XAUTHORITY="$(XAUTHORITY)" PWD="$(PWD)" envsubst < gazebo-harmonic/amd/gazebo_harmonic.yaml | podman kube play --replace -

run-ardupilot:
	@echo "Usando USER_UID=${USER_UID}, XAUTHORITY=$(XAUTHORITY) e PWD=$(PWD)"
	xhost +local:
	USER_UID=${USER_UID} XAUTHORITY="$(XAUTHORITY)" PWD="$(PWD)" envsubst < ardupilot-sitl/ardupilot_sitl.yaml | podman kube play --replace -

stop:
	-podman kube down drone_sim.yaml
	-podman kube down gazebo-harmonic/amd/gazebo_harmonic.yaml
	-podman kube down ardupilot-sitl/ardupilot_sitl.yaml