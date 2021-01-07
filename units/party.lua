local A, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

local frame = "party"

-- -----------------------------------
-- > PARTY UNIT SPECIFIC FUNCTiONS
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
-- > PARTY STYLE
-- -----------------------------------

local function CreateParty(self)
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

local function CreatePartySub(self, unit)
    self.mystyle = unit
    self.cfg = cfg.units[unit]

    self:RegisterForClicks("AnyDown")

    self:SetScale(cfg.scale)
    api:SetBackdrop(self, 2, 2, 2, 2)
    api:CreateDropShadow(self, 6, 6)

    lum:CreateHealthBar(self, "secondary")
    lum:CreateMouseoverHighlight(self)

    -- Health
    self.Health.colorClass = false
    self.Health.colorClassPet = true
    self.Health.colorSelection = true

    -- Texts
    self.Name = lum:CreatePartySubNameString(self, self.cfg, cfg.fontsize - 2)
    lum:CreateHealthValueString(self, cfg.fontsize, nil, -2, 0, "RIGHT")

    -- Heal Prediction
    lum:CreateHealPrediction(self)

    self.Range = cfg.frames.range
    self.CustomClick = {}
end

local function CreatePartyTarget(self) return CreatePartySub(self, "partytarget") end

local function CreatePartyPet(self) return CreatePartySub(self, "partypet") end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
local Frames = {}

local function SetStateVisibility(self, event, ...)
    if (event == "PLAYER_ENTERING_WORLD") then
        local condition = "[group:raid] hide; show"
        if (select(2, GetInstanceInfo()) == "arena") then condition = "show" end

        for _, frame in pairs(Frames) do
            UnregisterAttributeDriver(frame, 'state-visibility')
            RegisterAttributeDriver(frame, 'state-visibility', condition)
            frame.visibility = condition
        end
    end
end

ns.Frames.Party = function()
    if cfg.units[frame].show then
        oUF:RegisterStyle(A .. "Party", CreateParty)
        oUF:SetActiveStyle(A .. "Party")

        local party = oUF:SpawnHeader("oUF_LumenParty", nil, nil, "showParty", true, "showRaid", false, "showPlayer",
            true, "yOffset", -5, "groupBy", "ASSIGNEDROLE", "groupingOrder", "TANK,HEALER,DAMAGER",
            "oUF-initialConfigFunction", ([[
        self:SetAttribute('*type2', nil)
        self:SetHeight(%d)
        self:SetWidth(%d)
    ]]):format(cfg.units[frame].height, cfg.units[frame].width))
        party:SetPoint(cfg.units[frame].pos.a1, cfg.units[frame].pos.af, cfg.units[frame].pos.a2,
            cfg.units[frame].pos.x, cfg.units[frame].pos.y)
        party:Show()
        Frames["Party"] = party

        if cfg.units["partytarget"].show then
            oUF:RegisterStyle(A .. "PartyTarget", CreatePartyTarget)
            oUF:SetActiveStyle(A .. "PartyTarget")

            local partytarget = oUF:SpawnHeader("oUF_LumenPartyTarget", nil, nil, "showParty", true, "showRaid", false,
                "showPlayer", true, "yOffset", -5 - cfg.units["party"].height + cfg.units["partytarget"].height,
                "groupBy", "ASSIGNEDROLE", "groupingOrder", "TANK,HEALER,DAMAGER", "oUF-initialConfigFunction", ([[
                self:SetAttribute('unitsuffix', 'target')
                self:SetAttribute('*type2', nil)
                self:SetHeight(%d)
                self:SetWidth(%d)
            ]]):format(cfg.units["partytarget"].height, cfg.units["partytarget"].width))
            partytarget:SetPoint("TOPLEFT", party, "TOPRIGHT", 6, 0)
            partytarget:Show()
            Frames["PartyTarget"] = partytarget
        end

        if cfg.units["partypet"].show then
            oUF:RegisterStyle(A .. "PartyPet", CreatePartyPet)
            oUF:SetActiveStyle(A .. "PartyPet")

            local partypet = oUF:SpawnHeader("oUF_LumenPartyPet", nil, nil, "showParty", true, "showRaid", false,
                "showPlayer", true, "yOffset", -5 - cfg.units["party"].height + cfg.units["partypet"].height, "groupBy",
                "ASSIGNEDROLE", "groupingOrder", "TANK,HEALER,DAMAGER", "oUF-initialConfigFunction", ([[
                self:SetAttribute('unitsuffix', 'pet')
                self:SetAttribute('*type2', nil)
                self:SetHeight(%d)
                self:SetWidth(%d)
            ]]):format(cfg.units["partypet"].height, cfg.units["partypet"].width))
            partypet:SetPoint("TOPLEFT", party, "TOPRIGHT", 6, -cfg.units["partytarget"].height - 2)
            partypet:Show()
            Frames["PartyPet"] = partypet
        end

        local event = CreateFrame("Frame")
        event:RegisterEvent("PLAYER_ENTERING_WORLD")
        event:SetScript("OnEvent", SetStateVisibility)
    end
end
