local _, ns = ...

local lum, core, api, cfg, m, G, oUF, Ace3, LSM = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF, ns.Ace3, ns.LSM
local filters, debuffs, watchers = ns.filters, ns.debuffs, ns.watchers

local UnitAura, UnitPowerType = UnitAura, UnitPowerType

-- -----------------------------------
-- > Health bar
-- -----------------------------------

local onPostUpdateHealth = function(health, unit, min, max)
    local self = health.__owner
    local frame = self.mystyle

    if cfg.units[frame].health.gradientColored then
        local color = CreateColor(oUF:ColorGradient(min, max, 1, 0, 0, 1, 1, 0, unpack(api:RaidColor(unit))))
        health:SetStatusBarColor(color:GetRGB())
    end

    -- Class colored text
    if cfg.units[frame].health.classColoredText then self.Name:SetTextColor(unpack(api:RaidColor(unit))) end
end

function lum:CreateHealthBar(self, frameType)
    if not self.cfg.health.show then return end

    local health = CreateFrame("StatusBar", nil, self)
    local margin = 0
    if (self.cfg.power ~= nil) then margin = cfg.frames[frameType].health.margin + self.cfg.power.height end
    health:SetHeight(self.cfg.height - margin)
    health:SetWidth(self.cfg.width)
    health:SetPoint("TOP")
    health:SetStatusBarTexture(m.textures.status_texture)
    health:SetStatusBarColor(unpack(cfg.colors.health))
    health:GetStatusBarTexture():SetHorizTile(false)

    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture(m.textures.bg_texture)
    health.bg.multiplier = .5

    health.Smooth = self.cfg.health.smooth
    health.PostUpdate = onPostUpdateHealth

    if self.cfg.health.classColored then health.colorClass = true end
    if self.cfg.health.reactionColored then health.colorReaction = true end
    health.colorDisconnected = true
    health.colorTapping = true

    self.Health = health
    return self.Health
end

-- -----------------------------------
-- > Power bar
-- -----------------------------------

function lum:CreateMaxPowerWarningGlow(self)
    local frame = self.Backdrop or self

    local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    glow:SetSize(frame:GetWidth() * 1.4, 24)
    glow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
    glow:SetBlendMode("BLEND")
    glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
    glow:Hide()
    self.Power.glow = glow
end

-- BUG: When max power coloring is not updating correctly
local function PostUpdatePowerColor(self, unit)
    if self.glow then
        local r, g, b = self:GetStatusBarColor()
        r, g, b = core:TintColor(r, g, b, 0.3)
        self.glow:SetVertexColor(r, g, b, 0.9)
    end
end

local function PostUpdatePower(self, unit, cur, min, max)
    local powertype = UnitPowerType("player")

    -- Show the glow when power is at max (except for Mana)
    if self.glow and powertype ~= 0 then
        local playerIsInCombat = UnitAffectingCombat("player")

        if cur == max and playerIsInCombat then
            self.glow:Show()
        else
            self.glow:Hide()
        end
    end
end

function lum:CreatePowerBar(self, frameType)
    if not self.cfg.power.show then return end

    local power = CreateFrame("StatusBar", nil, self)
    power:SetHeight(self.cfg.power.height)
    power:SetWidth(self.cfg.width)
    power:SetStatusBarTexture(m.textures.status_texture)
    power:GetStatusBarTexture():SetHorizTile(false)
    power:SetPoint("TOP", self.Health, "BOTTOM", 0, -cfg.frames[frameType].health.margin)

    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints(power)
    power.bg:SetTexture(m.textures.bg_texture)
    power.bg:SetAlpha(0.15)

    power.Smooth = self.cfg.power.smooth
    power.frequentUpdates = self.cfg.power.frequentUpdates

    power.colorTapping = true
    power.colorDisconnected = false
    if self.cfg.power.classColored then
        power.colorClass = true
    else
        power.colorPower = true
    end

    power.PostUpdateColor = PostUpdatePowerColor
    power.PostUpdate = PostUpdatePower
    self.Power = power

    return self.Power
end

-- ----------------------------------------
-- > Additional Power
-- Power bar for specs like Balance Druid
-- ----------------------------------------

local function AdditionalPowerPostUpdate(self, cur, max)
    local frame = self.__owner.mystyle
    local powertype = UnitPowerType("player")

    if powertype == 0 then return end

    if not cfg.units[frame].additionalpower.hideOnFull then return end

    -- Hide bar if full
    if cur == max or powertype == 0 then
        self:Hide()
    else
        self:Show()
    end
end

