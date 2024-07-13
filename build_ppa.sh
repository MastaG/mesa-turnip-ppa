#!/bin/bash
patches=(
	"fix-for-anon-file;../../../turnip-patches/fix-for-anon-file.patch;"
	"fix-for-getprogname;../../../turnip-patches/fix-for-getprogname.patch;"
	"dri3;../../../turnip-patches/dri3.patch;"
	"zink_fixes;../../../turnip-patches/zink_fixes.patch;"
	#"descr-prefetching-optimization-a7xx;merge_requests/29873;"
	#"make-gmem-work-with-preemption;merge_requests/29871;"
	#"VK_EXT_fragment_density_map;merge_requests/29938;"
)
export DEBEMAIL="${EMAIL}"
export DEBFULLNAME="MastaG"
install_dev() {
	if [ ! -e .devready ]
	then
		echo 'install dev packages...'
		sudo apt install -y devscripts dpkg-dev build-essential fakeroot dput-ng curl
		echo 'done' > .devready
	else
		echo 'dev packages already installed'
	fi
}
sudo apt update
sudo apt install -y software-properties-common git
echo "${PUBKEY}" | base64 --decode | gpg --batch --import
echo "${PRIVKEY}" | base64 --decode | gpg --batch --import
git config --global user.email "${EMAIL}"
git config --global user.name "MastaG"
sudo add-apt-repository -n -y ppa:oibaf/graphics-drivers
sudo add-apt-repository -n -y ppa:mastag/mesa-turnip-kgsl
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
do
	install_dev
	sudo apt build-dep -y ${i}
	rm -Rf ${i}*
	apt-get source ${i}
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
		for patch in ${patches[@]}
		do
			echo "Applying patch ${patch}"
			patch_source="$(echo ${patch} | cut -d ";" -f 2 | xargs)"
			patch_name="$(echo ${patch} | cut -d ";" -f 1 | xargs)"
			dch -a "${patch_name} - ${patch_source}"
			if [[ ${patch_source} == *"../../.."* ]]
			then
				apply="$(echo ${patch_source} | sed 's:.*/::')"
				cp -f ${patch_source} .
				echo "${apply}" >> series
			else
				patch_file="${patch_source#*\/}"
				patch_args=$(echo ${patch} | cut -d ";" -f 3 | xargs)
				curl --output "${patch_file}".patch -k --retry-delay 30 --retry 5 -f --retry-all-errors https://gitlab.freedesktop.org/mesa/mesa/-/"${patch_source}".patch
				sleep 1
				echo "${patch_file}".patch >> series
			fi
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
	echo "Push to launchpad"
	dput --force ppa:mastag/mesa-turnip-kgsl *.changes
fi
