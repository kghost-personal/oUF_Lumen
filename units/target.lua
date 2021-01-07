local A, ns = ...

local lum, core, api, cfg, m, G, oUF = ns.lum, ns.core, ns.api, ns.cfg, ns.m, ns.G, ns.oUF
local filters = ns.filters

local frame = "target"

-- -----------------------------------
-- > TARGET STYLE
-- -----------------------------------

local function CreateTarget(self)
    self.mystyle = frame
    self.cfg = cfg.units[frame]

    lum:SharedStyle(self, "main")

    -- Texts
    lum:CreateNameString(self, cfg.fontsize, nil, 4, -0.5, "LEFT", self.cfg.width - 56)
    lum:CreateHealthValueString(self, cfg.fontsize, nil, -4, -0.5, "RIGHT")
    lum:CreatePowerValueString(self, cfg.fontsize - 3, nil, 0, 0, "CENTER")
    lum:CreateClassificationString(self, cfg.fontsize - 1)

    lum:CreateCastbar(self)
    lum:CreateHealPrediction(self)
    lum:CreateTargetIconIndicators(self)

    -- Auras
    lum:SetBuffAuras(self, frame, 8, 1, cfg.frames.secondary.height + 4, 2, "TOPLEFT", self, "BOTTOMLEFT", -2, -2,
        "BOTTOMLEFT", "RIGHT", "DOWN", true)

    lum:SetBarTimerAuras(self, frame, 12, 12, 24, 2, "BOTTOMLEFT", self, "TOPLEFT", -2,
        cfg.frames.secondary.height + 16, "BOTTOMLEFT", "UP")
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
ns.Frames.Target = function()
    if cfg.units[frame].show then
        oUF:RegisterStyle("oUF_LumenTarget", CreateTarget)
        oUF:SetActiveStyle("oUF_LumenTarget")
        local f = oUF:Spawn(frame, "oUF_LumenTarget")

        -- Frame Visibility
        if cfg.units[frame].visibility then
            f:Disable()
            RegisterAttributeDriver(f, "state-visibility", cfg.units[frame].visibility)
        end

        -- Fader
        if cfg.units[frame].fader then api:CreateFrameFader(f, cfg.units[frame].fader) end
    end
end
