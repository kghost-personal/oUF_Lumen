local _, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF

local font = m.fonts.font

-- ------------------------------------------------------------------------
-- > CASTBARS
-- ------------------------------------------------------------------------

local CheckForSpellInterrupt = function(self, unit)
  local initialColor = cfg.units[unit].castbar.color

  if unit == "vehicle" then
    unit = "player"
  end

  if (self.notInterruptible and UnitCanAttack("player", unit)) then
    self.Glowborder:SetBackdropBorderColor(25 / 255, 200 / 255, 255 / 255, 1)
    self.Glowborder:Show()
    self:SetStatusBarColor(0.2, 0.2, 0.2)
  else
    self.Glowborder:Hide()
    self:SetStatusBarColor(unpack(initialColor))
  end
end

-- Castbar Custom Cast TimeText
local CustomCastTimeText = function(self, duration)
  self.Time:SetText(("%.1f"):format(self.channeling and duration or self.max - duration))
  if self.Max then
    self.Max:SetText(("%.1f "):format(self.max))
    self.Max:Show()
  end
end

local onPostCastStart = function(self, unit)
  -- Set the castbar unit's initial color
  self:SetStatusBarColor(unpack(cfg.units[unit].castbar.color))
  CheckForSpellInterrupt(self, unit)
  api:StartFadeIn(self)
end

local OnPostCastFail = function(self, unit)
  -- Color castbar red when cast fails
  self:SetStatusBarColor(182 / 255, 34 / 255, 32 / 255)
  api:StartFadeOut(self)

  if self.Max then
    self.Max:Hide()
  end
end

local OnPostCastInterruptible = function(self, unit)
  CheckForSpellInterrupt(self, unit)
end

