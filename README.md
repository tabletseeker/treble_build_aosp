# Fully Customizable TrebleDroid AOSP GSI

## Introduction
In addition to building an aosp 14 gsi, this repository aims to grant the user complete control over all customizable aspects of the build, such as adding a custom wallpaper, changing Phh settings, creating custom signing keys, modifying system settings, installing apks and more.
## Dependencies
This project uses a graphical user interface provided by the package `dialog` which is available on all Arch and Debian/Ubuntu distributions.
- Debian/Ubuntu
```
sudo apt-get install -y dialog
```
- Arch
```
sudo pacman -S dialog --noconfirm
```

## Build
All necessary packages and path implementations are covered by the build script, which will automatically setup a working build environment for Debian/Ubuntu or Arch.

- Add user to group plugdev and log out:
    ```
   sudo usermod -aG plugdev $LOGNAME && kill -9 -1
    ```  
- Create a new working directory for your AOSP build and navigate to it:
    ```
    mkdir aosp; cd aosp
    ```
- Clone this repo:
    ```
    git clone https://github.com/tabletseeker/treble_build_aosp -b android-14.0
    ```
- Customize as needed (Without any changes the default customizations apply)

- Finally, start the build script:
- Hint: Use a terminal window with minimum dimensions of 89x45 for correct dialog display
    ```
    bash treble_build_aosp/build.sh
    ```
## GUI

### Build Stage Selector
- Contains all customizable stages of the build process.
- You can enable/disable individual steps as needed.
  
