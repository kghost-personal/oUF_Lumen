local A, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

local frame = "raid"

-- -----------------------------------
-- > RAID UNIT SPECIFIC FUNCTiONS
-- -----------------------------------

-- Post Health Update
local PostUpdateHealth = function(health, unit, min, max)
    local self = health.__owner
    local dead, disconnnected, ghost = UnitIsDead(unit), not UnitIsConnected(unit), UnitIsGhost(unit)
    local perc = math.floor(min / max * 100 + 0.5)

    -- Inverted colors
    if cfg.units[frame].health.invertedColors then
        health:SetStatusBarColor(unpack(cfg.colors.inverted))
        health.bg:SetVertexColor(unpack(api:RaidColor(unit)))
        health.bg:SetAlpha(1)
    end

    -- Use gradient colored health
    if cfg.units[frame].health.gradientColored then
        local color = CreateColor(oUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0, .5, .9, 0))
        health:SetStatusBarColor(color:GetRGB())
    end

    if disconnnected or dead or ghost then
        self.HPborder:Hide()
        health.bg:SetVertexColor(.25, .25, .25)
        health.value:Hide()
    else -- Player alive and kicking!
        health.value:Show()
        if (min == max) then -- It has max health
            self.HPborder:Hide()
        else
            health.value:Show()
            if perc < 35 then -- Show warning health border
                self.HPborder:Show()
            else
                self.HPborder:Hide()
            end
        end
    end
end

-- PostUpdate Power
local PostUpdatePower = function(power, unit, min, max)
    local dead, disconnnected, ghost = UnitIsDead(unit), not UnitIsConnected(unit), UnitIsGhost(unit)

    if disconnnected or dead or ghost then
        power:SetValue(max)
        if (dead) then
            power:SetStatusBarColor(1, 0, .2, .5)
        elseif (disconnnected) then
            power:SetStatusBarColor(0, .4, .8, .5)
        elseif (ghost) then
            power:SetStatusBarColor(1, 1, 1, .5)
        end
    else
        power:SetValue(min)
        if (unit == "vehicle") then power:SetStatusBarColor(143 / 255, 194 / 255, 32 / 255) end
    end
end

-- -----------------------------------
-- > RAID STYLE
-- -----------------------------------

