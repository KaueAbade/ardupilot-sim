# Simulação do Drone
## Ardupilot SITL
Para se simular o cérebro do drone será utilizado o simulador SITL que faz parte do ferramental disponibilizado no [código fonte](https://github.com/Falcon-IFSP/ardupilot) do [ArduPilot](https://ardupilot.org/dev/index.html).

Para casos gerais, as informações presentes no [blog da ferramenta](https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html) são suficientes. Aqui serão descritos apenas os procedimentos realizados para operar o simulador em condições não descritas na documentação.

### Setup em Fedora 43+ (RHEL)
Infelizmente a ferramenta utilizada apresenta tutorias de instalação apenas para [Microsoft Windows (via WSL)](https://ardupilot.org/dev/docs/sitl-on-windows-wsl.html), [Linux Alpine, Arch, MAC, openSUSE, Ubuntu e Docker](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html).
Dessa forma, é necessário fazer algumas coisas mais para a instalar no Fedora 43+ e, acredito eu, nas demais distribuições RHEL. 

 - Uma das possibilidades é utilizar um script de instalação reescrito para essas distribuições - [presente nas branches da Falcon do código fonte](https://github.com/Falcon-IFSP/ardupilot/blob/falcon-master/Tools/environment_install/install-prereqs-fedora.sh) - dessa forma basta seguir o passo-a-passo das outras distribuições substituindo o gerenciador de pacotes pelo [`dnf`](https://docs.fedoraproject.org/pt_BR/quick-docs/dnf-vs-apt/) e o script de instalação pelo nosso!
 - A outra é adaptar o setup em Docker para Podman, este é preferivel já que assim são evitados diversos problemas de compatibilidade e ambiente virtual:
    - Esse setup também é bem mais simples, basta _clonar_ o nosso *clone* (😆) do Ardupilot:
      ```
      git clone --recurse-submodules https://github.com/Falcon-IFSP/ardupilot.git
      cd ardupilot
      ```
    - Então _buildar_ a imager docker:
       - Com interface gráfica: ```podman build . -t ardupilot --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) --build-arg SKIP_AP_GRAPHIC_ENV=0```
       - Ou sem: ```podman build . -t ardupilot --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)```
    - Depois, você pode executa-la:
      ```
      podman run --rm -it -v "$(pwd):/ardupilot" -u "$(id -u):$(id -g)" ardupilot:latest /ardupilot/Tools/autotest/sim_vehicle.py -v copter -f quad --console
      ```
    - Ou executar o nosso _pod_ em _kubernete_ (bem mais legal):
      ```
      git clone https://github.com/Falcon-IFSP/drone-sim.git
      cd drone-sim
      podman kube play --replace ardupilot.yaml
      ```

## Gazebo Harmonic
Lorem Ipsum