function lum:CreateAdditionalPower(self)
    if not self.cfg.additionalpower.show then return end

    local r, g, b = unpack(oUF.colors.power[ADDITIONAL_POWER_BAR_NAME])

    local AdditionalPower = CreateFrame("StatusBar", nil, self, "BackdropTemplate")
    AdditionalPower:SetStatusBarTexture(m.textures.status_texture)
    AdditionalPower:GetStatusBarTexture():SetHorizTile(false)
    AdditionalPower:SetSize(self.cfg.width, self.cfg.additionalpower.height)
    AdditionalPower:SetStatusBarColor(r, g, b)
    AdditionalPower.frequentUpdates = true

    if cfg.units.player.power.show then
        AdditionalPower:SetPoint("TOP", self.Health, "BOTTOM", 0, -16)
        api:SetBackdrop(AdditionalPower, 1.5, 1.5, 1.5, 1.5)
    else
        -- If power is not showing position the additional power below health
        AdditionalPower:SetPoint("TOP", self.Health, "BOTTOM", 0, -cfg.frames.main.health.margin)
    end

    local bg = AdditionalPower:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(AdditionalPower)
    bg:SetTexture(m.textures.bg_texture)
    bg:SetVertexColor(r * 0.25, g * 0.25, b * 0.25)

    local PowerValue = api:CreateFontstring(AdditionalPower, LSM:Fetch("font", Ace3.db.profile.font), cfg.fontsize - 3,
        nil)
    PowerValue:SetPoint("CENTER", AdditionalPower, 0, 0)
    PowerValue:SetJustifyH("CENTER")
    self:Tag(PowerValue, "[lum:altpower]")

    AdditionalPower.bg = bg
    AdditionalPower.PostUpdate = AdditionalPowerPostUpdate
    self.AdditionalPower = AdditionalPower
end

-- -----------------------------------
-- > Heal Prediction
-- -----------------------------------

function lum:CreateHealPrediction(self)
    if not self.Health then return end

    local myBar = CreateFrame("StatusBar", nil, self.Health)
    myBar:SetPoint("TOP")
    myBar:SetPoint("BOTTOM")
    myBar:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
    myBar:SetWidth(self.cfg.width)
    myBar:SetStatusBarTexture(m.textures.status_texture)
    myBar:SetStatusBarColor(125 / 255, 255 / 255, 50 / 255, .4)

    local otherBar = CreateFrame("StatusBar", nil, self.Health)
    otherBar:SetPoint("TOP")
    otherBar:SetPoint("BOTTOM")
    otherBar:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
    otherBar:SetWidth(self.cfg.width)
    otherBar:SetStatusBarTexture(m.textures.status_texture)
    otherBar:SetStatusBarColor(100 / 255, 235 / 255, 200 / 255, .4)

    local absorbBar = CreateFrame("StatusBar", nil, self.Health)
    absorbBar:SetPoint("TOP")
    absorbBar:SetPoint("BOTTOM")
    absorbBar:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
    absorbBar:SetWidth(self.cfg.width)
    absorbBar:SetStatusBarTexture(m.textures.status_texture)
    absorbBar:SetStatusBarColor(18053 / 255, 255 / 255, 205 / 255, .35)

    local healAbsorbBar = CreateFrame("StatusBar", nil, self.Health)
    healAbsorbBar:SetPoint("TOP")
    healAbsorbBar:SetPoint("BOTTOM")
    healAbsorbBar:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
    healAbsorbBar:SetWidth(self.cfg.width)
    healAbsorbBar:SetStatusBarTexture(m.textures.status_texture)
    healAbsorbBar:SetStatusBarColor(183 / 255, 244 / 255, 255 / 255, .35)

    -- Register with oUF
    self.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        maxOverflow = 1
    }
end

-- -----------------------------------
-- > Power Prediction
-- -----------------------------------

-- Fix: Not working for altBar
function lum:CreatePowerPrediction(self)
    local mainBar = CreateFrame("StatusBar", nil, self.Power)
    mainBar:SetStatusBarTexture(m.textures.status_texture)
    mainBar:SetReverseFill(true)
    mainBar:SetWidth(self.cfg.width)
    if self.Power then
        local r, g, b = self.Power:GetStatusBarColor()
        mainBar:SetStatusBarColor(r, g, b, 0.4)
        mainBar:SetPoint("TOP")
        mainBar:SetPoint("BOTTOM")
        mainBar:SetPoint("RIGHT", self.Power:GetStatusBarTexture(), "RIGHT")
    end

    local altBar = CreateFrame("StatusBar", nil, self.AdditionalPower)
    altBar:SetStatusBarTexture(m.textures.status_texture)
    altBar:SetReverseFill(true)
    altBar:SetWidth(self.cfg.width)
    if self.AdditionalPower then
        local r, g, b = self.AdditionalPower:GetStatusBarColor()
        altBar:SetStatusBarColor(r, g, b, 0.4)
        altBar:SetPoint("TOP")
        altBar:SetPoint("BOTTOM")
        altBar:SetPoint("RIGHT", self.AdditionalPower:GetStatusBarTexture(), "RIGHT")
    end

    self.PowerPrediction = {mainBar = mainBar and mainBar, altBar = altBar and altBar}
end

-- -----------------------------------
-- > Attack Swing Bar
-- -----------------------------------

function lum:CreateSwing(self)
    if not cfg.elements.swing.show[G.playerClass] then return end

    local frame = self.mystyle

    if not cfg.units.player.castbar.enable or not self.Castbar then return end

    if frame ~= "player" then return end

    local color = {0.5, 0.9, 1, 1}

    local bar = CreateFrame("StatusBar", nil, self)
    bar:SetSize(self.Castbar:GetWidth() + self.Castbar:GetHeight() + 2, 2)
    bar:SetPoint("TOPLEFT", self.Castbar, "BOTTOMLEFT", -(self.Castbar:GetHeight() + 2), -2)

    local two = CreateFrame("StatusBar", nil, bar)
    two:Hide()
    two:SetAllPoints()
    two:SetStatusBarTexture(m.textures.status_texture)
    two:SetStatusBarColor(unpack(color))
    api:SetBackdrop(two, 2, 2, 2, 2, {0, 0, 0, 0.8})

    local main = CreateFrame("StatusBar", nil, bar)
    main:Hide()
    main:SetAllPoints()
    main:SetStatusBarTexture(m.textures.status_texture)
    main:SetStatusBarColor(unpack(color))
    api:SetBackdrop(main, 2, 2, 2, 2, {0, 0, 0, 0.8})

    local off = CreateFrame("StatusBar", nil, bar)
    off:Hide()
    off:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -3)
    off:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, -6)
    off:SetStatusBarTexture(m.textures.status_texture)
    off:SetStatusBarColor(unpack(color))
    api:SetBackdrop(off, 2, 2, 2, 2, {0, 0, 0, 0.8})

    self.Swing = bar
    self.Swing.Twohand = two
    self.Swing.Mainhand = main
    self.Swing.Offhand = off
    self.Swing.hideOoc = true
