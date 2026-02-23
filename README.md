# Simulação do Drone

## Ardupilot SITL
Para se simular o cérebro do drone será utilizado o simulador SITL que faz parte do ferramental disponibilizado no [código fonte](https://github.com/Falcon-IFSP/ardupilot) do [ArduPilot](https://ardupilot.org/dev/index.html).

Para casos gerais, as informações presentes no [blog da ferramenta](https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html) são suficientes. Aqui serão descritos apenas os procedimentos realizados para operar o simulador em condições não descritas na documentação.

### Setup em Fedora 43+ (RHEL)
A ferramenta disponibiliza tutoriais de instalação oficialmente apenas para [Microsoft Windows (via WSL)](https://ardupilot.org/dev/docs/sitl-on-windows-wsl.html), [Linux Alpine, Arch, MAC, openSUSE, Ubuntu e Docker](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html).
Dessa forma, são necessárias etapas adicionais para instalá-la no Fedora 43+ e nas demais distribuições RHEL. 

 - Uma das possibilidades é utilizar um script de instalação reescrito para essas distribuições - [presente nas branches da Falcon do código fonte](https://github.com/Falcon-IFSP/ardupilot/blob/master/Tools/environment_install/install-prereqs-fedora.sh) - dessa forma basta seguir o passo-a-passo das outras distribuições substituindo o gerenciador de pacotes pelo [`dnf`](https://docs.fedoraproject.org/pt_BR/quick-docs/dnf-vs-apt/) e o script de instalação pelo nosso!
 - A outra é adaptar o setup em Docker para Podman, este é preferível já que assim são evitados diversos problemas de compatibilidade e ambiente virtual:
    - Esta abordagem é mais simples, basta _clonar_ este repositório:
      ```
      git clone https://github.com/Falcon-IFSP/drone-sim.git
      cd drone-sim
      ```
    - Então _buildar_ a imagem do ardupilot-sitl:
      ```
      make build-ardupilot
      ```
    - Agora, você pode executa-la:
      ```
      podman run --rm -it -u "$(id -u):$(id -g)" ardupilot-sitl:latest /ardupilot/Tools/autotest/sim_vehicle.py -v copter -f quad --console
      ```
    - Ou executar o nosso _pod_ em _Kubernetes_:
      > Edite o arquivo `ardupilot-sitl/ardupilot_sitl.yaml` para que a variável de ambiente `XAUTHORITY` seja a mesma no container e no _host_ (obtenha o valor com `echo $XAUTHORITY`).
      ```
      xhost +local:
      podman kube play --replace ardupilot-sitl/ardupilot_sitl.yaml
      ```

Ao fim, o Ardupilot SITL deve abrir um console de erros e um painel de informações do drone.
Para fins de controle externo, as portas seriais do drone são traduzidas para TCP/IP nas portas, 5760, 5762 e 5763 (ex: com Mission Planner, QGroundControl, MAVProxy).

## Gazebo Harmonic
Para se simular o cenário, os sensores e a física do drone será utilizado o [Gazebo Harmonic](https://ardupilot.org/dev/docs/sitl-with-gazebo.html), versão mais atual do simulador Gazebo com suporte oficial pelo time do Ardupilot.
> [!NOTE]
> Diferentemente do Ardupilot SITL, esse simulador realiza cálculos avançados e renderização gráfica 3D em tempo real. Por esse motivo, recomenda-se executá-lo com uma _GPU_ dedicada e com o menor número possível de camadas de virtualização, preferencialmente via _forwarding_.

Para casos gerais, as informações de integração presentes no [blog do Ardupilot](https://ardupilot.org/dev/docs/sitl-with-gazebo.html) são suficientes. Aqui serão descritos apenas os procedimentos realizados para operar o simulador em condições não descritas na documentação.

### Setup em Fedora 43+ (RHEL)
A ferramenta disponibiliza tutoriais de instalação oficialmente apenas para [Microsoft Windows](https://gazebosim.org/docs/harmonic/install_windows/), [macOS](https://gazebosim.org/docs/harmonic/install_osx/) e [Ubuntu](https://gazebosim.org/docs/harmonic/install_ubuntu/).
Dessa forma, são necessárias etapas adicionais para instalá-la no Fedora 43+ e nas demais distribuições RHEL. 
 - Uma das possibilidades é utilizar um script de instalação reescrito para essas distribuições - para este caso, não há ainda uma solução disponível neste repositório.
 - A outra é adaptar a instalação dentro de um container em Podman, essa é mais complexa pois é necessário configurar o _host_ para a passagem da _GPU_ para o contêiner.
    - Então, é necessário instalar os pré-requisitos necessários para sua placa de vídeo:
       - Placas de Vídeo AMD (Veja [1](https://access.redhat.com/solutions/7073764) e [2](https://instinct.docs.amd.com/projects/container-toolkit/en/latest/container-runtime/cdi-guide.html)):
          - Adicione os repositórios fornecidos pela AMD, conforme descrito no [site da AMD](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/quick-start.html):
          ```
          sudo tee /etc/yum.repos.d/amdgpu.repo <<EOF
          [amdgpu]
          name=amdgpu
          baseurl=https://repo.radeon.com/amdgpu/6.1.2/rhel/9.4/main/x86_64/
          enabled=1
          priority=50
          gpgcheck=1
          gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
          EOF
        
          sudo yum clean all
          sudo tee --append /etc/yum.repos.d/rocm.repo <<EOF
          [ROCm-6.1.2]
          name=ROCm6.1.2
          baseurl=https://repo.radeon.com/rocm/rhel9/6.1.2/main
          enabled=1
          priority=50
          gpgcheck=1
          gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
          EOF
        
          sudo yum clean all
          ```
          - Instale o driver e reinicie o sistema:
          ```
          sudo dnf install amdgpu-dkms
          sudo reboot
          ```
            - Instale os pacotes ROCm:
          ```
          sudo yum install rocm
          ```
            - Configure o SELinux para permitir que os contêineres usem os dispositivos do sistema _host_:
          ```
          sudo setsebool -P container_use_devices 1
          ```
            - Instale o AMD Contêiner Toolkit:
          ```
          sudo dnf install amd-container-toolkit
          ```
            - Execute-o para gerar as especificações CDI no _host_:
          ```
          sudo amd-ctk cdi generate
          ```
    - Depois de instalar os pré-requisitos, basta _clonar_ este repositório:
      ```
      git clone https://github.com/Falcon-IFSP/drone-sim.git
      cd drone-sim
      ```
    - Então _buildar_ a imagem do Gazebo:
      ```
      make build-gazebo
      ```
    - Agora, você pode executá-la:
      ```
      podman run --rm -it --device /dev/kfd --device /dev/dri --net=host --security-opt=no-new-privileges --cap-drop=ALL gazebo-harmonic-amd:latest /usr/bin/gz sim -v4 -r shapes.sdf
      ```
    - Ou executar o nosso _pod_ em _Kubernetes_:
      > Edite o arquivo `gazebo-harmonic/amd/gazebo_harmonic.yaml` para que a variável de ambiente `XAUTHORITY` seja a mesma no container e no _host_ (obtenha o valor com `echo $XAUTHORITY`).
      ```
      xhost +local:
      podman kube play --replace gazebo-harmonic/amd/gazebo_harmonic.yaml
      ```


Ao fim, o Gazebo deve abrir a sua janela principal.
Se o interesse for observar stream de vídeo por meio da câmera virtual do Gazebo, é necessário executar o seguinte comando utilizando _bash_, dentro do contêiner:
```
podman exec -ti drone-sim-gazebo-harmonic bash
gz topic -t $(gz topic -l | grep -i "streaming") -m gz.msgs.Boolean -p "data: 1"
```
