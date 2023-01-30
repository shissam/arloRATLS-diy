# arloRATLS-diy
Do It Yourself Remote Access to Locally Stored video on Unsupported Arlo Base Station(s).

![](https://raw.githubusercontent.com/shissam/arloRATLS-diy/master/assets/arloRATLS-diy.png)

(or get your bird out of EOL jail)

## Problem
Cameras for this proprietary eco-system push recordings to the vendor's cloud storage service thereby allowing authorized access to such recordings virtually from anywhere using a web browser or phone app. Furthermore, those same recordings (except for "manually" initiated recordings), can also be alternatively saved/mirrored on local storage (known as "Local Storage Backups") when enabled by a "base station".

Local storage backups are only available for specific [camera models and base stations](ihttps://kb.arlo.com/en_US/1146857). Such recordings are made to a supplied USB mass storage device inserted externally into the base station. For all base stations that support local storage backup, those recordings can be accessed by physically removing the USB mass storage device from the base station and subsequently reviewed on another computer.

There is, however, a subset of base stations which permit [remote acess to location storage backup](https://kb.arlo.com/000062337/What-is-Direct-Storage-Access-and-how-do-I-use-it) (a.k.a., RATLS). When enabled, with the proper base station, these locally stored backups are integrated into the web brower or phone application's ```Library```.

There are a number of limitations what come with the vendor's RATLS approach:
* Not all base stations support RATLS
* Manually initiatied reocrdings are not locally stored
* RATLS only supports viewing of locally stored videos for the last 30 days
* RATLS is only supported on the LAN (WAN access required VPN or opening ports from WAN to LAN)
* Locally stored videos will not have thumbnails viewable from the ```Library```
* Locally stored videos cannot be deleted remotely from the base stations (requires removing the USB mass storage device)

## Compounding Problem

Starting in 2023, the vendor has announced [End Of Life Policy](https://community.arlo.com/t5/Arlo/End-Of-Life-Policy/m-p/1893275#M84782) meaning that ```legacy``` products will no longer push recordings to the vendor's cloud storage service completely defeating the ability to access historical recordings which were part of the vendor's marketing and service agreement (implied through the vendor's explicit marketing literatire) with owners which was advertised and maintained from [2016-Oct-12](https://web.archive.org/web/20161012153328/http://www.arlo.com/en-us/products/arlo/default.aspx) to [2020-May-27](https://web.archive.org/web/20200527223637/https://www.arlo.com/en-us/products/arlo/default.aspx) based on third-party web site captures.

Furthermore, [Automatic email alerts and push notifications may be reduced or eliminated](https://downloads.arlo.com/images/PDFs/EOL_Policy/Arlo_End-of-Life-Policy-2022.pdf), meaning that owners _may_ have no idea that something has transpired (i.e., motion or audio detection) thereby placing the onus on the owner to determine (by some means) that there is an event that needs attention. And if by some "magic" the owner is made aware that something has occurred, the owner must access the locally stored videos as a means determine the extent of the event.

## Impact

This means for products which include base stations without the ability to access locally stored videos, the owners have no automated means to access those backup recordings without physical, manual, intervention with the base station and the USB mass storage device. This burden can be intolerable in a number of situations and use cases which are too numerous to enumerate, but here are a few examples:
* Owner must physically access the base station, properly disable local recordings, safely remove the USB mass storage device, insert the removed USB mass storage device into another computer, and sift through the myriad list of folders and obscure directory and file names to find the proper video event. Upon completing that activity, the owner must reverse the process to properly reinsert the USB mass storage device back into the base station.
* The product is employed at remote locations from the owner to monitor current and previous recorded events. In this case, the owner needs to do everything just listed above *PLUS* actually travel to the remote location(s) with the proper equipments (e.g., another computer) to conduct that investigation.
* (I am sure you can think of others burdensome use cases)

## arloRATLS-diy: An Approach

The goal of this approach is to overcome some of the short-falls of the vendor's RATLS as well as preserving some of the capabilities lost by the EOL announcement. Most specifically:
* Support base stations that are not supported by the vendor's RATLS
* Support access to locally stored recordings beyond the 30 day limit
* Support thumbnails for locally stored videos
* (TODO) Support deletion of locally stored videos

However, the vendor's eco-system does inhibit overcoming specific limitations which are beyond ```arloRATLS-diy```:
* LAN vs. WAN access to ```arloRATLS-diy```: this defined approach does *NOT* preclude the use of private cloud storage but the approach within continues to use WAN to LAN access via (self-hosted) VPN.
* Vendor's web brower or phone app approach cannot be "pointed" to ```arloRATLS-diy```: this defined approach requires your own (i.e., ```diy```) web brower for this access.

### arloRATLS-diy: A Recipe

COMING SOON

#### Hardware

* Base station which supports locally stored video backups
* A device<i><sup>(1)</sup></i> which supports the Linux USB Gadget<i><sup>(2)</sup></i> (e.g., Raspberry Pi 2 Zero)
* A device<i><sup>(1)</sup></i> which supports backend services (e.g., web server, ffmpeg)
* An external mass storage for longterm video backups (e.g., GB to TB storage)

_(1) these two devices could be the same device, this approach elected to separate these two devices._<br>
_(2) [here](https://magpi.raspberrypi.com/articles/pi-zero-w-smart-usb-flash-drive),[here](https://forums.raspberrypi.com/viewtopic.php?t=331867),[here](https://github.com/thagrol/Guides/blob/main/mass-storage-gadget.pdf),[here](https://github.com/kmpm/rpi-usb-gadget), and [here](https://linux-sunxi.org/USB_Gadget/Mass_storage)._

#### Software

COMING SOON