end

-- -----------------------------------
-- > Auras
-- -----------------------------------

local function PostCreateIcon(self, button)
    button.count:SetFont(LSM:Fetch("font", Ace3.db.profile.font), self.size - 8, nil)
    local countFrame = button.count:GetParent()
    countFrame:SetFrameLevel(countFrame:GetFrameLevel() + 20)
    lum:CreateMasqueIcon(button, self.size)
end

function lum:SetBuffAuras(self, frame, numAuras, numRows, size, spacing, anchor, parent, parentAnchor, posX, posY,
    initialAnchor, growthX, growthY, showStealableBuffs)
    if not cfg.units[frame].auras.buffs.show then return end

    local PlayerCustomFilter = function(...)
        local spellID = select(13, ...)
        if spellID then
            if filters["ALL"].buffs[spellID] or filters[G.playerClass].buffs[spellID] then return true end
        end
    end

    local buffs = lum:CreateAura(self, numAuras, numRows, size, spacing)
    buffs:SetPoint(anchor, parent, parentAnchor, posX, posY)
    buffs.initialAnchor = initialAnchor
    buffs["growth-y"] = growthY or "DOWN"
    buffs["growth-x"] = growthX or "RIGHT"
    buffs.showStealableBuffs = showStealableBuffs

    if frame == "playerplate" then buffs.CustomFilter = PlayerCustomFilter end

    self.Buffs = buffs
    return buffs
end

function lum:SetDebuffAuras(self, frame, numAuras, numRows, size, spacing, anchor, parent, parentAnchor, posX, posY,
    initialAnchor, growthX, growthY, showDebuffType, onlyShowPlayer)
    if not cfg.units[frame].auras.debuffs.show then return end

    -- Debuffs filter (Blacklist)
    local CustomFilter = function(element, unit, button, name, _, _, _, duration, _, _, _, _, spellID)
        if onlyShowPlayer and not button.isPlayer then return false end
        if not debuffs.list[frame] or not spellID then return true end
        if debuffs.list[frame][spellID] or duration == 0 then return false end
        return true
    end

    local debuffs = lum:CreateAura(self, numAuras, numRows, size, spacing)
    debuffs:SetPoint(anchor, parent, parentAnchor, posX, posY)
    debuffs.initialAnchor = initialAnchor
    debuffs["growth-y"] = growthY or "DOWN"
    debuffs["growth-x"] = growthX or "RIGHT"
    debuffs.showDebuffType = showDebuffType
    debuffs.onlyShowPlayer = onlyShowPlayer
    debuffs.CustomFilter = CustomFilter
    debuffs.PostCreateIcon = PostCreateIcon
    debuffs.disableMouse = true
    self.Debuffs = debuffs
    return debuffs
end

function lum:SetBarTimerAuras(self, frame, numAuras, numRows, size, spacing, anchor, parent, parentAnchor, posX, posY,
    initialAnchor, growthY)
    if not cfg.units[frame].auras.barTimers.show then return end

    local PlayerCustomFilter = function(...)
        local spellID = select(13, ...)
        if spellID then
            if filters["ALL"].buffs[spellID] or filters[G.playerClass].buffs[spellID] then return true end
        end
    end

    local TargetCustomFilter = function(element, unit, button, name, _, _, _, duration, _, _, _, _, spellID)
        if spellID then if (filters[G.playerClass].debuffs[spellID] and button.isPlayer) then return true end end
    end

    local barTimers = lum:CreateBarTimer(self, numAuras, numRows, size, spacing)
    barTimers:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, cfg.frames.secondary.height + 16)
    barTimers.initialAnchor = "BOTTOMLEFT"
    barTimers["growth-y"] = "UP"

    if frame == "player" then
        barTimers.CustomFilter = PlayerCustomFilter
        self.Buffs = barTimers
    end

    if frame == "target" then
        barTimers.CustomFilter = TargetCustomFilter
        self.Debuffs = barTimers
    end

    return barTimers
end

-- -----------------------------------
-- > Spell Watchers (Player Plate)
-- -----------------------------------

local function OnUpdateSpellButton(button, elapsed)
    if button.timeLeft then
        button.timeLeft = max(button.timeLeft - elapsed, 0)

        if button.timeLeft and button.timeLeft > 0 then
            button.time:SetFormattedText(core:FormatTime(button.timeLeft))
            if button.timeLeft < 6 then
                button.time:SetTextColor(0.9, 0.05, 0.05)
            elseif button.timeLeft < 60 then
                button.time:SetTextColor(1, 1, 0.6)
            else
                button.time:SetTextColor(0.1, 0.6, 1.0)
            end
        else
            button.time:SetText()
            button.icon:SetDesaturated(false)
        end
    else
        button.time:SetText()
    end
