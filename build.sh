#!/bin/bash
export DEBEMAIL="${EMAIL}"
export DEBFULLNAME="MastaG"
sudo apt update
# Disable system-upgrade for the github runner
# sudo apt -y upgrade
# sudo apt -y dist-upgrade
sudo apt install -y devscripts dpkg-dev build-essential fakeroot dput-ng git software-properties-common
echo "${PUBKEY}" | base64 --decode | gpg --batch --import
echo "${PRIVKEY}" | base64 --decode | gpg --batch --import
git config --global user.email "${EMAIL}"
git config --global user.name "MastaG"
sudo add-apt-repository -y ppa:oibaf/graphics-drivers
sudo add-apt-repository -y ppa:mastag/mesa-turnip-kgsl
sudo sed -i 's/^Types: deb$/Types: deb deb-src/g' /etc/apt/sources.list.d/oibaf-*.sources
sudo apt update
build=()
for i in {libdrm,mesa}
do
	if [ "${i}" == "mesa" ]
	then
		package="mesa-vulkan-drivers"
	elif [ "${i}" == "libdrm" ]
	then
		package="libdrm2"
	fi
	remotever="$(apt-cache policy ${package} | grep -B1 "oibaf/graphics-drivers/ubuntu" | head -1 | sed -En 's/.* (.*git.*) .*/\1/p')"
	ourver="$(apt-cache policy ${package} | grep -B1 "mastag/mesa-turnip-kgsl/ubuntu" | head -1 | sed -En 's/.* (.*git.*) .*/\1/p' | sed 's/-turnip-kgsl//g')"
	if [ "${ourver}" == "${remotever}" ]
	then
		echo "${i} version in our PPA: ${ourver}"
		echo "up-to-date with Obiaf's PPA :)"
		echo "doing nothing..."
		continue
	else
		echo "${i} version in our PPA: ${ourver}"
		echo "${i} version in Obiaf's PPA: ${remotever}"
		echo "building new version with turnip patches..."
		build+=("${i}")
	fi
done
sudo rm -f /etc/apt/sources.list.d/mastag-ubuntu-*
sudo apt update
for i in "${build[@]}"
	sudo apt build-dep -y ${i}
	rm -Rf ${i}*
	apt source ${i}
	rm -f ${i}*.dsc
	version="$(ls -d ${i}-* | sed "s/^${i}-//g")"
	newversion="$(echo "${version}" | sed 's/oibaf/oibaf-turnip-kgsl/g')"
	find ./ -maxdepth 1 | grep "${version}" | while read line
	do
		newfile="$(echo ${line} | sed "s/${version}/${newversion}/g")"
		mv -v "${line}" "${newfile}"
	done
	cd "${i}-${newversion}"
	if [ "${i}" == "mesa" ]
	then
		dch --newversion "${newversion}" "Rebuild mesa-turnip-kgsl with the following patches:"
		dch -r -u high "Rebuild mesa-turnip-kgsl with the following patches:"
		cd debian/patches
		ls ../../../turnip-patches/*.patch | while read line
		do
			patch="$(ls ${line} | sed 's:.*/::')"
			dch -a ${patch}
			echo "Adding: ${patch}"
			echo "${patch}" >> series
			cp -f "${line}" .
		done
		cd ../..
		# Enable kgsl
		sed -i 's/GALLIUM_DRIVERS += freedreno$/GALLIUM_DRIVERS += freedreno\n\tconfflags_GALLIUM += -Dfreedreno-kmds=msm,kgsl/g' debian/rules
	else
		dch --newversion "${newversion}" "Rebuild mesa-turnip-kgsl"
		dch -r -u high "Rebuild mesa-turnip-kgsl"
	fi
	debuild -S -sa -k${EMAIL}
	cd ..
done
if ls *.changes 1> /dev/null 2>&1
then
	dput --force ppa:mastag/mesa-turnip-kgsl *.changes
fi
