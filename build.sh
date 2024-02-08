#!/bin/bash

echo
echo "--------------------------------------"
echo "          AOSP 14.0 Buildbot          "
echo "                  by                  "
echo "             tablet_seeker            "
echo "--------------------------------------"
echo

BL=$PWD/treble_build_aosp
BD=$HOME/builds

buildList() {

while true; do
	
	exec 3>&1
	buildlist=(`dialog --title "\ZbBuild Stage Selection\Zn" "$@" \
		--colors \
		--backtitle "\ZbAOSP 14.0 Buildbot\Zn \Z1by tablet_seeker\Zn" \
		--separator " " \
		--item-help \
		--no-tags \
		--checklist "$(echo -e "\nPlease choose which stages you would like to customize during the build.\n\n\
		Press \Zb\Zr Space \Zn to toggle an option on/off.\n\n\
		Press \Zb\Zr Arrow UP ↑ \Zn or \Zb\Zr Arrow DOWN ↓ \Zn to navitage options.\n\n\
		Press \Zb\Zr Arrow RIGHT → \Zn + \Zb\Zr Cancel \Zn to use default values.\n" | sed -e "s/\\t//g")" 16 61 0 \
		"1" " Build Env Debian " "ON" "Build Environment for Debian and Ubuntu Distros" \
		"2" " Build Env Arch " "OFF"  "Build Environment for Arch Distros" \
		"3" " Custom System Settings " "OFF"  "Launch System Settings Form for Custom Value Selection" \
		"4" " Custom Android Version " "OFF" "Choose alternate Android Version" \
		"5" " Custom File Selection " "OFF" "Choose individually which files are copied during build time" \
		"6" " Custom Signing Keys " "ON"  "Launch automatic creation of new signing keys" \
		"7" " Custom Patch Selection " "OFF"  "Individually choose which patches should be applied during build" \
		 2>&1 1>&3`)
   		 
	case "$?" in


		1)
			dialog --colors \
			--title "\Z1Info\Zn" \
			--msgbox "Custom Build Selection Cancelled. Default values will apply!" 7 30 && break
			;;
							
		0)
			
			[[ "${buildlist[@]}" =~ .*(1|2)+ && "${buildlist[@]}" != *"1 2"* ]] && break || \
			dialog --colors \
			--title "\Z1Error Input\Zn" \
			--msgbox "You must choose a single build environment.\nPlease, try again!" 7 29			
			;;			
			
	esac

      	dialog --clear
	
done
}

buildEnvCheck() {

	[[ "${buildlist[@]}" == *"1"* ]] && buildEnvDebian || buildEnvArch

}