end

local function PostUpdateSpellWatcher(self, button, expirationTime)
    if expirationTime and expirationTime > 0 then
        button.timeLeft = expirationTime - GetTime()
        button:SetScript("OnUpdate", OnUpdateSpellButton)
    else
        button.time:SetText()
        button:SetScript("OnUpdate", nil)
    end
end

local function PostCreateSpellWatcher(self, button)
    api:CreateDropShadow(button, 4, 4)

    if cfg.elements.spellwatchers.useCustomText then
        local count = button.count
        count:ClearAllPoints()
        count:SetJustifyH("RIGHT")
        count:SetPoint("BOTTOM", button, "TOP", 1, 2)
        count:SetFont(STANDARD_TEXT_FONT, 14, "THICKOUTLINE")

        button.time = button:CreateFontString(nil, "OVERLAY")
        button.time:SetFont(LSM:Fetch("font", Ace3.db.profile.font), 16, "THINOUTLINE")
        button.time:SetPoint("CENTER", button, 0, 0)
        button.time:SetTextColor(1, 1, 0.65)
        button.time:SetShadowOffset(1, -1)
        button.time:SetShadowColor(0, 0, 0, 1)
        button.time:SetJustifyH("CENTER")
    end

    button.overlay:SetTexture(m.textures.button_border)
    -- button.overlay:SetVertexColor(0.05, 0.05, 0.05) -- FIX: Not setting the color...
end

function lum:CreateSpellWatchers(self)
    if not cfg.elements.spellwatchers.show then return end

    local frame = self.mystyle

    local SpellWatchers = CreateFrame("Frame", nil, self)
    SpellWatchers:SetSize(cfg.units[frame].width, cfg.units[frame].width / 5 + 4)
    SpellWatchers:SetPoint("BOTTOM", self, "TOP", 0, 0)
    SpellWatchers.gap = 4
    SpellWatchers.spells = watchers
    SpellWatchers.PostCreateButton = PostCreateSpellWatcher
    if cfg.elements.spellwatchers.useCustomText then
        SpellWatchers.disableCooldown = true
        SpellWatchers.PostUpdateSpell = PostUpdateSpellWatcher
    end
    self.SpellWatchers = SpellWatchers
end

-- --------------------------------------------------
-- > Class Power (Combo Points, Holy Power, etc...)
-- --------------------------------------------------

-- Colorize the last power color element
local function SetMaxClassPowerColor(element, max, powerType)
    if not element or not max then return end

    local color = element.__owner.colors.power.max[powerType]

    if element[max] and color then
        local r, g, b = color[1], color[2], color[3]

        local LastBar = element[max]
        LastBar:SetStatusBarColor(r, g, b)

        local bg = LastBar.bg
        if (bg) then
            local mu = bg.multiplier or 1
            bg:SetColorTexture(r * mu, g * mu, b * mu)
        end
    end
end

-- Post Update ClassPower
local function PostUpdateClassPower(element, cur, max, diff, powerType)
    local frame = element.__owner.mystyle

    if (diff) then
        local maxWidth, gap = cfg.units[frame].width, 6

        for i = 1, max do
            local Bar = element[i]
            Bar:SetWidth(((maxWidth / max) - (((max - 1) * gap) / max)))

            if (i > 1) then
                Bar:ClearAllPoints()
                Bar:SetPoint("LEFT", element[i - 1], "RIGHT", gap, 0)
            end
        end
    end

    SetMaxClassPowerColor(element, max, powerType)
end

local function CreateClassPower(self)
    local frame = self.mystyle

    local ClassPower = {}

    for i = 1, 10 do
        local Bar = CreateFrame("StatusBar", "oUF_LumenClassPower" .. self.unit, self, "BackdropTemplate")
        Bar:SetHeight(cfg.units[frame].classpower.height)
        Bar:SetStatusBarTexture(m.textures.status_texture)
        api:SetBackdrop(Bar, 1.5, 1.5, 1.5, 1.5)

        if (i > 1) then
            Bar:SetPoint("LEFT", ClassPower[i - 1], "RIGHT", 6, 0)
        else
            local pos = cfg.units[frame].classpower.pos
            Bar:SetPoint(pos.a1, self, pos.a2, pos.x, pos.y)
        end

        if (i > 5) then Bar:SetFrameLevel(Bar:GetFrameLevel() + 1) end

        local Background = Bar:CreateTexture(nil, "BORDER")
        Background:SetAllPoints()
        Background:SetTexture(m.textures.bg_texture)
        Background.multiplier = 0.2
        Bar.bg = Background

        ClassPower[i] = Bar
    end

    ClassPower.PostUpdate = PostUpdateClassPower
    self.ClassPower = ClassPower
end

