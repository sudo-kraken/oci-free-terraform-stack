#cloud-config

package_update: true
package_upgrade: true

packages:
  - ansible
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
  - grubby --update-kernel ALL
  - dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  - dnf update -y
  - dnf install epel-release -y
  - dnf install docker-ce docker-ce-cli containerd.io -y
  - dnf install -y docker-compose-plugin
  - docker compose --version
  - systemctl enable docker
  - systemctl start docker
  - docker info
  - echo 'OCI Ampere A1 OracleLinux 9.2' >> /etc/motd
  # Mount additional drive
  - |
    if [ ! -e "/dev/oracleoci/oraclevdb1" ]; then
      echo "n1" | sfdisk /dev/oracleoci/oraclevdb
      mkfs.ext4 /dev/oracleoci/oraclevdb1
      mkdir -p /mnt/data
      mount /dev/oracleoci/oraclevdb1 /mnt/data
      echo '/dev/oracleoci/oraclevdb1 /mnt/data ext4 defaults,nofail 0 2' >> /etc/fstab
    fi
