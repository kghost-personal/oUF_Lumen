local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

local MSQ = LibStub("Masque", true)
local MSQ_ButtonData = {
    AutoCast = false,
    AutoCastable = false,
    Border = false,
    Checked = false,
    Cooldown = false,
    Count = false,
    Duration = false,
    Disabled = false,
    Flash = false,
    Highlight = false,
    HotKey = false,
    Icon = false,
    Name = false,
    Normal = false,
    Pushed = false
}

local GroupAura = MSQ:Group("Lumen", "Aura")

function lum:CreateMasqueIcon(button, size)
    local data = {} -- only initialize once so no garbage collection issues
    for k, v in pairs(MSQ_ButtonData) do data[k] = v end

    button:SetSize(size, size)
    data.Normal = button:CreateTexture(nil, "ARTWORK")
    data.Normal:SetAllPoints()
    data.Cooldown = button.cd
    data.Count = button.count
    data.Icon = button.icon

    GroupAura:AddButton(button, data)
end
