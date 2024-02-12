# Tower of Druaga

Analogue Pocket port of Tower of Druaga.

Supports other games using the same board, including:

* Mappy
* Dig-Dug II
* Motos

## Known Issues

* High Score saving doesn't work.
* No dips.
* Does not support Super Pac-Man, Pac & Pal, or Grobda.

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
