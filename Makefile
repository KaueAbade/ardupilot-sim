.PHONY: build build-gazebo build-ardupilot run run-gazebo run-ardupilot stop clean help

export PWD=$(CURDIR)
export USER_UID=$(shell id -u)
export USER_GID=$(shell id -g)
export SKIP_AP_GRAPHIC_ENV=0

help:
	@echo "Available targets:"
	@echo "  make build           - Builda todos os contêineres"
	@echo "  make build-gazebo    - Builda o contêiner do Gazebo Harmonic com plugins do ArduPilot"
	@echo "  make build-ardupilot - Builda o contêiner do ArduPilot SITL"
	@echo "  make run             - Inicia a simulação completa (Gazebo + ArduPilot)"
	@echo "  make run-gazebo      - Inicia apenas o Gazebo"
	@echo "  make run-ardupilot   - Inicia apenas o ArduPilot SITL"
	@echo "  make stop            - Para todos os pods da simulação"
	@echo "  make clean           - Remove as imagens geradas"

build: build-gazebo build-ardupilot
	@echo "Todos os contêineres foram gerados com sucesso!"

build-gazebo:
	podman build -t ghcr.io/falcon-ifsp/drone-sim/gazebo-harmonic-ardupilot:latest gazebo-harmonic

build-ardupilot:
	podman build ardupilot-sitl/src -t ghcr.io/falcon-ifsp/drone-sim/ardupilot:latest --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg SKIP_AP_GRAPHIC_ENV=${SKIP_AP_GRAPHIC_ENV}
	podman build -t ghcr.io/falcon-ifsp/drone-sim/ardupilot-sitl:latest ardupilot-sitl/

run:
	@echo "Usando USER_UID=${USER_UID}, XAUTHORITY=$(XAUTHORITY) e PWD=$(PWD)"
	xhost +local:
	USER_UID=${USER_UID} XAUTHORITY="$(XAUTHORITY)" PWD="$(PWD)" envsubst < drone_sim.yaml | podman kube play --replace -
	podman exec drone-sim-gazebo-harmonic bash -c \
      'until gz topic -l 2>/dev/null | grep -qi streaming; do sleep 1; done; \
       gz topic -t $$(gz topic -l | grep -i "streaming") -m gz.msgs.Boolean -p "data: 1"'

run-gazebo:
	@echo "Usando USER_UID=${USER_UID}, XAUTHORITY=$(XAUTHORITY) e PWD=$(PWD)"
	xhost +local:
	USER_UID=${USER_UID} XAUTHORITY="$(XAUTHORITY)" PWD="$(PWD)" envsubst < gazebo-harmonic/gazebo_harmonic.yaml | podman kube play --replace -
	podman exec gazebo-harmonic-main bash -c \
      'until gz topic -l 2>/dev/null | grep -qi streaming; do sleep 1; done; \
       gz topic -t $$(gz topic -l | grep -i "streaming") -m gz.msgs.Boolean -p "data: 1"'

run-ardupilot:
	@echo "Usando USER_UID=${USER_UID}, XAUTHORITY=$(XAUTHORITY) e PWD=$(PWD)"
	xhost +local:
	USER_UID=${USER_UID} XAUTHORITY="$(XAUTHORITY)" PWD="$(PWD)" envsubst < ardupilot-sitl/ardupilot_sitl.yaml | podman kube play --replace -

stop:
	-podman kube down drone_sim.yaml
	-podman kube down gazebo-harmonic/gazebo_harmonic.yaml
	-podman kube down ardupilot-sitl/ardupilot_sitl.
	
clean:
	-podman rmi ghcr.io/falcon-ifsp/drone-sim/gazebo-harmonic-ardupilot:latest
	-podman rmi ghcr.io/falcon-ifsp/drone-sim/ardupilot:latest
	-podman rmi ghcr.io/falcon-ifsp/drone-sim/ardupilot-sitl:latest