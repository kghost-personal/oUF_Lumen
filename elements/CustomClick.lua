local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

local Spells = {
    MONK = {
        [268] = { -- Brewmaster
        },
        [270] = { -- Mistweaver
            HelpRight = 115450, -- Detox
            HelpAltRight = 116849, -- Life Cocoon
            HarmAltRight = 115546 -- Provoke
        },
        [269] = { -- Windwalker
        }
    },
    DRUID = {
        [102] = { -- Balance
            HelpRight = 2782 -- Remove Corruption
        },
        [103] = { -- Feral
        },
        [104] = { -- Guardian
        },
        [105] = { -- Restoration
            HelpRight = 88423 -- Nature's Cure
        }
    }
}

local function SetAction(self, targetType, mod, spellID)
    if (spellID) then
        local spellName = GetSpellInfo(spellID)
        self:SetAttribute("*" .. targetType .. "button" .. self.CustomClick.button, spellID and targetType)
        self:SetAttribute(mod .. "type-" .. targetType, spellID and "spell")
        self:SetAttribute(mod .. "spell-" .. targetType, spellName)
    end
end

local function Update(self)
    if not self:CanChangeAttribute() then return end

    local function lookup(t, ...)
        for _, k in ipairs {...} do
            t = t[k]
            if not t then return nil end
        end
        return t
    end

    local class = select(2, UnitClass("player"))
    local spec = select(1, GetSpecializationInfo(GetSpecialization()))
    local info = lookup(Spells, class, spec)
    if (info ~= nil) then
        SetAction(self, "help", "", info["HelpRight"])
        SetAction(self, "help", "alt-", info["HelpAltRight"])

        SetAction(self, "harm", "", info["HarmRight"])
        SetAction(self, "harm", "alt-", info["HarmAltRight"])
    end
end

local function ForceUpdate(element) return Update(element.__owner) end

local function Enable(self)
    local element = self.CustomClick
    if element then
        if not element.button then element.button = "2" end

        element.__owner, element.ForceUpdate = self, ForceUpdate
        self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', Update, true)
        self:RegisterEvent('PLAYER_REGEN_DISABLED', Update, true)
        self:RegisterEvent('PLAYER_REGEN_ENABLED', Update, true)
        return true
    end
end

local function Disable(self)
    if self.CustomClick then
        if self:CanChangeAttribute() then
            SetAction(self, "help", nil)
            SetAction(self, "harm", nil)
        end
        self:UnregisterEvent('PLAYER_REGEN_DISABLED', Update)
        self:UnregisterEvent('PLAYER_REGEN_ENABLED', Update)
    end
end

oUF:AddElement('CustomClick', Update, Enable, Disable)
