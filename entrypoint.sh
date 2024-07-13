#!/bin/bash
apt update
apt install -y sudo git
useradd -m -U -s /bin/bash build
mkdir -p /etc/apt/apt.conf.d
echo 'APT::Key::Assert-Pubkey-Algo ">=rsa1024";' > /etc/apt/apt.conf.d/99weakkey-warning
echo 'build ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/build_user
su -c 'cd $HOME; git clone https://github.com/MastaG/mesa-turnip-ppa.git; cd mesa-turnip-ppa; ./build_ppa.sh' build
