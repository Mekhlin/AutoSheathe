AutoSheathe = LibStub("AceAddon-3.0"):NewAddon("AutoSheathe", "AceTimer-3.0", "AceConsole-3.0")

function AutoSheathe:OnInitialize()
    defaults = {
        profile = {
            enableAddon = true,
            sheatheAction = 1,
            autoDraw = false
        }
    }

    events = {
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
    
    AutoSheathe.db = LibStub("AceDB-3.0"):New("AutoSheatheDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoSheathe", getOptions())
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoSheathe", "AutoSheathe")

    eventFrame = CreateFrame("FRAME", "AutoSheatheEventFrame")
    registerEvents(events)
    registerChatCommands()
end

function registerEvents(events)
    eventFrame:UnregisterAllEvents();

    for i, event in ipairs(events) do
        print(i, event)
        eventFrame:RegisterEvent(event)
    end

    eventFrame:SetScript("OnEvent", function (frame, event, first, second)
        handleWeaponSheathe()
  	end)
end

function AutoSheathe:OnEnable()
    if AutoSheathe.db.profile.enableAddon then
        startTimer()
    end
end

function handleWeaponSheathe()
    if not AutoSheathe.db.profile.enableAddon then
        return
    end

    infight = UnitAffectingCombat("player")

    if infight then
        if AutoSheathe.db.profile.autoDraw and canUnsheatheWeapon() then
            ToggleSheath()
            return
        else
            return
        end
    end
    
    if AutoSheathe.db.profile.sheatheAction == 2 and canUnsheatheWeapon() then
        ToggleSheath()
        return
    elseif AutoSheathe.db.profile.sheatheAction == 1 and canSheatheWeapon() then
        ToggleSheath()
        return
    end
end

function inVehicle()
    if UnitInVehicle("player") then
        return true
    end

    vehicles = {
        ["Rocfeather Skyhorn Kite"] = true,
        ["Goblin Glider"]           = true,
        ["Zen Flight"]              = true,
        ["Bronze Racer's Pennant"]  = true
    }

    for i = 1, 40 do
        local name, _, _, _, _, _ = UnitBuff("player",i)
        if name and vehicles[name] then
            return true
        end
    end
    return false
end

function canSheatheWeapon()
    if GetSheathState() == 1 then
        return false
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

    if inVehicle() then
        return false
    end
    
    return true
end

function startTimer()
  destroyExistingTimer()
  AutoSheathe.Timer = AutoSheathe:ScheduleRepeatingTimer("TimerFeedback", 3)
end

function destroyExistingTimer()
	if (not (AutoSheathe.Timer == nil)) then
  	AutoSheathe:CancelTimer(AutoSheathe.Timer)
    AutoSheathe.Timer = nil
  end
end

function AutoSheathe:TimerFeedback()
  handleWeaponSheathe()
end

function registerChatCommands()
  AutoSheathe:RegisterChatCommand("autosheathe","slashfunc")
  AutoSheathe:RegisterChatCommand("as","slashfunc")
end

function AutoSheathe:slashfunc(input)
input = string.lower(input)

    if input == "toggle" then
        isAddonEnabled = not AutoSheathe.db.profile.enableAddon
        AutoSheathe.db.profile.enableAddon = isAddonEnabled
        if AutoSheathe.db.profile.enableAddon then
            print("AutoSheathe:", "|cff00ff00enabled|r")
        else
            print("AutoSheathe:", "|cffff0000disabled|r")
        end
        return
    end
    if Settings then
		Settings.OpenToCategory("AutoSheathe")
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory("AutoSheathe")
	end
end

function getOptions()
    return {
        name = "AutoSheathe",
        type = "group",
        args = {
            enableAddon = {
                name = "Enable",
                desc = "Enable or disable AutoSheathe",
                type = "toggle",
                order = 1,
                set = function(info, val)
                    AutoSheathe.db.profile.enableAddon = val
                    if AutoSheathe.db.profile.enableAddon then
                        print("AutoSheathe:", "|cff00ff00enabled|r")
                    else
                        print("AutoSheathe:", "|cffff0000disabled|r")
                    end
                end,
                get = function(info) return AutoSheathe.db.profile.enableAddon end
            },
            sheatheConfing = {
                name = "Configuration",
                type = "group",
                order = 2,
                inline = true,
                args = {
                    sheatheAction = {
                        name = "Keep weapon",
                        desc = "Select sheathe action",
                        type = "select",
                        order = 1,
                        values = {
                            [1] = "Sheathed",
                            [2] = "Unsheathed"
                        },
                        set = function(info, val)
                            AutoSheathe.db.profile.sheatheAction = val
                            handleWeaponSheathe()
                        end,
                        get = function(info) return AutoSheathe.db.profile.sheatheAction end
                    },
                    enableAddon = {
                        name = "Auto draw weapon",
                        desc = "Unsheathe weapon when in fight",
                        type = "toggle",
                        order = 2,
                        set = function(info, val) AutoSheathe.db.profile.autoDraw = val end,
                        get = function(info) return AutoSheathe.db.profile.autoDraw end
                    }
                }
            },
            aboutOptions = {
                name = "About",
                type = "group",
                order = 3,
                inline = true,
                args = {
                    version = {
                        order = 1,
                        name = function(info) return "Version: " .. GetAddOnMetadata("AutoSheathe", "Version") end,
                        type = "description"
                    },
                    sourceCode = {
                        order = 2,
                        name = function(info) return "https://github.com/Mekhlin/AutoSheathe" end,
                        type = "description"
                    }
                }
            }
        }
    }
end