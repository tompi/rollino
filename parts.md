Parts list
==========

Everything for one Rollino; quantities are totals (it has two sensor boards).
The case itself (`body` and `base_cover` in `case/rollino.scad`) is printed.

PCBs
----

| Qty | Board | Notes |
|-----|-------|-------|
| 2 | sensor board (`pcb/sensor/`) | 2 layers, 1.6 mm FR4; has a cutout for the lens |
| 1 | base board (`pcb/base/`) | 2 layers, 1.6 mm FR4; has a cutout for the XIAO's parts |

0.2 mm tracks, 0.15 mm clearance, 0.3 mm drills: any fab's standard process.
Both have a bare-copper logo, so pick ENIG (or HASL) rather than bare copper
finish.

Electronics
-----------

| Qty | Part | Where | Notes |
|-----|------|-------|-------|
| 1 | Seeed XIAO nRF52840 (not Sense) | base U1 | soldered upside down by its edge pads |
| 2 | PixArt PMW3610DM-SUDU | sensor U1 | |
| 2 | LM18-LSI lens | under each PMW3610 | the PMW3610's lens; often sold with it |
| 2 | TI TPS7A0518PDBVR (1.8 V LDO, SOT-23-5) | sensor U2 | |
| 4 | Hirose FH12-6S-0.5SH(55) (or JUSHUO AFC01-S06FCA) | sensor J1, base J1/J2 | 6-pin, 0.5 mm FPC connector |
| 2 | 6-way FFC, 0.5 mm pitch, 50 mm, **opposite-side (type B) contacts** | sensor to base | for 0.3 mm thick FPC connectors (FH12); 50 mm is the stock length |
| 1 | LiPo 602020, about 200 mAh, with protection board | on the XIAO's back | up to 22 x 20 x 6.5 mm; leads solder to the XIAO's battery pads |

Passives, all 0603, for both sensor boards together (10 V or more):

| Qty | Value | Where (on each sensor board) |
|-----|-------|------------------------------|
| 6 | 100 nF X7R | C2, C3, C4 |
| 4 | 10 nF X7R | C5, C7 |
| 4 | 1 uF | C8, C9 |
| 2 | 3.3 uF | C1 |
| 2 | 10 uF X7R | C6 |
| 2 | 10 k resistor | R1 |

Optional: up to three momentary switches for left, middle and right click,
wired from the base board's TP1-TP3 pads to TP4 (GND).

Mechanical
----------

| Qty | Part | Notes |
|-----|------|-------|
| 1 | 55 mm trackball ball | the size Kensington's trackballs use (Expert Mouse, SlimBlade), sold as replacements |
| 3 | 3 mm ceramic bearing balls (ZrO2 or Si3N4) | the ball's supports; get a few spares |
| 4 | M2 x 8 countersunk thread-forming screws for plastic | through the cover and base board into the case |
| 2 | M2 x 6 thread-forming screws for plastic, low (pan or wafer) head | one through each sensor board's ear |

Screw lengths are from the model: the cover and base board are 5.2 mm
together, with 4.5 mm pilot holes above them; each sensor board is 1.6 mm,
with a 5 mm pilot hole behind it.
