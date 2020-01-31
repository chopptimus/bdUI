local parent, ns = ...
local lib = ns.bdConfig

--========================================
-- Methods Here
--========================================
local methods = {
	-- set value to profile[key]
	["set"] = function(self, value)
		self.save = self.module:get_save()

		if (not value) then value = self:get() end
		self.save[self.key] = value
		
		self.check:SetChecked(value)
		if (value) then
			_G[self.check:GetName().."Text"]:SetAlpha(1)
		else
			_G[self.check:GetName().."Text"]:SetAlpha(lib.media.muted)
		end
	end,
	-- return value from profile[key]
	["get"] = function(self)
		self.save = self.module:get_save()

		return self.save[self.key]
	end,
	["onclick"] = function(self)
		self.save[self.key] = self.check:GetChecked()
		self:set()

		self.callback(self.check, nil, self.save[self.key])
	end
}

local skin = function(frame)
	local inside = frame:CreateMaskTexture()
	inside:SetTexture([[Interface\Minimap\UI-Minimap-Background]], 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
	inside:SetSize(12, 12)
	inside:SetPoint('CENTER')

	frame.inside = inside

	local outside = frame:CreateMaskTexture()
	outside:SetTexture([[Interface\Minimap\UI-Minimap-Background]], 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
	outside:SetSize(15, 15)
	outside:SetPoint('CENTER')

	frame.outside = outside

	frame:SetCheckedTexture(lib.media.flat)
	frame:SetNormalTexture(lib.media.flat)
	frame:SetHighlightTexture(lib.media.flat)
	frame:SetDisabledTexture(lib.media.flat)
	frame:SetPushedTexture("")

	local Check = frame:GetCheckedTexture()
	Check:SetVertexColor(unpack(lib.media.blue))
	Check:SetTexCoord(0, 1, 0, 1)
	Check:SetPoint("TOPLEFT", frame, "TOPLEFT", lib.border, -lib.border)
	Check:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -lib.border, lib.border)
	Check:AddMaskTexture(inside)

	local highlight = frame:GetHighlightTexture()
	highlight:SetTexCoord(0, 1, 0, 1)
	highlight:SetVertexColor(1, 1, 1)
	highlight:SetAlpha(0.3)
	highlight:AddMaskTexture(inside)

	local normal = frame:GetNormalTexture()
	normal:SetPoint("TOPLEFT", frame, "TOPLEFT", -lib.border, lib.border)
	normal:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", lib.border, -lib.border)
	normal:SetTexCoord(0, 1, 0, 1)
	normal:SetVertexColor(unpack(lib.media.border))
	normal:AddMaskTexture(outside)

	local disabled = frame:GetDisabledTexture()
	disabled:SetVertexColor(.3, .3, .3)
	disabled:AddMaskTexture(outside)

	-- hooksecurefunc(frame, "SetNormalTexture", function(f, t) if t ~= "" then f:SetNormalTexture("") end end)
	-- hooksecurefunc(frame, "SetPushedTexture", function(f, t) if t ~= "" then f:SetPushedTexture("") end end)
	-- hooksecurefunc(frame, "SetHighlightTexture", function(f, t) if t ~= "" then f:SetHighlightTexture("") end end)
	-- hooksecurefunc(frame, "SetDisabledTexture", function(f, t) if t ~= "" then f:SetDisabledTexture("") end end)
end

--========================================
-- Spawn Element
--========================================
local function create(options, parent)
	options.size = options.size or "half"
	local container = lib:create_container(options, parent, 16)

	local check = CreateFrame("CheckButton", options.name.."_"..options.key, container, "ChatConfigCheckButtonTemplate")
	local text = _G[check:GetName().."Text"]
	check:SetPoint("LEFT", container, "LEFT", -2, 0)
	text:SetText(options.label)
	text:SetFontObject("bdConfig_font")
	text:ClearAllPoints()
	text:SetPoint("LEFT", check, "RIGHT", 2, -1)

	container.callback = options.callback
	container.key = options.key
	container.module = options.module
	container.check = check
	Mixin(container, methods)
	container:set()
	check:SetScript("OnClick", function() container:onclick() end)

	skin(check)

	return container
end

lib:register_element("toggle", create)