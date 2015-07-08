# Tiny AVC

Tiny AVC (Tiny **A**utomated **V**ersion **C**hecker) is a modding tool for [Project Zomboid](http://projectzomboid.com/) which allows players to see if a mod they are using is outdated.

## For Players
You can [install](http://theindiestone.com/forums/index.php/topic/1395-) Tiny AVC like any other mod you use. Once you open the mod selection screen in the game, you should see a button called "Check for updates". Once you press it Tiny AVC will check the installed mods and display information about their current status:

![preview](https://raw.githubusercontent.com/blind-coder/pz-tiny_avc/master/poster.png)

## For Modders

Supporting TinyAVC in your mod is easy. Just open the mod.info file and add the following lines:

```
modversion=0.7.0
pzversion=32.16
versionurl=https://raw.githubusercontent.com/blind-coder/pz-tiny_avc/master/mod.info
```

- ```modversion``` This is the current version of your mod.
- ```pzversion``` The version of Project Zomboid the mod has been developed for.
- ```versionurl``` A url which points to a online file containing the version information.  
TinyAVC will use this file to fetch the latest information about your mod. The file has to contain the ```modversion``` and ```pzversion``` fields. If you want to notify your users of a new version you only have to change the ```modversion``` value and Tiny AVC will display a notification.  
As this file has the same syntax as the mod.info file, you can simply use that.
