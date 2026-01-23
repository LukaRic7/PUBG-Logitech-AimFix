# Recoil Controller Profiles

This document explains how to configure weapon profiles.

## Notice

Recoil profiles does NOT have the same results across computers. It's impossible
to compensate for both ingame settings, and hardware settings. Always configure
your own weapons to get the best result.

# Overview

The script uses weapon profiles to manage recoil for different weapons in PUBG.
Each profile contains parameters and information needed for optimal recoil control.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Name of the profile. Can be anything |
| `type` | string | Weapon type. Only used for `DMR` |
| `mag_size` | number | Number of bullets in a full magazine |
| `dump_time` | number (ms) | Time to fire the full magazine |
| `recoil_min` | number | Starting vertical mouse movement |
| `recoil_max` | number | Maximum vertical movement at the end of the magazine |
| `recoil_growth` | number | Growth rate for the recoil curve |
| `burst_count` | number | **Only for DMRs.** Amount of shots when using recoil control on a DMR |
| `recoil_y` | number | **Only for DMRs.** Vertical movement per shot |
| `fire_delay` | number (ms) | **Only for DMRs.** Delay between shots |

> **Note:** Some fields are only used for certain weapon types (DMR)

# How To Tune
1. `type` Only used for DMR. If DMR set it's value to "**DMR**"
2. `name` Be creative, can be anything, used for organization.
3. `mag_size` Use your fucking eyes.
4. `dump_time` To find out the dump time, follow below:
    1. Start shooting at the exact same time as toggling the script.
    2. Right when the magazine is empty, toggle off the script.
    3. Look at the console for the message that looks somewhat like this `[00:00:07 +648] RC: Disabled`
    4. You will see the delta time between messages, here its **648**, that's your magazine dump time.
5. `recoil_min` Only affects the first few bullets!
    1. If bullets jumps too high, increase.
    2. If bullets jumps too low, decrease.
6. `recoil_max` Only affects bullets after the start!
    1. If bullets jump too high, increase.
    2. If bullets jump too low, decrease.
7. `recoil_growth` Small increments works best (approximately 0.05 - 0.2).
    1. If recoil climbs quickly at the start, lower growth (slower ramp-up).
    2. If recoil climbs too slow at first, then jerks at the end, increase growth (faster ramp early).
8. `burst_count` Set this to whatever you want, but 1 or above.
    1. Be aware if it's too high, it will continue until done, you CANNOT stop it.
9. `recoil_y` Only used for DMR. The recoil to compensate for after each shot.
    1. If bullets go down, decrease.
    2. If bullets go up, increase.
10. `fire_delay` Only used for DMR. The delay before being able to shoot the next shot.
    1. If too low, messes up the entire flow.
    2. If too high, safe, but could have more firerate potential.