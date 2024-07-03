
![Schermafdruk_2024-07-02_09-42-26](https://github.com/MastaG/mesa-turnip-ppa/assets/15012115/84b6d427-c780-45a2-85bf-cf8b84d6fa56)

This repository takes care of two things:

- Re-building oibaf's graphics-drivers ppa (nightly mesa from git) with extra patches applied.

  The patches are meant for running Ubuntu 24.04 (and 24.10 soon) within a proot environment using Termux on your Android device.

  This should allow for accelated Vulkan and OpenGL (using Zink).

  It will push the patched mesa version to my pesonal ppa: https://launchpad.net/~mastag/+archive/ubuntu/mesa-turnip-kgsl

  Quick steps to get this working, assuming you already have Ubuntu 24.04 with xfce4 setup inside your proot env:

  1. Use this sample script to enter your proot distribution:
     ```
     !/bin/sh

     export XDG_RUNTIME_DIR=${TMPDIR}

     # Kill open X11 processes
     kill -9 $(pgrep -f "termux.x11") 2>/dev/null

     # Enable PulseAudio over Network
     pulseaudio --verbose --start --exit-idle-time=-1 --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1"

     # Prepare termux-x11 session
     termux-x11 :0 -ac -extension MIT-SHM &

     # Wait a bit until termux-x11 gets started.
     sleep 2

     # Login in PRoot Environment.
     proot-distro login ubuntu --shared-tmp --user username
     ```
  2. Once logged into your proot distribution, add the ppa and install the updated drivers:
     ```
     sudo apt update
     sudo apt install software-properties-common
     sudo add-apt-repository ppa:mastag/mesa-turnip-kgsl
     sudo apt update
     sudo apt dist-upgrade
     ```
  2. Add the following variables to ```/etc/environment```:
     ```
     MESA_LOADER_DRIVER_OVERRIDE=zink
     VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json:/usr/share/vulkan/icd.d/freedreno_icd.armv7l.json
     TU_DEBUG=noconform
     MESA_NO_ERROR=1
     ```
  3. Use this script to start xfce4:
     ```
     sudo /etc/init.d/dbus start
     sudo chown -R root:root /tmp/.ICE-unix
     export DISPLAY=:0
     taskset -c 4-7 startxfce4
     ```
  4. Edit your ```~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml``` file and change: ```vblank_mode``` from ```auto``` to ```off```.
  


- Building nightly turnip driver releases for use with Android emulators such as Yuzu, Strato, Flycast etc. (big shoutout to @Weab-chan for doing all the work for me).
  It basicallly builds a vanilla and patched release.

You can find the patches in the: ```turnip-patches``` directory.
However I also occasionally apply open merge requests, see the following arrays for more information:
For the mesa ppa: https://github.com/MastaG/mesa-turnip-ppa/blob/8e2b333e299acf6d68cc10a2e26969e3bbba7e65/build_ppa.sh#L2
For the turnip nightly releases: https://github.com/MastaG/mesa-turnip-ppa/blob/8e2b333e299acf6d68cc10a2e26969e3bbba7e65/turnip_builder.sh#L14

Feel free to contribute by opening a PR :)
