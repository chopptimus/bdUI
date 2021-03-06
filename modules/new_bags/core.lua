--===============================================
-- FUNCTIONS
--===============================================
local bdUI, c, l = unpack(select(2, ...))
local mod = bdUI:get_module("New Bags")
local config = {}

-- default variables
mod.containers = {}
mod.bag_frames = {}
local ace_hook = LibStub("AceHook-3.0")
ace_hook:Embed(mod)

--===============================================
-- Core functionality
-- place core functionality here
--===============================================
function mod:initialize()
	mod.config = mod:get_save()
	config = mod.config
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return end
	if (not config.enabled or mod.initialized) then return end
	mod.initialized = true

	-- store saved variable for messing with
	config.categories = config.categories or {}
	-- config.categories = {}
	mod.categories = config.categories

	if (not mod.categories.first_run_complete) then
		mod:create_category("New Items", {
			["new_items"] = true,
			["default"] = true,
			["duplicate"] = true,
			["locked"] = true,
			["order"] = -1,
		})
		mod:create_category("Weapons", {
			["type"] = mod.types["Weapon"],
			["default"] = true,
			["order"] = 1,
		})
		mod:create_category("Armor", {
			["type"] = mod.types["Armor"],
			["default"] = true,
			["order"] = 2,
		})
		mod:create_category("Quest & Keys", {
			["type"] = tMerge(mod.types["Quest"], mod.types["Keys"]),
			["default"] = true,
			["itemids"] = {138019}
		})
		mod:create_category("Hearths", {
			["itemids"] = {6948, 140192, 141605, 110560},
			["default"] = true,
		})
		mod:create_category("Tools", {
			["type"] = tMerge(mod.types["Consumable"], mod.types["Enchantment"], mod.types["Tokens"]),
			["default"] = true,
		})
		mod:create_category("Food & Potion", {
			["subtype"] = tMerge(mod.subtypes.Food, mod.subtypes.Potions),
			["default"] = true,
		})
		mod:create_category("Tradeskill", {
			["type"] = tMerge(mod.types["Tradeskill"], mod.types["Gems"], mod.types["Recipes"]),
			["default"] = true,
		})
		mod:create_category("Miscellaneous", {
			['type'] = tMerge(mod.types["Bags"], mod.types["Miscellaneous"]),
			["default"] = true,
		})
		
		mod:create_category("Uncategorized", {
			["catch_all"] = true,
			["default"] = true,
			["locked"] = true,
			["order"] = 100
		})
	end

	-- Create Frames
	mod:create_bags()

	-- mod:create_bank()
end

function mod:config_callback()
	mod.config = mod:get_save()
	config = mod.config
	if (not config.enabled) then return end
	mod:initialize()
end

--===============================================
-- Create Container
--===============================================
local function create_button(parent)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(20, 20)
	button.text = button:CreateFontString(nil, "OVERLAY")
	button.text:SetFont(bdUI.media.font, 11, "OUTLINE")
	button.text:SetAllPoints()
	button.text:SetJustifyH("CENTER")
	button.text:SetTextColor(.4, .4, .4)

	button:SetScript("OnEnter", function(self)
		self.text:SetTextColor(1, 1, 1)
	end)
	button:SetScript("OnLeave", function(self)
		self.text:SetTextColor(.4, .4, .4)
	end)

	button:SetScript("OnClick", function(self)
		button:callback()
	end)

	return button