buildEnvDebian() {

	sudo apt-get update && sudo apt-get install -y git-core gnupg flex bc bison \
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

	aur_packages=(
		"xml2"
	 	"ncurses5-compat-libs"
	  	"lib32-ncurses5-compat-libs"
	   	"aosp-devel"
	    	"lineageos-devel"
	     	"android-sdk-build-tools"
	      	"android-sdk-platform-tools"
		"android-sdk"
	 	"android-platform"
		"android-support-repository"
		"android-sdk-cmdline-tools-latest"
		"marvin_dsc"
	)

	sudo pacman -Syyu --noconfirm
	sudo pacman -S ttf-dejavu repo git base-devel jdk17-openjdk android-tools bc --noconfirm
	mkdir -p $PWD/install_packages
	cd $PWD/install_packages
	
	for package in ${aur_packages[@]}; do
		[ -w "${package}" ] && cd ${package}; git pull; cd .. || git clone https://aur.archlinux.org/${package}.git
		(cd "${package}" && makepkg -s -i -c --noconfirm --skippgpcheck; cd ..)
	done

	cd ..
	git config --global user.email "anon@ymous.com"
	git config --global user.name "johndoe"

	getent group android-sdk || sudo groupadd android-sdk
	sudo gpasswd -a $LOGNAME android-sdk
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
        ver_regex='android-[0-9]{2}(\.[0-9])+_r[0-9]{1,2}'
        
	if [[ "${buildlist[@]}" == *"4"* ]]; then
        
		while true; do

			exec 3>&1
			version=`dialog --title "\ZbVersion Selection\Zn" "$@" \
			--colors \
			--tab-correct \
			--backtitle "\ZbAOSP 14.0 Buildbot\Zn \Z1by tablet_seeker\Zn" \
			--inputbox "$(echo -e "\nPlease enter a valid android mainline version number starting from android-10.\n
			Press \Zb\Zr TAB \Zn + \Zb\Zr Cancel \Zn to skip.\n
			Examples: \Zb\Zr android-12.1.0_r7 \Zn \Zb\Zr android-14.0.0_r16 \Zn" | sed -e "s/\\t//g")" 15 55 "android-" 2>&1 1>&3`
      
			case "$?" in


				1)
					dialog --colors \
					--title "\Z1Info\Zn" \
					--msgbox "Custom Repo Selection Cancelled. Default version will apply!" 7 30 && break
					;;
									
				0)
					
					[[ $version =~ $ver_regex ]] && break || dialog --colors \
					--title "\Z1Error Input\Zn" \
					--msgbox "Only main branch versions >10 are allowed.\nPlease, try again!" 7 29		
					;;				
					
			esac
		
		done
 		
   		dialog --clear
	
	fi
	
	[ -z "$version" ] && version="android-14.0.0_r28"
        
        repo init -u https://android.googlesource.com/platform/manifest -b "$version" --git-lfs --depth=1
        echo ""
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

	patch_array=($(find $BL/patches/. -name "*.patch" | sed 's|.*/||' | cut -d\. -f1 | sort))
   
	if [[ "${buildlist[@]}" == *"7"* ]] && [ ${#patch_array[@]} -gt 2 ] ; then

		[ ! -d $BL/patch_dump  ] && mkdir $BL/patch_dump
		
		unset darray
		state="OFF"
		
		for x in ${!patch_array[@]}; do

			darray+=($(echo "${patch_array[x]} ${patch_array[x]} $state"))
			[ $x -eq 0 ] && darray[1]=" ${darray[1]}"  || \
			{ int=$((int+3));darray[int+1]=" ${darray[int+1]}"; }

		done

		while true; do
					
			exec 3>&1
			p_choice=(`dialog --title "\ZbPatch Selection\Zn" "$@" \
				--colors \
				--backtitle "\ZbAOSP 14.0 Buildbot\Zn \Z1by tablet_seeker\Zn" \
				--separator " " \
				--no-tags \
				--scrollbar \
				--visit-items \
				--extra-button \
				--extra-label "Select All" \
				--checklist "$(echo -e "\nPlease select the patches you would \Zb\Z1not\Zn like to be applied.\n
				Press \Zb\Zr Space \Zn to toggle an option on/off\n\n\
				Press \Zb\Zr Arrow UP ↑ \Zn or \Zb\Zr Arrow DOWN ↓ \Zn for slow scrolling\n\n\
				Press \Zb\Zr Page UP ↑ \Zn or \Zb\Zr Page DOWN ↓ \Zn for rapid scrolling\n\n\
				Press \Zb\Zr Arrow RIGHT → \Zn + \Zb\Zr Cancel \Zn to use default values\n" | sed -e "s/\\t//g")" 35 75 5 "${darray[@]}" \
				2>&1 1>&3`)
				 
			case "$?" in

				3)
					state="ON"
					unset darray
     					unset int
					
					for x in ${!patch_array[@]}; do

						darray+=($(echo "${patch_array[x]} ${patch_array[x]} $state"))
						[ $x -eq 0 ] && darray[1]=" ${darray[1]}"  || \
						{ int=$((int+3));darray[int+1]=" ${darray[int+1]}"; }

					done     					
					;;

				1)
					dialog --colors \
					--title "\Z1Info\Zn" \
					--msgbox "Custom Patch Selection Cancelled. All patches will be applied!" 7 30 && break
					;;
									
				0)
					
					[ ${#p_choice[@]} -eq 0 ] && dialog --colors \
					--title "\Z1Info\Zn" \
					--msgbox "No patches selected for removal. All patches will be applied!" 7 30 && break

					[ ${#p_choice[@]} -eq ${#patch_array[@]} ] && dialog --colors \
					--title "\Z1Info\Zn" \
					--msgbox "Building without patches is not recommended. Please try again!" 7 29 || break						
					;;				
					
			esac
		
		done
	
		for x in ${!p_choice[@]}; do
		
			move=$(find $BL/patches/. -name "*.patch" | grep -w "${p_choice[x]}")
			mv "$move" $BL/patch_dump	
		
		done
		
	fi

        	dialog --clear
	   
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
	#xml path and unique settings prefix (def_ , config_ ...)
	xml=(
		"$PWD/frameworks/base/core/res/res/values/config.xml"
		"config_"
	 	"$PWD/frameworks/base/packages/SettingsProvider/res/values/defaults.xml"
	 	"def_"
	)
		
	if [[ "${buildlist[@]}" == *"3"* ]]; then


		for (( i=0;i<${#xml[@]};i+=2)); do

			unset config
			unset darray
			unset names
			unset values
			unset dialog

			mapfile -t config <<< $(cat "${xml[i]}" | grep -Ew '<(bool|integer|fraction)\s.*=".*">([0-9]+|[0-9]+%|true|false)<' | sed 's/.*name=//' | sort)
			current=$(echo "${xml[i]##*/}")
			names=($(printf '%s\n' "${config[@]}" |  grep -Eo '".*"' | cut -d \" -f2 | cut -d "_" -f2-))
			values=($(printf '%s\n' "${config[@]}" | grep -Po '>([^\s]+)<' | sed 's|[<>,]||g'))
			
			[ ${#names[@]} -ne ${#values[@]} ] && echo "xml structure has changed, please update grep command!" && exit
				
				for x in ${!config[@]}; do
    
					[ "$x" -eq "0" ] && string="${names[x]} 1 1 ${values[x]} 1 59 10 0" || \
					string="${names[x]} $((x+1)) 1 ${values[x]} $((x+1)) 59 10 0"
					darray+=($(echo "$string"))

				done

			while true; do
			
				exec 3>&1
				dialog=(`dialog --colors \
				  --ok-label "Submit" \
				  --backtitle "\ZbAOSP 14.0 Buildbot\Zn \Z1by tablet_seeker\Zn" \
      				  --title "\ZbCustom Settings Selection\Zn" "$@" \
	    			  --scrollbar \
				  --form "$(echo "\nCurrent XML File: \Z1\Zb$current\Zn\n\n 
				Allowed Values: \Zb\Zr true \Zn \Zb\Zr false \Zn \Zb\Zr [0-9]+ \Zn \Zb\Zr [0-9]+% \Zn\n\n\
				Press \Zb\Zr Ctrl \Zn + \Zb\Zr u \Zn  to clear.\n\n\
				Press \Zb\Zr TAB \Zn + \Zb\Zr Cancel \Zn  to skip.\n\n\
				Press \Zb\Zr Page UP \Zn or \Zb\Zr Page DOWN \Zn for rapid scrolling.\n\n\
				Press \Zb\Zr Arrow UP ↑ \Zn or \Zb\Zr Arrow DOWN ↓ \Zn for slow scrolling.\n" | sed -e "s/\\t//g")" 38 75 22 "${darray[@]}" \
				2>&1 1>&3`)

				case "$?" in

					1)
						break
						;;
							
					0)
			
						[ ${#values[@]} -ne ${#dialog[@]} ] && dialog --colors \
						--title "\Z1Error Input\Zn" \
						--msgbox "One or more empty boxes detected, but not allowed.\nPlease, try again!" 7 31
						[ $(printf '%s\n' "${dialog[@]}" | grep -Ewc "[0-9]+|[0-9]+%|true|false") -eq ${#values[@]} ] && \
						{ for x in "${!values[@]}"; do [ "${values[x]}" != "${dialog[x]}" ] && \
						{ choice+=($(echo "${xml[i]} ${names[x]} ${dialog[x]}")); }; done; break; } || \
						dialog --colors --title "\Z1Error Input\Zn" \
						--msgbox "Allowed values are boolean, integer and fraction." 6 32				
						;;				

				esac
			
			done

		done

	fi

		dialog --clear
		#pre-selected config settings
		settings="\tconfig_navBarInteractionMode:2:
		config_audio_notif_vol_default:0:
		config_defaultHapticFeedbackIntensity:0:
		config_audio_ring_vol_default:0:
		def_haptic_feedback:false:
		def_bluetooth_on:false:
		def_sound_effects_enabled:false:
		def_notifications_use_ring_volume:false"
		#assembling settings string
		for i in "${xml[@]}"; do
		
			index=$((index+1))
			[ $(($index%2)) -ne 0 ] && settings=$(echo -e "$settings" | sed -e "/${xml[$index]}/ s|\t*|$i:|")

		done
	 	#assembling array
	 	IFS=":"
	 	[ ${#choice[@]} -gt 0 ] && settings+=" $(printf ':%s' "${choice[@]}")"
		read -ra array <<< $(echo "$settings" | tr -d '\n')
	
		#updating config files
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
				
			line_nr=$(grep -n "$grep" "$dest" | cut -d ":" -f1)
			[ ! -z "$line_nr" ] && sed -i "$line_nr s/>.*</>$replace</g" "$dest" \
			|| echo -e "\n grep failed on config_patch: $grep"
		done	
		#battery_percentage
		space=$(printf "%*s%s" 4)
		init_core="$space<bool name=\"config_defaultBatteryPercentageSetting\">true</bool>"
		grep_check=$(grep -n "config_defaultBatteryPercentageSetting" "${xml[0]}"  | cut -d ":" -f1 || echo "")
		[ -z "$grep_check" ] && { init_line=$(grep -n "config_battery_percentage_setting_available" "${xml[0]}" | cut -d ":" -f1) && ((init_line++)) && \
		sed -i "$init_line i \\\n$init_core" "${xml[0]}"; } || { [ $(sed -n "$grep_check p" "${xml[0]}" | grep -Eo "true|false") = false ] && \
		sed -i "$grep_check s|^.*$|$init_core|" "${xml[0]}" ; }
}

copyFiles() {
	
	files=('{ cp $BL/pointer/xhdpi/*.png $PWD/frameworks/base/core/res/res/drawable-xhdpi/pointer_arrow.png;
	cp $BL/pointer/mdpi/*.png $PWD/frameworks/base/core/res/res/drawable-mdpi/pointer_arrow.png;
	cp $BL/pointer/hdpi/*.png $PWD/frameworks/base/core/res/res/drawable-hdpi/pointer_arrow.png;
	cp $BL/pointer/xxhdpi/*.png $PWD/frameworks/base/core/res/res/drawable-xxhdpi/pointer_arrow.png; }'
	'cp $BL/apk/handheld_product.mk $PWD/build/target/product/handheld_product.mk'
	'cp $BL/misc/phh/xml/* $PWD/treble_app/app/src/main/res/xml'
	'{ cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/core/res/res/drawable-sw600dp-nodpi/default_wallpaper.png;
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/core/res/res/drawable-sw720dp-nodpi/default_wallpaper.png;
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/core/res/res/drawable-nodpi/default_wallpaper.png;
	cp $BL/misc/wallpaper/default_wallpaper.png $PWD/frameworks/base/tests/HwAccelerationTest/res/drawable/default_wallpaper.png; }'
	'cp -r $BL/apk/apps/* $PWD/packages/apps')
 	f_choice=("1" "2" "3")

	if [[ "${buildlist[@]}" == *"5"* ]]; then

		while true; do

			exec 3>&1
			f_choice=(`dialog --title "\ZbCopy Selection\Zn" "$@" \
				--colors \
				--backtitle "\ZbAOSP 14.0 Buildbot\Zn \Z1by tablet_seeker\Zn" \
				--separator " " \
				--item-help \
				--no-tags \
				--checklist "$(echo -e "\nPlease choose which files you would like to be copied to the final image's filesystem.\n\n\
				Press \Zb\Zr Space \Zn to toggle an option on/off.\n\n\
				Press \Zb\Zr Arrow UP ↑ \Zn or \Zb\Zr Arrow DOWN ↓ \Zn to navitage options.\n\n\
				Press \Zb\Zr Arrow RIGHT → \Zn + \Zb\Zr Cancel \Zn to use default values.\n" | sed -e "s/\\t//g")" 16 61 0 \
				"0" " Copy Modified Pointer Images " "OFF" "Globally transparent pointer image (For stylus users)" \
				"1" " Copy Product.mlk " "ON"  "Needed for automatic app installation" \
				"2" " Copy Custom PHH XML " "ON"  "Overwrites the default phh settings with your modified xmls" \
				"3" " Copy Custom Wallpaper " "ON"  "Overwrites the default wallpaper with your custom one" \
				"4" " Copy App Folders " "OFF" "Adds your apps for automatic install (app folders must be prepped!)" \
				2>&1 1>&3`)
				 
			case "$?" in


				1)
					dialog --colors \
					--title "\Z1Info\Zn" \
					--msgbox "Custom File Selection Cancelled. Default values will apply!" 7 30 && \
   					{ f_choice=("1" "2" "3"); break; }
					;;
									
				0)
					
					[ ${#f_choice[@]} -eq 0 ] && dialog --colors \
					--title "\Z1Info\Zn" \
					--msgbox "All options unselected. Nothing will be copied!" 6 29
     					break			
					;;				
					
			esac
				 
		done
	
	fi
		
		for x in ${f_choice[@]}; do
		
			sleep 0.2
			eval "${files[x]}"
		
		done

      		dialog --clear

}

makeKeys() {

	[[ "${buildlist[@]}" == *"6"* ]] && $BL/misc/keymaker.sh

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

buildVndkliteVariants() {
    echo "--> Building treble_arm64_bvN-vndklite"
    cd treble_adapter
    sudo bash lite-adapter.sh 64 $BD/system-treble_arm64_bvN.img
    mv s.img $BD/system-treble_arm64_bvN-vndklite.img
    sudo rm -rf d tmp
    echo "--> Building treble_arm64_bgN-vndklite"
    sudo bash lite-adapter.sh 64 $BD/system-treble_arm64_bgN.img
    mv s.img $BD/system-treble_arm64_bgN-vndklite.img
    sudo rm -rf d tmp
    cd ..
    echo
}

generatePackages() {
    echo "--> Generating packages"
    buildDate="$(date +%Y%m%d)"
    xz -cv $BD/system-treble_arm64_bvN.img -T0 > $BD/aosp-arm64-ab-vanilla-14.0-$buildDate.img.xz
    xz -cv $BD/system-treble_arm64_bvN-vndklite.img -T0 > $BD/aosp-arm64-ab-vanilla-vndklite-14.0-$buildDate.img.xz
    xz -cv $BD/system-treble_arm64_bgN.img -T0 > $BD/aosp-arm64-ab-gapps-14.0-$buildDate.img.xz
    xz -cv $BD/system-treble_arm64_bgN-vndklite.img -T0 > $BD/aosp-arm64-ab-gapps-vndklite-14.0-$buildDate.img.xz
    rm -rf $BD/system-*.img
    echo
}

START=$(date +%s)

buildList
buildEnvCheck
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
buildVndkliteVariants
generatePackages
generateOta

END=$(date +%s)
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
