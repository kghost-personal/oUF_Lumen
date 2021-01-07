local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF
local filters = ns.filters

local frame = "boss"

-- -----------------------------------
-- > Boss Style
-- -----------------------------------

local function PostCreateIcon(self, button) lum:CreateMasqueIcon(button, self.size) end

local function CreateBoss(self)
    self.mystyle = frame
    self.cfg = cfg.units[frame]

    lum:SharedStyle(self, "secondary")

    self:SetSize(self.cfg.width, self.cfg.height)

    -- Texts
    lum:CreateNameString(self, cfg.fontsize + 2, nil, 4, 0, "LEFT", self.cfg.width - 60)
    lum:CreateHealthValueString(self, cfg.fontsize, nil, -4, 0, "RIGHT")
    lum:CreatePowerValueString(self, cfg.fontsize - 4, nil, 0, 0, "CENTER")

    -- Auras
    lum:SetBuffAuras(self, frame, 4, 1, self.cfg.height + 4, 2, "TOPRIGHT", self, "LEFT", -6, self.cfg.height - 3,
        "BOTTOMRIGHT", "LEFT", "UP", true)

    -- Castbar
    if self.cfg.castbar.enable then lum:CreateCastbar(self) end

    -- Raid Icons
    local RaidIcon = self:CreateTexture(nil, "ARTWORK")
    RaidIcon:SetPoint("RIGHT", self, "LEFT", -8, 2)
    RaidIcon:SetSize(20, 20)
    self.RaidTargetIndicator = RaidIcon

    self.Range = cfg.frames.range

    local size = self.cfg.height - 2
    local watchers = CreateFrame("Frame", nil, self)
    watchers:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 2, 2)
    watchers:SetSize(size * 8, size)
    watchers.size = size
    watchers.spacing = 0
    watchers.initialAnchor = "BOTTOMLEFT"
    watchers["growth-x"] = "RIGHT"
    watchers["growth-y"] = "UP"
    watchers.PostCreateIcon = PostCreateIcon
    watchers.Watchers = {[48438] = 1, [33763] = 2, [774] = 3, [8936] = 4, [102351] = 5, [155777] = 6}
    self.BuffWatchers = watchers
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
ns.Frames.Boss = function()
    if cfg.units[frame].show then
        oUF:RegisterStyle("oUF_LumenBoss", CreateBoss)
        oUF:SetActiveStyle("oUF_LumenBoss")

        for index = 1, MAX_BOSS_FRAMES or 5 do
            local boss = oUF:Spawn(frame .. index, "oUF_LumenBoss" .. index)
            -- local boss = oUF:Spawn("player", 'oUF_LumenBoss' .. index) -- Debug

            if index == 1 then
                boss:SetPoint(cfg.units.boss.pos.a1, cfg.units.boss.pos.af, cfg.units.boss.pos.a2, cfg.units.boss.pos.x,
                    cfg.units.boss.pos.y)
            else
                boss:SetPoint("TOP", _G["oUF_LumenBoss" .. index - 1], "BOTTOM", 0, -2)
            end
        end
    end
end