-- Death Knight Runebar
local function CreateRuneBar(self)
    local frame = self.mystyle

    local Runes = {}
    Runes.sortOrder = "asc"
    Runes.colorSpec = true

    for i = 1, 6 do
        local Rune = CreateFrame("StatusBar", "oUF_LumenRuneBar" .. self.unit, self, "BackdropTemplate")
        local numRunes, maxWidth, gap = 6, cfg.units[frame].width, 6
        local width = ((maxWidth / numRunes) - (((numRunes - 1) * gap) / numRunes))

        Rune:SetSize(width, cfg.units[frame].classpower.height)
        Rune:SetStatusBarTexture(m.textures.status_texture)
        api:SetBackdrop(Rune, 1.5, 1.5, 1.5, 1.5)

        if (i == 1) then
            local pos = cfg.units[frame].classpower.pos
            Rune:SetPoint(pos.a1, self, pos.a2, pos.x, pos.y)
        else
            Rune:SetPoint("LEFT", Runes[i - 1], "RIGHT", gap, 0)
        end

        local Background = Rune:CreateTexture(nil, "BORDER")
        Background:SetAllPoints()
        Background:SetTexture(m.textures.bg_texture)
        Background.multiplier = 0.2
        Rune.bg = Background

        Runes[i] = Rune
    end

    self.Runes = Runes
end

-- Class Power (Combo Points, Runes, etc...)
function lum:CreateClassPower(self)
    local frame = self.mystyle

    if not self.unit or not frame then return end

    if not cfg.units[frame].classpower.show then return end

    if G.playerClass == "DEATHKNIGHT" then
        CreateRuneBar(self)
    else
        CreateClassPower(self)
    end
end

-- -----------------------------------
-- > Alternative Power
-- Quest or boss special power
-- -----------------------------------

local function AltPowerPostUpdate(self, unit, cur, min, max)
    if self.unit ~= unit then return end

    local _, r, g, b = _G.UnitAlternatePowerTextureInfo(self.__owner.unit, 2)

    if (r == 1 and g == 1 and b == 1) or not b then r, g, b = 1, 0, 0 end

    self:SetStatusBarColor(r, g, b)
    if cur < max then
        if self.isMouseOver then
            self.Text:SetFormattedText("%s / %s - %d%%", core:ShortNumber(cur), core:ShortNumber(max),
                core:NumberToPerc(cur, max))
        elseif cur > 0 then
            self.Text:SetFormattedText("%s", core:ShortNumber(cur))
        else
            self.Text:SetText(nil)
        end
    else
        if self.isMouseOver then
            self.Text:SetFormattedText("%s", core:ShortNumber(cur))
        else
            self.Text:SetText(nil)
        end
    end
end

local function AlternativePowerOnEnter(self)
    if not self:IsVisible() then return end

    self.isMouseOver = true
    self:ForceUpdate()
    _G.GameTooltip_SetDefaultAnchor(_G.GameTooltip, self)
    self:UpdateTooltip()
end

local function AlternativePowerOnLeave(self)
    self.isMouseOver = nil
    self:ForceUpdate()
    _G.GameTooltip:Hide()
end

function lum:CreateAlternativePower(self)
    if cfg.elements.altpowerbar.show then
        local AlternativePower = CreateFrame("StatusBar", nil, self)
        AlternativePower:SetStatusBarTexture(m.textures.status_texture)
        api:SetBackdrop(AlternativePower, 2, 2, 2, 2)
        AlternativePower:SetHeight(16)
        AlternativePower:SetWidth(200)
        AlternativePower:SetPoint("CENTER", "UIParent", "CENTER", 0, 350)

        AlternativePower.Text = api:CreateFontstring(AlternativePower, LSM:Fetch("font", Ace3.db.profile.font), 10,
            "THINOUTLINE")
        AlternativePower.Text:SetPoint("CENTER", 0, 0)

        local AlternativePowerBG = AlternativePower:CreateTexture(nil, "BORDER")
        AlternativePowerBG:SetAllPoints()
        AlternativePowerBG:SetAlpha(0.3)
        AlternativePowerBG:SetTexture(m.textures.bg_texture)
        AlternativePowerBG:SetColorTexture(1 / 3, 1 / 3, 1 / 3)

        AlternativePower:EnableMouse(true)
        AlternativePower:SetScript("OnEnter", AlternativePowerOnEnter)
        AlternativePower:SetScript("OnLeave", AlternativePowerOnLeave)
        AlternativePower.PostUpdate = AltPowerPostUpdate
        self.AlternativePower = AlternativePower
    end
end

-- ------------------------------------------
-- > Icon Indicators (Combat, Resting, etc.)
-- ------------------------------------------

function lum:CreatePlayerIconIndicators(self)
    if not self.Health then return end

    -- Combat indicator
    local Combat = api:CreateFontstring(self, m.fonts.symbols, 18, "THINOUTLINE")
    Combat:SetPoint("RIGHT", self, "LEFT", -10, 0)
    Combat:SetText("")
    Combat:SetTextColor(255 / 255, 26 / 255, 48 / 255, 0.9)
    self.CombatIndicator = Combat

    -- Resting
    if not api:IsPlayerMaxLevel() then
        local Resting = api:CreateFontstring(self.Health, LSM:Fetch("font", Ace3.db.profile.font), cfg.fontsize - 2,
            "THINOUTLINE")
        Resting:SetPoint("CENTER", self.Health, "TOP", 0, 1)
        Resting:SetText("zZz")
        Resting:SetTextColor(255 / 255, 255 / 255, 255 / 255, 0.80)
        self.RestingIndicator = Resting
    end
end

