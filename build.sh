#!/bin/bash

echo
echo "--------------------------------------"
echo "          AOSP 14.0 Buildbot          "
echo "                  by                  "
echo "             tablet_seeker            "
echo "--------------------------------------"
echo


set -e

BL=$PWD/treble_build_aosp
BD=$HOME/builds

buildEnvDebian() {

sudo apt-get update && sudo apt-get install -y git-core gnupg flex bison \
build-essential zip curl zlib1g-dev libc6-dev-i386 libncurses5 x11proto-core-dev \
libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3 \
clang repo git android-sdk-platform-tools-common openjdk-17-jdk

git config --global user.email "anon@ymous.com"
git config --global user.name "johndoe"

JAVA_DIR=$(ls /usr/lib/jvm | grep -Em1 java-[0-9]{2}-openjdk)
export SKIP_ABI_CHECKS=true
export JAVA_HOME=/usr/lib/jvm/$JAVA_DIR
}

buildEnvArch() {

sudo pacman -Syyu --noconfirm
sudo pacman -S ttf-dejavu repo git base-devel jdk17-openjdk android-tools --noconfirm
mkdir -p $PWD/packages
cd $PWD/packages

git clone https://aur.archlinux.org/aosp-devel.git
git clone https://aur.archlinux.org/lineageos-devel.git
git clone https://aur.archlinux.org/xml2.git
git clone https://aur.archlinux.org/android-sdk-cmdline-tools-latest.git
git clone https://aur.archlinux.org/android-sdk-build-tools.git
git clone https://aur.archlinux.org/android-sdk-platform-tools.git
git clone https://aur.archlinux.org/android-sdk.git
git clone https://aur.archlinux.org/android-platform.git
git clone https://aur.archlinux.org/ncurses5-compat-libs.git
git clone https://aur.archlinux.org/lib32-ncurses5-compat-libs.git
git clone https://aur.archlinux.org/android-support-repository.git
git clone https://aur.archlinux.org/marvin_dsc.git

for i in $(ls -tr | column -t) ; do

	(cd "$i" && makepkg -s -i -c --noconfirm; cd ..)

done

	cd ..
	git config --global user.email "anon@ymous.com"
	git config --global user.name "johndoe"

	sudo groupadd android-sdk
	sudo gpasswd -a liveuser android-sdk
	sudo setfacl -R -m g:android-sdk:rwx /opt/android-sdk
	sudo setfacl -d -m g:android-sdk:rwX /opt/android-sdk
	newgrp android-sdk

	JAVA_DIR=$(ls /usr/lib/jvm | grep -Em1 java-[0-9]{2}-openjdk)
	export SKIP_ABI_CHECKS=true
	export JAVA_HOME=/usr/lib/jvm/$JAVA_DIR
}

initRepos() {
    if [ ! -d .repo ]; then
        echo "--> Initializing workspace"
        repo init --depth=1 -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r11
        echo

        echo "--> Preparing local manifest"
        mkdir -p .repo/local_manifests
        cp $BL/manifest.xml .repo/local_manifests/aosp.xml
        echo
    fi
}

syncRepos() {
    echo "--> Syncing repos"
    repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
    echo
}

applyPatches() {
    echo "--> Applying TrebleDroid patches"
    bash $BL/apply-patches.sh $BL trebledroid
    echo

    echo "--> Applying personal patches"
    bash $BL/apply-patches.sh $BL personal
    echo

    echo "--> Generating makefiles"
    cd device/phh/treble
    cp $BL/aosp.mk .
    bash generate.sh aosp
    cd ../../..
    echo
}

