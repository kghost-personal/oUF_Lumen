local A, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF
local filters = ns.filters

local frame = "player"

-- -----------------------------------
-- > Player Style
-- -----------------------------------

local function CreatePlayer(self)
    self.mystyle = frame
    self.cfg = cfg.units[frame]

    lum:SharedStyle(self, "main")

    -- Text strings
    lum:CreateNameString(self, cfg.fontsize, nil, 4, -0.5, "LEFT", self.cfg.width - 56)
    lum:CreateHealthValueString(self, cfg.fontsize, nil, -4, -0.5, "RIGHT")
    lum:CreatePowerValueString(self, cfg.fontsize - 3, nil, 0, 0, "CENTER")

    lum:CreateCastbar(self)
    lum:CreateAdditionalPower(self)
    lum:CreateHealPrediction(self)
    lum:CreatePowerPrediction(self)
    lum:CreateAlternativePower(self)
    lum:CreatePlayerIconIndicators(self)
    lum:CreateSwing(self)
    lum:MirrorBars()

    -- Addons
    lum:CreateExperienceBar(self)
    lum:CreateReputationBar(self)
    lum:CreateArtifactPowerBar(self)

    -- Auras
    lum:SetDebuffAuras(self, frame, 12, 12, cfg.frames.main.height + 4, 4, "BOTTOMRIGHT", self, "BOTTOMLEFT", -56, -2,
        "BOTTOMRIGHT", nil, "UP", true)

    lum:SetBarTimerAuras(self, frame, 12, 12, 24, 2, "BOTTOMLEFT", self, "TOPLEFT", -2,
        cfg.frames.secondary.height + 16, "BOTTOMLEFT", "UP")
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
ns.Frames.Player = function()
    if cfg.units[frame].show then
        oUF:RegisterStyle("oUF_LumenPlayer", CreatePlayer)
        oUF:SetActiveStyle("oUF_LumenPlayer")
        local f = oUF:Spawn(frame, "oUF_LumenPlayer")

        -- Frame Visibility
        if cfg.units[frame].visibility then
            f:Disable()
            RegisterAttributeDriver(f, "state-visibility", cfg.units[frame].visibility)
        end

        -- Fader
        if cfg.units[frame].fader then api:CreateFrameFader(f, cfg.units[frame].fader) end
    end
end
