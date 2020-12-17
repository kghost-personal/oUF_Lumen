local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m,
                                       ns.G, ns.oUF

local max = max

-- ------------------------------------------------------------------------
-- > AURAS RELATED FUNCTIONS
-- ------------------------------------------------------------------------

local function PostCreateIcon(self, button)
    local unit = self.__owner.unit
    local frame = self.__owner.mystyle

    lum:CreateMasqueIcon(button, self.size)

    if unit == "vehicle" then unit = "player" end
    -- For player debuffs show the spell name
    if unit == "player" and cfg.units[frame].auras.debuffs.spellName then
        button.spell = button:CreateFontString(nil, "OVERLAY")
        button.spell:SetPoint("RIGHT", button, "LEFT", -4, 0)
        button.spell:SetFont(m.fonts.font, 16, "THINOUTLINE")
        button.spell:SetTextColor(1, 1, 1)
        button.spell:SetShadowOffset(1, -1)
        button.spell:SetShadowColor(0, 0, 0, 1)
        button.spell:SetJustifyH("RIGHT")
        button.spell:SetWordWrap(false)
    end
end

local function PostUpdateIcon(icons, unit, icon, index)
    local name, _, _, _, duration, expirationTime =
        UnitAura(unit, index, icon.filter)

    if (icon.spell) then icon.spell:SetText(name) end
end

function lum:CreateAura(self, num, rows, size, spacing)
    local auras = CreateFrame("Frame", nil, self)
    auras:SetSize((num * (size + 6)) / rows, (size + 6) * rows)
    auras.num = num
    auras.size = size
    auras.spacing = spacing or 6
    auras.PostCreateIcon = PostCreateIcon
    auras.PostUpdateIcon = PostUpdateIcon
    return auras
end