local function CreateRaid(self)
    self.mystyle = frame
    self.cfg = cfg.units[frame]

    lum:SharedStyle(self, "secondary")

    self.Overlay = CreateFrame("Frame", nil, self)
    self.Overlay:SetAllPoints()
    self.OutOfCombatOverlay = CreateFrame("Frame", nil, self)
    self.OutOfCombatOverlay:SetAllPoints()
    RegisterStateDriver(self.OutOfCombatOverlay, "visibility", "[combat] hide; show")

    -- Health & Power
    self.Health.PostUpdate = PostUpdateHealth
    self.Power.PostUpdate = PostUpdatePower

    -- Texts
    self.Name = lum:CreatePartyNameString(self, self.cfg, cfg.fontsize)
    self.Name:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 2, -2)
    self.Attrs = lum:CreatePartyAttrsString(self, cfg.fontsize)
    self.Attrs:SetPoint("LEFT", self.Name, "RIGHT", 0, 0)
    lum:CreateHealthValueString(self, cfg.fontsize, nil, -2, 2, "BOTTOMRIGHT", "RIGHT")

    lum:CreatePartyAttrsOOCString(self, cfg.fontsize)

    lum:SetDebuffAuras(self, frame, 8, 1, self.cfg.height / 2 - 2, 0, "TOPRIGHT", self, "TOPRIGHT", 0, 0, "TOPRIGHT",
        "LEFT", "DOWN", true, false)

    self.BuffWatchers = lum:CreateBuffWatchers(self, self.cfg.height / 2 - 2)
    self.BuffWatchers.Watchers = cfg.BuffWatchers[select(2, UnitClass("player"))]

    -- Dispellable
    lum:CreateDispellable(self)

    -- Group Role Icon
    local GroupRoleIndicator = lum:CreateGroupRoleIndicator(self.OutOfCombatOverlay)
    GroupRoleIndicator:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 8)
    GroupRoleIndicator:SetSize(12, 12)
    self.GroupRoleIndicator = GroupRoleIndicator

    -- Raid Target Indicator
    local RaidTargetIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
    RaidTargetIndicator:SetPoint("LEFT", self.GroupRoleIndicator, "RIGHT", 2, 0)
    RaidTargetIndicator:SetSize(16, 16)
    self.RaidTargetIndicator = RaidTargetIndicator

    -- Ready Check Icon
    local ReadyCheck = self.OutOfCombatOverlay:CreateTexture()
    ReadyCheck:SetPoint("CENTER", self, "CENTER", 0, 0)
    ReadyCheck:SetSize(20, 20)
    ReadyCheck.finishedTimer = 10
    ReadyCheck.fadeTimer = 2
    self.ReadyCheckIndicator = ReadyCheck

    -- Heal Prediction
    lum:CreateHealPrediction(self)

    -- Health warning border
    lum:CreateHealthBorder(self)

    -- Threat warning border
    lum:CreateThreatBorder(self)

    -- Phase indicator
    self.PhaseIndicator = CreateFrame("Frame", nil, self)
    self.PhaseIndicator:SetSize(self.cfg.height, self.cfg.height)
    self.PhaseIndicator:SetPoint("TOPRIGHT", self)
    self.PhaseIndicator:EnableMouse(true)
    self.PhaseIndicator.Icon = self.PhaseIndicator:CreateTexture(nil, "OVERLAY")
    self.PhaseIndicator.Icon:SetAllPoints()

    self.Range = cfg.frames.range
    self.CustomClick = {}

    self.Overlay:Raise()
    self.OutOfCombatOverlay:Raise()
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
local Frames = {}

local function SetStateVisibility(self, event, ...)
    if (event == "PLAYER_ENTERING_WORLD") then

        local condition = "[group:raid] show; hide"
        local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
        if (instanceType == "arena") then condition = "hide" end

        for i = 1, 8 do
            local frame = Frames[i]
            UnregisterAttributeDriver(frame, 'state-visibility')
            if (maxPlayers and maxPlayers > 5 and i * 5 > maxPlayers) then
                RegisterAttributeDriver(frame, 'state-visibility', "hide")
                frame.visibility = "hide"
            else
                RegisterAttributeDriver(frame, 'state-visibility', condition)
                frame.visibility = condition
            end
        end
    end
end

ns.Frames.Raid = function()
    if cfg.units[frame].show then
        oUF:RegisterStyle(A .. "Raid", CreateRaid)
        oUF:SetActiveStyle(A .. "Raid")

        local last = nil
        for i = 1, 8 do
            local raid = oUF:SpawnHeader("oUF_LumenRaid" .. tostring(i), nil, nil, "showParty", false, "showRaid", true,
                "showPlayer", true, "point", "TOP", "groupFilter", tostring(i), "yOffset", "-5",
                "oUF-initialConfigFunction", ([[
            self:SetAttribute('*type2', nil)
            self:SetHeight(%d)
            self:SetWidth(%d)
        ]]):format(cfg.units[frame].height, cfg.units[frame].width))
            if (i == 1) then
                raid:SetPoint(cfg.units[frame].pos.a1, cfg.units[frame].pos.af, cfg.units[frame].pos.a2,
                    cfg.units[frame].pos.x, cfg.units[frame].pos.y)
            else
                raid:SetPoint("TOPLEFT", last, "TOPRIGHT", 5, 0)
            end
            raid:Show()
            Frames[i] = raid
            last = raid
        end

        local event = CreateFrame("Frame")
        event:RegisterEvent("PLAYER_ENTERING_WORLD")
        event:SetScript("OnEvent", SetStateVisibility)
    end
end
