--[[

██████╗ ██╗   ██╗██████╗  ██████╗     ██████╗ ███████╗ ██████╗ ██████╗ ██╗██╗         ██╗   ██╗██████╗     ██████╗ 
██╔══██╗██║   ██║██╔══██╗██╔════╝     ██╔══██╗██╔════╝██╔════╝██╔═══██╗██║██║         ██║   ██║╚════██╗   ██╔═████╗
██████╔╝██║   ██║██████╔╝██║  ███╗    ██████╔╝█████╗  ██║     ██║   ██║██║██║         ██║   ██║ █████╔╝   ██║██╔██║
██╔═══╝ ██║   ██║██╔══██╗██║   ██║    ██╔══██╗██╔══╝  ██║     ██║   ██║██║██║         ╚██╗ ██╔╝██╔═══╝    ████╔╝██║
██║     ╚██████╔╝██████╔╝╚██████╔╝    ██║  ██║███████╗╚██████╗╚██████╔╝██║███████╗     ╚████╔╝ ███████╗██╗╚██████╔╝
╚═╝      ╚═════╝ ╚═════╝  ╚═════╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝      ╚═══╝  ╚══════╝╚═╝ ╚═════╝ 
  Written by LJ -> https://github.com/LukaRic7/PUBG-Logitech-AimFix

--]]

-- Mouse key that toggles the recoil control.
local toggle_key = 8

-- Mouse key that cycles to the next weapon recoil control.
local cycle_next_key = 7

-- Stop recoil control when the magazine is empty.
local auto_stop_recoil = true

-- Use this to get verbose console output.
local verbose_console = false

-- Ordered weapon cycle, default weapon is the first in the row.
local weapon_cycle = {  }

-- Profile list, add more if needed, even if they aren't used.
local user_profiles = {

}



