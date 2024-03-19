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
        "UNIT_AURA",
        "QUEST_ACCEPTED",
        "QUEST_FINISHED",
        "MERCHANT_CLOSED"
	}

    AutoSheathe.db = LibStub("AceDB-3.0"):New("AutoSheatheDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoSheathe", AutoSheathe:GetOptions())
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoSheathe", "AutoSheathe")

    eventFrame = CreateFrame("FRAME", "AutoSheatheEventFrame")
    timer = nil
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
        AutoSheathe:HandleSheathe()
  	end)
end

function AutoSheathe:OnEnable()
    if AutoSheathe.db.profile.enableAddon then
        startTimer()
    end
end

function AutoSheathe:GetOptions()
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
                        startTimer()
                    else
                        destroyExistingTimer()
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
                            AutoSheathe:HandleSheathe()
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
                        type = "description",
                        name = function()
                            addonVersion = GetAddOnMetadata("AutoSheathe", "Version")
                            return "Version: " .. addonVersion .. "\nhttps://github.com/Mekhlin/AutoSheathe"
                        end
                    }
                }
            }
        }
    }
end

function AutoSheathe:HandleSheathe()

    if not AutoSheathe.db.profile.enableAddon then
        return
    end

    sheathState = GetSheathState()
    infight = UnitAffectingCombat("player")

    if infight then
        if sheathState == 1 and AutoSheathe.db.profile.autoDraw then
            ToggleSheath()
            return
        elseif sheathState == 2 then
            return
        end
    end

    if not infight then
        if (sheathState == 2 and AutoSheathe.db.profile.sheatheAction == 1) then
            ToggleSheath()
            return
        elseif (sheathState == 2 and AutoSheathe.db.profile.sheatheAction == 2) then
            return
        elseif (sheathState == 1 and AutoSheathe.db.profile.sheatheAction == 1) then
            return
        elseif (sheathState == 1 and AutoSheathe.db.profile.sheatheAction == 2) then
            if not inVehicle() then
                ToggleSheath()
                return
            end
        end
    end
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
  AutoSheathe:HandleSheathe()
end

function registerChatCommands()
  AutoSheathe:RegisterChatCommand("autosheathe","slashfunc")
  AutoSheathe:RegisterChatCommand("as","slashfunc")
end

function AutoSheathe:slashfunc(input)
    if Settings then
		Settings.OpenToCategory("AutoSheathe")
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory("AutoSheathe")
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