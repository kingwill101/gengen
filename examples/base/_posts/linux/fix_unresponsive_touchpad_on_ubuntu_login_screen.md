---
title: "Ubuntu: unresponsive touchpad at login"
date: 2021-03-03T20:28:42-05:00
draft: false
tags : [linux, touchpad, ubuntu, sddm, gdm, login, xorg, X]
author: "Glenford Williams"
description: "Fixing unresponsive topuchpad at login"
---

I have been a Linux user for many years and now and then I come across an issue that I've never seen.

My current Ubuntu install has been around for about 6 months and recently I noticed that my touchpad no longer worked 
whenever I got to the login screen.
This I assume came about as a result of me switching between desktop environments (installed KDE for about a month now). 
The issue persisted between gdm and sddm which felt a bit weird, usually i find that switching between display managers fix these weird quirks.
To cut a long story short, after doing a bit of research I found the following xorg config that ended up solving all my 
touchpad issues.

For my system `lsb_release -a` returns 

```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.10
Release:        20.10
Codename:       groovy
```
and `uname -ar` returns
```
Linux kingwill101-Inspiron-5491-2n1 5.10.7-051007-generic #202101122046 SMP Tue Jan 12 21:13:32 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```
Not sure if my situation is unique in any shape but hope the solution works for you as well.

## Solution

Save the following to `/etc/X11/xorg.conf.d/20-touchpad.conf`
```
Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"

        Option "Tapping" "on"
        Option "NaturalScrolling" "on"
        Option "MiddleEmulation" "on"
        Option "DisableWhileTyping" "on"
EndSection

```

sources -

https://github.com/sddm/sddm/issues/657#issuecomment-241268283
https://wiki.archlinux.org/index.php/Touchpad_Synaptics#Frequently_used_options
