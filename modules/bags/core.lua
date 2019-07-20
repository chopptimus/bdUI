--===============================================
-- FUNCTIONS
--===============================================
local bdUI, c, l = unpack(select(2, ...))
local mod = bdUI:get_module("name")
local config

--===============================================
-- Core functionality
-- place core functionality here
--===============================================
function mod:initialize()
	config = mod._config
	if (not config.enabled) then return end

	BACKPACK_HEIGHT = BACKPACK_HEIGHT or 22

	mod:create_bags()
	mod:create_bank()
	mod:create_loot()
end

--===============================================
-- CONFIG CALLBACK
--===============================================
function mod:callback()

end



mod.bagslots = {
	CharacterBag0Slot,
	CharacterBag1Slot,
	CharacterBag2Slot,
	CharacterBag3Slot
}
mod.bank = {}

-- Set Up Frames
mod.bags = CreateFrame("frame","bdBags", UIParent)
mod.bags:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
mod.bank = CreateFrame("frame","bdBank", UIParent)
mod.bank:SetPoint("LEFT", UIParent, "LEFT", 20, 40)

function mod:resetTracker()
	bdUI.config.persistent.goldtrack = {}
end

function mod:redraw()
	if (mod.bags:IsShown()) then
		mod:bag_generation()
	end
	if (mod.bank:IsShown()) then
		if (mod.onreagents) then
			mod:quickreagent(true)
		else		
			mod:bankGenerate()
		end
	end
end
bdUI:hookEvent("bd_reconfig", function() mod:redraw() end)

function mod:setup(frame)
	frame:SetWidth(config.buttonsize*config.buttonsperrow+20)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(2)
	bdUI:set_backdrop(frame)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton","RightButton")
	frame:RegisterForDrag("LeftButton","RightButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	frame:Hide()
	
	frame.sort = CreateFrame("frame", nil, frame)
	frame.sort:SetHeight(20)
	frame.sort:SetWidth(20)
	frame.sort:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -6)
	frame.sort:SetScript("OnEnter", function()
		frame.sort.text:SetTextColor(1,1,1)
	end)
	frame.sort:SetScript("OnLeave", function()
		frame.sort.text:SetTextColor(.4,.4,.4)
	end)
	frame.sort:SetScript("OnMouseDown", function(self, delta)
		if (frame:GetName() == "bdBags") then 
			SortBags();
		else
			BankItemAutoSortButton:Click()
		end
	end)
	frame.sort.text = frame.sort:CreateFontString(nil, "OVERLAY")
	frame.sort.text:SetPoint("CENTER", frame.sort, "CENTER")
	frame.sort.text:SetFont(bdUI.media.font, 12, "OUTLINE")
	frame.sort.text:SetText("S")
	frame.sort.text:SetTextColor(.4,.4,.4)	
	
	frame.bags = CreateFrame('Frame', nil, frame)
	frame.bags:SetWidth(180)
	frame.bags:SetHeight(40)
	frame.bags:SetFrameLevel(27)
	frame.bags:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -2)
	frame.bags:Hide()
	
	bdUI:set_backdrop(frame.bags)
	
	frame.bags.toggle = CreateFrame('Frame', nil, frame)
	frame.bags.toggle:SetHeight(20)
	frame.bags.toggle:SetWidth(20)
	frame.bags.toggle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
	frame.bags.toggle:EnableMouse(true)
	
	frame.bags.toggle.text = frame.bags.toggle:CreateFontString("button")
	frame.bags.toggle.text:SetPoint("CENTER", frame.bags.toggle, "CENTER")
	frame.bags.toggle.text:SetFont(bdUI.media.font, 12, "OUTLINE")
	frame.bags.toggle.text:SetText("B")
	frame.bags.toggle.text:SetTextColor(.4,.4,.4)
	frame.bags.toggle:SetScript('OnMouseUp', function()
		if (togglebag ~= 1) then
			togglebag = 1
			frame.bags:Show()
			frame.bags.toggle.text:SetTextColor(1,1,1)
		else
			togglebag= 0
			frame.bags:Hide()
			frame.bags.toggle.text:SetTextColor(.4,.4,.4)
		end
	end)
	
	frame.bags.toggle:SetScript("OnEnter", function(self)
		self.text:SetTextColor(1,1,1)
	end)
	frame.bags.toggle:SetScript("OnLeave", function(self)
		self.text:SetTextColor(.4,.4,.4)
	end)