function lum:CreateTargetIconIndicators(self)
    -- Quest Icon
    local QuestIcon = api:CreateFontstring(self.Health, m.fonts.symbols, 18, "THINOUTLINE")
    QuestIcon:SetPoint("LEFT", self.Health, "RIGHT", 8, 0)
    QuestIcon:SetText("")
    QuestIcon:SetTextColor(238 / 255, 217 / 255, 43 / 255)
    self.QuestIndicator = QuestIcon

    -- Raid Icons
    local RaidIcon = self:CreateTexture(nil, "OVERLAY")
    RaidIcon:SetPoint("LEFT", self, "RIGHT", 8, 1)
    RaidIcon:SetSize(20, 20)
    self.RaidTargetIndicator = RaidIcon
end

-- ------------------------------------------
-- > Party / Raid
-- ------------------------------------------

-- Group Role Indicator
local function UpdateRoleIcon(self, event)
    local lfdrole = self.GroupRoleIndicator

    local role = UnitGroupRolesAssigned(self.unit)

    if UnitIsConnected(self.unit) and role ~= "NONE" then
        lfdrole:SetTexture(cfg.roleIconTextures[role])
        lfdrole:SetVertexColor(unpack(cfg.roleIconColor[role]))
    else
        lfdrole:Hide()
    end
end

function lum:CreateGroupRoleIndicator(self)
    local roleIcon = self:CreateTexture(nil, "OVERLAY")
    roleIcon.Override = UpdateRoleIcon
    self:RegisterEvent("UNIT_CONNECTION", UpdateRoleIcon)
    return roleIcon
end

-- ------------------------------------------
-- > Strings
-- ------------------------------------------

-- Name
function lum:CreateNameString(self, size, outline, x, y, point, width)
    if not self.Health or not self.cfg.name.show then return end

    local name = api:CreateFontstring(self.Health, LSM:Fetch("font", Ace3.db.profile.mfont), size, outline)
    name:SetPoint(point, self.Health, x, y)
    name:SetJustifyH(point)
    name:SetWidth(width)
    name:SetHeight(size)
    self:Tag(name, "[lum:level] [lum:name]")
    self.Name = name
end

-- Party Name
function lum:CreatePartyNameString(self, cfg, size)
    local name = api:CreateFontstring(self.Health, LSM:Fetch("font", Ace3.db.profile.mfont), size, nil)
    name:SetJustifyH("LEFT")
    if cfg.health.classColoredText then
        self:Tag(name, "[raidcolor][lum:name]")
    else
        self:Tag(name, "[lum:name]")
    end
    return name
end

function lum:CreatePartyAttrsString(self, size)
    local attrs = api:CreateFontstring(self.Health, LSM:Fetch("font", Ace3.db.profile.font), size)
    attrs:SetJustifyH("LEFT")
    self:Tag(attrs, "[lum:playerstatus] [lum:leader]")
    return attrs
end

function lum:CreatePartyAttrsOOCString(self, size)
    self.classText = api:CreateFontstring(self.OutOfCombatOverlay, LSM:Fetch("font", Ace3.db.profile.font), size)
    self.classText:SetPoint("TOPRIGHT", self, "TOPRIGHT", -4, -2)
    self.classText:SetJustifyH("RIGHT")
    self:Tag(self.classText, "[lum:level] [raidcolor][class]")
end

function lum:CreatePartySubNameString(self, cfg, size)
    local name = api:CreateFontstring(self.Health, LSM:Fetch("font", Ace3.db.profile.mfont), size)
    name:SetPoint("LEFT", self.Health, 2, 0)
    name:SetJustifyH("LEFT")
    name:SetWidth(cfg.width)
    name:SetHeight(size)
    self:Tag(name, "[lum:name]")
    return name
end

-- Health Value
function lum:CreateHealthValueString(self, size, outline, x, y, point, justify)
    if not self.Health then return end

    local health = self.Health
    health.value = api:CreateFontstring(health, LSM:Fetch("font", Ace3.db.profile.font), size, outline)
    health.value:SetPoint(point, health, x, y)
    health.value:SetJustifyH(justify or point)
    health.value:SetTextColor(1, 1, 1)
    self:Tag(health.value, "[lum:hpperc] [lum:hpvalue]")
end

-- Power Value
function lum:CreatePowerValueString(self, size, outline, x, y, point)
    local style = self.mystyle

    if not self.Power or not cfg.units[style].power.text.show then return end

    local power = self.Power
    power.value = api:CreateFontstring(power, LSM:Fetch("font", Ace3.db.profile.font), size, outline)
    power.value:SetPoint(point, power, x, y)
    power.value:SetJustifyH(point)
    self:Tag(power.value, "[lum:powervalue]")
end

-- Classification
function lum:CreateClassificationString(self, size)
    local clf = api:CreateFontstring(self, LSM:Fetch("font", Ace3.db.profile.font), size)
    clf:SetPoint("LEFT", self, "TOPLEFT", 0, 12)
    clf:SetTextColor(1, 1, 1, 1)
    self:Tag(clf, "[lum:classification]")
end

-- ------------------------------------------
-- > Addons (Experience, Reputation, etc.)
-- ------------------------------------------