end
function mod:create_container(name, start_id, end_id)
	local bags = CreateFrame("Frame", "bd"..name, UIParent)
	mod.border = bdUI.border
	bags:SetSize(500, 400)
	bags:SetFrameStrata("HIGH")
	bags:EnableMouse(true)
	bags:SetMovable(true)
	bags:SetUserPlaced(true)
	bags:SetFrameStrata("HIGH")
	bags:RegisterForDrag("LeftButton","RightButton")
	bags:RegisterForDrag("LeftButton","RightButton")
	bags:SetScript("OnDragStart", function(self) self:StartMoving() end)
	bags:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	bags:Hide()
	bdUI:set_backdrop(bags)
	bags.bd_background:SetVertexColor(.08, .09, .11, 1)

	-- header
	local header = CreateFrame("frame", nil, bags)
	header:SetPoint("TOPLEFT", bags, "TOPLEFT", 0, 0)
	header:SetPoint("BOTTOMRIGHT", bags, "TOPRIGHT", 0, -30)
	bags.header = header

	-- bag replacements
	local containers = mod:create_containers(bags, start_id, end_id)
	containers:SetPoint("BOTTOMRIGHT", bags, "TOPRIGHT", 0, mod.border)

	-- footer
	local footer = CreateFrame("frame", nil, bags)
	footer:SetPoint("TOPLEFT", bags, "BOTTOMLEFT", 0, 30)
	footer:SetPoint("BOTTOMRIGHT", bags, "BOTTOMRIGHT", 0, 0)
	bags.footer = footer

	-- add category
	local add_category = create_button(footer)
	add_category.text:SetText("+")
	add_category:SetPoint("RIGHT", footer, "RIGHT", -4, 0)
	add_category.text:SetFont(bdUI.media.font, 14, "OUTLINE")
	add_category.callback = function(self)
		mod:create_category("New Category", {
			["brand_new"] = true
		})
		mod:update_bags()
	end

	-- category container
	local container = CreateFrame("frame", nil, bags)
	container:SetPoint("TOPLEFT", bags, "TOPLEFT", 0, -30)
	container:SetPoint("BOTTOMRIGHT", bags, "BOTTOMRIGHT", 0, 30)
	bags.container = container

	-- close
	local close_button = create_button(header)
	close_button.text:SetText("X")
	close_button:SetPoint("RIGHT", header, "RIGHT", -4, 0)
	close_button.callback = function(self)
		bags:Hide()
	end

	-- sort
	local sort_bags = create_button(header)
	sort_bags.text:SetText("S")
	sort_bags:SetPoint("RIGHT", close_button, "LEFT", -4, 0)
	bags.sorter = sort_bags

	-- bags
	local bags_button = create_button(header)
	bags_button.text:SetText("B")
	bags_button:SetPoint("RIGHT", sort_bags, "LEFT", -4, 0)
	bags_button.callback = function()
		containers:SetShown(not containers:IsShown())
	end

	-- money
	local money = mod:create_money(name, bags)
	money:SetPoint("LEFT", header, "LEFT", 6, -1)

	-- search
	local searchBox = CreateFrame("EditBox", "bd"..name.."SearchBox", bags, "BagSearchBoxTemplate")
	searchBox:SetHeight(20)
	searchBox:SetPoint("RIGHT", bags_button, "LEFT", -8, 2)
	searchBox:SetPoint("LEFT", money, "RIGHT", 4, 2)
	searchBox:SetFrameLevel(27)
	searchBox.Left:Hide()
	searchBox.Right:Hide()
	searchBox.Middle:Hide()
	local icon = _G[searchBox:GetName().."SearchIcon"]
	icon:ClearAllPoints()
	icon:SetPoint("LEFT", searchBox,"LEFT", 4, -1)
	bdUI:set_backdrop(searchBox)
	searchBox.bd_background:SetVertexColor(.06, .07, .09, 1)
	tinsert(_G.ITEM_SEARCHBAR_LIST, searchBox:GetName())

	-- callback for sizing
	function bags:update_size(width, height)
		-- print(height)
		bags:SetSize(width, height + header:GetHeight() + footer:GetHeight())
	end

	-- create parent bags for id searching
	for bagID = start_id, end_id do
		local f = CreateFrame("Frame", 'bdBagsItemContainer'..bagID, bags)
		f:SetID(bagID)
		mod.bag_frames[bagID] = f
	end

	mod.containers[name:lower()] = bags
	return bags
end