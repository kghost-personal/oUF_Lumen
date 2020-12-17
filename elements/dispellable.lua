
local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m,
                                       ns.G, ns.oUF

function lum:CreateDispellable(self)
    local button = CreateFrame('Button', nil, self.Overlay)
    button:SetPoint('CENTER')
    button:SetToplevel(true)
    button:EnableMouse(false)

    local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
    cd:SetHideCountdownNumbers(false) -- set to true to disable cooldown numbers on the cooldown spiral
    cd:SetAllPoints()
    cd:EnableMouse(false)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()

    local count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal', 1)
    count:SetPoint('BOTTOMRIGHT', -1, 1)

    local texture = self.Health:CreateTexture(nil, 'OVERLAY')
    texture:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 0) -- hide in case the class can't dispel at all
    texture.dispelAlpha = 0.2

    button.cd = cd
    button.icon = icon
    button.count = count
    button:Hide() -- hide in case the class can't dispel at all

    lum:CreateMasqueIcon(button, 22)

    self.Dispellable = {
        dispelIcon = button,
        dispelTexture = texture,
    }
end
