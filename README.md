# HT6022_OSX

A quickly-done HT6022 user interface for the OSX.

![UI screenshot](/screenshots/ht6022-1.png "UI screenshot")

## Features
- Few and far between at the moment =)
- It displays CH1 and CH2 as yellow / blue graph.
- Some trigger/offset capability
- Channel voltage selection
- Resolution selection
- Calibration (post-read)

## Requirements
- libusb 1.0
 - I got it from HomeBrew (http://brew.sh)
 - To install libusb, run --> brew install libusb

## Calibration
- Turn your HT6022 on, and let it sit for a few minutes to heat up.
- Connect your probes as shown in the photo. Set them to 1X.
- Press the little "C" button beside each channel.
- Done! The graph on the display is adjusted by manipulating data after it is read from device.
![Calibration Photo](/screenshots/calibration.jpg "Calibration Photo")

## Credits
- Many thanks to rpm2003rpm for the libusb driver. I'm very glad to have this working on OSX!
