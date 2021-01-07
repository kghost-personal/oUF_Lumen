--[[
# Element: BuffWatchers

Handles creation and updating of aura icons.

## Widget

BuffWatchers   - A Frame to hold `Button`s representing both buffs and debuffs.

## Notes

At least one of the above widgets must be present for the element to work.

## Options

.disableMouse       - Disables mouse events (boolean)
.disableCooldown    - Disables the cooldown spiral (boolean)
.size               - Aura icon size. Defaults to 16 (number)
.spacing            - Spacing between each icon. Defaults to 0 (number)
.['spacing-x']      - Horizontal spacing between each icon. Takes priority over `spacing` (number)
.['spacing-y']      - Vertical spacing between each icon. Takes priority over `spacing` (number)
.['growth-x']       - Horizontal growth direction. Defaults to 'RIGHT' (string)
.['growth-y']       - Vertical growth direction. Defaults to 'UP' (string)
.initialAnchor      - Anchor point for the icons. Defaults to 'BOTTOMLEFT' (string)
.tooltipAnchor      - Anchor point for the tooltip. Defaults to 'ANCHOR_BOTTOMRIGHT', however, if a frame has anchoring
                      restrictions it will be set to 'ANCHOR_CURSOR' (string)

## Examples

    -- Position and size
    local Buffs = CreateFrame('Frame', nil, self)
    Buffs:SetPoint('RIGHT', self, 'LEFT')
    Buffs:SetSize(16 * 2, 16 * 16)

    -- Register with oUF
    self.Buffs = Buffs
--]] local _, ns = ...
local oUF = ns.oUF

local VISIBLE = 1
local HIDDEN = 0

local function UpdateTooltip(self) GameTooltip:SetUnitAura(self:GetParent().__owner.unit, self:GetID()) end

local function onEnter(self)
    if (not self:IsVisible()) then return end

    GameTooltip:SetOwner(self, self:GetParent().tooltipAnchor)
    self:UpdateTooltip()
end

local function onLeave() GameTooltip:Hide() end

local function createAuraIcon(element, index)
    local button = CreateFrame("Button", element:GetDebugName() .. "Button" .. index, element)
    button:RegisterForClicks("RightButtonUp")

    local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
    cd:SetAllPoints()

    local icon = button:CreateTexture(nil, "BORDER")
    icon:SetAllPoints()

    local countFrame = CreateFrame("Frame", nil, button)
    countFrame:SetAllPoints(button)
    countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

    local count = countFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", countFrame, "BOTTOMRIGHT", -1, 0)

    button.UpdateTooltip = UpdateTooltip
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)

    button.icon = icon
    button.count = count
    button.cd = cd

    --[[ Callback: BuffWatchers:PostCreateIcon(button)
	Called after a new aura button has been created.

	* self   - the widget holding the aura buttons
	* button - the newly created aura button (Button)
	--]]
    if (element.PostCreateIcon) then element:PostCreateIcon(button) end

    return button
end

local function updateIcon(element, unit)
    local exists = {}

    local index = 1
    while (true) do
        local name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
            canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3 =
            UnitAura(unit, index)

        if (name == nil) then break end

        local position = element.Watchers[spellID]
        if (position and (caster == "player" or caster == "vehicle")) then
            exists[position] = true
            local button = element.Icons[position]

            -- We might want to consider delaying the creation of an actual cooldown
            -- object to this point, but I think that will just make things needlessly
            -- complicated.
            if (button.cd and not element.disableCooldown) then
                if (duration and duration > 0) then
                    button.cd:SetCooldown(expiration - duration, duration)
                    button.cd:Show()
                else
                    button.cd:Hide()
                end
            end

            if (button.icon) then button.icon:SetTexture(texture) end
            if (button.count) then button.count:SetText(count > 1 and count) end

            local size = element.size or 16
            button:SetSize(size, size)

            button:EnableMouse(not element.disableMouse)
            button:SetID(index)
            button:Show()

            --[[ Callback: BuffWatchers:PostUpdateIcon(unit, button, index, position)
			Called after the aura button has been updated.

			* self        - the widget holding the aura buttons
			* unit        - the unit on which the aura is cast (string)
			* button      - the updated aura button (Button)
			* index       - the index of the aura (number)
			* position    - the actual position of the aura button (number)
			* duration    - the aura duration in seconds (number?)
			* expiration  - the point in time when the aura will expire. Comparable to GetTime() (number)
			* debuffType  - the debuff type of the aura (string?)['Curse', 'Disease', 'Magic', 'Poison']
			* isStealable - whether the aura can be stolen or purged (boolean)
			--]]
            if (element.PostUpdateIcon) then
                element:PostUpdateIcon(unit, button, index, position, duration, expiration, debuffType, isStealable)
            end
        end

        index = index + 1
    end

    for spellId, index in pairs(element.Watchers) do if (exists[index] == nil) then element.Icons[index]:Hide() end end
