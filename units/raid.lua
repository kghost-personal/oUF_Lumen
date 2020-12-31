local A, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

local frame = "raid"

-- -----------------------------------
-- > PARTY UNIT SPECIFIC FUNCTiONS
-- -----------------------------------

-- Post Health Update
local PostUpdateHealth = function(health, unit, min, max)
    local self = health.__owner
    local dead, disconnnected, ghost = UnitIsDead(unit), not UnitIsConnected(unit), UnitIsGhost(unit)
    local perc = math.floor(min / max * 100 + 0.5)

    -- Inverted colors
    if cfg.units[frame].health.invertedColors or cfg.units[frame].showPortraits then
        health:SetStatusBarColor(unpack(cfg.colors.inverted))
        health.bg:SetVertexColor(unpack(api:RaidColor(unit)))
        health.bg:SetAlpha(1)
    end

    -- Use gradient colored health
    if cfg.units[frame].health.gradientColored then
        local color = CreateColor(oUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0, .5, .9, 0))
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

local PostUpdatePortrait = function(element, unit)
    element:SetModelAlpha(0.2)
    element:SetDesaturation(0.9)
end

-- -----------------------------------
-- > PARTY STYLE
-- -----------------------------------

local function CreateRide(self)
    self.mystyle = frame
    self.cfg = cfg.units[frame]

    lum:SharedStyle(self, "secondary")

    self.Overlay = CreateFrame("Frame", nil, self)
    self.Overlay:SetAllPoints()

    -- Health & Power
    self.Health.PostUpdate = PostUpdateHealth
    self.Power.PostUpdate = PostUpdatePower

    -- Texts
    lum:CreateHealthValueString(self, m.fonts.font, cfg.fontsize - 2, "THINOUTLINE", 4, 8, "LEFT")
    lum:CreatePartyNameString(self, m.fonts.mlang, cfg.fontsize)

    if self.cfg.health.classColoredText then
        self:Tag(self.Name, "[lum:playerstatus] [lum:leader] [raidcolor][lum:name]")
    end

    -- Dispellable
    local button = CreateFrame('Button', nil, self.Overlay)
    button:SetPoint('CENTER')
    button:SetSize(22, 22)
    button:SetToplevel(true)
    button:EnableMouse(false)

    local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
    cd:SetHideCountdownNumbers(false) -- set to true to disable cooldown numbers on the cooldown spiral
    cd:SetAllPoints()
    cd:EnableMouse(false)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()

    local overlay = button:CreateTexture(nil, 'OVERLAY')
    overlay:SetTexture('Interface\\Buttons\\UI-Debuff-Overlays')
    overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    overlay:SetAllPoints()

    local count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal', 1)
    count:SetPoint('BOTTOMRIGHT', -1, 1)

    local texture = self.Health:CreateTexture(nil, 'OVERLAY')
    texture:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 0) -- hide in case the class can't dispel at all
    texture.dispelAlpha = 0.2

    button.cd = cd
    button.icon = icon
    button.overlay = overlay
    button.count = count
    button:Hide() -- hide in case the class can't dispel at all

    self.Dispellable = {dispelIcon = button, dispelTexture = texture}

    -- Group Role Icon
    local GroupRoleIndicator = lum:CreateGroupRoleIndicator(self.Overlay)
    GroupRoleIndicator:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 8)
    GroupRoleIndicator:SetSize(12, 12)
    self.GroupRoleIndicator = GroupRoleIndicator

    -- Raid Target Indicator
    local RaidTargetIndicator = self.Overlay:CreateTexture(nil, 'OVERLAY')
    RaidTargetIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
    RaidTargetIndicator:SetSize(16, 16)
    self.RaidTargetIndicator = RaidTargetIndicator

    -- Ready Check Icon
    local ReadyCheck = self.Overlay:CreateTexture()
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
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
if cfg.units[frame].show then
    oUF:RegisterStyle(A .. "Raid", CreateRide)
    oUF:SetActiveStyle(A .. "Raid")

    local raid = oUF:SpawnHeader("oUF_LumenParty", nil, "raid", "groupBy", "GROUP", "groupingOrder", "1,2,3,4,5,6,7,8",
                                 "unitsPerColumn", 5, "showParty", false, "showPlayer", true, "showRaid", true,
                                 "yOffset", -5, "oUF-initialConfigFunction", ([[
            self:SetAttribute('*type2', nil)
            self:SetHeight(%d)
            self:SetWidth(%d)
        ]]):format(cfg.units[frame].height, cfg.units[frame].width))
    raid:SetPoint(cfg.units[frame].pos.a1, cfg.units[frame].pos.af, cfg.units[frame].pos.a2, cfg.units[frame].pos.x,
                  cfg.units[frame].pos.y)
end
