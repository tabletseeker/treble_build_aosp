# Fully Customizable TrebleDroid AOSP GSI

## Build
All necessary packages and path implementations are covered by the build script, which will automatically setup a working build environment for Debian/Ubuntu or Arch.

- Add user to group plugdev and log out:
    ```
   sudo usermod -aG plugdev $LOGNAME
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
    ```
    bash treble_build_aosp/build.sh
    ```
## Customization
All customization options can be found in the treble_build_aosp folder
#### misc
- treble_build_aosp/misc/phh/xml contains the config xmls for all phh settings.
  the currently assigned default settings are linear brightness (to fix broken slider adjustment),
  double tap to wake, Samsung alternate audio policy and stereo to fix multi speaker issues and allowing the
  lowest possible brightness.
- treble_build_aosp/misc/wallpaper contains the default wallpaper. You can replace it with any image you want
  as long as the image size matches your device's screen resolution. The current image's size is 1600x2560 ( Galaxy Tab S6)
- treble_build_aosp/misc/gradle.sh fixes java and android path issues in the original treble_app build.sh
- treble_build_aosp/misc/keymaker.sh automatically removes the default signing keys and creates new ones (password requested)
#### apk
- treble_build_aosp/apk/handheld_product.mk is needed to enter application folders for installation
- treble_build_aosp/apk/apps contains the application folders that will be automatically installed in the build
  
What you need to do:
- create a folder in treble_build_aosp/apk/apps
- rename the folder to resemble your app's name with the first letter being capitalized
- enter that name in the treble_build_aosp/apk/handheld_product.mk
- create an Android.mk file in your new app folder
- add your apk file to this folder and rename it accordingly
- uncomment this line `#cp -r $BL/apk/apps/* $PWD/packages/apps` in the treble_build_aosp/build.sh
#### Caution!
By default the apk folder already contains a few app folders with Android.mk files. If you **do not** want them, **delete** those folders.    This is for the purpose of including apps most people install anyways and to serve as a template for other apps you might want to install.    Thus all you would have to do to install them is add the apks (from apkmirror or any other suorce) to those folders and rename the apks as referenced in the Android.mk under LOCAL_SRC_FILES.
#### pointer
contains transparent pointer_arrow.png duplicates that will override the defaults during build. This is meant to make stylus operation easier.
You can disable it by commenting out the following in treble_build_aosp/build.sh:
```
cp $BL/pointer/xhdpi/*.png $PWD/frameworks/base/core/res/res/drawable-xhdpi/pointer_arrow.png
cp $BL/pointer/mdpi/*.png $PWD/frameworks/base/core/res/res/drawable-mdpi/pointer_arrow.png
cp $BL/pointer/hdpi/*.png $PWD/frameworks/base/core/res/res/drawable-hdpi/pointer_arrow.png
cp $BL/pointer/xxhdpi/*.png $PWD/frameworks/base/core/res/res/drawable-xxhdpi/pointer_arrow.png
```
#### system settings
- treble_build_aosp/build.sh contains a function called `configPatches()`
- this function allows you to automatically add preferred android system settings to the appropriate xml
- for ease of access the most common settings have been written out and named in the array
- new additions can be made to the string variable

How it works:
3 sets of values are needed to replace a default setting in any xml:
- xml location
- example: `"$PWD/frameworks/base/core/res/res/values/config.xml"`
- uniquely identifiable text so grep can find the line
- example: `"config_navBarInteractionMode"`
- the entire line with preferred settings value + spacer (default android spacing is 4)
- example: `"$space""<integer name=\"config_audio_notif_vol_default\">0</integer>"` - be sure to escape \\"\\" quotation marks
- Finally each part needs to be separated with a : delimiter

example addition to string:
`string="$PWD/frameworks/base/core/res/res/values/config.xml:config_navBarInteractionMode:$space<integer name=\"config_audio_notif_vol_default\">0</integer>"`
you can add as many entries as you want as long as they always follow this same pattern and delimiter separation.
  
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