end
mod:setup(mod.bags)
mod:setup(mod.bank)

-- rare/epic border
function mod:IconBorder(border)
	local parent = border:GetParent()
	local count = _G[parent:GetName().."Count"]
	local cooldown = _G[parent:GetName().."Cooldown"]
	local quest = _G[parent:GetName().."IconQuestTexture"] or parent.IconQuestTexture
	local flash = border.flashAnim;
	local glow = border.newitemglowAnim;
	local newitem = parent.NewItemTexture;
	local battlepay = parent.BattlepayItemTexture;
	local r, g, b = border:GetVertexColor()
	r, g, b = bdUI:round(r, 1), bdUI:round(g, 1), bdUI:round(b, 1)
	
	-- set everything to the bottom of the frame
	border:SetTexture(bdUI.media.flat)
	border:ClearAllPoints()
	border:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT", bordersize, bordersize)
	border:SetPoint("TOPRIGHT",parent,"BOTTOMRIGHt", -bordersize, bordersize+3)
	if (not border.top) then
		border.top = parent:CreateTexture(nil)
		border.top:SetTexture(bdUI.media.flat)
		border.top:SetVertexColor(unpack(bdUI.media.backdrop))
		border.top:SetPoint("BOTTOMLEFT",parent, "BOTTOMLEFT", 2, 5)
		border.top:SetPoint("TOPRIGHT",parent, "BOTTOMRIGHT", -2, 6)
	end
	
	-- flash/glow/newitem are a pain
	mod:killShowable(flash)
	mod:killShowable(glow)
	mod:killShowable(newitem)
	mod:killShowable(battlepay)
	parent.hover:SetTexture(bdUI.media.flat)
	parent.hover:SetVertexColor(1, 1, 1, .1)
	
	-- quest
	if (quest) then
		quest:SetTexture(bdUI.media.flat)
		quest:SetVertexColor(1,1,0)
		quest.SetTexture = function() return end
		quest.SetVertexColor = function() return end
		quest:ClearAllPoints()
		quest:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT", bordersize, bordersize)
		quest:SetPoint("TOPRIGHT",parent,"BOTTOMRIGHt", -bordersize, bordersize+3)
	end
	
	-- hide depending on rarity
	local color = r..g..b
	if (color == "111" or color == "0.70.70.7" or color == "000") then
		border:Hide()
		border.top:Hide()
		count:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-1, 1)
	else
		border:Show()
		border.top:Show()
		count:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-1, 5)
	end
end

function mod:SkinEditBox(frame)
	frame.Left:Hide()
	frame.Right:Hide()
	frame.Middle:Hide()
	local icon = _G[frame:GetName().."SearchIcon"]
	icon:ClearAllPoints()
	icon:SetPoint("LEFT",frame,"LEFT",4,-1)

	frame.Instructions:SetFont(bdUI.media.font,12)
	frame.Instructions:ClearAllPoints()
	frame.Instructions:SetPoint("LEFT",frame,"LEFT",18,0)
	
	frame.SetHeight = function() return end
	frame.SetWidth = function() return end
	frame.SetSize = function() return end
	
	bdUI:set_backdrop(frame)
end