![Build List Dialog](https://i.ibb.co/Pm5DGHM/1.png?raw=true)

### Custom Android Version
- Allows for the selection of an older/newer version number.
- You can choose any version as far back as android-10
  
![Android Version Dialog](https://i.ibb.co/hfpptcs/2.png?raw=true)

### Patch Selector
- Collects all .patch files from treble_build_aosp/patches
- Giving you the option to choose which patches should not be applied during the build.
  
![Patch Selection Dialog](https://i.ibb.co/dQbJ8Xq/3.png)

### File Selector
- Gives you the option to choose which files should be copied during the build.
- You can also launch a separate dialog for files to be copied to the filesystem on boot.
- For example: .ovpn files, images, documents etc.
  
![Files Dialog](https://i.ibb.co/7R4RMbc/4.png)

### Custom Settings Selector
- Creates a list of all available android settings, including all values, gathered from a given .xml file.
- Currently, the script uses frameworkbase defaults.xml and config.xml which contain the vast majority of useful settings.
- You can add more settings by simply adding the path to your xml and identifier to the xml array in build.sh.
- The list contains integer, fraction and boolean, but can be expanded to include string, string-array and integer-array.
  
![Settings Dialog](https://i.ibb.co/rMqXfsY/5.png)
![Settings2 Dialog](https://i.ibb.co/tb4ZWMD/6.png)

## Customization
All customization options can be found in the treble_build_aosp folder
### Phh settings, signing keys & wallpaper
#### misc
- misc/phh/xml contains the config xmls for all phh settings.
  the currently assigned default settings are linear brightness (to fix broken slider adjustment),
  double tap to wake, Samsung alternate audio policy and stereo to fix multi speaker issues and allowing the
  lowest possible brightness.
- misc/wallpaper contains the default wallpaper. You can replace it with any image you want
  as long as the image size matches your device's screen resolution. The current image's size is 1600x2560 ( Galaxy Tab S6)
- misc/gradle.sh fixes java and android path issues in the original treble_app build.sh
- misc/keymaker.sh automatically removes the default signing keys and creates new ones using the official android make_key script (password requested)
### Automatically installing apps
#### apk
- apk/handheld_product.mk is needed to enter application folders for installation
- apk/apps contains the application folders that will be automatically installed in the build
  
What you need to do:
- create a folder in treble_build_aosp/apk/apps
- rename the folder to resemble your app's name with the first letter being capitalized
- enter that name in the treble_build_aosp/apk/handheld_product.mk
- create an Android.mk file in your new app folder
- add your apk file to this folder and rename it accordingly
- uncomment this line `#cp -r $BL/apk/apps/* $PWD/packages/apps` in the treble_build_aosp/build.sh
#### Caution!
By default the apk folder already contains a few app folders with Android.mk files. If you do not wish to add apks to these default folders, which would trigger automatic installation, make sure to **delete** them before uncommenting the line mentioned above, because app folders with missing apks cause a build error. The purpose of including default app folders is to provide mk files for apps most people install anyways and to serve as a template for other apps you might want to install. Thus all you would have to do to install them is add the apks (from apkmirror or any other source) to those folders and rename these apks as referenced in the Android.mk under LOCAL_SRC_FILES.
### Transparent pointer image (For Stylus users)
#### pointer
contains transparent pointer_arrow.png duplicates that will override the defaults during build. The default pointer is a giant black cursor which is ugly and while PHH settings do offer alternatives, most people still prefer a completely transparent and thus non-visible pointer. This is meant to make stylus operation easier.
### Changing any system settings on the fly
#### system settings
- treble_build_aosp/build.sh contains a function called `configPatches()`
- this function allows you to automatically add preferred android system settings to the appropriate xml
- for ease of access the most common settings have been written out and named in the array so you can easily find and change them, such as navigation bar style, ring volume, haptic feedback, battery percentage style etc.
- new settings can be added to the settings variable

How it works:
3 sets of values are needed to replace a default setting in any xml:
- xml location
- example: `"$PWD/frameworks/base/core/res/res/values/config.xml"`
- uniquely identifiable text so grep can find the line aka "grep identifier"
- example: `"config_navBarInteractionMode"`
- settings values can be integer, string, boolean or fraction
- example: `>2<`  `>true<`  `>60%<`
- Finally each part needs to be separated with a : delimiter

How to add a new config entry:

- add your config path and sed identifier to the xml array in that order
- add the <grep> identifier and settings value separated by : to the settings string
- the sed identifier is unique to each setting, as all config entries carry their own specific prefix that denotes their origin.
- for example config.xml uses `config_`  defaults.xml uses `def_` as a prefix for each of their settings entries.

Example addition of android.xml and setting "android_backlight_intensity_default"
```
	# Note that the path has to be placed above the sed identifier. Thus the path's array index must always be even and the identifier's odd.
	xml=(
		"$PWD/frameworks/base/core/res/res/values/config.xml"
		"config_"
	 	"$PWD/frameworks/base/packages/SettingsProvider/res/values/defaults.xml"
	 	"def_"
		"$PWD/frameworks/base/core/res/res/defaults/android.xml"
		"android_"
	)

settings="\tconfig_navBarInteractionMode:2
	config_audio_notif_vol_default:0
	config_defaultHapticFeedbackIntensity:0
	config_audio_ring_vol_default:0
	def_haptic_feedback:false
	def_bluetooth_on:false
	def_sound_effects_enabled:false
	def_notifications_use_ring_volume:false
    	android_backlight_intensity_default:45%"
 ```

 Example addition of a setting from the already implemented defaults.xml or config.xml

- add the <grep> identifier and settings value separated by : to the settings string
```
settings="\tconfig_navBarInteractionMode:2
	config_audio_notif_vol_default:0
	config_defaultHapticFeedbackIntensity:0
	config_audio_ring_vol_default:0
	def_haptic_feedback:false
	def_bluetooth_on:false
	def_sound_effects_enabled:false
	def_notifications_use_ring_volume:false
    	def_backlight_intensity_default:45%"
 ```

You can add as many entries as you want as long as they always follow this same pattern and delimiter separation.
  
## Credits
These people have helped this project in some way or another, so they should be the ones who receive all the credit:
- [phhusson](https://github.com/phhusson)
- [AndyYan](https://github.com/AndyCGYan)
- [eremitein](https://github.com/eremitein)
- [kdrag0n](https://github.com/kdrag0n)
- [Peter Cai](https://github.com/PeterCxy)
- [haridhayal11](https://github.com/haridhayal11)
- [sooti](https://github.com/sooti)
- [Iceows](https://github.com/Iceows)
- [ChonDoit](https://github.com/ChonDoit)
- [ponces](https://github.com/ponces)

## Donations :heartpulse:
If you like my contributions please feel free to drop a coin.
- Bitcoin Address: bc1qjz2dqu4u5uhxcv43jqmlefgffe3hnfavcs8w90

