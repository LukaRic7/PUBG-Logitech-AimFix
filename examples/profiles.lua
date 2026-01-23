-- Weapon cycle
local weapon_cycle = { "MK12", "VSS", "AUG" }

-- User profiles
local user_profiles = {
  -- ###################### --
  {
      type          = "DMR",
      name          = "MK12",
      mag_size      = 32,
      recoil_y      = 9,
      fire_delay    = 120
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