-- oUF_Experience Tooltip
local function UpdateExperienceTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -8)

    local isHonor = IsWatchingHonorAsXP()
    local cur = (isHonor and UnitHonor or UnitXP)("player")
    local max = (isHonor and UnitHonorMax or UnitXPMax)("player")
    local per = math.floor(cur / max * 100 + 0.5)
    local bars = cur / max * (isHonor and 5 or 20)

    local rested = (isHonor and GetHonorExhaustion or GetXPExhaustion)() or 0
    rested = math.floor(rested / max * 100 + 0.5)

    if isHonor then
        GameTooltip:SetText(string.format("Honor Rank %s", UnitHonorLevel("player")))
        GameTooltip:AddLine(string.format("|cffff4444%s / %s Points|r", BreakUpLargeNumbers(cur),
            BreakUpLargeNumbers(max)))
        GameTooltip:AddLine(string.format("|cffffffff%.1f bars|r, |cff2581e9%s%% rested|r", bars, rested))
        GameTooltip:Show()
    else
        GameTooltip:SetText(string.format("%s / %s (%s%%)", BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), per))
        GameTooltip:AddLine(string.format("|cffffffff%.1f bars|r, |cff2581e9%s%% rested|r", bars, rested))
        GameTooltip:Show()
    end
end

-- Color the Experience Bar
local function ExperiencePostUpdate(self)
    -- Showing Honor
    if IsWatchingHonorAsXP() then
        self:SetStatusBarColor(255 / 255, 75 / 255, 75 / 255)
        self.Rested:SetStatusBarColor(255 / 255, 205 / 255, 90 / 255)
    else -- Experience
        self:SetStatusBarColor(0 / 255, 100 / 225, 255 / 255)
        self.Rested:SetStatusBarColor(0 / 255, 125 / 225, 255 / 255, 0.3)
    end
end

-- oUF_Reputation Tooltip
local function UpdateReputationTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -8)

    local name, standing, min, max, value, factionID = GetWatchedFactionInfo()
    local isParagon = C_Reputation.IsFactionParagon(factionID)
    local color = FACTION_BAR_COLORS[standing]

    if name and isParagon then
        local currentValue, threshold = C_Reputation.GetFactionParagonInfo(factionID)

        if currentValue and threshold then
            min, max = 0, threshold
            value = currentValue % threshold
            if hasRewardPending then value = value + threshold end
        end

        GameTooltip:AddLine(format("|cff%02x%02x%02x%s|r", 0, 100, 255, name))
        GameTooltip:AddLine(format("|cffcecece%s:|r |cffb7b7b7%d / %d|r", _G["FACTION_STANDING_LABEL" .. standing],
            value, max - min))
        GameTooltip:Show()
    else
        if name and color then
            GameTooltip:AddLine(format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name))
            GameTooltip:AddLine(format("|cffcecece%s:|r |cffb7b7b7%d / %d|r", _G["FACTION_STANDING_LABEL" .. standing],
                value - min, max - min))
            GameTooltip:Show()
        end
    end
end

-- oUF_Experience
function lum:CreateExperienceBar(self)
    if cfg.elements.experiencebar.show then
        local Experience = CreateFrame("StatusBar", nil, self)
        Experience:SetStatusBarTexture(m.textures.status_texture)
        Experience:SetPoint(cfg.elements.experiencebar.pos.a1, cfg.elements.experiencebar.pos.af,
            cfg.elements.experiencebar.pos.a2, cfg.elements.experiencebar.pos.x, cfg.elements.experiencebar.pos.y)
        Experience:SetHeight(cfg.elements.experiencebar.height)
        Experience:SetWidth(cfg.elements.experiencebar.width)

        local Rested = CreateFrame("StatusBar", nil, Experience)
        Rested:SetStatusBarTexture(m.textures.status_texture)
        Rested:SetAllPoints(Experience)
        api:SetBackdrop(Rested, 2, 2, 2, 2)

        local ExperienceBG = Rested:CreateTexture(nil, "BORDER")
        ExperienceBG:SetAllPoints()
        ExperienceBG:SetAlpha(0.3)
        ExperienceBG:SetTexture(m.textures.bg_texture)
        ExperienceBG:SetColorTexture(0.2, 0.2, 0.2)

        Experience:EnableMouse(true)
        Experience.UpdateTooltip = UpdateExperienceTooltip
        Experience.PostUpdate = ExperiencePostUpdate

        self.Experience = Experience
        self.Experience.Rested = Rested
    end
end

-- oUF_Reputation
function lum:CreateReputationBar(self)
    if cfg.elements.experiencebar.show then
        local Reputation = CreateFrame("StatusBar", nil, self)
        Reputation:SetStatusBarTexture(m.textures.status_texture)
        Reputation:SetPoint(cfg.elements.experiencebar.pos.a1, cfg.elements.experiencebar.pos.af,
            cfg.elements.experiencebar.pos.a2, cfg.elements.experiencebar.pos.x, cfg.elements.experiencebar.pos.y)
        Reputation:SetHeight(cfg.elements.experiencebar.height)
        Reputation:SetWidth(cfg.elements.experiencebar.width)
        api:SetBackdrop(Reputation, 2, 2, 2, 2)
        Reputation.colorStanding = true

        local ReputationBG = Reputation:CreateTexture(nil, "BORDER")
        ReputationBG:SetAllPoints()
        ReputationBG:SetAlpha(0.3)
        ReputationBG:SetTexture(m.textures.bg_texture)
        ReputationBG:SetColorTexture(1 / 3, 1 / 3, 1 / 3)

        Reputation:EnableMouse(true)
        Reputation.UpdateTooltip = UpdateReputationTooltip

        self.Reputation = Reputation
    end
end

