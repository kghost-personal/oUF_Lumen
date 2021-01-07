local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

-- ------------------------------------------------------------------------
-- > AURAS RELATED FUNCTIONS
-- ------------------------------------------------------------------------

function lum:CreateAura(self, num, rows, size, spacing)
    local auras = CreateFrame("Frame", nil, self)
    auras:SetSize((num * (size + 6)) / rows, (size + 6) * rows)
    auras.num = num
    auras.size = size
    auras.spacing = spacing or 6
    return auras
end
