# ScreenshotFramer
[![Twitter: @PatrickKladek](https://img.shields.io/badge/twitter-@PatrickKladek-red.svg?style=flat)](https://twitter.com/PatrickKladek)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/Patrick-Kladek/CocoaDebugKit/blob/master/LICENSE.md)
![alt text](https://img.shields.io/badge/Platform-Mac%2010.13+-blue.svg "Target Mac")
![alt text](https://img.shields.io/badge/Language-Swift%204-orange.svg "Language")

With Screenshot Framer you can create Localized App Store Images.
![](Documentation/Overview.png)

### How does it work

Screenshot Framer simply put pictures on top of each other and saves the image to disk.
You can specify the path of every image layer and use a `.strings` file for the text layers. You can than export all possible Image & Language combinations

![](Documentation/How%20it%20works.gif)



### Preparation

Download the Sample Project here or create your own project structure.
When you are using Fastlanes snapshot you can reuse that folder structure and only add missing files:

![](Documentation/File%20Structure.png)

##### backgrounds
If you want a background other that white

##### device_frames
If you want your screenshots framed in a device. You may use any Image here. It is useful if the images support alpha values. Unfortunatley we can not give you our device images due to copyrights. You can download apples device images and copy them in this folder. It may be neccesary to export them as png tho.

##### localized image Folder
(en-US, de-DE and so on) are generated using Fastlane snapshot or you may also copy them in this folders. Important is that you have a strings file in this folder called `screenshots.strings`

```
"1" = "It Starts With a Thought";
"2" = "Add Your Thoughts";
"3" = "Discover Connections";
"4" = "Visualize Your Idea";
"5" = "Productive on the Go";
 |
This Number is later replaced with variable "image"
```

##### Configuration File
This file contain the configuration for the image export.
Open the file `iPhone SE` and change the number in image textfield or language popup. You may also change the position and size of each layer or create new layers.


### Usage

You create your Images like in your favorite Image editing App.
The main difference is that you can specify variables and use them for the image path.
Possible Variables:

* `$image` can contain only numbers (typically 1-5)
* `$language` contains every sub-folder name in your project folder (in this case `Sample Project`) excluding `backgrounds, device_frames and Export`

In the screenshot below the File is: `$language/iPhone SE-$image.png`. This is automatically translated to `en-US/iPhone SE-1.png` and this file is rendered. For german this would be translated to `de-DE/iPhone SE-1.png`

![](Documentation/Usage.png)

When you are happy with the output you can check how the screenshots look in different languages by simply changing the languge popup and change the image number. You can than export the images by clicking `Export All`. You can also specify which images are created by changing `From` and `To` Values


### Known limitations & bugs
* No rearanging of layers (drag and drop in tableView)
* May use exessice amount of memory while exporing (up to 4GB)
* no ascpect ratio lock. keep that in mind if you scale images
* For better overview output is set to `Export/$language/iPhone SE-$image framed.png` but you could also remove `Export` and Fastlane Upload to itunesconnect should work (not tested)

Callisto is brought to you by IdeasOnCanvas, the creator of MindNode for iOS, macOS & watchOS.