function mod:skin(frame)
	local aurora = select(1,IsAddOnLoaded("Aurora"))
	if (aurora) then
		local F, C = unpack(Aurora or FreeUI)
		C.defaults['bags'] = false
	end
	if (frame.skinned) then return end

	-- bdUI:StripTextures(frame, true)

	-- frame.text = frame:CreateFontString(nil, overlay)
	-- frame.text:SetFont(bdUI.media.font, 12, "THINOUTLINE")
	-- frame.text:SetAllPoints(frame)

	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(6)

	local normal = _G[frame:GetName().."NormalTexture"]
	local count = _G[frame:GetName().."Count"]
	local cooldown = _G[frame:GetName().."Cooldown"]
	local icon = _G[frame:GetName().."IconTexture"]
	local flash = frame.flash
	normal:SetAllPoints(frame)
	-- if (flash) then
	-- 	flash:SetAllPoints(parent)
	-- end
	frame:SetAlpha(1)
	
	frame:SetNormalTexture("")
	frame:SetPushedTexture("")
	count:SetFont(bdUI.media.font,13,"THINOUTLINE")
	count:SetJustifyH("RIGHT")
	count:SetAlpha(.9)
	
	-- button textures
	local hover = frame:CreateTexture()
	hover:SetTexture(bdUI.media.flat)
	hover:SetVertexColor(1, 1, 1, .1)
	hover:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-2)
	hover:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
	frame.hover = hover
	frame:SetHighlightTexture(hover)
	frame.SetHighlightTexture = function() return end
	
	frame:set_backdrop({bgFile = bdUI.media.flat, edgeFile = bdUI.media.flat, edgeSize = 2})
	frame:set_backdropColor(unpack(bdUI.media.backdrop))
	frame:set_backdropBorderColor(unpack(bdUI.media.border))
	
	icon:SetAllPoints(frame)
	icon:SetPoint("TOPLEFT", frame, 2, -2)
	icon:SetPoint("BOTTOMRIGHT", frame, -2, 2)
	icon:SetTexCoord(.1, .9, .1, .9)
	
	cooldown:GetRegions():SetFont(bdUI.media.font, 14, "OUTLINE")
	cooldown:GetRegions():SetJustifyH("Center")
	cooldown:GetRegions():ClearAllPoints()
	cooldown:GetRegions():SetAllPoints(cooldown)
	cooldown:SetParent(frame)
	cooldown:SetAllPoints(frame)
	
	hooksecurefunc(frame.IconBorder,"SetVertexColor", function() mod:IconBorder(frame.IconBorder) end)
	mod:IconBorder(frame.IconBorder)
	frame.skinned = true
end

function mod:killShowable(frame)
	if (not frame) then return end
	frame:Hide()
	frame.Show = function() return end
	frame.Hide = function() return end
	frame.SetAlpha = function() return end
	frame.SetTextColor = function() return end
	frame.SetVertexColor = function() return end
end

