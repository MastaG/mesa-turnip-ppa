#!/bin/bash
apt update
apt install -y sudo git
useradd -m -U -s /bin/bash build
echo 'build ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/build_user
su -c 'cd $HOME; git clone https://github.com/MastaG/mesa-turnip-ppa.git; cd mesa-turnip-ppa; ./build_ppa.sh' build