-- Castbar generator
function lum:CreateCastbar(self)
  local unit = self.mystyle

  if not unit and not cfg.units[unit].castbar.enabled then
    return
  end

  local Castbar = CreateFrame("StatusBar", nil, self)
  Castbar:SetStatusBarTexture(m.textures.status_texture)
  Castbar:GetStatusBarTexture():SetHorizTile(false)
  Castbar:SetFrameStrata("HIGH")
  Castbar:SetToplevel(true)

  local Background = Castbar:CreateTexture(nil, "BACKGROUND")
  Background:SetAllPoints(Castbar)
  Background:SetTexture(m.textures.bg_texture)
  Background:SetColorTexture(.1, .1, .1)
  Background:SetAlpha(0.3)

  local Text = Castbar:CreateFontString(nil, "OVERLAY")
  Text:SetTextColor(1, 1, 1)
  Text:SetShadowOffset(1, -1)
  Text:SetJustifyH("LEFT")
  Text:SetHeight(12)

  local Time = Castbar:CreateFontString(nil, "OVERLAY")
  Time:SetTextColor(1, 1, 1)
  Time:SetJustifyH("RIGHT")

  local Icon = Castbar:CreateTexture(nil, "ARTWORK")
  Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  local Shield = Castbar:CreateTexture(nil, "OVERLAY")
  Shield:SetSize(20, 20)
  Shield:SetPoint("CENTER", Castbar)

  -- Spell casting time
  Castbar.Max = Castbar:CreateFontString(nil, "OVERLAY")
  Castbar.Max:SetTextColor(150 / 255, 150 / 255, 150 / 255)
  Castbar.Max:SetJustifyH("RIGHT")
  Castbar.Max:SetFont(font, cfg.fontsize - 2, "THINOUTLINE")
  Castbar.Max:SetPoint("RIGHT", Time, "LEFT", 0, 0)

  if (unit == "player") then
    api:SetBackdrop(Castbar, cfg.units.player.castbar.height + 4, 2, 2, 2)
    Castbar:SetStatusBarColor(unpack(cfg.units.player.castbar.color))
    Castbar:SetWidth(cfg.units.player.castbar.width - cfg.units.player.castbar.height + 6)
    Castbar:SetHeight(cfg.units.player.castbar.height)
    Castbar:SetPoint(
      cfg.units.player.castbar.pos.a1,
      cfg.units.player.castbar.pos.af,
      cfg.units.player.castbar.pos.a2,
      cfg.units.player.castbar.pos.x,
      cfg.units.player.castbar.pos.y
    )

    Text:SetFont(font, cfg.fontsize + 1, "THINOUTLINE")
    Text:SetWidth(cfg.units.player.castbar.width - 60)
    Text:SetPoint("LEFT", Castbar, 4, 0)

    Time:SetFont(font, cfg.fontsize + 1, "THINOUTLINE")
    Time:SetPoint("RIGHT", Castbar, -6, 0)

    Icon:SetHeight(cfg.units.player.castbar.height)
    Icon:SetWidth(cfg.units.player.castbar.height)
    Icon:SetPoint("LEFT", Castbar, -(cfg.units.player.castbar.height + 2), 0)

    -- Add safezone
    if (cfg.units.player.castbar.latency.show) then
      local SafeZone = Castbar:CreateTexture(nil, "OVERLAY")
      SafeZone:SetTexture(m.textures.status_texture)
      SafeZone:SetVertexColor(unpack(cfg.units.player.castbar.latency.color))
    end
  elseif (unit == "target") then
    api:SetBackdrop(Castbar, cfg.units.target.castbar.height + 4, 2, 2, 2)
    Castbar:SetStatusBarColor(unpack(cfg.units.target.castbar.color))
    Castbar:SetWidth(cfg.units.target.castbar.width - cfg.units.target.castbar.height + 6)
    Castbar:SetHeight(cfg.units.target.castbar.height)
    Castbar:SetPoint("CENTER", "UIParent", "CENTER", 0, 350)

    Text:SetFont(font, cfg.fontsize + 2, "THINOUTLINE")
    Text:SetWidth(cfg.units.target.castbar.width - 60)
    Text:SetPoint("LEFT", Castbar, 6, 0)

    Time:SetFont(font, cfg.fontsize + 2, "THINOUTLINE")
    Time:SetPoint("RIGHT", Castbar, -6, 0)

    Icon:SetHeight(cfg.units.target.castbar.height)
    Icon:SetWidth(cfg.units.target.castbar.height)
    Icon:SetPoint("LEFT", Castbar, -(cfg.units.target.castbar.height + 2), 0)
  elseif (unit == "focus") then
    api:SetBackdrop(Castbar, cfg.units.focus.castbar.height + 4, 2, 2, 2)
    Castbar:SetStatusBarColor(unpack(cfg.units.focus.castbar.color))
    Castbar:SetWidth(cfg.units.focus.castbar.width - cfg.units.focus.castbar.height + 6)
    Castbar:SetHeight(cfg.units.focus.castbar.height)
    Castbar:SetPoint("CENTER", "UIParent", "CENTER", 0, 300)

    Text:SetFont(font, cfg.fontsize + 1, "THINOUTLINE")
    Text:SetWidth(cfg.units.focus.castbar.width - 60)
    Text:SetPoint("LEFT", Castbar, 4, 0)

    Time:SetFont(font, cfg.fontsize, "THINOUTLINE")
    Time:SetPoint("RIGHT", Castbar, -6, 0)

    Icon:SetHeight(cfg.units.focus.castbar.height)
    Icon:SetWidth(cfg.units.focus.castbar.height)
    Icon:SetPoint("LEFT", Castbar, -(cfg.units.focus.castbar.height + 2), 0)
  elseif (unit == "boss") then
    api:SetBackdrop(Castbar, 2, 2, 2, 2)
    Castbar:SetStatusBarColor(unpack(cfg.units.boss.castbar.color))
    Castbar:SetWidth(cfg.units.boss.castbar.width - cfg.units.boss.castbar.height + 6)
    Castbar:SetHeight(cfg.units.boss.castbar.height)
    Castbar:SetPoint("LEFT", self, cfg.units.boss.height + 2, 0)
    Castbar:SetPoint("TOPRIGHT", self, 0, 0)

    Text:SetFont(font, cfg.fontsize + 1, "THINOUTLINE")
    Text:SetWidth(cfg.units.boss.width - 50)
    Text:SetPoint("LEFT", Castbar, 4, 0)

    Time:SetFont(font, cfg.fontsize, "THINOUTLINE")
    Time:SetPoint("RIGHT", Castbar, -6, 0)

    Icon:SetHeight(cfg.units.boss.height)
    Icon:SetWidth(cfg.units.boss.height)
    Icon:SetPoint("LEFT", Castbar, -(cfg.units.boss.castbar.height + 2), 0)
  end

  -- Non Interruptable glow
  lum:SetGlowBorder(Castbar)
  Castbar.Glowborder:SetPoint("TOPLEFT", Castbar, "TOPLEFT", -(Castbar:GetHeight() + 2) - 6, 6)

  Castbar.PostCastStart = onPostCastStart
  Castbar.PostCastFail = OnPostCastFail
  Castbar.PostCastInterruptible = OnPostCastInterruptible

  Castbar.CustomTimeText = CustomCastTimeText
  Castbar.timeToHold = cfg.elements.castbar.timeToHold

  -- FadeIn / FadeOut animation
  api:CreateFaderAnimation(Castbar)
  Castbar.faderConfig = cfg.elements.castbar.fader

  Castbar.Text = Text
  Castbar.Time = Time
  Castbar.Icon = Icon
  -- Castbar.Shield = Shield
  Castbar.SafeZone = SafeZone
  Castbar.bg = Background
  self.Castbar = Castbar -- register with oUF
end
