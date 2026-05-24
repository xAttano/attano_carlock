Config = {}

Config.TargetSupport = true

Config.TargetIcon = 'fa-solid fa-lock'

Config.ProgressLength = 850

Config.CheckRadius = 5.0

Config.CommandOnLock = 'me Locking vehicle'
Config.CommandOnUnlock = 'me Unlocking vehicle'

Config.Sounds = true
Config.Horn = true
Config.Lights = true

Config.Notifications = {
    Locked = true,
    Unlocked = true,
    NotYourVehicle = true,
    NoNearbyVehicles = true,
    LockpickSuccess = true,
    LockpickFailed = true,
    HotwireSuccess = true,
    HotwireFailed = true,
    AlreadyHasKey = true,
    NeedLockpick = true,
    VehicleAlreadyUnlocked = true,
    MustBeDriver = true
}

Config.DisableControls = {
    VehicleMovement = false,
    PlayerMovement = true,
    Combat = true
}

Config.KeyFobAnimation = {
    dict = 'anim@mp_player_intmenu@key_fob@',
    clip = 'fob_click_fp'
}

Config.RequireKeyToStart = true

Config.LockpickItem = 'lockpick'
Config.RemoveLockpickOnFail = true
Config.LockpickBreakChance = 35

Config.LockpickTime = 5000
Config.HotwireTime = 8000

Config.LockpickSkillcheck = { 'easy', 'easy', 'medium' }
Config.HotwireSkillcheck = { 'easy', 'easy', 'medium', 'medium' }

Config.AllowLockpickNPCVehicles = true
Config.AllowHotwireNPCVehicles = true
Config.LockpickAllowIfUnlocked = false

Config.HotwiredKeysAreTemporary = true

Config.HotwireKey = 51
Config.LockpickKeybind = 'z'

Config.Locale = {
    ProgressLocking = "Locking...",
    ProgressUnlocking = "Unlocking...",
    ProgressLockpicking = "Lockpicking vehicle...",
    ProgressHotwiring = "Hotwiring vehicle...",

    TargetLabel = "Lock/Unlock Vehicle",
    HotwirePrompt = "[E] Hotwire vehicle",

    NotifyTitle = "Attano Car Lock",
    NotifyLocked = "You have locked your vehicle.",
    NotifyUnlocked = "You have unlocked your vehicle.",
    NoVehicleNearby = "There are no nearby vehicles.",
    NotOwned = "This vehicle does not belong to you.",
    LockedWhileInside = "You cannot exit while the vehicle is locked.",
    LockpickSuccess = "Vehicle unlocked.",
    LockpickFailed = "Lockpicking failed.",
    HotwireSuccess = "Vehicle hotwired.",
    HotwireFailed = "Hotwiring failed.",
    AlreadyHasKey = "You already have the keys.",
    NeedLockpick = "You need a lockpick.",
    VehicleAlreadyUnlocked = "This vehicle is already unlocked.",
    MustBeDriver = "You must be in the driver seat."
}
