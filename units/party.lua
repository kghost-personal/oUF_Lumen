local A, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m,
                                       ns.G, ns.oUF

local frame = "party"

-- -----------------------------------
-- > PARTY UNIT SPECIFIC FUNCTiONS
-- -----------------------------------

-- Post Health Update
local PostUpdateHealth = function(health, unit, min, max)
    local self = health.__owner
    local dead, disconnnected, ghost = UnitIsDead(unit),
                                       not UnitIsConnected(unit),
                                       UnitIsGhost(unit)
    local perc = math.floor(min / max * 100 + 0.5)

    -- Inverted colors
    if cfg.units[frame].health.invertedColors or cfg.units[frame].showPortraits then
        health:SetStatusBarColor(unpack(cfg.colors.inverted))
        health.bg:SetVertexColor(unpack(api:RaidColor(unit)))
        health.bg:SetAlpha(1)
    end

    -- Use gradient colored health
    if cfg.units[frame].health.gradientColored then
        local color = CreateColor(oUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0,
                                                    .5, .9, 0))
        health:SetStatusBarColor(color:GetRGB())
    end

    -- Show health value as the missing value
    health.value:SetText("-" .. core:ShortNumber(max - min))

    if disconnnected or dead or ghost then
        self.HPborder:Hide()
        health.bg:SetVertexColor(.25, .25, .25)
        health.value:Hide()
    else -- Player alive and kicking!
        health.value:Show()
        if (min == max) then -- It has max health
            health.value:Hide()
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
    local dead, disconnnected, ghost = UnitIsDead(unit),
                                       not UnitIsConnected(unit),
                                       UnitIsGhost(unit)

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
        if (unit == "vehicle") then
            power:SetStatusBarColor(143 / 255, 194 / 255, 32 / 255)
        end
    end
end

local PostUpdatePortrait = function(element, unit)
    element:SetModelAlpha(0.2)
    element:SetDesaturation(0.9)
end

-- local PartyUpdate = function(self)
--   print(api:IsPlayerHealer())
-- end

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
    self.Health.colorClass = false
    self.Health.PostUpdate = PostUpdateHealth
    self.Power.PostUpdate = PostUpdatePower

    -- Texts
    lum:CreateHealthValueString(self, m.fonts.font, cfg.fontsize - 2, "THINOUTLINE", 4, 8, "LEFT")
    lum:CreatePartyNameString(self, m.fonts.mlang, cfg.fontsize)

    if self.cfg.health.classColoredText then
        self:Tag(self.Name, "[lum:playerstatus] [lum:leader] [raidcolor][lum:name]")
    end

    self.classText = api:CreateFontstring(self.OutOfCombatOverlay, m.fonts.font, cfg.fontsize, "THINOUTLINE")
    self.classText:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 5)
    self.classText:SetJustifyH("RIGHT")
    self:Tag(self.classText, "[lum:level] [raidcolor][class]")

    -- Portrait
    if self.cfg.showPortraits then
        local Portrait = CreateFrame("PlayerModel", "PartyPortrait", self.Health)
        Portrait:SetAllPoints()
        Portrait:SetFrameLevel(self.Health:GetFrameLevel())
        Portrait:SetAlpha(.2)
        Portrait.PostUpdate = PostUpdatePortrait
        self.Portrait = Portrait
    end

    if self.cfg.auras.buffs.show then
        local buffs = lum:CreateAura(self, 12, 1, self.cfg.height / 2 - 2, 0)
        buffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -2, 2)
        buffs.initialAnchor = "TOPRIGHT"
        buffs["growth-x"] = "LEFT"
        buffs["growth-y"] = "DOWN"
        self.Buffs = buffs
    end

    if self.cfg.auras.debuffs.show then
        -- Debuffs Filter (Blacklist)
        local DebuffsCustomFilter = function(element, unit, button, name, _, _, _, duration, _, _, _, _, spellID)
            if spellID then
                if ns.debuffs.list[frame][spellID] or duration == 0 then
                    return false
                end
            end
            return true
        end

        local debuffs = lum:CreateAura(self, 12, 1, self.cfg.height / 2 - 2, 0)
        debuffs:SetPoint("TOPRIGHT", self.Buffs, "BOTTOMRIGHT", 0, 2)
        debuffs.initialAnchor = "TOPRIGHT"
        debuffs["growth-x"] = "LEFT"
        debuffs["growth-y"] = "DOWN"
        debuffs.showDebuffType = true
        debuffs.CustomFilter = DebuffsCustomFilter
        self.Debuffs = debuffs
    end

    -- Dispellable
    lum:CreateDispellable(self)

    -- Group Role Icon
    local GroupRoleIndicator = lum:CreateGroupRoleIndicator(self.OutOfCombatOverlay)
    GroupRoleIndicator:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 8)
    GroupRoleIndicator:SetSize(12, 12)
    self.GroupRoleIndicator = GroupRoleIndicator

    -- Raid Target Indicator
    local RaidTargetIndicator = self.Overlay:CreateTexture(nil, 'OVERLAY')
    RaidTargetIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
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

    self.Range = cfg.frames.range
    self.CustomClick = {}

    self.Overlay:Raise()
    self.OutOfCombatOverlay:Raise()

    -- self:RegisterEvent("PLAYER_TALENT_UPDATE", PartyUpdate, true)
    -- self:RegisterEvent("CHARACTER_POINTS_CHANGED", PartyUpdate, true)
    -- self:RegisterEvent("PLAYER_ROLES_ASSIGNED", PartyUpdate, true)
    -- self:RegisterEvent("GROUP_ROSTER_UPDATE", PartyUpdate, true)
    -- self:RegisterEvent("GROUP_FORMED", PartyUpdate, true)
    -- self:RegisterEvent("GROUP_JOINED", PartyUpdate, true)
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
    local name = api:CreateFontstring(self.Health, m.fonts.mlang, cfg.fontsize - 2, "THINOUTLINE")
    name:SetPoint("LEFT", self.Health, 2, 0)
    name:SetJustifyH("LEFT")
    name:SetWidth(self.cfg.width / 2)
    name:SetHeight(cfg.fontsize - 2)
    self:Tag(name, "[lum:name]")
    self.Name = name

    lum:CreateHealthValueString(self, m.fonts.font, cfg.fontsize, "THINOUTLINE", -2, 0, "RIGHT")

    -- Heal Prediction
    lum:CreateHealPrediction(self)

    self.Range = cfg.frames.range
    self.CustomClick = {}
