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

local db

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
            auto_draw = true,
            city_sheathe = false
        }
    }

    self.db = LibStub("AceDB-3.0"):New("AutoSheatheDB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	db = self.db.profile
    timer = nil

    createBlizzOptions(self.db)
    registerGameEvents()

    self:RegisterChatCommand("as", "slashfunc")
end

function AutoSheathe:OnEnable()
    if not db.enabled then
        return
    end

    startTimer()
end

function AutoSheathe:OnDisable()
    if db.enabled then
        return
    end

    destroyExistingTimer();
end

function createConfig(database)
    local function get(info)
        return db[info.arg]
    end

    local function set(info, val)
        local arg = info.arg
        db[arg] = val
        if arg == "city_sheathe" then
            handleWeapon()
        end
    end

    local options = {
        name = "AutoSheathe",
        type = "group",
        args = {
            selected_profile = {
                type = "description",
                order = 5,
                name = function() return "Current profile: " .. "|cffffa500" .. database:GetCurrentProfile() .. "|r\n" end
            },
            enabled = {
                type = "toggle",
                order = 10,
                name = "Enable",
                desc = "Enable or disable AutoSheathe",
                set = function(info, val)
                    db.enabled = val
                    if val then
                        AutoSheathe:Enable()
                    else
                        AutoSheathe:Disable()
                    end
                end,
                get = function(info) return db.enabled end
            },
            basic_options = {
                type = "group",
                order = 20,
                name = "Basic options",
                inline = true,
                get = get,
                set = set,
                disabled = function() return not db.enabled end,
                args = {
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
                order = 30,
                inline = true,
                get = get,
                set = set,
                disabled = function() return not db.enabled end,
                args = {
                    auto_draw = {
                        type = "toggle",
                        order = 1,
                        name = "Auto draw weapon",
                        desc = "Draw weapon when attacked",
                        disabled = function() return not db.enabled or db.sheath_state == 2 end,
                        arg = "auto_draw"
                    },
                    city_sheathe = {
                        type = "toggle",
                        order = 2,
                        name = "Sheathe weapon in cities",
                        desc = "Keep weapon sheathed when in cities or near an innkeeper",
                        disabled = function() return not db.enabled or db.sheath_state == 1 end,
                        arg = "city_sheathe"
                    }
                }
            },
            reset_profile = {
                type = "execute",
                order = -1,
                name = "Defaults",
                desc = "Resets profile to default values",
                func = function() self.db:ResetProfile() end,
                disabled = function() return not db.enabled end,
            }
        }
    }

    return options
end

function createBlizzOptions(database)
    options = createConfig(database)

    local aboutOptions = {
        name = "About",
        type = "group",
        args = {
                version = {
                    type = "description",
                    order = 1,
                    name = function(info) return "Version: " .. GetAddOnMetadata("AutoSheathe", "Version") end
                }
            }
        }

    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")

    config:RegisterOptionsTable("AutoSheathe", options)
    dialog:AddToBlizOptions("AutoSheathe", "AutoSheathe")

    profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(database)
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
        handleWeapon()
  	end)
end

function handleWeapon()
    if not db.enabled then
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

    if db.city_sheathe then
        if IsResting() and sheathState == 2 then
            ToggleSheath()
            return
        end
    end

    if db.sheath_state == 2 and canDrawWeapon() then
        ToggleSheath()
        return
    elseif db.sheath_state == 1 and canSheatheWeapon() then
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

    if IsResting() and db.city_sheathe then
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

    if UnitAffectingCombat("player") and db.auto_draw then
        return true
    end

    if IsSwimming() then
        return false
    end

    -- If player is mounted or affexted by "vehicle buff".
    if IsMounted() or inVehicle() then
        return false
    end

    -- Player is in a city or near an innkeeper.
    if IsResting() and db.city_sheathe then
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

function AutoSheathe:slashfunc(input)
    if Settings then
        Settings.OpenToCategory("AutoSheathe")
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("AutoSheathe")
    end
end

function AutoSheathe:OnProfileChanged(event, database, newProfileKey)
    db = database.profile
    handleWeapon()
end 