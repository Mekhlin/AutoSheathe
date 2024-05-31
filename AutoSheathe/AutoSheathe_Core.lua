local gameEvents = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "LOOT_OPENED",
    "LOOT_CLOSED",
    "UNIT_EXITED_VEHICLE",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_FLAGS_CHANGED"
}

local buffVehicles = {
    ["Rocfeather Skyhorn Kite"] = true,
    ["Goblin Glider"]           = true,
    ["Zen Flight"]              = true,
    ["Tiki Army"]               = true
}

-- Create and initialize addon
AutoSheathe = LibStub("AceAddon-3.0"):NewAddon("AutoSheathe", "AceTimer-3.0")
eventFrame = CreateFrame("FRAME", "AutoSheatheEventFrame")

function AutoSheathe:OnInitialize()
    
    defaultOptions = AutoSheathe:GetDefaultOptions()
    self.db = LibStub("AceDB-3.0"):New("AutoSheatheDB", defaultOptions)

    self:LoadOptions()
    self:RegisterGameEvents()
end

function AutoSheathe:OnEnable()
    if not AutoSheathe.db.profile.enabled then
        return
    end

    startTimer()
end

function AutoSheathe:OnDisable()
    if AutoSheathe.db.profile.enabled then
        return
    end

    destroyExistingTimer();
end

function AutoSheathe:LoadOptions()
    options = AutoSheathe:GetOptions()

    local aboutOptions = {
        name = "About",
        type = "group",
        args = {
                addon_version = {
                    type = "description",
                    order = 1,
                    name = function(info) return "AutoSheathe v" .. GetAddOnMetadata("AutoSheathe", "Version") end
                },
                github = {
                    type = "description",
                    order = 2,
                    name = function(info) return "https://github.com/Mekhlin/AutoSheathe" end
                }
            }
        }

    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")

    config:RegisterOptionsTable("AutoSheathe", options)
    dialog:AddToBlizOptions("AutoSheathe", "AutoSheathe")

    profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    config:RegisterOptionsTable("AutoSheathe-Profiles", profileOptions)
    dialog:AddToBlizOptions("AutoSheathe-Profiles", "Profiles", "AutoSheathe")

    config:RegisterOptionsTable("AutoSheathe-About", aboutOptions)
    dialog:AddToBlizOptions("AutoSheathe-About", "About", "AutoSheathe")
end

function AutoSheathe:RegisterGameEvents()
    eventFrame:UnregisterAllEvents();

    for i, event in ipairs(gameEvents) do
        eventFrame:RegisterEvent(event)
    end

    eventFrame:SetScript("OnEvent", function (frame, event, first, second)
        handleWeapon()
  	end)
end

-- This is where the magic happens!
function handleWeapon()
    if not AutoSheathe.db.profile.enabled then
        return
    end

    infight = UnitAffectingCombat("player")
    if infight then
        if canDrawWeapon() then
            ToggleSheath()
            return
        else
            return
        end
    end

    sheathState = GetSheathState()

    if AutoSheathe.db.profile.city_sheathe then
        if IsResting() and sheathState == 2 then
            ToggleSheath()
            return
        end
    end

    if AutoSheathe.db.profile.afk_sheathe then
        if UnitIsAFK("player") and sheathState == 2 then
            ToggleSheath()
            return
        end
    end

    if AutoSheathe.db.profile.sheath_state == 2 and canDrawWeapon() then
        ToggleSheath()
        return
    elseif AutoSheathe.db.profile.sheath_state == 1 and canSheatheWeapon() then
        ToggleSheath()
        return
    end
end

function inVehicle()
    if UnitInVehicle("player") then
        return true
    end

    for i = 1, 40 do
        local name, _, _, _, _, _ = UnitBuff("player",i)
        if name and buffVehicles[name] then
            return true
        end
    end
    return false
end

function canSheatheWeapon()
    if GetSheathState() == 1 then
        return false
    end

    if IsResting() and AutoSheathe.db.profile.city_sheathe then
        return true
    end
    
    if UnitIsAFK("player") and AutoSheathe.db.profile.afk_sheathe then
        return true
    end

    if UnitAffectingCombat("player") then
        return false
    end

    if inVehicle() then
        return true
    end

    return true
end

function canDrawWeapon()
    if GetSheathState() == 2 then
        return false
    end

    if UnitAffectingCombat("player") and AutoSheathe.db.profile.auto_draw then
        return true
    end

    if IsSwimming() then
        return false
    end

    if IsMounted() or inVehicle() then
        return false
    end

    -- Player is in a city or near an innkeeper.
    if IsResting() and AutoSheathe.db.profile.city_sheathe then
        return false
    end
    
    -- Player is AFK.
    if UnitIsAFK("player") and AutoSheathe.db.profile.afk_sheathe then
        return false
    end

    return true
end

function startTimer()
  destroyExistingTimer()
  AutoSheathe.Timer = AutoSheathe:ScheduleRepeatingTimer("TimerFeedback", 2)
end

function destroyExistingTimer()
	if (not (AutoSheathe.Timer == nil)) then
  	AutoSheathe:CancelTimer(AutoSheathe.Timer)
    AutoSheathe.Timer = nil
  end
end

function AutoSheathe:TimerFeedback()
    handleWeapon()
end