end

local function CreatePartyTarget(self)
    return CreatePartySub(self, "partytarget")
end

local function CreatePartyPet(self)
    return CreatePartySub(self, "partypet")
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
if cfg.units[frame].show then
    oUF:RegisterStyle(A .. "Party", CreateParty)
    oUF:SetActiveStyle(A .. "Party")

    local party = oUF:SpawnHeader("oUF_LumenParty", nil, "party", "showParty",
                                  true, "showRaid", false, "showPlayer", true,
                                  "yOffset", -20, "groupBy", "ASSIGNEDROLE",
                                  "groupingOrder", "TANK,HEALER,DAMAGER",
                                  "oUF-initialConfigFunction", ([[
        self:SetAttribute('*type2', nil)
  		self:SetHeight(%d)
  		self:SetWidth(%d)
  	]]):format(cfg.units[frame].height, cfg.units[frame].width))
    party:SetPoint(
        cfg.units[frame].pos.a1, cfg.units[frame].pos.af,
        cfg.units[frame].pos.a2, cfg.units[frame].pos.x,
        cfg.units[frame].pos.y)

    if cfg.units["partytarget"].show then
        oUF:RegisterStyle(A .. "PartyTarget", CreatePartyTarget)
        oUF:SetActiveStyle(A .. "PartyTarget")

        local partytarget = oUF:SpawnHeader("oUF_LumenPartyTarget", nil, "party",
            "showParty", true, "showRaid", false, "showPlayer", true,
            "yOffset", -5 - cfg.units["party"].height + cfg.units["partytarget"].height,
            "groupBy", "ASSIGNEDROLE",
            "groupingOrder", "TANK,HEALER,DAMAGER",
            "oUF-initialConfigFunction", ([[
                 self:SetAttribute('unitsuffix', 'target')
                 self:SetAttribute('*type2', nil)
                 self:SetHeight(%d)
                 self:SetWidth(%d)
            ]]):format(cfg.units["partytarget"].height, cfg.units["partytarget"].width))
        partytarget:SetPoint("TOPLEFT", party, "TOPRIGHT", 6, 0)
    end

    if cfg.units["partypet"].show then
        oUF:RegisterStyle(A .. "PartyPet", CreatePartyPet)
        oUF:SetActiveStyle(A .. "PartyPet")

        local partypet = oUF:SpawnHeader("oUF_LumenPartyPet", nil, "party",
            "showParty", true, "showRaid", false, "showPlayer", true,
            "yOffset", -5 - cfg.units["party"].height + cfg.units["partypet"].height,
            "groupBy", "ASSIGNEDROLE", "groupingOrder", "TANK,HEALER,DAMAGER",
            "oUF-initialConfigFunction", ([[
                 self:SetAttribute('unitsuffix', 'pet')
                 self:SetAttribute('*type2', nil)
                 self:SetHeight(%d)
                 self:SetWidth(%d)
            ]]):format(cfg.units["partypet"].height, cfg.units["partypet"].width))
        partypet:SetPoint("TOPLEFT", party, "TOPRIGHT", 6, - cfg.units["partytarget"].height - 2)
    end
end
