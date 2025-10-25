---
title: 'Nokia C3 Multitasking - Run multiple Apps Tutorial--an excerpt from http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html'
date: 2012-02-17T14:55:00.000-08:00
draft: false
aliases: [ "/2012/02/nokia-c3-multitasking-run-multiple-apps.html" ]
---

  

[EarlyChicken!](http://earlychicken.blogspot.com/)
==================================================

my OOP Projects' archive and random stuffs.

[Early Chicken](http://www.earlychicken.info/)

*   Blog
*   Stalk Me
*   About me
*   Thanks to

11

Mar

### [Nokia C3 Multitasking - Run multiple Apps Tutorial](http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html)

Nokia C3 is running on s40 platform, and s40 is not capable of multitasking. Yes! That's true, though only in the hands of average users. But for advance users, not afraid to tweak its phone to its full potential, Nokia C3 is very capable multitasking phone. You heard it right, once hacked Nokia C3 can rival its s60 big brothers, like the Nokia E63.  
  

> **Advantages:**  
> 
> 1.  Put simply, while your browsing your favorite website via your favorite web browser(eg OperaMini, Bolt, etc)  or your playing a game, then someone sent you an sms message. On normal Nokia C3, you have to close the application first, closing that means, you cant continue what you are doing later on, then you can read the message. On hacked Nokia C3, you can just minimize the application, read the sms message, you can even reply to it, then open the minimized application and you'll continue where you left off.
> 2.  It increases productivity. You can open multiple apps simultaneously, like open Operamini for browsing, then open SHmessenger for chating with friends on FB while listening to music on your favorite media player, etc.
> 3.  It runs application in the background. That means, you can run MobilePhinger, ping an adress, to stabilize and keep you internet connection alive. You can also run apps like Call Cheat Manager to fake a call.
> 4.  Its like S60 goodness on a cheap s40 phone.
> 5.  Since its hacked, your phones' J2Me Security Wall is disabled, that means no annoying warning popups even on unsigned java apps..
> 
>   
>   
> **Disadvantages:**  
> 
> 1.  When you turn on your phone, theres a warning "Test in RSNDI USB Mode", just select No, otherwise, USB connection will not work. Incase you accidentaly selected Yes, you can restart your phone and select No.
> 2.  The Mail in the Main Menu will be removed. I had a C3 for monts now, but I havent even use the Mail application, though for those whos using it, heres a workarround for this. Just select and add Mail in the Goto option of the in the Homescreen shortcuts.
> 3.  When you exit an aplication, theres a small notification "Warning TCK Flag Off" that'll pop up, its not annoying though.
> 
>   
>   
> **Additional Notes:**  
> How does C3 really handle multitasking?  
> For normal usage, I havent had any problems. Im using Operamini 5.1(Unmodded version) opened two tabs, the one is Facebook and the other is Symbianize.com, im also logged in Facebook and YM CHat in SHmessenger, chating with friends on FB, I also opened Snaptu for reading blogs and Im actively replying on SMS.. Ive checked the ram usage using Memory Up Pro, and it also tops at arround 10% of the total 2MB Ram of Nokia C3..  
>   
> However, I did stress tested it. Testing how extreme it can handle multi tasking. I opened Opera Mini 5.1, Opera Mini 5.1 modded, Snaptu, SHMessenger, TTpod(played a music), Mobile Phinger, BlueFTP, MobyExplorer(I deleted the imgcache folder which contains around 1000+ cache files) and boom! My C3 shutsdown. lol. But, I doubt, no one would use multitask like this in normal usage..

  
**Now for the hacking proper**  
  
**Removing the J2ME Security Wall **  
**You'll need the following:**  

1.  USB Cable, i used CA-101D Nokia Cable
2.  JAF V1.98.62: [http://www.mediafire.com/?31nnaojlw1d](http://www.mediafire.com/?31nnaojlw1d)
3.  OGM JAF Pkey Emulator V5: [http://www.mediafire.com/?i5jnoj4wgqe](http://www.mediafire.com/?i5jnoj4wgqe)
4.  Nokia Cable Driver[http://nds1.nokia.com/files/support/global/phones/software/Nokia\_Connectivity\_Cable\_Driver\_eng.msi](http://nds1.nokia.com/files/support/global/phones/software/Nokia_Connectivity_Cable_Driver_eng.msi)
5.  Windows OS PC(the application required are compatible with Windows OS only) 

**Setting it up:**  

*   Download and install JAF V1.98.62
*   Download and install Nokia Cable Driver. 
*   Restart your C3, connect your C3 to your Computer, select OVI Suite Mode, wait till all the drivers are installed. If it ask for drivers, just click cancel.
*   Download OGM JAF Pkey Emulator V5, extract it then Run: Follow this screenshot: 

[![](http://i53.tinypic.com/a3ijyf.jpg) ](http://i53.tinypic.com/a3ijyf.jpg)

 Click the Go Button

*   A promp witll pop up.

[![](http://img293.imageshack.us/img293/4568/2meb1d0c7.jpg)](http://img293.imageshack.us/img293/4568/2meb1d0c7.jpg)

  
Just click the OK Button

  

*   You'll then be presented with the JAF Main Window.

[![](https://lh6.googleusercontent.com/-pAZJF43dJc0/TXj7XAjlonI/AAAAAAAAAEE/B8UeAeni_h8/s320/3mc5f6b81.jpg) ](https://lh6.googleusercontent.com/-pAZJF43dJc0/TXj7XAjlonI/AAAAAAAAAEE/B8UeAeni_h8/s1600/3mc5f6b81.jpg)

Just follow screenshot. First click the BB5 Tab, then check the following checkboxes, the one highlighted in Red, then click the Service button. Just Click the image to view its full resolution.

  

*   After that a file save prompt will appear, just save the PP in your Desktop for easier access.
*   Now open the PP you just saved in your Desktop with Notepad.
*   It will look like this:

> \[Product Profile RM-614\_354xxxxxxxxxxxx\]  
> SETS 1  
> ELEMENTS 2  
>   
> SET 1  
> 0 31  
> 1 0

*   Now Edit it, add 48 2 just after SET 1 so it will look like this:
*   Note: It must be right after SET 1, or else it'll not work.

> \[Product Profile RM-614\_354xxxxxxxxxxxx\]  
> SETS 1  
> ELEMENTS 2  
>   
> SET 1  
> 48 2  
> 0 31  
> 1 0

  

*   Save the PP, just press CTRL+S in notepad.
*   Back on the JAF Main Window, Follow this screenshot.

[![](https://lh6.googleusercontent.com/-Zp1osG6mW1s/TXj9TXPww1I/AAAAAAAAAEI/i7GTSoJ5kDc/s320/7mc1045de.jpg)](https://lh6.googleusercontent.com/-Zp1osG6mW1s/TXj9TXPww1I/AAAAAAAAAEI/i7GTSoJ5kDc/s1600/7mc1045de.jpg)

*   It will ask you for a PP file, just browse and select the PP you just saved in your Desktop.

[![](https://lh6.googleusercontent.com/-Bh0RhZ7n-oY/TXj9vitrOaI/AAAAAAAAAEM/XXCm1DDTYvo/s320/8m0fd8d15.jpg)](https://lh6.googleusercontent.com/-Bh0RhZ7n-oY/TXj9vitrOaI/AAAAAAAAAEM/XXCm1DDTYvo/s1600/8m0fd8d15.jpg)

  

*   It will start flashing your phone like so.

[![](https://lh5.googleusercontent.com/-LGsB_6-JJfY/TXj-DemzQyI/AAAAAAAAAEQ/Ae66TmkQIl4/s1600/9md996e41.jpg)](https://lh5.googleusercontent.com/-LGsB_6-JJfY/TXj-DemzQyI/AAAAAAAAAEQ/Ae66TmkQIl4/s1600/9md996e41.jpg)

  

*   During the flashing process, it will turn your Phone into Test Mode, after the flashing just select Normal mode in the JAF Windows, Phone Model Box.
*   Whoala! Your done! Now you now have a Hacked Nokia C3. This also works on other S40 v5/v6.

For more info, visit here: [http://symbianize.com/showthread.php?t=171486](http://symbianize.com/showthread.php?t=171486)  
  
**Note: Ive tested in on v4.45 Nokia C3 and no success. It only worked on my Nokia C3 v7.25. So if it doesnt work on youre C3, try upgrading your firmware to v7.25.**  
  
**Now your done with the hacking, now its time for the modding:**  
\-Modding the J2ME application to be able to be minimized.  
  
You'll need the following:  

1.  Winrar - [http://www.rarlab.com/](http://www.rarlab.com/)
2.  JAR of the J2ME application.

Steps:  

1.  Open the Jar(eg. operamini.jar) with Winrar.
2.  In the winrar browser/window, open the META-INF Folder.
3.  Inside it, theres a MANIFEST.MF file, just drag/extract it to your desktop. Do not close winrar.
4.  Go to your Desktop and Open MANIFEST.MF with Notepad.
5.  Add this **Nokia-MIDlet-no-exit: true** on the end line of the MANIFEST.MF.

Example:  
Original MANIFEST.MF:  

> Manifest-Version: 1.0  
> MicroEdition-Configuration: CLDC-1.0  
> MIDlet-Name: Call Cheater Manager  
> MIDlet-Info-URL: www.eamobile.tk  
> MIDlet-Icon: /icons/icono.png  
> MIDlet-Delete-Confirm: visit www.eamobile.tk  
> MIDlet-Vendor: EAMobile-Xavi  
> MIDlet-1: Call Cheater Manager, /icons/icono.png, c.c  
> MIDlet-Version: 1.1  
> MicroEdition-Profile: MIDP-2.0  
> Nokia-MIDlet-no-exit: True

Add **Nokia-MIDlet-no-exit: true **to the last line:  

> Manifest-Version: 1.0  
> MicroEdition-Configuration: CLDC-1.0  
> MIDlet-Name: Call Cheater Manager  
> MIDlet-Info-URL: www.eamobile.tk  
> MIDlet-Icon: /icons/icono.png  
> MIDlet-Delete-Confirm: visit www.eamobile.tk  
> MIDlet-Vendor: EAMobile-Xavi  
> MIDlet-1: Call Cheater Manager, /icons/icono.png, c.c  
> MIDlet-Version: 1.1  
> MicroEdition-Profile: MIDP-2.0  
> Nokia-MIDlet-no-exit: True  
> **Nokia-MIDlet-no-exit: true**

Now save it.  
  
Then drag the modified MANIFEST.MF in to the Winrar Window, make sure you drag it inside the META-INF Folder. A replace prompt will appear, just click yes.  
  
Now copy your modded jar file to your C3, do this to all your app and you'll be multi tasking in no time.  
  
Heres the Fun Part!   

Once youve installed the modded apps on your hacked C3. And you want to try the multitasking, all you have to do is open a modded app, then to minimize it, just press the **red call button/cancel call button**, then you can open another app.. Now to maximize an app, just run the app again and you'll continue where you left off on that app.

  
  
Enjoy!  
  
  

**Heres some apps ive modded for multitasking, latest version of Operamini, Snaptu, SHmessenger, TTpod with my Own 320x240 mod, etc. **[http://www.mediafire.com/?8kw24e45cxjj2so](http://www.mediafire.com/?8kw24e45cxjj2so)

LABELS: [C3](http://earlychicken.blogspot.com/search/label/c3), [DOWNLOADS](http://earlychicken.blogspot.com/search/label/downloads), [MODS](http://earlychicken.blogspot.com/search/label/mods), [NOKIA](http://earlychicken.blogspot.com/search/label/nokia), [TIPS](http://earlychicken.blogspot.com/search/label/tips), [TUTORIALS](http://earlychicken.blogspot.com/search/label/tutorials)

*   [Disqus](http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html#)
    

*   [Like](http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html#)
*   [Dislike](http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html# "I don't like this page")

[Login](http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html#)

### Add New Comment

![](http://mediacdn.disqus.com/1329444752/images/noavatar32.png)

*   Post as …
*   Image
    

                        Sort by popular now                                Sort by best rating                                Sort by newest first                                Sort by oldest first                  

### Showing 0 comments

*   [M _Subscribe by email_](http://earlychicken.blogspot.com/2011/03/nokia-c3-multitasking-run-multiple-apps.html#)
*   [S _RSS_](http://earlychicken.disqus.com/earlychicken_nokia_c3_multitasking_run_multiple_apps_tutorial_99/latest.rss)

[Newer Post](http://earlychicken.blogspot.com/2011/03/ttpod-v150-j2me-320x240-edition.html "Newer Post")[Older Post](http://earlychicken.blogspot.com/2011/03/crysis-2-multiplayer-demo-impressions.html "Older Post")[Home](http://earlychicken.blogspot.com/)

  

© 2010