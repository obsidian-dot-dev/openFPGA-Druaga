# Tower of Druaga

Analogue Pocket port of Tower of Druaga.

Supports other games using the same board, including:

* Mappy
* Dig-Dug II
* Motos
* Super Pac-Man
* Grobda
* Pac & Pal
* Pac-Man and Chomp Chomp

## Known Issues

* High Score saving doesn't work.
* Dips not supported.
* Video flicker reported for Mappy when played in Dock.

Note:  File bugs for issues you encounter on the Github tracker.  Any issues are most likely with my integration, and not with the cores themselves.  Please do not engage the original core authors for support requests related to this port.

## History 
0.9.3
* Adding additional configs for Pac-man and Chomp Chomp.
* Add coin pulse signal to fix issues with coin input not registering.

0.9.2
* Temporarily disabling dip switches until I can debug them.

0.9.1
* Add support for Super Pac-Man & Grobda
* Add per-game configuration/dip-switches (experimental)
* First tag'd release

0.9.0
* Initial commit

## Attribution

```
---------------------------------------------------------------------------------
-- 
-- Arcade: The Tower of Druaga  port to MiSTer by MiSTer-X
-- 24 October 2019
-- From: https://github.com/MrX-8B/MiSTer-Arcade-Druaga
-- 
---------------------------------------------------------------------------------
-- FPGA Druaga for XILINX Spartan-3
--------------------------------------
-- Copyright (c) 2007 MiSTer-X
---------------------------------------------------------------------------------
-- Cycle-Accurate 6809 Core
-- Revision 1.0 - 13th August 2016
---------------------------------------------------
-- Copyright (c) 2016, Greg Miller
---------------------------------------------------------------------------------
-- 
```

-  Quartus template and core integration based on the Analogue Pocket port of [Donkey Kong by ericlewis](https://github.com/ericlewis/openFPGA-DonkeyKong)

## ROM Instructions

ROM files are not included, you must use [mra-tools-c](https://github.com/sebdel/mra-tools-c/) to convert to singular rom files as described by the various _instance.json_ files, then place the ROM files in `/Assets/druaga/common`.
