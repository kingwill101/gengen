
---
title: "Auto unlock gnome keyring  with SDDM"
date: 2021-03-03T20:28:42-05:00
draft: false
tags : [linux, gnome, kde,keyring, ubuntu, sddm, gdm, login, xorg, X]
author: "Glenford Williams"
description: "Fixing unresponsive topuchpad at login"

---

In GDM+GNOME, when you login, GNOME Keyring is automatically unlocked. However, it doesn't do so in SDDM+KDE. When you start some GNOME or Electron application, they ask you type login password again.

Here is a solution!

Edit `/etc/pam.d/sddm` and `add pam_gnome_keyring.so`:
```
#%PAM-1.0
auth     include        common-auth
auth     optional       pam_gnome_keyring.so
account  include        common-account
password include        common-password
session  required       pam_loginuid.so
session  include        common-session
session  optional       pam_gnome_keyring.so auto_start
```

sources -

https://en.opensuse.org/GNOME_Keyring