-- Calls when each bag is opened
function mod:Draw(frame,size,id)
	BagItemSearchBox:ClearAllPoints()
	frame.size = size;
	for i = 1, size do
		local index = size - i + 1;
		local itemButton = _G[frame:GetName().."Item"..i];
		itemButton:SetID(index);
		itemButton:Show();
	end
	frame:SetID(id);
	frame:Show()
	
	--print(id)
	if (id == 4) then
		mod:bag_generation(frame,size,id)
	elseif (id == 5) then
		mod:bankGenerate(frame,size,id)
	end
	
	-- hide everything that shouldn't be there
	for i = 1, 12 do
		local frame = _G['ContainerFrame'..i]
		local closebutton = _G[frame:GetName().."CloseButton"]
		local portrait = _G[frame:GetName().."PortraitButton"]
		local background = _G[frame:GetName().."BackgroundTop"]
		local extraslots = _G[frame:GetName().."ExtraBagSlotsHelpBox"]

		frame:SetFrameStrata("HIGH")
		frame:SetFrameLevel(3)
		frame:EnableMouse(false)
		frame:DisableDrawLayer("BACKGROUND")
		frame:DisableDrawLayer("BORDER")
		frame:DisableDrawLayer("ARTWORK")
		frame:DisableDrawLayer("OVERLAY")
		frame:DisableDrawLayer("HIGHLIGHT")

		mod:killShowable(extraslots)
		mod:killShowable(frame.FilterIcon)
		mod:killShowable(frame.ClickableTitleFrame)
		mod:killShowable(closebutton)
		mod:killShowable(portrait)
		mod:killShowable(background)
		for p = 1, 7 do
			select(p, _G["ContainerFrame"..i]:GetRegions()):SetAlpha(0)
		end
	end
	for i = 1, 5 do				
		select(i, _G['BankFrame']:GetRegions()):Hide()
	end
	for i = 1, 5 do				
		select(i, _G['BankFrame']:GetChildren()):Hide()
	end
	for i = 1, 5 do
		local child = select(i, _G['BankFrameMoneyFrameInset']:GetChildren())
		if (not child) then break end
		child:Hide()
	end
	-- _G['BankFrame'].NineSlice:Hide()
	_G["BackpackTokenFrame"]:GetRegions():SetAlpha(0)
	
	
	BankFrameCloseButton:Hide()
	BankFrameMoneyFrame:Hide()
	bdUI:StripTextures(BankFrameMoneyFrameInset)
	bdUI:StripTextures(BankFrameMoneyFrameBorder)
	bdUI:StripTextures(BankFrameMoneyFrame)
	bdUI:StripTextures(BankFrame)
	bdUI:StripTextures(BankSlotsFrame,true)
	BankSlotsFrame:SetFrameStrata("HIGH")
	BankSlotsFrame:SetFrameLevel(3)
	BankSlotsFrame:SetParent(mod.bank)
	ReagentBankFrame:SetFrameStrata("HIGH")
	ReagentBankFrame:SetFrameLevel(3)
	ReagentBankFrame:SetParent(mod.bank)
	bdUI:StripTextures(ReagentBankFrame)
	ReagentBankFrame:DisableDrawLayer("BACKGROUND")
	ReagentBankFrame:DisableDrawLayer("ARTWORK")
	BankPortraitTexture:Hide()
	BankFrame:EnableMouse(false)
	BankSlotsFrame:EnableMouse(false)
	mod:killShowable(BagHelpBox)
end


-- Make entire bags show or hide when the main bag closes
ContainerFrame1Item1:HookScript("OnHide",function() mod.bags:Hide() end)
ContainerFrame1Item1:HookScript("OnShow",function() mod.bags:Show() end)
BankFrame:HookScript("OnHide",function() ToggleAllBags() end)
BankFrame:HookScript("OnShow",function() ToggleAllBags() end)
hooksecurefunc(BankFrame,"Show",function() ToggleAllBags() end)
hooksecurefunc(BankFrame,"Hide",function() ToggleAllBags() end)
-- hooksecurefunc("SortBags", function()  end)

local evHandler = CreateFrame("frame")
evHandler:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
evHandler:SetScript("OnEvent", function()
	-- print("bnew item")
	mod:bag_generation()
end)

-- Hijack blizzard functions
-- -- PS i hate that i'm doing this. todo is rewrite this entire addon
function ToggleBag() return end
function ToggleBackpack() return end
function OpenBackpack() return end
function CloseBackpack() return end
function updateContainerFrameAnchors() return end
function ContainerFrame_GenerateFrame(frame, size, id) mod:Draw(frame, size, id) end
function OpenAllBags(frame) ToggleAllBags("open") end

-- Open all Bags
function ToggleAllBags(func)
	-- show all bags
	if (BankFrame:IsShown()) then
		mod.bank:Show()
		mod.bags:Show()
		for i=0, NUM_CONTAINER_FRAMES, 1 do OpenBag(i) end
	else -- show only main backpack
		if (mod.bags:IsShown() and (not func or not func == "open")) then
			for i=0, NUM_CONTAINER_FRAMES, 1 do CloseBag(i) end
			mod.bags:Hide()
			mod.bank:Hide()
			CloseBankFrame()
		else
			for i=0, NUM_CONTAINER_FRAMES, 1 do OpenBag(i) end
			mod.bags:Show()
		end
	end

	mod:bag_generation()
end
BackpackTokenFrame:Hide();