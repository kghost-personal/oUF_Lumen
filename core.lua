local addon, ns = ...

local core = CreateFrame("Frame") -- Core methods
ns.core = core
ns.Frames = {}

local floor, mod = floor, mod

local LSM = LibStub("LibSharedMedia-3.0")
ns.LSM = LSM
LSM:Register("font", "BigNoodleTitling", [[Interface\Addons\oUF_Lumen\media\font.ttc]])

local Ace3 = LibStub("AceAddon-3.0"):NewAddon("Lumen", "AceConsole-3.0")
ns.Ace3 = Ace3

local OptionBase = {
    name = "Lumen",
    handler = Ace3,
    type = 'group',
    args = {
        BaseFont = {
            type = 'select',
            dialogControl = 'LSM30_Font',
            name = 'Font',
            desc = 'Basic font',
            values = LSM:HashTable("font"),
            arg = function() return Ace3.db.profile, "font" end,
            get = "GetOption",
            set = "SetOption"
        },
        LocalizationFont = {
            type = 'select',
            dialogControl = 'LSM30_Font',
            name = 'Localization font',
            desc = 'Localization font for display localized strings, like player names',
            values = LSM:HashTable("font"),
            arg = function() return Ace3.db.profile, "mfont" end,
            get = "GetOption",
            set = "SetOption"
        }
    }
}

local defaults = {profile = {mfont = "BigNoodleTitling", font = "BigNoodleTitling"}}

function Ace3:GetOption(info)
    local dict, name = info.arg()
    return dict[name]
end

function Ace3:SetOption(info, key)
    local dict, name = info.arg()
    dict[name] = key
end

function Ace3:OnInitialize()
    local title = GetAddOnMetadata(addon, 'title')

    -- Remove MovableFrames option
    local nextFreeArraySpace = 1;
    for i = 1, #INTERFACEOPTIONS_ADDONCATEGORIES do
        local v = INTERFACEOPTIONS_ADDONCATEGORIES[i];
        if (v.name ~= title) then
            INTERFACEOPTIONS_ADDONCATEGORIES[nextFreeArraySpace] = INTERFACEOPTIONS_ADDONCATEGORIES[i];
            nextFreeArraySpace = nextFreeArraySpace + 1;
        end
    end
    for i = nextFreeArraySpace, #INTERFACEOPTIONS_ADDONCATEGORIES do INTERFACEOPTIONS_ADDONCATEGORIES[i] = nil; end
    InterfaceAddOnsList_Update();

    Ace3.db = LibStub("AceDB-3.0"):New("LumenDB", defaults, true)
    local config = LibStub("AceConfig-3.0")
    local cd = LibStub("AceConfigDialog-3.0")

    config:RegisterOptionsTable("LumenBase", OptionBase)
    Ace3.optionBaseFrame = cd:AddToBlizOptions("LumenBase", title)

    config:RegisterOptionsTable("LumenProfiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(Ace3.db))
    Ace3.optionProfileFrame = cd:AddToBlizOptions("LumenProfiles", "Profiles", title)
end

function Ace3:OnEnable()
    ns.Frames.Player()
    ns.Frames.Target()
    ns.Frames.Pet()
    ns.Frames.Focus()
    ns.Frames.TargetTarget()
    ns.Frames.Party()
    ns.Frames.Raid()
    ns.Frames.Boss()
end

-- ------------------------------------------------------------------------
-- > MATH
-- ------------------------------------------------------------------------

function core:Round(number, idp)
    idp = idp or 0
    local mult = 10 ^ idp
    return floor(number * mult + .5) / mult
end

-- Shortens Numbers
function core:ShortNumber(v)
    if v > 1E10 then
        return (floor(v / 1E9)) .. "|cff999999b|r"
    elseif v > 1E9 then
        return (floor((v / 1E9) * 10) / 10) .. "|cff999999b|r"
    elseif v > 1E7 then
        return (floor(v / 1E6)) .. "|cff999999m|r"
    elseif v > 1E6 then
        return (floor((v / 1E6) * 10) / 10) .. "|cff999999m|r"
    elseif v > 1E4 then
        return (floor(v / 1E3)) .. "|cff999999k|r"
    elseif v > 1E3 then
        return (floor((v / 1E3) * 10) / 10) .. "|cff999999k|r"
    else
        return v
    end
end

function core:NumberToPerc(v1, v2) return floor(v1 / v2 * 100 + 0.5) end

function core:FormatTime(s)
    local day, hour, minute = 86400, 3600, 60

    if s >= day then
        return format("%dd", floor(s / day + 0.5))
    elseif s >= hour then
        return format("%dh", floor(s / hour + 0.5))
    elseif s >= minute then
        return format("%dm", floor(s / minute + 0.5))
    end

    -- Seconds
    local t = mod(s, minute)
    if t > 1 then return format("%d", t) end
    return format("%.1f", t)
end

function core:GetTotalElements(elements)
    local count = 0
    for _ in pairs(elements) do count = count + 1 end
    return count
end

-- Check if the array contains a specific value
function core:HasValue(tab, val)
    for index, value in ipairs(tab) do if value == val then return true end end
    return false
end

-- Convert color to HEX
function core:ToHex(r, g, b)
    if r then
        if (type(r) == "table") then
            if (r.r) then
                r, g, b = r.r, r.g, r.b
            else
                r, g, b = unpack(r)
            end
        end
        return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
    end
end

-- Make color lighter (add white)
function core:TintColor(r, g, b, factor)
    if not r or not factor then return end

    local R = r + (1 - r) * factor
    local G = g + (1 - g) * factor
    local B = b + (1 - b) * factor

    return R, G, B
end

-- Make color darker (add black)
function core:ShadeColor(r, g, b, factor)
    if not r or not factor then return end

    local R = r * (1 - factor)
    local G = g * (1 - factor)
    local B = b * (1 - factor)

    return R, G, B
end
