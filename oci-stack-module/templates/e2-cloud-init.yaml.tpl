#cloud-config

package_update: true
package_upgrade: true

packages:
  - tmux
  - rsync
  - git
  - curl
  - gettext
  - device-mapper-persistent-data
  - lvm2
  - bzip2

groups:
  - docker
system_info:
  default_user:
    groups: [docker]

runcmd:
  - dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  - dnf update -y
  - dnf install docker-ce docker-ce-cli containerd.io -y
  - dnf install -y docker-compose-plugin
  - docker compose --version
  - systemctl enable docker
  - systemctl start docker
  - docker info
  - echo 'OCI Ampere E2 OracleLinux 9.2' >> /etc/motd
