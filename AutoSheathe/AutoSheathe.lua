-- Create a new addon object using AceAddon
AutoSheathe = LibStub("AceAddon-3.0"):NewAddon("AutoSheathe", "AceEvent-3.0")

function AutoSheathe:OnInitialize()
    defaults = {
        profile = {
            enableAddon = true,  -- Default value for checkbox
            sheatheAction = 1
        }
    }

    events = {
        'ADDON_LOADED',
        'PLAYER_LOGIN',
        'PLAYER_REGEN_ENABLED',
        'LOOT_CLOSED',
        'AUCTION_HOUSE_CLOSED',
        'UNIT_EXITED_VEHICLE',
        'BARBER_SHOP_CLOSE',
        'PLAYER_ENTERING_WORLD',
        'UNIT_AURA',
        'QUEST_ACCEPTED',
        'QUEST_FINISHED', 
        'MERCHANT_CLOSED'
	}

    -- Initialize database with defaults
    AutoSheathe.db = LibStub("AceDB-3.0"):New("AutoSheatheDB", defaults, true)

    -- Register options table
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoSheathe", AutoSheathe:GetOptions())
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoSheathe", "AutoSheathe")
    
    eventFrame = CreateFrame("FRAME", "AutoSheatheEventFrame")
    registerEvents(events)
end

function registerEvents(events)
    eventFrame:UnregisterAllEvents();
    for i = 1, #events do
        eventFrame:RegisterEvent(events[i])
    end
    
    eventFrame:SetScript("OnEvent", function (frame, event, first, second)
      if (event ~= "ADDON_LOADED") then
        HandleSheathe()
      end
  	end)
end

-- Define options table
function AutoSheathe:GetOptions()
    return {
        name = "AutoSheathe",
        type = "group",
        args = {
            enableAddon = {
                name = "Enable AutoSheathe",
                desc = "Enable or disable AutoSheathe",
                type = "toggle",
                order = 1,
                set = function(info, val)
                    AutoSheathe.db.profile.enableAddon = val
                    HandleSheathe()
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
                        name = "Sheathing",
                        desc = "Select sheathe action",
                        type = "select",
                        order = 1,
                        values = {
                            [1] = "Sheathe weapon",
                            [2] = "Keep weapon unsheathed"
                        },
                        set = function(info, val)
                            AutoSheathe.db.profile.sheatheAction = val
                            HandleSheathe()
                        end,
                        get = function(info) return AutoSheathe.db.profile.sheatheAction end
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

function SheatheEvent_PLAYER_LOGIN()
    print("AutoSheathe enabled.")
    HandleSheathe();
end

-- leave combat
function SheatheEvent_PLAYER_REGEN_ENABLED()
    HandleSheathe();
end

-- enter combat
function SheatheEvent_PLAYER_REGEN_DISABLED()
    HandleSheathe();
end

function SheatheEvent_LOOT_OPENED()
    -- Classic: when looting, the weapon is automatically sheathed
    -- without canceling, the weapon sometimes disappears visually
    HandleSheathe()
end

function SheatheEvent_LOOT_CLOSED()
    -- Classic: when auto looting is enabled and there is no loot
    -- the weapon is not automatically sheathed
    HandleSheathe()
end

function HandleSheathe()

    if not AutoSheathe.db.profile.enableAddon then
        return
    end

    local infight = UnitAffectingCombat("player")
    if not infight then
        if (GetSheathState() == 2 and AutoSheathe.db.profile.sheatheAction == 1) then
            ToggleSheath()
        elseif (GetSheathState() == 2 and AutoSheathe.db.profile.sheatheAction == 2) then
            return
        elseif (GetSheathState() == 1 and AutoSheathe.db.profile.sheatheAction == 1) then
            return
        end
    end
end