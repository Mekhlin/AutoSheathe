function AutoSheathe:GetDefaultOptions()
    return {
        profile = {
            enabled = true,
            sheath_state = 1,
            auto_draw = true,
            city_sheathe = false,
            afk_sheathe = false
        }
    }
end

function AutoSheathe:GetOptions()
    local function get(info)
        return AutoSheathe.db.profile[info.arg]
    end

    local function set(info, val)
        local arg = info.arg
        AutoSheathe.db.profile[arg] = val
        if arg == "city_sheathe" then
            AutoSheathe:HandleWeapon()
        end
    end

    local options = {
        name = "AutoSheathe",
        type = "group",
        args = {
            selected_profile = {
                type = "description",
                order = 5,
                name = function() return "Current profile: " .. "|cffffa500" .. AutoSheathe.db:GetCurrentProfile() .. "|r\n" end
            },
            enabled = {
                type = "toggle",
                order = 10,
                name = "Enable",
                desc = "Enable or disable AutoSheathe",
                set = function(info, val)
                    AutoSheathe.db.profile.enabled = val
                    if val then
                        AutoSheathe:Enable()
                    else
                        AutoSheathe:Disable()
                    end
                end,
                get = function(info) return AutoSheathe.db.profile.enabled end
            },
            basic_options = {
                type = "group",
                order = 20,
                name = "Basic options",
                inline = true,
                get = get,
                set = set,
                disabled = function() return not AutoSheathe.db.profile.enabled end,
                args = {
                    sheath_state = {
                        type = "select",
                        order = 1,
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
                disabled = function() return not AutoSheathe.db.profile.enabled end,
                args = {
                    auto_draw = {
                        type = "toggle",
                        order = 1,
                        name = "Auto draw weapon",
                        desc = "Draw weapon when attacked/targeted",
                        disabled = function() return not AutoSheathe.db.profile.enabled or AutoSheathe.db.profile.sheath_state == 2 end,
                        arg = "auto_draw"
                    },
                    city_sheathe = {
                        type = "toggle",
                        order = 2,
                        name = "Sheathe weapon in cities",
                        desc = "Keep weapon sheathed when in cities or near an innkeeper",
                        disabled = function() return not AutoSheathe.db.profile.enabled or AutoSheathe.db.profile.sheath_state == 1 end,
                        arg = "city_sheathe"
                    },
                    afk_sheathe = {
                        type = "toggle",
                        order = 3,
                        name = "Sheathe weapon on AFK",
                        desc = "Keep weapon sheathed when player is AFK",
                        disabled = function() return not AutoSheathe.db.profile.enabled or AutoSheathe.db.profile.sheath_state == 1 end,
                        arg = "afk_sheathe"
                    }
                }
            },
            reset_profile = {
                type = "execute",
                order = -1,
                name = "Defaults",
                width = "half",
                desc = "Resets profile to default values",
                func = function() AutoSheathe.db:ResetProfile() end,
                disabled = function() return not AutoSheathe.db.profile.enabled end,
            }
        }
    }

    return options
end

function AutoSheathe:GetAbout()
    local aboutOptions = {
        name = "About",
        type = "group",
        inline = true,
        args = {
            addon_version = {
                type = "description",
                order = 1,
                name = function(info) return "AutoSheathe v" .. GetAddOnMetadata("AutoSheathe", "Version") end
            }
        }
    }

    return aboutOptions
end