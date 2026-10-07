Rollino
=======

An attempt to make a cheap, solid and low profile DIY finger trackball.

The ball floats just 1 mm above the table on three ceramic support balls.
Two PMW3610 sensors look up at the ball from below its equator, placed so
their lines of sight are orthogonal (X, Y and twist are all observable).
A Seeed XIAO nRF52840 running ZMK and a 602020 LiPo lie flat in a squashed
dome in front of the ball, behind a lid screwed on from underneath.

![Exploded view](case/renders/exploded.png)

- `case/rollino.scad` - parametric OpenSCAD model (ball size, sensor/MCU
  placement, battery, ...). Set `part` to `assembly`, `exploded`, `hardware`, `section`,
  or `body` / `elec_lid` for printable parts.
- `case/renders/` - preview renders.
- `datasheets/` - component datasheets. The PMW3610 datasheet is available
  [here](https://www.epsglobal.com/Media-Library/EPSGlobal/Products/files/pixart/PMW3610DM-SUDU.pdf?ext=.pdf).
