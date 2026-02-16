-- Weapon cycle
local weapon_cycle = {
-- {{  5.56 NATO   }} --
  --"M416 RD"
  --"AUG RD",
  --"G36C RD",

-- {{ NON-FULLAUTO }} --
  --"Muktant RD",
  "M16A4 Burst 4x", "M16A4 Single 4x" -- Create groups that is easy togglable

-- {{  7.62 NATO   }} --
  "Beryl RD", -- Togglable in cycle using double-dash
  --"AKM RD",
  --"ACE RD",
  
-- {{   9mm NATO   }} --
  "VSS",
  --"MP5K RD",
  "Vector RD",
  --"Bizon 2x", "Bizon 6x",
  
-- {{   SPECIALS   }} --
  "P90", "P90 Zoom",
  --"MG3 RD", "MG3 4x",
  --"GROZA RD",
}

-- User profiles
local user_profiles = {
  -- ###################### --
  {
    type          = "DMR",
    name          = "MK12",
    burst_count   = 3,
    recoil_y      = 37,
    fire_delay    = 170
  },
  -- ###################### --
  {
    name          = "VSS",
    mag_size      = 22,
    dump_time     = 1800,
    recoil_min    = 9,
    recoil_max    = 18,
    recoil_growth = 0.10
  },
  -- ###################### --
  {
    name          = "AUG",
    mag_size      = 40,
    dump_time     = 3800,
    recoil_min    = 4,
    recoil_max    = 14,
    recoil_growth = 0.16
  },
  -- ###################### --
  {
    name          = "MP5K",
    mag_size      = 40,
    dump_time     = 2550,
    recoil_min    = 7,
    recoil_max    = 9,
    recoil_growth = 0.20
  }
  -- ###################### --
}