configPatches() {
	#xml_location
	config_xml="$PWD/frameworks/base/core/res/res/values/config.xml"
	defaults_xml="$PWD/frameworks/base/packages/SettingsProvider/res/values/defaults.xml"
	#spacing
	space=$(printf "%*s%s" 4)
	#array_additions | string="<location>:<grep>:$space<replace>:<location>:<grep>:$space<replace>....."
	string=""
	#navigation_bar
	array[0]="$config_xml"
	array[1]="config_navBarInteractionMode"
	array[2]="$space""<integer name=\"config_navBarInteractionMode\">2</integer>"
	#notification_sound
	array[3]="$config_xml"
	array[4]="config_audio_notif_vol_default"
	array[5]="$space""<integer name=\"config_audio_notif_vol_default\">0</integer>"
	#haptic_feedback
	array[6]="$config_xml"
	array[7]="config_defaultHapticFeedbackIntensity"
	array[8]="$space""<integer name=\"config_defaultHapticFeedbackIntensity\">0</integer>"
	#ring_volume
	array[9]="$config_xml"
	array[10]="config_audio_ring_vol_default"
	array[11]="$space""<integer name=\"config_audio_ring_vol_default\">0</integer>"
	#haptic_feedback2
	array[12]="$defaults_xml"
	array[13]="def_haptic_feedback"
	array[14]="$space""<bool name=\"def_haptic_feedback\">false</bool>"
	#bluetooth_disabled
	array[15]="$defaults_xml"
	array[16]="def_bluetooth_on"
	array[17]="$space""<bool name=\"def_bluetooth_on\">false</bool>"
	#touch_sounds
	array[18]="$defaults_xml"
	array[19]="def_sound_effects_enabled"
	array[20]="$space""<bool name=\"def_sound_effects_enabled\">false</bool>"
	#ring_default
	array[21]="$defaults_xml"
	array[22]="def_notifications_use_ring_volume"
	array[23]="$space""<bool name=\"def_notifications_use_ring_volume\">false</bool>"
	#insert_string->array
	count="${#array[@]}"
	IFS=":"
	read -ra ADDR<<<"$string"

	if [[ ! -z "$string" ]]; then

		for i in "${ADDR[@]}"; do 

			array[$count]="$i"
			((count++))
			 
		done
	fi

	for ((x=0;x<$(echo "${#array[@]}/3" | bc);x++)); do

		if [ "$x" -eq "0" ]; then
		
			dest="${array[0]}"
			grep="${array[1]}"
			replace="${array[2]}"
		else
		
			dest="${array[x*3]}"
			grep="${array[x*3+1]}"
			replace="${array[x*3+2]}"
		fi
			
		line_nr=$(cat "$dest" | grep -n "$grep" | cut -d ":" -f1)
		[ ! -z "$line_nr" ] && sed -i "$line_nr s|^.*$|$replace|" "$dest" || echo -e "\n grep failed on config_patch: $grep"
	done
		
	#battery_percentage
	init_core="$space""<\!-- Default value set for battery percentage in status bar false = disabled, true = enabled -->\n$space<bool name=\"config_defaultBatteryPercentageSetting\">true</bool>"
	grep_check=$(cat "$config_xml" | grep -o "config_defaultBatteryPercentageSetting" || true)
	init_line=$(cat "$config_xml" | grep -n "config_battery_percentage_setting_available" | cut -d ":" -f1) && ((init_line++)) || init_line=4565
	[ -z "$grep_check" ] && sed -i "$init_line i \\\n$init_core" "$config_xml" || echo -e "\ngrep failed on config_patch: defaultBatteryPercentageSetting"
}

copyFiles() {
	#pointer_img
	cp $BL/pointer/xhdpi/*.png $PWD/frameworks/base/core/res/res/drawable-xhdpi/pointer_arrow.png
	cp $BL/pointer/mdpi/*.png $PWD/frameworks/base/core/res/res/drawable-mdpi/pointer_arrow.png
	cp $BL/pointer/hdpi/*.png $PWD/frameworks/base/core/res/res/drawable-hdpi/pointer_arrow.png
	cp $BL/pointer/xxhdpi/*.png $PWD/frameworks/base/core/res/res/drawable-xxhdpi/pointer_arrow.png
	#product_packages
	cp $BL/apk/handheld_product.mk $PWD/build/target/product/handheld_product.mk
	#phh_settings
	cp $BL/misc/phh/xml/* $PWD/treble_app/app/src/main/res/xml
	#wallpaper_1600x2560
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/core/res/res/drawable-sw600dp-nodpi/default_wallpaper.png
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/core/res/res/drawable-sw720dp-nodpi/default_wallpaper.png
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/core/res/res/drawable-nodpi/default_wallpaper.png
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/tests/HwAccelerationTest/res/drawable/default_wallpaper.png
	#apps
	#cp -r $BL/apk/apps/* $PWD/packages/apps
}

makeKeys() {

	$BL/misc/keymaker.sh

}

setupEnv() {
    echo "--> Setting up build environment"
    source build/envsetup.sh &>/dev/null
    mkdir -p $BD
    echo
}

buildTrebleApp() {
    #copy build.sh
    cp $BL/misc/gradle.sh $PWD/treble_app/build.sh
    echo "--> Building treble_app"
    cd treble_app
    bash build.sh release
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
    echo
}

buildVanillaVariant() {
    echo "--> Building treble_arm64_bvN"
    lunch treble_arm64_bvN-userdebug
    make -j$(nproc --all) installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img $BD/system-treble_arm64_bvN.img
    echo
}

buildGappsVariant() {
    echo "--> Building treble_arm64_bgN"
    lunch treble_arm64_bgN-userdebug
    make -j$(nproc --all) installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img $BD/system-treble_arm64_bgN.img
    echo
}

buildVndkliteVariant() {
    echo "--> Building treble_arm64_bvN-vndklite"
    cd sas-creator
    sudo bash lite-adapter.sh 64 $BD/system-treble_arm64_bvN.img
    cp s.img $BD/system-treble_arm64_bvN-vndklite.img
    sudo rm -rf s.img d tmp
    cd ..
    echo
}

generatePackages() {
    echo "--> Generating packages"
    buildDate="$(date +%Y%m%d)"
    xz -cv $BD/system-treble_arm64_bvN.img -T0 > $BD/aosp-arm64-ab-vanilla-14.0-$buildDate.img.xz
    xz -cv $BD/system-treble_arm64_bvN-vndklite.img -T0 > $BD/aosp-arm64-ab-vndklite-14.0-$buildDate.img.xz
    xz -cv $BD/system-treble_arm64_bgN.img -T0 > $BD/aosp-arm64-ab-gapps-14.0-$buildDate.img.xz
    rm -rf $BD/system-*.img
    echo
}

START=$(date +%s)

buildEnvDebian
#buildEnvArch
initRepos
syncRepos
applyPatches
setupEnv
buildTrebleApp
copyFiles
configPatches
makeKeys
buildVanillaVariant
buildGappsVariant
buildVndkliteVariant
generatePackages

END=$(date +%s)
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