-- oUF_ArtifactPower
function lum:CreateArtifactPowerBar(self)
    if cfg.elements.artifactpowerbar.show then
        local ArtifactPower = CreateFrame("StatusBar", nil, self)
        ArtifactPower:SetStatusBarTexture(m.textures.status_texture)
        ArtifactPower:SetStatusBarColor(217 / 255, 205 / 255, 145 / 255)
        ArtifactPower:SetPoint(cfg.elements.artifactpowerbar.pos.a1, cfg.elements.artifactpowerbar.pos.af,
            cfg.elements.artifactpowerbar.pos.a2, cfg.elements.artifactpowerbar.pos.x,
            cfg.elements.artifactpowerbar.pos.y)
        ArtifactPower:SetHeight(cfg.elements.artifactpowerbar.height)
        ArtifactPower:SetWidth(cfg.elements.artifactpowerbar.width)
        api:SetBackdrop(ArtifactPower, 2, 2, 2, 2)
        ArtifactPower:EnableMouse(true)
        self.ArtifactPower = ArtifactPower

        local ArtifactPowerBG = ArtifactPower:CreateTexture(nil, "BORDER")
        ArtifactPowerBG:SetAllPoints()
        ArtifactPowerBG:SetAlpha(0.3)
        ArtifactPowerBG:SetTexture(m.textures.bg_texture)
        ArtifactPowerBG:SetColorTexture(1 / 3, 1 / 3, 1 / 3)
    end
end

-- -----------------------------------
-- > Borders
-- -----------------------------------

-- Create Target Border
-- function lum:CreateTargetBorder(self)
--   self.TargetBorder = CreateFrame("Frame", nil, self, "BackdropTemplate")
--   api:CreateBorder(self, self.TargetBorder, 1, 3, "Interface\\ChatFrame\\ChatFrameBackground")
--   self:RegisterEvent("PLAYER_TARGET_CHANGED", ChangedTarget)
--   self:RegisterEvent("RAID_ROSTER_UPDATE", ChangedTarget)
-- end

-- Create Party / Raid health warning status border
function lum:CreateHealthBorder(self)
    self.HPborder = CreateFrame("Frame", nil, self, "BackdropTemplate")
    api:CreateBorder(self, self.HPborder, 1, 4)
    self.HPborder:SetBackdropBorderColor(180 / 255, 255 / 255, 0 / 255, 1)
end

local function UpdateThreat(self, event, unit)
    if (self.unit ~= unit) then return end

    local status = UnitThreatSituation(unit)
    unit = unit or self.unit

    if status and status > 1 then
        local r, g, b = GetThreatStatusColor(status)
        self.ThreatBorder:Show()
        self.ThreatBorder:SetBackdropBorderColor(r, g, b, 1)
    else
        self.ThreatBorder:SetBackdropBorderColor(r, g, b, 0)
        self.ThreatBorder:Hide()
    end
end

-- Create Party / Raid Threat Status Border
function lum:CreateThreatBorder(self)
    self.ThreatBorder = CreateFrame("Frame", nil, self, "BackdropTemplate")
    api:CreateBorder(self, self.ThreatBorder, 1, 3)
    self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", UpdateThreat)
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", UpdateThreat)
end

-- Create Glow Border
function lum:SetGlowBorder(self)
    local glow = CreateFrame("Frame", nil, self, "BackdropTemplate")
    glow:SetFrameLevel(0)
    glow:SetPoint("TOPLEFT", self, "TOPLEFT", -6, 6)
    glow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 6, -6)
    glow:SetBackdrop({
        bgFile = m.textures.white_square,
        edgeFile = m.textures.glow_texture,
        tile = false,
        tileSize = 16,
        edgeSize = 4,
        insets = {left = -4, right = -4, top = -4, bottom = -4}
    })
    glow:SetBackdropColor(0, 0, 0, 0)
    glow:SetBackdropBorderColor(0, 0, 0, 1)

    self.Glowborder = glow
end

-- -----------------------------------
-- > Frame Highlight
-- -----------------------------------

local OnFrameEnter = function(self)
    if not self.Highlight then return end

    self.Highlight:Show() -- Mouseover highlight Show
    UnitFrame_OnEnter(self)
end

local OnFrameLeave = function(self)
    if not self.Highlight then return end

    self.Highlight:Hide() -- Mouseover highlight Hide
    UnitFrame_OnLeave(self)
end

function lum:CreateMouseoverHighlight(self)
    if not self.Health then return end

    local highlight = self.Health:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints(self)
    highlight:SetTexture(m.textures.white_square)
    highlight:SetVertexColor(1, 1, 1, .05)
    highlight:SetBlendMode("ADD")
    highlight:Hide()
    self.Highlight = highlight

    self:SetScript("OnEnter", OnFrameEnter)
    self:SetScript("OnLeave", OnFrameLeave)
end

function lum:CreateDispellable(self)
    local button = CreateFrame('Button', "Dispellable", self.Overlay)
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

    self.Dispellable = {dispelIcon = button, dispelTexture = texture}
end

function lum:CreateBuffWatchers(self, size)
    local watchers = CreateFrame("Frame", nil, self)
    watchers:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 2, 2)
    watchers:SetSize(size * 8, size)
    watchers.size = size
    watchers.spacing = 0
    watchers.initialAnchor = "BOTTOMLEFT"
    watchers["growth-x"] = "RIGHT"
    watchers["growth-y"] = "UP"
    watchers.PostCreateIcon = PostCreateIcon
    watchers.disableMouse = true
    return watchers
end