--[[
  ___ ___ ___ ___ ___ _      _    ___   ___ ___ ___ 
 | _ \ __/ __/ _ \_ _| |    | |  / _ \ / __|_ _/ __|
 |   / _| (_| (_) | || |__  | |_| (_) | (_ || | (__ 
 |_|_\___\___\___/___|____| |____\___/ \___|___\___|
   Dont fucking touch.
--]]

-- ==============================
-- SECTION 1: Helper Functions
-- ==============================

-- Store the last log timestamp for calculating delta times
local last_log_time = GetRunningTime()

--[[
DebugLog: Prints formatted information to the console with timestamps
#Params
 :message -> The message to be printed
 :*args -> Additional formatting arguments
--]]
function DebugLog(message, ...)
  -- Calculate delta, and update last log time
  local now = GetRunningTime()
  local delta = now - last_log_time
  last_log_time = now

  -- Convert now from ms to HH:MM:SS
  local total_seconds = math.floor(now / 1000)
  local ms = now % 1000
  local hours = math.floor(total_seconds / 3600)
  local minutes = math.floor((total_seconds % 3600) / 60)
  local seconds = total_seconds % 60

  -- Create timestamp string
  local timestamp = string.format("[%02d:%02d:%02d +%d]", hours, minutes, seconds, delta)
  if select("#", ...) > 0 then
      message = string.format(message, ...)
  end
  
  -- Log the message to console
  OutputLogMessage("%s %s\n", timestamp, message)
end

--[[
VerifyAndInitialize: Verifies user config and initializes profiles and weapon cycle
--]]
function VerifyAndInitialize()
    if verbose_console then
      DebugLog("Verifying and initializing")
    end

  -- Loop through user defined profiles and append them to the controller
  for i, obj in ipairs(user_profiles) do
    Controller:add_profile(obj)
  end
  
  -- Check if all weapons in the cycle exists in the controller
  for i, name in ipairs(weapon_cycle) do
    if not Controller.profiles[name] then
      DebugLog("WARNING: Profile '%s' in weapon cycle does not exist!", name)
    end
  end
end

--[[
Class: Provides a simple way to create classes with :new() and :init()
--]]
function Class()
  if verbose_console then
    DebugLog("Creating class")
  end
    
  local cls = {}
  cls.__index = cls
  
  function cls:new(obj)
    -- Use provided or empty table
    obj = obj or {}
    
    -- Set metatable so methods can be colon-called
    setmetatable(obj, self)
    
    -- Call init() function if defined
    if obj.init then obj:init() end
    
    return obj
  end
  
  return cls
end

-- ==============================
-- SECTION 2: Weapon Profile Class
-- ==============================

-- Weapon profile class: Stores individual weapon characteristics
WeaponProfile = Class()

--[[
WeaponProfile:init(): Initialize the weapon profile
--]]
function WeaponProfile:init()
  -- Check if the weapon type is DMR
  if self.type == "DMR" then
    self.time_per_bullet = self.fire_delay
  else
    -- Full auto weapons
    self.time_per_bullet = self.dump_time / self.mag_size
  end
end

--[[
WeaponProfile:recoil(): Calculate recoil for a given shot number
#Params
  :shot_number -> Current shot fired after starting to shoot
--]]
function WeaponProfile:recoil(shot_number)
  -- If the weapon is a DMR, use constant
  if self.type == "DMR" then
    return self.recoil_y
  end

  -- Exponential recoil compensation formula
  return self.recoil_min
    + (self.recoil_max - self.recoil_min)
    * (1 - math.exp(-self.recoil_growth * shot_number))
end

-- ==============================
-- SECTION 3: Recoil Controller Class
-- ==============================

-- Recoil controller class: Manages all profiles, toggling, and recoil loops
RecoilController = Class()

--[[ 
RecoilController:init(): Initialize the controller
--]]
function RecoilController:init()
  self.enabled = false
  self.current_index = 1
  self.profiles = {}
  self.cycle_order = weapon_cycle
  self.current_profile = nil
end

--[[ 
RecoilController:add_profile(): Add a new weapon profile to the controller
#Params
 :tbl -> Table containing weapon stats (name, mag_size, dump_time, recoil_min/max/growth)
--]]
function RecoilController:add_profile(tbl)
  -- Verify the profile has a name
  if not tbl.name then
    DebugLog("ERROR: Profile missing name")
    return
  end
  
  -- Check for duplicate weapon name
  if self.profiles[tbl.name] then
    DebugLog("ERROR: Duplicate profile name '%s'", tbl.name)
    return
  end

  -- Create a WeaponProfile object
  local profile = WeaponProfile:new(tbl)
  
  -- Store it in the profiles table, keyed by weapon name
  self.profiles[profile.name] = profile

  -- If no profile is currently active, set this as the first active profile
  if not self.current_profile then
    self.current_profile = profile
  end
end

--[[ 
RecoilController:next_profile(): Cycle to the next weapon profile in cycle_order (wraps around)
--]]
function RecoilController:next_profile()
  -- Return early if no weapons are in the cycle
  if #self.cycle_order == 0 then return end
  
  -- Increment index and wrap around if necessary
  self.current_index = self.current_index % #self.cycle_order + 1
  
  -- Get weapon name and update current profile
  local name = self.cycle_order[self.current_index]
  self.current_profile = self.profiles[name]
  
  -- Log the change
  DebugLog("Switched -> %s%s", name, self.current_profile.type == "DMR" and " (DMR)" or "")
end

--[[ 
RecoilController:toggle(): Toggle recoil control ON/OFF
--]]
function RecoilController:toggle()
  -- Toggle and log
  self.enabled = not self.enabled
  DebugLog("RC: %s", self.enabled and "Enabled" or "Disabled")
end

--[[ 
RecoilController:run(): Main loop that applies recoil compensation
--]]
function RecoilController:run()
  -- Return if RC is disabled or no current profile exists
  if not self.enabled or not self.current_profile then return end

  -- Create local variables
  local profile = self.current_profile
  local shot_count = 0
  
  -- >>> DMR MODE <<< --
  if profile.type == "DMR" then
    for i=1, profile.burst_count do      
      -- Fire one shot
      PressMouseButton(1)
      Sleep(10)
      ReleaseMouseButton(1)
      
      -- Apply recoil
      MoveMouseRelative(0, profile.recoil_y)
      
      -- Enforce fire-rate
      Sleep(profile.fire_delay)
    end
    
    -- Make sure not to enter AR mode
    return
  end
  
  -- >>> AR MODE <<< --
  local start = GetRunningTime()

  -- Loop while left mouse button is held down
  while  IsMouseButtonPressed(1) do
    -- Time since shooting started
    local elapsed = GetRunningTime() - start
    
    -- Compute bullet number based on timing
    shot_count = elapsed / profile.time_per_bullet

    -- Auto-stop if magazine is empty
    if auto_stop_recoil and shot_count >= profile.mag_size then
      break
    end
    
    -- Calculate vertical mouse movement for current shot
    local y = math.floor(profile:recoil(math.ceil(shot_count)))
    
    -- Apply movement, and sleep to control loop rate
    MoveMouseRelative(0, y)
    Sleep(20)
  end
end

-- ==============================
-- SECTION 4: Event Handler
-- ==============================

-- Enable Logitech mouse button events
EnablePrimaryMouseButtonEvents(true)

--[[
OnEvent: Handles Logitech mouse events
#Params
  :event -> Event name
  :arg -> Mouse button number or key code
--]]
function OnEvent(event, arg)
  DebugLog("Event: %s %i", event, arg)

  -- Stop recoil if the profile is deactivated
  if event == "PROFILE_DEACTIVATED" then
    if verbose_console then
      DebugLog("Profile deactivated")
    end
    ReleaseMouseButton(1)
    return
  end
  
  -- Toggle recoil control ON/OFF
  if event == "MOUSE_BUTTON_PRESSED" and arg == toggle_key then
    if verbose_console then
      DebugLog("Toggle key pressed")
    end
    Controller:toggle()
  end

  -- Cycle to next weapon profile
  if event == "MOUSE_BUTTON_PRESSED" and arg == cycle_next_key then
    if verbose_console then
      DebugLog("Cycle key pressed")
    end
    Controller:next_profile()
  end

  -- Run recoil loop while left mouse button is pressed
  if event == "MOUSE_BUTTON_PRESSED" and arg == 1 then
    if verbose_console then
      DebugLog("Primary button pressed")
    end
    Controller:run()
  end

  if event == "MOUSE_BUTTON_RELEASED" and arg == 1 then
    if verbose_console then
      DebugLog("Primary button released")
    end
  end
end

-- Lift off!
Controller = RecoilController:new()
VerifyAndInitialize()