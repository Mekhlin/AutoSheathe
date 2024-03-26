local gameEvents = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_REGEN_ENABLED",
    "LOOT_CLOSED",
    "AUCTION_HOUSE_CLOSED",
    "UNIT_EXITED_VEHICLE",
    "BARBER_SHOP_CLOSE",
    "PLAYER_ENTERING_WORLD",
    "QUEST_ACCEPTED",
    "QUEST_FINISHED",
    "MERCHANT_CLOSED"
}

local buffVehicles = {
    ["Rocfeather Skyhorn Kite"] = true,
    ["Goblin Glider"]           = true,
    ["Zen Flight"]              = true,
    ["Bronze Racer's Pennant"]  = true
}

-- Create and initialize addon
AutoSheathe = LibStub("AceAddon-3.0"):NewAddon("AutoSheathe", "AceTimer-3.0", "AceConsole-3.0")
eventFrame = CreateFrame("FRAME", "AutoSheatheEventFrame")

function AutoSheathe:OnInitialize()
    defaults = {
        profile = {
            enabled = true,
            sheath_state = 1,
            auto_draw = false,
            city_sheathe = false
        }
    }

    AutoSheathe.db = LibStub("AceDB-3.0"):New("AutoSheatheDB", defaults, true)
    AutoSheathe.db.RegisterCallback(AutoSheathe, "OnProfileChanged", "OnProfileChanged")
	AutoSheathe.db.RegisterCallback(AutoSheathe, "OnProfileReset", "OnProfileChanged")

    createBlizzOptions()
    registerGameEvents()

    self:RegisterChatCommand("as", "slashfunc")
end

function AutoSheathe:OnEnable()
    startSheatheTimer()
end

function createconfig()
    local function get(info)
        return AutoSheathe.db.profile[info.arg]
    end

    local function set(info, val)
        local arg = info.arg
        AutoSheathe.db.profile[arg] = val
    end

    local options = {
        name = "|cff9d875fAutoSheathe|r",
        type = "group",
        args = {
            enabled = {
                type = "toggle",
                order = 0,
                name = "Enable",
                desc = "Enable or disable AutoSheathe",
                set = function(info, val)
                    AutoSheathe.db.profile.enabled = val
                    if arg == "city_sheathe" then
                        handleWeaponSheathe()
                    end
                end,
                get = function(info) return AutoSheathe.db.profile.enabled end
            },
            basic_options = {
                type = "group",
                order = 10,
                name = "Basic",
                inline = true,
                get = get,
                set = set,
                disabled = function() return not AutoSheathe.db.profile.enabled end,
                args = {
                    basic_info = {
                        type = "description",
                        order = 10,
                        name = "Basic options for AutoSheathe"
                    },
                    sheath_state = {
                        type = "select",
                        order = 20,
                        name = "Keep weapon",
                        desc = "Select sheath state",
                        values = {
                            [1] = "Sheathed",
                            [2] = "Unsheathed"
                        },
                        arg = "sheath_state"
                    }
                }
            },
            conditions = {
                name = "Conditions",
                type = "group",
                order = 20,
                inline = true,
                get = get,
                set = set,
                disabled = function() return not AutoSheathe.db.profile.enabled end,
                args = {
                    auto_draw = {
                        type = "toggle",
                        order = 1,
                        name = "Auto draw weapon",
                        desc = "Unsheathe weapon when attacked",
                        disabled = function() return AutoSheathe.db.profile.sheath_state == 2 end,
                        arg = "auto_draw"
                    },
                    city_sheathe = {
                        type = "toggle",
                        order = 2,
                        name = "Stay sheathed in cities",
                        desc = "Keep weapon sheathed when in cities or near an innkeeper",
                        disabled = function() return AutoSheathe.db.profile.sheath_state == 1 end,
                        arg = "city_sheathe"
                    }
                }
            },
            reset_profile = {
                type = "execute",
                order = -1,
                name = "Defaults",
                desc = "Resets profile to default values",
                func = function() AutoSheathe.db:ResetProfile() end,
                disabled = function() return not AutoSheathe.db.profile.enabled end,
            }
        }
    }

    return options
end

function createBlizzOptions()
    options = createconfig()

    local aboutOptions = {
        name = "About",
        type = "group",
        args = {
                version = {
                    name = function(info) return "Version: " .. GetAddOnMetadata("AutoSheathe", "Version") end,
                    type = "description"
                }
            }
        }

    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")

    config:RegisterOptionsTable("AutoSheathe", options)
    dialog:AddToBlizOptions("AutoSheathe", "AutoSheathe")

    profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(AutoSheathe.db)
    config:RegisterOptionsTable("AutoSheathe-Profiles", profileOptions)
    dialog:AddToBlizOptions("AutoSheathe-Profiles", "Profiles", "AutoSheathe")

    config:RegisterOptionsTable("AutoSheathe-About", aboutOptions)
    dialog:AddToBlizOptions("AutoSheathe-About", "About", "AutoSheathe")
end

function registerGameEvents()
    eventFrame:UnregisterAllEvents();

    for i, event in ipairs(gameEvents) do
        eventFrame:RegisterEvent(event)
    end

    eventFrame:SetScript("OnEvent", function (frame, event, first, second)
        handleWeaponSheathe()
  	end)
end

function handleWeaponSheathe()
    if not AutoSheathe.db.profile.enabled then
        return
    end

    infight = UnitAffectingCombat("player")
    if infight then
        if canUnsheatheWeapon() then
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

    if AutoSheathe.db.profile.sheath_state == 2 and canUnsheatheWeapon() then
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

    if UnitAffectingCombat("player") then
        return false
    end

    if inVehicle() then
        return true
    end

    return true
end

function canUnsheatheWeapon()
    if GetSheathState() == 2 then
        return false
    end

    if UnitAffectingCombat("player") and AutoSheathe.db.profile.auto_draw then
        return true
    end

    -- If player is mounted or affexted by "vehicle buff".
    if IsMounted() or inVehicle() then
        return false
    end

    -- Player is in a city or near an innkeeper.
    if IsResting() and AutoSheathe.db.profile.city_sheathe then
        return false
    end

    return true
end

function startSheatheTimer()
  destroyExistingSheatheTimer()
  AutoSheathe.Timer = AutoSheathe:ScheduleRepeatingTimer("OnSheatheTimerFeedback", 2)
end

function destroyExistingSheatheTimer()
	if (not (AutoSheathe.Timer == nil)) then
  	AutoSheathe:CancelTimer(AutoSheathe.Timer)
    AutoSheathe.Timer = nil
  end
end

function AutoSheathe:OnSheatheTimerFeedback()
  handleWeaponSheathe()
end

function AutoSheathe:slashfunc(input)
    if Settings then
        Settings.OpenToCategory("AutoSheathe")
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("AutoSheathe")
    end
end

function AutoSheathe:OnProfileChanged(event, database, newProfileKey)
    handleWeaponSheathe()
end