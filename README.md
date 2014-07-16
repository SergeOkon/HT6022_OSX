# HT6022_OSX
==============

A very quickly-done HT6022 user interface for the OSX.


## Features
- Not much right now!
- It display CH1 and CH2 as yellow / blue graph.
- Some trigger/offset capability
- Channel voltage selection
- Resolution selection


## Missing
- Calibration of any kind.


## Requirements
- Xcode 5
- libusb 1.0
  - I got is view HomeBrew. 
  - It lives in /usr/local/{include,lib}. This is referenced by the project.


## To run
- Get libusr
- Plug in the HT6022
- Open project in Xcode
- Run.

## Credit
Many thanks to rpm2003rpm for the libusb driver. 
HT6022 support on non-windows OS would be a pipe dream without it!
