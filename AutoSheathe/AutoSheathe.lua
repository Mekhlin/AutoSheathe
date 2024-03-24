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

local vehicleBuffs = {
    ["Rocfeather Skyhorn Kite"] = true,
    ["Goblin Glider"]           = true,
    ["Zen Flight"]              = true,
    ["Bronze Racer's Pennant"]  = true
}

-- Create and initialize addon
AutoSheathe = LibStub("AceAddon-3.0"):NewAddon("AutoSheathe", "AceTimer-3.0")
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

    local aboutOptions = {
        name = "About",
        type = "group",
        order = 30,
        inline = true,
        args = {
            version = {
                type = "description",
                name = function(info) return "Version: " .. GetAddOnMetadata("AutoSheathe", "Version") end
            }
        }
    }

    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")

    config:RegisterOptionsTable("AutoSheathe", AutoSheathe:GetOptions())
    config:RegisterOptionsTable("AutoSheathe-About", aboutOptions)

    dialog:AddToBlizOptions("AutoSheathe", "AutoSheathe")
    dialog:AddToBlizOptions("AutoSheathe-About", "About", "AutoSheathe")

    AutoSheathe:RegisterGameEvents()
    registerSlashCommands()
end

function AutoSheathe:OnEnable()
    startSheatheTimer()
end

function AutoSheathe:RegisterGameEvents()
    eventFrame:UnregisterAllEvents();

    for i, event in ipairs(gameEvents) do
        eventFrame:RegisterEvent(event)
    end

    eventFrame:SetScript("OnEvent", function (frame, event, first, second)
        handleWeaponSheathe()
  	end)
end

function AutoSheathe:GetOptions()
    local function get(info)
        return AutoSheathe.db.profile[info.arg]
    end

    local function set(info, val)
        local arg = info.arg
        AutoSheathe.db.profile[arg] = val
    end

    return {
        name = "|cff9d875fAutoSheathe|r",
        type = "group",
        args = {
            enabled = {
                name = "Enable",
                desc = "Enable or disable AutoSheathe",
                type = "toggle",
                order = 0,
                set = function(info, val)
                    AutoSheathe.db.profile.enabled = val
                    if arg == "city_sheathe" then
                        handleWeaponSheathe()
                    end
                end,
                get = function(info) return AutoSheathe.db.profile.enabled end
            },
            basic_options = {
                name = "Basic",
                type = "group",
                order = 10,
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
                        name = "Keep weapon",
                        desc = "Select sheath state",
                        type = "select",
                        order = 20,
                        values = {
                            [1] = "Sheathed",
                            [2] = "Unsheathed"
                        },
                        arg = "sheath_state"
                    }
                }
            },
            sheathe_conditions = {
                name = "Conditions",
                type = "group",
                order = 20,
                inline = true,
                get = get,
                set = set,
                disabled = function() return not AutoSheathe.db.profile.enabled end,
                args = {
                    auto_draw = {
                        name = "Auto draw weapon",
                        desc = "Unsheathe weapon when attacked",
                        type = "toggle",
                        order = 1,
                        disabled = function() return getConfigSheathState() == 2 end,
                        arg = "auto_draw"
                    },
                    city_sheathe = {
                        name = "Stay sheathed in cities",
                        desc = "Keep weapon sheathed when in cities or near an innkeeper",
                        type = "toggle",
                        order = 2,
                        disabled = function() return getConfigSheathState() == 1 end,
                        arg = "city_sheathe"
                    }
                }
            }
        }
    }
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

    if getConfigSheathState() == 2 and canUnsheatheWeapon() then
        ToggleSheath()
        return
    elseif getConfigSheathState() == 1 and canSheatheWeapon() then
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
        if name and vehicleBuffs[name] then
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
  AutoSheathe.Timer = AutoSheathe:ScheduleRepeatingTimer("SheatheTimerFeedback", 2)
end

function destroyExistingSheatheTimer()
	if (not (AutoSheathe.Timer == nil)) then
  	AutoSheathe:CancelTimer(AutoSheathe.Timer)
    AutoSheathe.Timer = nil
  end
end

function AutoSheathe:SheatheTimerFeedback()
  handleWeaponSheathe()
end

function registerSlashCommands()
    local console = LibStub("AceConsole-3.0")

    local function slashfunc(input)
        if not AutoSheathe.db.profile.enabled then
            return
        end

        input = string.lower(input)
        command, arg = console:GetArgs(input, 2)

        if command == "toggle" then
            if arg == "autodraw" and getConfigSheathState() == 1 then
                isAutoDrawEnabled = not AutoSheathe.db.profile.auto_draw
                AutoSheathe.db.profile.auto_draw = isAutoDrawEnabled
                print("Auto draw weapon:", booleanToText(AutoSheathe.db.profile.auto_draw))
                return
            end

            if arg == "city" and getConfigSheathState() == 2 then
                isCitySheatheEnabled = not AutoSheathe.db.profile.city_sheathe
                AutoSheathe.db.profile.auto_draw = isCitySheatheEnabled
                print("Keep weapon sheathed in cities:", booleanToText(AutoSheathe.db.profile.city_sheathe))
                return
            end

            isAddonEnabled = not AutoSheathe.db.profile.enabled
            AutoSheathe.db.profile.enabled = isAddonEnabled
            print("AutoSheathe:", booleanToText(AutoSheathe.db.profile.enabled))
            return
        end

        if Settings then
            Settings.OpenToCategory("AutoSheathe")
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("AutoSheathe")
        end
    end

    console:RegisterChatCommand("autosheathe",slashfunc)
    console:RegisterChatCommand("as",slashfunc)
end

function getConfigSheathState() return AutoSheathe.db.profile.sheath_state end

function booleanToText(val)
    if val then
        return "|cff00ff00enabled|r"
    end
    return "|cffff0000disabled|r"
end