end

local function SetPosition(element, index)
    local sizex = (element.size or 16) + (element["spacing-x"] or element.spacing or 0)
    local sizey = (element.size or 16) + (element["spacing-y"] or element.spacing or 0)
    local anchor = element.initialAnchor or "BOTTOMLEFT"
    local growthx = (element["growth-x"] == "LEFT" and -1) or 1
    local growthy = (element["growth-y"] == "DOWN" and -1) or 1
    local cols = math.floor(element:GetWidth() / sizex + 0.5)

    local button = element.Icons[index]
    local col = (index - 1) % cols
    local row = math.floor((index - 1) / cols)

    button:ClearAllPoints()
    button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
end

local function UpdateWatchers(self, event, unit)
    if (self.unit ~= unit) then return end

    local element = self.BuffWatchers
    if (element) then
        --[[ Callback: BuffWatchers:PreUpdate(unit)
		Called before the element has been updated.

		* self - the widget holding the aura buttons
		* unit - the unit for which the update has been triggered (string)
		--]]
        if (element.PreUpdate) then element:PreUpdate(unit) end

        updateIcon(element, unit)

        --[[ Callback: BuffWatchers:PostUpdate(unit)
		Called after the element has been updated.

		* self - the widget holding the aura buttons
		* unit - the unit for which the update has been triggered (string)
		--]]
        if (element.PostUpdate) then element:PostUpdate(unit) end
    end
end

local function Update(self, event, unit)
    if (self.unit ~= unit) then return end

    UpdateWatchers(self, event, unit)

    -- Assume no event means someone wants to re-anchor things. This is usually
    -- done by UpdateAllElements and :ForceUpdate.
    if (event == "ForceUpdate" or not event) then
        local element = self.BuffWatchers
        if (element) then
            for spellId, index in pairs(element.Watchers) do
                (element.SetPosition or SetPosition)(element, index)
            end
        end
    end
end

local function ForceUpdate(element) return Update(element.__owner, "ForceUpdate", element.__owner.unit) end

local function Enable(self)
    if (self.BuffWatchers) then
        self:RegisterEvent("UNIT_AURA", UpdateWatchers)

        local element = self.BuffWatchers
        if (element) then
            element.__owner = self
            element.ForceUpdate = ForceUpdate

            element.Icons = {}
            for spellId, index in pairs(element.Watchers) do
                if (element.Icons[index] == nil) then
                    --[[ Override: BuffWatchers:CreateIcon(position)
					Used to create the aura button at a given position.

					* self     - the widget holding the aura buttons
					* position - the position at which the aura button is to be created (number)

					## Returns

					* button - the button used to represent the aura (Button)
					--]]
                    element.Icons[index] = (element.CreateIcon or createAuraIcon)(element, index)

                    --[[ Override: BuffWatchers:SetPosition(from, to)
					Used to (re-)anchor the aura buttons.
					Called when new aura buttons have been created or if :PreSetPosition is defined.

					* self - the widget that holds the aura buttons
					* from - the offset of the first aura button to be (re-)anchored (number)
					* to   - the offset of the last aura button to be (re-)anchored (number)
					--]]
                    local f = (element.SetPosition or SetPosition)
                    f(element, index)
                end
            end

            -- Avoid parenting GameTooltip to frames with anchoring restrictions,
            -- otherwise it'll inherit said restrictions which will cause issues
            -- with its further positioning, clamping, etc
            if (not pcall(self.GetCenter, self)) then
                element.tooltipAnchor = "ANCHOR_CURSOR"
            else
                element.tooltipAnchor = element.tooltipAnchor or "ANCHOR_BOTTOMRIGHT"
            end

            element:Show()
        end

        return true
    end
end

local function Disable(self)
    if (self.BuffWatchers) then
        self:UnregisterEvent("UNIT_AURA", UpdateWatchers)

        if (self.BuffWatchers) then self.BuffWatchers:Hide() end
    end
end

oUF:AddElement("BuffWatchers", Update, Enable, Disable)
