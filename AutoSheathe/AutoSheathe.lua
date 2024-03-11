local ADDON_NAME = "AutoSheathe";
local ADDON_VERSION = "1.0.0";
local ADDON_REPO = "https://github.com/Mekhlin/AutoSheathe";
local ADDON_LICENSE = "MIT License";

--[[
Options Panel
--]]

local function TextColor(text, color)
    if color ~= nil then
        return "|c" .. color .. text .. "|r"
    end

    return text
end

function AutoSheathe_CreateOptionsPanel()
        local panel = CreateFrame("Frame", "autoSheathOptionsPanel");
        panel.name = ADDON_NAME;
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name);
        category.ID = panel.name;
        Settings.RegisterAddOnCategory(category);

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(TextColor(ADDON_NAME, "ffa9ce77"));

        local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0);
        version:SetText(TextColor("v"..ADDON_VERSION, "ffc0c0c0"));

        local addOnSource = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        addOnSource:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -8);
        addOnSource:SetText(ADDON_REPO);

        local licenseHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
        licenseHeader:SetPoint("TOPLEFT", addOnSource, "BOTTOMLEFT", 0, -30);
        licenseHeader:SetText(TextColor("License"));

        local licenseName = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        licenseName:SetPoint("TOPLEFT", licenseHeader, "BOTTOMLEFT", 0, -8);
        licenseName:SetText(ADDON_LICENSE);
end

--[[
Addon
--]]

function SheatheEvent_PLAYER_LOGIN()
    print(ADDON_NAME .. " enabled.")
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
    local infight = UnitAffectingCombat("player")
    if not infight then
        if GetSheathState() == 2 then
            ToggleSheath()
        end
    end
end

local AutoSheatheEvents = {
PLAYER_REGEN_ENABLED = SheatheEvent_PLAYER_LOGIN,
PLAYER_REGEN_ENABLED = SheatheEvent_PLAYER_REGEN_ENABLED,
PLAYER_REGEN_DISABLED = SheatheEvent_PLAYER_REGEN_DISABLED,
LOOT_OPENED = SheatheEvent_LOOT_OPENED,
LOOT_CLOSED = SheatheEvent_LOOT_CLOSED,
};

function AutoSheathe_OnEvent(self, event, ...)
    if event and AutoSheatheEvents[event] then
        AutoSheatheEvents[event](self, ...);
    end
end

function AutoSheathe_OnLoad(self)
    AutoSheathe_CreateOptionsPanel()
    self:UnregisterAllEvents();

    for event, _ in pairs(AutoSheatheEvents) do
        self:RegisterEvent(event);
    end
end