-- Xursed Hub | Slap Battles
-- Modern Obsidian Glass UI + Custom Background Engine

local tbl = {}
local num = 0
local font = Font.new(
	"rbxasset://fonts/families/GothamSSm.json",
	Enum.FontWeight.Medium,
	Enum.FontStyle.Normal
)
local fontBold = Font.new(
	"rbxasset://fonts/families/GothamSSm.json",
	Enum.FontWeight.Bold,
	Enum.FontStyle.Normal
)

local XursedThemes = {
	Xursed = {
		Base = Color3.fromRGB(14, 13, 20),
		Surface = Color3.fromRGB(24, 22, 34),
		Accent = Color3.fromRGB(220, 50, 100),
		GradA = Color3.fromRGB(28, 14, 34),
		GradB = Color3.fromRGB(11, 11, 18)
	},
	Amethyst = {
		Base = Color3.fromRGB(18, 13, 28),
		Surface = Color3.fromRGB(29, 22, 44),
		Accent = Color3.fromRGB(168, 85, 247),
		GradA = Color3.fromRGB(38, 20, 62),
		GradB = Color3.fromRGB(13, 10, 22)
	},
	Abyss = {
		Base = Color3.fromRGB(10, 17, 28),
		Surface = Color3.fromRGB(17, 28, 44),
		Accent = Color3.fromRGB(34, 211, 238),
		GradA = Color3.fromRGB(12, 36, 56),
		GradB = Color3.fromRGB(8, 13, 22)
	},
	Emerald = {
		Base = Color3.fromRGB(10, 22, 18),
		Surface = Color3.fromRGB(17, 36, 30),
		Accent = Color3.fromRGB(16, 185, 129),
		GradA = Color3.fromRGB(14, 46, 36),
		GradB = Color3.fromRGB(8, 16, 13)
	},
	Bloodmoon = {
		Base = Color3.fromRGB(22, 10, 14),
		Surface = Color3.fromRGB(36, 17, 22),
		Accent = Color3.fromRGB(239, 68, 68),
		GradA = Color3.fromRGB(54, 15, 22),
		GradB = Color3.fromRGB(14, 8, 10)
	},
	Solaris = {
		Base = Color3.fromRGB(22, 16, 11),
		Surface = Color3.fromRGB(36, 27, 18),
		Accent = Color3.fromRGB(245, 158, 11),
		GradA = Color3.fromRGB(52, 34, 14),
		GradB = Color3.fromRGB(16, 12, 8)
	},
	Sakura = {
		Base = Color3.fromRGB(24, 14, 22),
		Surface = Color3.fromRGB(38, 22, 35),
		Accent = Color3.fromRGB(244, 114, 182),
		GradA = Color3.fromRGB(56, 24, 46),
		GradB = Color3.fromRGB(16, 10, 15)
	},
	Void = {
		Base = Color3.fromRGB(9, 9, 13),
		Surface = Color3.fromRGB(19, 19, 26),
		Accent = Color3.fromRGB(226, 232, 240),
		GradA = Color3.fromRGB(24, 24, 34),
		GradB = Color3.fromRGB(6, 6, 9)
	}
}
local XursedThemeOrder = {
	"Xursed", "Amethyst", "Abyss", "Emerald", "Bloodmoon", "Solaris", "Sakura", "Void"
}

local XursedBG = {}
XursedBG.ScaleModes = {"Crop", "Stretch", "Fit", "Tile"}
XursedBG.ScaleEnums = {
	Crop = Enum.ScaleType.Crop,
	Stretch = Enum.ScaleType.Stretch,
	Fit = Enum.ScaleType.Fit,
	Tile = Enum.ScaleType.Tile
}
XursedBG.Cache = {}

local function xursedHashUrl(str)
	local h = 5381
	for i = 1, #str do
		h = ((h * 33) + string.byte(str, i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function xursedHttpRequest(url)
	local req =
		(syn and syn.request)
			or (http and http.request)
			or http_request
			or (fluxus and fluxus.request)
			or request
	if type(req) == "function" then
		local ok, res = pcall(req, {
			Url = url,
			Method = "GET",
			Headers = {
				["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) XursedHub/2.0",
				["Accept"] = "image/*,*/*;q=0.8"
			}
		})
		if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
			local code = tonumber(res.StatusCode) or 200
			if code >= 200 and code < 400 then
				return true, res.Body
			end
			return false, "HTTP " .. tostring(code)
		end
	end
	local ok2, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok2 and type(body) == "string" and #body > 0 then
		return true, body
	end
	return false, "Failed to download image URL"
end

function XursedBG.ResolveAsset(rawInput)
	local trimmed = tostring(rawInput or ""):match("^%s*(.-)%s*$")
	if trimmed == "" then
		return true, "", "Cleared"
	end
	if trimmed:match("^%d+$") then
		return true, "rbxassetid://" .. trimmed, "Asset ID: " .. trimmed
	end
	if trimmed:match("^rbxassetid://") or trimmed:match("^rbxasset://") or trimmed:match("^https?://www%.roblox%.com/asset/%?id=%d+") then
		return true, trimmed, "Roblox Asset"
	end
	if trimmed:match("^https?://") then
		if XursedBG.Cache[trimmed] then
			return true, XursedBG.Cache[trimmed], "Cached URL"
		end
		local getAsset = getcustomasset or getsynasset
		if type(getAsset) ~= "function" or type(writefile) ~= "function" then
			return false, "", "Executor lacks getcustomasset / writefile for URLs (use rbxassetid://)"
		end
		local ok, data = xursedHttpRequest(trimmed)
		if not ok then
			return false, "", tostring(data)
		end
		local head = data:sub(1, 32):lower()
		if head:find("<html", 1, true) or head:find("<!doctype", 1, true) then
			return false, "", "URL returned HTML instead of a direct image link"
		end
		if type(isfolder) == "function" and type(makefolder) == "function" then
			pcall(function()
				if not isfolder("XursedHub") then
					makefolder("XursedHub")
				end
				if not isfolder("XursedHub/Backgrounds") then
					makefolder("XursedHub/Backgrounds")
				end
			end)
		end
		local ext = trimmed:match("%.([%a%d]+)%?.*$") or trimmed:match("%.([%a%d]+)$") or "png"
		ext = ext:lower()
		if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" and ext ~= "webp" and ext ~= "bmp" and ext ~= "gif" then
			ext = "png"
		end
		local filePath = "XursedHub/Backgrounds/bg_" .. xursedHashUrl(trimmed) .. "." .. ext
		local wOk, wErr = pcall(writefile, filePath, data)
		if not wOk then
			return false, "", "writefile failed: " .. tostring(wErr)
		end
		local aOk, assetUri = pcall(getAsset, filePath)
		if not aOk or type(assetUri) ~= "string" or assetUri == "" then
			return false, "", "getcustomasset failed: " .. tostring(assetUri)
		end
		XursedBG.Cache[trimmed] = assetUri
		local host = trimmed:match("^https?://([^/]+)") or "custom URL"
		return true, assetUri, "Loaded from " .. host
	end
	return false, "", "Enter a valid https:// image URL (e.g. files.catbox.moe/...) or rbxassetid://"
end

function XursedBG.ApplyToLayers(bgImage, dimOverlay, config, assetUri)
	if not bgImage then
		return
	end
	local hasCustom = type(assetUri) == "string" and assetUri ~= ""
	local opacityPct = math.clamp(tonumber(config.CustomBgOpacity) or 75, 0, 100)
	local dimPct = math.clamp(tonumber(config.CustomBgDim) or 45, 0, 95)
	local scaleName = config.CustomBgScaleType or "Crop"
	bgImage.ScaleType = XursedBG.ScaleEnums[scaleName] or Enum.ScaleType.Crop
	if hasCustom then
		bgImage.Image = assetUri
		bgImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
		bgImage.ImageTransparency = 1 - (opacityPct / 100)
		bgImage.Visible = true
		if dimOverlay then
			dimOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
			dimOverlay.BackgroundTransparency = 1 - (dimPct / 100)
			dimOverlay.Visible = true
		end
	else
		bgImage.Image = ""
		bgImage.ImageTransparency = 1
		bgImage.Visible = false
		if dimOverlay then
			dimOverlay.BackgroundTransparency = 1
			dimOverlay.Visible = false
		end
	end
end

function XursedBG.BuildSettingsPanel(opts)
	local parent = opts.Parent
	local config = opts.Config
	local bgImage = opts.BgImage
	local dimOverlay = opts.DimOverlay
	local saveConfig = opts.SaveConfig
	local createSlider = opts.CreateSlider
	local getAccent = opts.GetAccent
	local activeUri = ""

	local panel = Instance.new("Frame")
	panel.Name = "CustomBgPanel"
	panel.Size = UDim2.new(1, 0, 0, 146)
	panel.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 10)
	pCorner.Parent = panel
	local pStroke = Instance.new("UIStroke")
	pStroke.Name = "AccentStroke"
	pStroke.Color = getAccent()
	pStroke.Thickness = 1
	pStroke.Transparency = 0.65
	pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pStroke.Parent = panel

	local header = Instance.new("TextLabel")
	header.Name = "BgHeader"
	header.Size = UDim2.new(1, -20, 0, 18)
	header.Position = UDim2.new(0, 12, 0, 8)
	header.BackgroundTransparency = 1
	header.FontFace = fontBold
	header.TextSize = 12
	header.TextColor3 = Color3.fromRGB(245, 247, 252)
	header.Text = "Custom Background (Catbox / Image URL / Asset ID)"
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = panel

	local urlBox = Instance.new("TextBox")
	urlBox.Name = "CustomBgUrlBox"
	urlBox.Size = UDim2.new(1, -24, 0, 30)
	urlBox.Position = UDim2.new(0, 12, 0, 32)
	urlBox.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
	urlBox.BackgroundTransparency = 0.15
	urlBox.BorderSizePixel = 0
	urlBox.FontFace = font
	urlBox.TextSize = 11
	urlBox.TextColor3 = Color3.fromRGB(240, 242, 250)
	urlBox.PlaceholderColor3 = Color3.fromRGB(130, 134, 152)
	urlBox.PlaceholderText = "https://files.catbox.moe/example.png or rbxassetid://..."
	urlBox.Text = type(config.CustomBgUrl) == "string" and config.CustomBgUrl or ""
	urlBox.TextXAlignment = Enum.TextXAlignment.Left
	urlBox.TextTruncate = Enum.TextTruncate.AtEnd
	urlBox.ClearTextOnFocus = false
	urlBox.Parent = panel
	local uCorner = Instance.new("UICorner")
	uCorner.CornerRadius = UDim.new(0, 7)
	uCorner.Parent = urlBox
	local uPad = Instance.new("UIPadding")
	uPad.PaddingLeft = UDim.new(0, 8)
	uPad.PaddingRight = UDim.new(0, 8)
	uPad.Parent = urlBox

	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, -24, 0, 28)
	btnRow.Position = UDim2.new(0, 12, 0, 68)
	btnRow.BackgroundTransparency = 1
	btnRow.Parent = panel
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.Padding = UDim.new(0, 6)
	btnLayout.Parent = btnRow

	local function makeActionBtn(name, text, scaleW, bgCol)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.new(scaleW, -4, 1, 0)
		b.BackgroundColor3 = bgCol
		b.BackgroundTransparency = 0.1
		b.BorderSizePixel = 0
		b.FontFace = fontBold
		b.TextSize = 11
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = text
		b.Parent = btnRow
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 7)
		c.Parent = b
		return b
	end

	local applyBtn = makeActionBtn("BgApplyBtn", "Apply Background", 0.42, getAccent())
	local fitBtn = makeActionBtn(
		"BgFitBtn",
		"Fit: " .. tostring(config.CustomBgScaleType or "Crop"),
		0.30,
		Color3.fromRGB(34, 32, 48)
	)
	local clearBtn = makeActionBtn("BgClearBtn", "Clear", 0.28, Color3.fromRGB(68, 28, 38))

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "BgStatus"
	statusLbl.Size = UDim2.new(1, -24, 0, 34)
	statusLbl.Position = UDim2.new(0, 12, 0, 102)
	statusLbl.BackgroundTransparency = 1
	statusLbl.FontFace = font
	statusLbl.TextSize = 10
	statusLbl.TextColor3 = Color3.fromRGB(175, 180, 200)
	statusLbl.TextWrapped = true
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.TextYAlignment = Enum.TextYAlignment.Top
	statusLbl.Text = "Paste a direct Catbox, Imgur, Discord, or rbxassetid:// link and click Apply."
	statusLbl.Parent = panel

	local function applyUrl(raw, silent)
		if not silent then
			statusLbl.Text = "Loading background..."
			statusLbl.TextColor3 = Color3.fromRGB(230, 200, 120)
		end
		task.spawn(function()
			local ok, uri, msg = XursedBG.ResolveAsset(raw)
			if ok then
				activeUri = uri
				config.CustomBgUrl = tostring(raw or ""):match("^%s*(.-)%s*$")
				saveConfig()
				XursedBG.ApplyToLayers(bgImage, dimOverlay, config, activeUri)
				statusLbl.Text = uri ~= "" and ("Active: " .. msg) or "Background cleared (using theme)."
				statusLbl.TextColor3 = uri ~= "" and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(175, 180, 200)
			else
				statusLbl.Text = "Error: " .. tostring(msg)
				statusLbl.TextColor3 = Color3.fromRGB(248, 113, 113)
			end
		end)
	end

	applyBtn.MouseButton1Click:Connect(function()
		applyUrl(urlBox.Text, false)
	end)
	clearBtn.MouseButton1Click:Connect(function()
		urlBox.Text = ""
		applyUrl("", false)
	end)
	fitBtn.MouseButton1Click:Connect(function()
		local cur = config.CustomBgScaleType or "Crop"
		local idx = 1
		for i, name in ipairs(XursedBG.ScaleModes) do
			if name == cur then
				idx = i
				break
			end
		end
		local nextMode = XursedBG.ScaleModes[(idx % #XursedBG.ScaleModes) + 1]
		config.CustomBgScaleType = nextMode
		fitBtn.Text = "Fit: " .. nextMode
		saveConfig()
		XursedBG.ApplyToLayers(bgImage, dimOverlay, config, activeUri)
	end)

	createSlider(
		parent,
		"Background Opacity",
		0,
		100,
		math.clamp(tonumber(config.CustomBgOpacity) or 75, 0, 100),
		function(val)
			config.CustomBgOpacity = val
			saveConfig()
			XursedBG.ApplyToLayers(bgImage, dimOverlay, config, activeUri)
		end
	)
	createSlider(
		parent,
		"Background Dim Overlay",
		0,
		95,
		math.clamp(tonumber(config.CustomBgDim) or 45, 0, 95),
		function(val)
			config.CustomBgDim = val
			saveConfig()
			XursedBG.ApplyToLayers(bgImage, dimOverlay, config, activeUri)
		end
	)

	if type(config.CustomBgUrl) == "string" and config.CustomBgUrl ~= "" then
		applyUrl(config.CustomBgUrl, true)
	end

	return {
		RefreshAccent = function(acc)
			pStroke.Color = acc
			applyBtn.BackgroundColor3 = acc
		end
	}
end

local function func()
	local CoreGui = game:GetService("CoreGui")
	pcall(function()
		if type(gethui) == "function" then
			local v1 = gethui()
			if v1 then
				CoreGui = v1
			end
		end
	end)
	return CoreGui
end

function tbl.Log(arg1, arg2, arg3, arg4)
	if num >= 25 then
		return nil
	end

	local v1
	local ok, result = pcall(function()
		if type(writefile) ~= "function" then
			error("this executor has no writefile support, so the log could not be saved", 0)
		end

		if type(isfolder) == "function" and type(makefolder) == "function" then
			if not isfolder("XursedHub") then
				makefolder("XursedHub")
			end
			if not isfolder("XursedHub/ErrorLogs") then
				makefolder("XursedHub/ErrorLogs")
			end
		end

		num = num + 1
		local str = "Unknown"
		pcall(function()
			if type(identifyexecutor) == "function" then
				local v1, v2 = identifyexecutor()
				str = tostring(v1)

				if v2 then
					str = str .. " " .. tostring(v2)
				end
			end
		end)
		local tbl = {}
		local v2 = "WHAT WENT WRONG : " .. tostring(arg1)
		local ok, result = pcall(os.date, "%Y-%m-%d %H:%M:%S")
		local str1

		if ok then
			str1 = tostring(result)
		else
			str1 = "unknown"
		end

		local v3 = "TIME (local)    : " .. str1
		local ok1, result1 = pcall(os.date, "!%Y-%m-%d %H:%M:%S")
		local str2

		if ok1 then
			str2 = tostring(result1)
		else
			str2 = "unknown"
		end

		local v4 = "TIME (UTC)      : " .. str2
		local v5 = "REASON          : " .. tostring(arg2)
		tbl[1] = "==================== XURSED HUB ERROR LOG ===================="
		tbl[2] = ""
		tbl[3] = v2
		tbl[4] = v3
		tbl[5] = v4
		tbl[6] = v5

		if arg4 then
			table.insert(tbl, "SUGGESTED FIX   : " .. tostring(arg4))
		end

		table.insert(tbl, "")
		table.insert(tbl, "---------------------- ENVIRONMENT ----------------------")
		table.insert(tbl, "Place ID : " .. tostring(game.PlaceId))
		table.insert(tbl, "Job ID   : " .. tostring(game.JobId))
		table.insert(tbl, "Executor : " .. str)

		if arg3 ~= nil and tostring(arg3) ~= "" then
			table.insert(tbl, "")
			table.insert(tbl, "------------------------ DETAILS ------------------------")
			table.insert(tbl, tostring(arg3))
		end

		table.insert(tbl, "")
		table.insert(tbl, "=============================================================")
		local ok2, result2 = pcall(os.date, "%Y-%m-%d_%H-%M-%S")
		local str3

		if ok2 then
			str3 = tostring(result2)
		else
			str3 = "unknown"
		end

		local v6 = "XursedHub/ErrorLogs" .. "/Error_" .. str3 .. "_" .. tostring(num) .. ".txt"
		writefile(v6, table.concat(tbl, "\r\n"))
		v1 = v6
	end)

	if ok then
		warn("[Xursed Hub] Error log saved: " .. tostring(v1))
	else
		warn("[Xursed Hub] Could not write error log: " .. tostring(result))
	end

	return v1
end

function tbl.RunAntiCheatBypass()
	local TweenService = game:GetService("TweenService")
	local tbl1 = {}
	pcall(function()
		local v1 = func()
		local XursedHubLoading = v1:FindFirstChild("XursedHubLoading")

		if XursedHubLoading then
			XursedHubLoading:Destroy()
		end

		local xursedHubLoading = Instance.new("ScreenGui")
		xursedHubLoading.Name = "XursedHubLoading"
		xursedHubLoading.ResetOnSpawn = false
		xursedHubLoading.IgnoreGuiInset = true
		xursedHubLoading.DisplayOrder = 1000001
		xursedHubLoading.Parent = v1
		tbl1.Gui = xursedHubLoading
		local root = Instance.new("CanvasGroup")
		root.Name = "Root"
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundColor3 = Color3.fromRGB(9, 8, 14)
		root.BorderSizePixel = 0
		root.Active = true
		root.Parent = xursedHubLoading
		tbl1.Root = root
		local uiGradient = Instance.new("UIGradient")
		uiGradient.Color = ColorSequence.new(Color3.fromRGB(34, 12, 32), Color3.fromRGB(8, 8, 13))
		uiGradient.Rotation = 125
		uiGradient.Parent = root
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromScale(1.2, 1.2)
		frame.BackgroundColor3 = Color3.fromRGB(220, 50, 100)
		frame.BackgroundTransparency = 0.9
		frame.BorderSizePixel = 0
		frame.Parent = root
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(1, 0)
		uiCorner.Parent = frame
		local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		uiAspectRatioConstraint.AspectRatio = 1
		uiAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
		uiAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Height
		uiAspectRatioConstraint.Parent = frame
		TweenService:Create(
			frame,
			TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{BackgroundTransparency = 0.95}
		)
			:Play()
		local card = Instance.new("Frame")
		card.Name = "Card"
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromScale(0.5, 0.5)
		card.Size = UDim2.new(0.86, 0, 0, 210)
		card.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
		card.BackgroundTransparency = 0.06
		card.BorderSizePixel = 0
		card.Parent = root
		local uiSizeConstraint = Instance.new("UISizeConstraint")
		uiSizeConstraint.MaxSize = Vector2.new(400, 210)
		uiSizeConstraint.MinSize = Vector2.new(220, 170)
		uiSizeConstraint.Parent = card
		local uiCorner1 = Instance.new("UICorner")
		uiCorner1.CornerRadius = UDim.new(0, 16)
		uiCorner1.Parent = card
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = Color3.fromRGB(220, 50, 100)
		uiStroke.Thickness = 1.5
		uiStroke.Transparency = 0.35
		uiStroke.Parent = card
		local uiScale = Instance.new("UIScale")
		uiScale.Parent = card

		local function func1()
			local CurrentCamera = workspace.CurrentCamera

			if not CurrentCamera then
				return
			end

			local ViewportSize = CurrentCamera.ViewportSize
			uiScale.Scale = math.clamp(
				math.min(ViewportSize.X / 440, ViewportSize.Y / 260),
				0.55,
				1.15
			)
		end

		func1()
		tbl1.CamConn =
			workspace.CurrentCamera
				and workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(func1)
		local ring = Instance.new("Frame")
		ring.Name = "Ring"
		ring.AnchorPoint = Vector2.new(0.5, 0)
		ring.Position = UDim2.new(0.5, 0, 0, 20)
		ring.Size = UDim2.fromOffset(46, 46)
		ring.BackgroundTransparency = 1
		ring.Parent = card
		local uiCorner2 = Instance.new("UICorner")
		uiCorner2.CornerRadius = UDim.new(1, 0)
		uiCorner2.Parent = ring
		local uiStroke1 = Instance.new("UIStroke")
		uiStroke1.Thickness = 4
		uiStroke1.Color = Color3.fromRGB(240, 75, 130)
		uiStroke1.Parent = ring
		local uiGradient1 = Instance.new("UIGradient")
		uiGradient1.Transparency = NumberSequence.new(
			{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.55, 0.15),
				NumberSequenceKeypoint.new(0.56, 1),
				NumberSequenceKeypoint.new(1, 1)
			}
		)
		uiGradient1.Parent = uiStroke1
		tbl1.RingGradient = uiGradient1
		local brand = Instance.new("TextLabel")
		brand.Name = "Brand"
		brand.BackgroundTransparency = 1
		brand.Position = UDim2.new(0, 10, 0, 76)
		brand.Size = UDim2.new(1, -20, 0, 26)
		brand.FontFace = fontBold
		brand.TextSize = 22
		brand.TextColor3 = Color3.fromRGB(248, 245, 255)
		brand.Text = "Xursed Hub"
		brand.Parent = card
		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.BackgroundTransparency = 1
		header.Position = UDim2.new(0, 10, 0, 106)
		header.Size = UDim2.new(1, -20, 0, 20)
		header.FontFace = font
		header.TextSize = 14
		header.TextColor3 = Color3.fromRGB(205, 165, 195)
		header.TextTruncate = Enum.TextTruncate.AtEnd
		header.Text = "Initializing Xursed Hub..."
		header.Parent = card
		tbl1.Header = header
		local track = Instance.new("Frame")
		track.Name = "Track"
		track.AnchorPoint = Vector2.new(0.5, 0)
		track.Position = UDim2.new(0.5, 0, 0, 142)
		track.Size = UDim2.new(1, -48, 0, 8)
		track.BackgroundColor3 = Color3.fromRGB(36, 26, 44)
		track.BorderSizePixel = 0
		track.ClipsDescendants = true
		track.Parent = card
		local uiCorner3 = Instance.new("UICorner")
		uiCorner3.CornerRadius = UDim.new(1, 0)
		uiCorner3.Parent = track
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.Parent = track
		local uiCorner4 = Instance.new("UICorner")
		uiCorner4.CornerRadius = UDim.new(1, 0)
		uiCorner4.Parent = fill
		local uiGradient2 = Instance.new("UIGradient")
		uiGradient2.Color = ColorSequence.new(
			Color3.fromRGB(220, 50, 100),
			Color3.fromRGB(168, 85, 247)
		)
		uiGradient2.Parent = fill
		tbl1.Fill = fill
		local percent = Instance.new("TextLabel")
		percent.Name = "Percent"
		percent.BackgroundTransparency = 1
		percent.Position = UDim2.new(0, 10, 0, 164)
		percent.Size = UDim2.new(1, -20, 0, 20)
		percent.FontFace = font
		percent.TextSize = 13
		percent.TextColor3 = Color3.fromRGB(190, 150, 185)
		percent.Text = "0%"
		percent.Parent = card
		tbl1.Percent = percent
		task.spawn(function()
			while tbl1.RingGradient and tbl1.RingGradient.Parent do
				tbl1.RingGradient.Rotation = (tbl1.RingGradient.Rotation + 6) % 360
				task.wait()
			end
		end)
	end)
	local flag = false
	local flag1 = false
	local v6
	task.spawn(function()
		local ok, result = pcall(function()
			local response = game:HttpGet(
				"https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/SB/Modules/CleanClientAntiCheat.luau"
			)

			if type(response) ~= "string" or response == "" then
				error("HttpGet returned an empty response", 0)
			end

			local v1, v2 = loadstring(response)

			if not v1 then
				error("loadstring could not compile the anti-cheat script: " .. tostring(v2), 0)
			end

			v1("Slap Battles")
		end)
		flag1 = ok

		if not ok then
			v6 = tostring(result)
		end

		flag = true
	end)
	local num = 0
	local v1 = os.clock()

	while not flag and os.clock() - v1 < 45 do
		local v2 = task.wait()
		local v3 = 0.9 - num
		local v4 = math.min((tonumber(v2) or 0.03) * 0.6, 1)
		num = num + v3 * v4
		pcall(function()
			if tbl1.Fill then
				tbl1.Fill.Size = UDim2.new(num, 0, 1, 0)
			end
			if tbl1.Percent then
				tbl1.Percent.Text = tostring(math.floor(num * 100)) .. "%"
			end
		end)
	end

	local v5 = not flag

	if v5 then
		v6 = "The anti-cheat script did not finish within " .. tostring(45) .. " seconds."
	end

	if flag1 then
		pcall(function()
			if tbl1.Fill then
				TweenService:Create(
					tbl1.Fill,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = UDim2.new(1, 0, 1, 0)}
				)
					:Play()
			end
			if tbl1.Percent then
				tbl1.Percent.Text = "100%"
			end
		end)
		task.wait(0.45)
	else
		warn("[Xursed Hub] Anti-cheat bypass problem: " .. tostring(v6))
		tbl.Log(
			v5 and "Anti-cheat bypass timed out" or "Anti-cheat bypass failed",
			tostring(v6),
			"Module URL: https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/SB/Modules/CleanClientAntiCheat.luau\nThe hub kept loading anyway, but anti-cheat protection may not be active.",
			"Check your internet connection and make sure your executor supports HttpGet and loadstring, then re-run Xursed Hub."
		)
		pcall(function()
			if tbl1.Header then
				tbl1.Header.Text = "Bypass failed, continuing..."
			end
		end)
		task.wait(1.8)
	end

	pcall(function()
		if tbl1.Root then
			TweenService:Create(
				tbl1.Root,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{GroupTransparency = 1}
			)
				:Play()
		end
	end)
	task.wait(0.45)
	pcall(function()
		if tbl1.CamConn then
			tbl1.CamConn:Disconnect()
		end
		if tbl1.Gui then
			tbl1.Gui:Destroy()
		end
	end)
	return flag1
end

function tbl.PromptWrongPlace(arg1)
	local TeleportService = game:GetService("TeleportService")
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local str
	local flag = false
	local xursedHubWrongPlace
	local ok, result = pcall(function()
		local v1 = func()
		local XursedHubWrongPlace = v1:FindFirstChild("XursedHubWrongPlace")

		if XursedHubWrongPlace then
			XursedHubWrongPlace:Destroy()
		end

		xursedHubWrongPlace = Instance.new("ScreenGui")
		xursedHubWrongPlace.Name = "XursedHubWrongPlace"
		xursedHubWrongPlace.ResetOnSpawn = false
		xursedHubWrongPlace.IgnoreGuiInset = true
		xursedHubWrongPlace.DisplayOrder = 1000000
		xursedHubWrongPlace.Parent = v1
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.new(0.9, 0, 0, 250)
		frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
		frame.BorderSizePixel = 0
		frame.Parent = xursedHubWrongPlace
		local uiSizeConstraint = Instance.new("UISizeConstraint")
		uiSizeConstraint.MaxSize = Vector2.new(420, 250)
		uiSizeConstraint.Parent = frame
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 10)
		uiCorner.Parent = frame
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = Color3.fromRGB(220, 50, 100)
		uiStroke.Thickness = 2
		uiStroke.Parent = frame
		local textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.Position = UDim2.new(0, 16, 0, 12)
		textLabel.Size = UDim2.new(1, -32, 0, 28)
		textLabel.FontFace = font
		textLabel.TextSize = 22
		textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Text = "Xursed Hub Failed To Load"
		textLabel.Parent = frame
		local textLabel1 = Instance.new("TextLabel")
		textLabel1.BackgroundTransparency = 1
		textLabel1.Position = UDim2.new(0, 16, 0, 48)
		textLabel1.Size = UDim2.new(1, -32, 0, 110)
		textLabel1.FontFace = font
		textLabel1.TextSize = 16
		textLabel1.TextColor3 = Color3.fromRGB(230, 230, 235)
		textLabel1.TextWrapped = true
		textLabel1.TextXAlignment = Enum.TextXAlignment.Left
		textLabel1.TextYAlignment = Enum.TextYAlignment.Top
		textLabel1.Text =
			"You are either in the wrong game, or this game isn't really supported. Join slap battles or uh, launch the script anyway.....? I guess....??"
		textLabel1.Parent = frame

		local function func1(text, arg2, arg3, backgroundColor3)
			local textButton = Instance.new("TextButton")
			textButton.AnchorPoint = Vector2.new(0, 1)
			textButton.Position = UDim2.new(arg2, arg3, 1, -16)
			textButton.Size = UDim2.new(0.5, -22, 0, 42)
			textButton.BackgroundColor3 = backgroundColor3
			textButton.BorderSizePixel = 0
			textButton.AutoButtonColor = true
			textButton.FontFace = font
			textButton.TextSize = 15
			textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			textButton.TextWrapped = true
			textButton.Text = text
			textButton.Parent = frame
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 8)
			uiCorner.Parent = textButton
			return textButton
		end

		local v2 = func1("Join Slap Battles", 0, 16, Color3.fromRGB(220, 50, 100))
		local v3 = func1("Launch Script Anyway", 0.5, 6, Color3.fromRGB(70, 70, 82))
		v2.Activated:Connect(function()
			if flag or str then
				return
			end

			flag = true
			v2.Text = "Teleporting..."
			local ok, result = pcall(function()
				TeleportService:Teleport(arg1, LocalPlayer)
			end)

			if ok then
				str = "join"
			else
				v2.Text = "Teleport failed"
				tbl.Log(
					"Could not teleport to Slap Battles",
					"TeleportService:Teleport threw an error: " .. tostring(result),
					"Target Place ID: " .. tostring(arg1),
					"Join Slap Battles manually from the Roblox app or website, then run Xursed Hub again."
				)
				task.delay(
					2,
					function()
						if v2.Parent then
							v2.Text = "Join Slap Battles"
						end
						flag = false
					end
				)
			end
		end)
		v3.Activated:Connect(function()
			if str then
				return
			end
			str = "launch"
		end)
		TeleportService.TeleportInitFailed:Connect(function(arg11, arg2, arg3)
			if arg11 ~= LocalPlayer then
				return
			end

			tbl.Log(
				"Teleport to Slap Battles failed",
				"Roblox refused the teleport. Result: "
					.. tostring(arg2) .. " | Message: " .. tostring(arg3),
				"Target Place ID: " .. tostring(arg1),
				"If you are on Delta, turn off the 'Verify Teleports' toggle in the Delta settings. Otherwise join Slap Battles manually."
			)
			pcall(function()
				if v2.Parent then
					v2.Text = "Teleport failed"
				end
			end)
			flag = false
		end)
	end)

	if not ok then
		warn("[Xursed Hub] Could not build the wrong-game window: " .. tostring(result))
		tbl.Log(
			"Could not show the wrong-game window",
			"Building the GUI threw an error: " .. tostring(result),
			nil,
			"Join Slap Battles manually and run Xursed Hub again."
		)
		return "none"
	end

	while not str and xursedHubWrongPlace and xursedHubWrongPlace.Parent do
		task.wait(0.1)
	end

	if str == "launch" then
		pcall(function()
			xursedHubWrongPlace:Destroy()
		end)
	end

	return str or "none"
end

local ok, result = xpcall(
	function()
		local tbl1 = {}

		if not game:IsLoaded() then
			game.Loaded:Wait()
		end

		warn("[Xursed Hub Diagnostic] Script body is running.")
		tbl1[1] = game:GetService("CoreGui")
		tbl1[2] = tbl1[1]
		pcall(function()
			if type(gethui) == "function" then
				local v1 = gethui()
				if v1 then
					tbl1[2] = v1
				end
			end
		end)
		tbl1[3] = game:GetService("UserInputService")
		tbl1[4] = game:GetService("RunService")
		tbl1[5] = game:GetService("Players")
		tbl1[6] = game:GetService("ReplicatedStorage")
		tbl1[7] = game:GetService("TweenService")
		tbl1[8] = game:GetService("Stats")
		tbl1[9] = game:GetService("HttpService")
		tbl1[10] = game:GetService("TeleportService")
		game:GetService("RbxAnalyticsService")
		tbl1[11] = tbl1[5].LocalPlayer

		tbl1[12] = {
			[7234087065] = "Xursed Hub | barzil",
			[11520107414] = "Xursed Hub | No Oneshots Arena",
			[18550498098] = "Xursed Hub | Guide Realm",
			[122902713960550] = "Xursed Hub | Sand Glove Obtainment",
			[124596094333302] = "Xursed Hub | New Player Server"
		}

		tbl1[13] =
			({
				[6403373529] = true,
				[11828384869] = true,
				[7234087065] = true,
				[11520107414] = true,
				[18550498098] = true,
				[122902713960550] = true,
				[124596094333302] = true
			})[game.PlaceId]
				== true
		warn(
			"[Xursed Hub Diagnostic] Started. PlaceId="
				.. tostring(game.PlaceId) .. "; main hub allowed=" .. tostring(tbl1[13])
		)

		if not tbl1[13] and game.PlaceId ~= 11520107397 then
			warn(
				"Xursed Hub did not start: this PlaceId is not supported. Run it inside the supported Slap Battles place."
			)
			tbl.Log(
				"Xursed Hub failed to load (unsupported game)",
				"You are either in the wrong game, or this game isn't supported. Place ID "
					.. tostring(game.PlaceId) .. " is not in the supported list.",
				"Supported places include 6403373529 (Slap Battles), 11828384869, 7234087065, 11520107414, 18550498098, 122902713960550, 124596094333302 and 11520107397 (Killstreak Only).",
				"Join Slap Battles, or press 'Launch Script Anyway' (some features may not work)."
			)

			if tbl.PromptWrongPlace(6403373529) == "launch" then
				tbl1[13] = true
			else
				return
			end
		end

		tbl.RunAntiCheatBypass()
		tbl1[14] = function(arg1)
			local Tab = arg1.Tab
			local Store = arg1.Store
			local v1 = arg1.Folder or "XursedHub"
			local font = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			local color = Color3.fromRGB(245, 245, 245)
			local color1 = Color3.fromRGB(120, 230, 140)
			local color2 = Color3.fromRGB(255, 110, 110)

			local function func()
				return type(writefile) == "function" and type(readfile) == "function"
			end

			local function func1()
				if type(isfolder) == "function" and type(makefolder) == "function" then
					pcall(function()
						if not isfolder(v1) then
							makefolder(v1)
						end
					end)
				end
			end

			local function func2(arg1)
				return
					(tostring(arg1 or ""):gsub("[^%w _%-]", "")
						:gsub("^%s+", "")
						:sub(1, 32)
						:gsub("%s+$", ""))
			end

			local function func3(arg1)
				if type(arg1) ~= "string" or arg1 == "" then
					return nil
				end

				local ok, result = pcall(function()
					return tbl1[9]:JSONDecode(arg1)
				end)

				if ok and type(result) == "table" then
					return result
				end

				return nil
			end

			local function func4(arg1)
				return
					type(arg1) == "table"
						and (type(arg1.CONFIG_SETTINGS) == "table"
							or type(arg1.CONFIG_SLIDERS) == "table")
			end

			local function func5(arg1)
				local v1 = setclipboard or toclipboard

				if type(v1) ~= "function" then
					return false
				end

				return (pcall(v1, arg1))
			end

			local function func6()
				local v1 = getclipboard or clippaste

				if type(v1) ~= "function" then
					return nil
				end

				local ok, result = pcall(v1)

				if ok and type(result) == "string" then
					return result
				end

				return nil
			end

			local function func7(parent, text, size)
				local hubButton = Instance.new("TextButton")
				hubButton.Name = "HubButton"
				hubButton.Size = size
				hubButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				hubButton.BorderSizePixel = 0
				hubButton.FontFace = font
				hubButton.TextSize = 11
				hubButton.TextColor3 = color
				hubButton.Text = text
				hubButton.Parent = parent
				local uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = UDim.new(0, 5)
				uiCorner.Parent = hubButton
				return hubButton
			end

			local function func8(arg1)
				local configRow = Instance.new("Frame")
				configRow.Name = "ConfigRow"
				configRow.Size = UDim2.new(1, 0, 0, arg1)
				configRow.BackgroundTransparency = 1
				configRow.BorderSizePixel = 0
				configRow.Parent = Tab
				local uiListLayout = Instance.new("UIListLayout")
				uiListLayout.FillDirection = Enum.FillDirection.Horizontal
				uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				uiListLayout.Padding = UDim.new(0, 4)
				uiListLayout.Parent = configRow
				return configRow
			end

			local function func9(parent, text, arg3, arg4)
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = arg3 or UDim2.new(1, 0, 0, arg4 or 20)
				textLabel.BackgroundTransparency = 1
				textLabel.FontFace = font
				textLabel.TextSize = 11
				textLabel.TextColor3 = color
				textLabel.TextXAlignment = Enum.TextXAlignment.Left
				textLabel.TextWrapped = true
				textLabel.Text = text
				textLabel.Parent = parent
				return textLabel
			end

			local v2 = func9(Tab, "Config: ready.", UDim2.new(1, 0, 0, 28))
			v2.Name = "ConfigStatus"
			v2.TextSize = 10

			local function SetStatus(arg1, arg2)
				v2.Text = tostring(arg1)
				v2.TextColor3 = arg2 == true and color1 or arg2 == false and color2 or color
			end

			local v3 = func8(28)
			local configNameInput = Instance.new("TextBox")
			configNameInput.Name = "ConfigNameInput"
			configNameInput.Size = UDim2.new(0.66, -2, 1, 0)
			configNameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			configNameInput.BorderSizePixel = 0
			configNameInput.FontFace = font
			configNameInput.TextSize = 11
			configNameInput.TextColor3 = color
			configNameInput.PlaceholderText = "Config name (e.g. Legit)"
			configNameInput.Text = ""
			configNameInput.ClearTextOnFocus = false
			configNameInput.Parent = v3
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 5)
			uiCorner.Parent = configNameInput
			local v4 = func7(v3, "Save Config", UDim2.new(0.34, -2, 1, 0))
			local configJsonBox = Instance.new("TextBox")
			configJsonBox.Name = "ConfigJsonBox"
			configJsonBox.Size = UDim2.new(1, 0, 0, 56)
			configJsonBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
			configJsonBox.BorderSizePixel = 0
			configJsonBox.Font = Enum.Font.Code
			configJsonBox.TextSize = 10
			configJsonBox.TextColor3 = color
			configJsonBox.PlaceholderText =
				"Export shows the config JSON here. Paste a config here and press Import."
			configJsonBox.Text = ""
			configJsonBox.TextXAlignment = Enum.TextXAlignment.Left
			configJsonBox.TextYAlignment = Enum.TextYAlignment.Top
			configJsonBox.TextWrapped = true
			configJsonBox.MultiLine = true
			configJsonBox.ClearTextOnFocus = false
			configJsonBox.Parent = Tab
			local uiCorner1 = Instance.new("UICorner")
			uiCorner1.CornerRadius = UDim.new(0, 5)
			uiCorner1.Parent = configJsonBox
			local v5 = func8(28)
			local v6 = func7(v5, "Export", UDim2.new(0.3333333333333333, -3, 1, 0))
			local v7 = func7(v5, "Import", UDim2.new(0.3333333333333333, -3, 1, 0))
			local v8 = func7(v5, "Clear Box", UDim2.new(0.3333333333333333, -3, 1, 0))
			local v9 = func8(26)
			func9(v9, "Saved configs", UDim2.new(0.62, -2, 1, 0))
			local v10 = func7(v9, "Refresh", UDim2.new(0.38, -2, 1, 0))
			local configList = Instance.new("Frame")
			configList.Name = "ConfigList"
			configList.Size = UDim2.new(1, 0, 0, 0)
			configList.AutomaticSize = Enum.AutomaticSize.Y
			configList.BackgroundTransparency = 1
			configList.BorderSizePixel = 0
			configList.Parent = Tab
			local uiListLayout = Instance.new("UIListLayout")
			uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			uiListLayout.Padding = UDim.new(0, 4)
			uiListLayout.Parent = configList

			local function func10(arg2)
				local tbl = {}

				for k, toggleState in pairs(arg1.ToggleStates) do
					tbl[k] = toggleState == true
				end

				return
					{
						CONFIG_NAME = arg2,
						CONFIG_VERSION = 2,
						CONFIG_HUB = arg1.HubName,
						CONFIG_SETTINGS = tbl,
						CONFIG_SLIDERS = Store.SnapshotSliders(),
						CONFIG_THEME = arg1.Config.Theme,
						CONFIG_CREATION = os.date("!%Y-%m-%dT%H:%M:%SZ")
					}
			end

			local function Apply(arg2)
				if not func4(arg2) then
					return false, "That isn't a Xursed Hub config."
				end

				local tbl = {}

				if type(arg2.CONFIG_SLIDERS) == "table" then
					for k, config_slider in pairs(arg2.CONFIG_SLIDERS) do
						if tonumber(config_slider) then
							tbl[k] = tonumber(config_slider)
						end
					end
				end

				if tbl.WalkSpeed == nil and tonumber(arg2.CONFIG_WALK_SPEED) then
					tbl.WalkSpeed = tonumber(arg2.CONFIG_WALK_SPEED)
				end

				if tbl.JumpPower == nil and tonumber(arg2.CONFIG_JUMP_POWER) then
					tbl.JumpPower = tonumber(arg2.CONFIG_JUMP_POWER)
				end

				if tbl["UI Size"] == nil and tonumber(arg2.CONFIG_UI_SCALE) then
					tbl["UI Size"] = math.floor(tonumber(arg2.CONFIG_UI_SCALE) * 100 + 0.5)
				end

				local num = 0
				local num1 = 0

				for k1, v1 in pairs(tbl) do
					local v2 = Store.SliderControls[k1]
					if v2 then
						v2(v1, true)
						num = num + 1
					end
				end

				if type(arg2.CONFIG_SETTINGS) == "table" then
					for k2, config_setting in pairs(arg2.CONFIG_SETTINGS) do
						local v3 = arg1.ToggleControls[k2]
						if v3 and type(config_setting) == "boolean" then
							if arg1.ToggleStates[k2] ~= config_setting then
								v3(config_setting, true)
							end
							num1 = num1 + 1
						end
					end
				end

				if
					type(arg2.CONFIG_THEME) == "string"
						and arg1.Themes[arg2.CONFIG_THEME]
						and arg1.Config.Theme ~= arg2.CONFIG_THEME
				then
					arg1.ApplyTheme(arg2.CONFIG_THEME)
				end

				if type(arg2.CONFIG_NAME) == "string" and arg2.CONFIG_NAME ~= "" then
					configNameInput.Text = func2(arg2.CONFIG_NAME)
				end

				return true, ("Applied %d toggle(s) and %d slider(s)."):format(num1, num)
			end

			local function func11(arg1, arg2)
				if not func() then
					return false
				end

				func1()
				local v2 = arg1:gsub("%s+", "_")
				return (pcall(writefile, v1 .. "/" .. v2 .. ".json", tbl1[9]:JSONEncode(arg2)))
			end

			local function func12(arg1)
				local v1 = func9(configList, arg1, UDim2.new(1, 0, 0, 20))
				v1.Name = "ConfigListMessage"
				v1.TextSize = 10
			end

			local function Refresh()
				for _, child in ipairs(configList:GetChildren()) do
					if child ~= uiListLayout then
						child:Destroy()
					end
				end

				if type(listfiles) ~= "function" or type(readfile) ~= "function" then
					func12("This executor can't list files. Use Export / Import instead.")
					return 0
				end

				func1()
				local ok, result = pcall(listfiles, v1)

				if not ok or type(result) ~= "table" then
					func12("No config folder yet. Save a config to create it.")
					return 0
				end

				local tbl = {}

				for _, v2 in ipairs(result) do
					if type(v2) == "string" and v2:lower():sub(-5) == ".json" then
						local ok1, result1 = pcall(readfile, v2)
						local v3 = ok1 and func3(result1) or nil

						if
							type(v3) == "table"
								and (type(v3.CONFIG_SETTINGS) == "table"
									or type(v3.CONFIG_SLIDERS) == "table")
						then
							local v4 = v2:gsub("^.*[/\\]", ""):gsub("%.json$", "")
							table.insert(tbl, {path = v2, label = tostring(v3.CONFIG_NAME or v4)})
						end
					end
				end

				table.sort(
					tbl,
					function(a, b)
						return a.label:lower() < b.label:lower()
					end
				)

				if #tbl == 0 then
					func12("No saved configs yet.")
					return 0
				end

				for _, v5 in ipairs(tbl) do
					local configEntryRow = Instance.new("Frame")
					configEntryRow.Name = "ConfigEntryRow"
					configEntryRow.Size = UDim2.new(1, 0, 0, 26)
					configEntryRow.BackgroundTransparency = 1
					configEntryRow.BorderSizePixel = 0
					configEntryRow.Parent = configList
					local uiListLayout1 = Instance.new("UIListLayout")
					uiListLayout1.FillDirection = Enum.FillDirection.Horizontal
					uiListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
					uiListLayout1.Padding = UDim.new(0, 4)
					uiListLayout1.Parent = configEntryRow
					local v6 = func7(configEntryRow, v5.label, UDim2.new(0.58, -3, 1, 0))
					local v7 = func7(configEntryRow, "Copy", UDim2.new(0.2, -3, 1, 0))
					local v8 = func7(configEntryRow, "Delete", UDim2.new(0.22, -3, 1, 0))
					v6.TextTruncate = Enum.TextTruncate.AtEnd
					v6.MouseButton1Click:Connect(function()
						local ok, result = pcall(readfile, v5.path)
						local v1 = ok and func3(result) or nil

						if not func4(v1) then
							SetStatus('Could not read "' .. v5.label .. '".', false)
							return
						end

						local v2, v3 = Apply(v1)
						SetStatus(v2 and 'Loaded "' .. v5.label .. '". ' .. v3 or v3, v2)
					end)
					v7.MouseButton1Click:Connect(function()
						local ok, result = pcall(readfile, v5.path)

						if not ok or type(result) ~= "string" then
							SetStatus('Could not read "' .. v5.label .. '".', false)
							return
						end

						configJsonBox.Text = result

						if func5(result) then
							SetStatus('Copied "' .. v5.label .. '" to your clipboard.', true)
						else
							SetStatus(
								"Clipboard unsupported; the JSON is in the box so you can copy it.",
								nil
							)
						end
					end)
					local flag = false
					v8.MouseButton1Click:Connect(function()
						if type(delfile) ~= "function" then
							SetStatus("This executor can't delete files.", false)
							return
						end

						if not flag then
							flag = true
							v8.Text = "Sure?"
							task.delay(
								2.5,
								function()
									flag = false
									if v8.Parent then
										v8.Text = "Delete"
									end
								end
							)
							return
						end

						if pcall(delfile, v5.path) then
							SetStatus('Deleted "' .. v5.label .. '".', true)
							Refresh()
						else
							SetStatus('Could not delete "' .. v5.label .. '".', false)
							flag = false
							v8.Text = "Delete"
						end
					end)
				end

				return #tbl
			end

			v4.MouseButton1Click:Connect(function()
				local v1 = func2(configNameInput.Text)

				if v1 == "" then
					SetStatus("Type a config name first (letters, numbers, spaces).", false)
					return
				end

				configNameInput.Text = v1
				local v2 = func10(v1)

				if func11(v1, v2) then
					local num = 0
					local num1 = 0

					for _ in pairs(v2.CONFIG_SETTINGS) do
						num = num + 1
					end

					for _ in pairs(v2.CONFIG_SLIDERS) do
						num1 = num1 + 1
					end

					SetStatus(
						'Saved "' .. v1 .. '" (' .. num .. " toggles, " .. num1 .. " sliders).",
						true
					)
					Refresh()
				else
					configJsonBox.Text = tbl1[9]:JSONEncode(v2)
					SetStatus(
						"Couldn't write a file on this executor. The JSON is in the box; copy it to keep it.",
						false
					)
				end
			end)
			v6.MouseButton1Click:Connect(function()
				local v1 = func2(configNameInput.Text)

				if v1 == "" then
					v1 = "Exported Config"
				end

				local v2 = tbl1[9]:JSONEncode((func10(v1)))
				configJsonBox.Text = v2

				if func5(v2) then
					SetStatus("Exported and copied to your clipboard.", true)
				else
					SetStatus("Exported to the box (clipboard unsupported). Copy it manually.", nil)
				end
			end)
			v7.MouseButton1Click:Connect(function()
				local Text = configJsonBox.Text

				if Text == nil or Text:gsub("%s", "") == "" then
					Text = func6()
				end

				local v1 = func3(Text)

				if not v1 then
					SetStatus("Couldn't read JSON. Paste a config into the box first.", false)
					return
				end

				local v2, v3 = Apply(v1)

				if not v2 then
					SetStatus(v3, false)
					return
				end

				local v4 = func2(v1.CONFIG_NAME)

				if v4 ~= "" and func11(v4, v1) then
					SetStatus('Imported and saved as "' .. v4 .. '". ' .. v3, true)
					Refresh()
				else
					SetStatus("Imported. " .. v3, true)
				end
			end)
			v8.MouseButton1Click:Connect(function()
				configJsonBox.Text = ""
				SetStatus("Box cleared.", nil)
			end)
			v10.MouseButton1Click:Connect(function()
				local v1 = Refresh()
				SetStatus("Found " .. tostring(v1) .. " saved config(s).", nil)
			end)
			Refresh()
			return {Apply = Apply, Refresh = Refresh, SetStatus = SetStatus}
		end
		local func3
		tbl1[15] = nil

		if tbl1[13] then
			local tbl2, tbl3, tbl4, flag, v2, v3, flag1, num, num1, tbl5, func1, xursedHubGui,
				decorativeOverlay, toggleGuiBtn, container, tbl8, color, ApplyTheme, flag3, uDim21,
				tabContainer, uiListLayout, frame, tbl9, v65

			do
				tbl2 = {}
				tbl3 = {}
				tbl4 = {}
				flag = false
				local v1 =
					readfile
						or function()
							return nil
						end
				v2 = writefile or function() end
				v3 = setclipboard or toclipboard
				local v4 =
					syn and syn.request
						or http and http.request
						or http_request
						or fluxus and fluxus.request
						or request
						or function() end
				flag1 = false
				num = 0
				num1 = 0

				local function func()
					if tbl1[3].TouchEnabled and not tbl1[3].KeyboardEnabled then
						return "Mobile"
					end

					if tbl1[3].KeyboardEnabled then
						return "PC"
					end

					if tbl1[3].GamepadEnabled then
						return "Console"
					end

					return "Unknown Device"
				end

				tbl5 = {
					Theme = "Xursed",
					TotalTime = 0,
					AlwaysOnTop = false,
					HideUsernameAndID = false,
					UIScale = 1,
					CustomBgUrl = "",
					CustomBgOpacity = 75,
					CustomBgDim = 45,
					CustomBgScaleType = "Crop"
				};

				(function()
					local ok, result = pcall(v1, "XursedHub_Settings.json")

					if ok and type(result) == "string" and result ~= "" then
						local ok1, result1 = pcall(function()
							return tbl1[9]:JSONDecode(result)
						end)
						if ok1 and type(result1) == "table" then
							tbl5 = result1
						end
					end

					local v2 = tbl5
					v2.TotalTime = math.max(0, tonumber(v2.TotalTime) or 0)

					if not tbl5.Theme or not XursedThemes[tbl5.Theme] then
						tbl5.Theme = "Xursed"
					end

					if tbl5.AlwaysOnTop == nil then
						tbl5.AlwaysOnTop = false
					end

					if tbl5.HideUsernameAndID == nil then
						tbl5.HideUsernameAndID = false
					end

					if type(tbl5.CustomBgUrl) ~= "string" then
						tbl5.CustomBgUrl = ""
					end

					tbl5.CustomBgOpacity = math.clamp(tonumber(tbl5.CustomBgOpacity) or 75, 0, 100)
					tbl5.CustomBgDim = math.clamp(tonumber(tbl5.CustomBgDim) or 45, 0, 95)
					if type(tbl5.CustomBgScaleType) ~= "string" or not XursedBG.ScaleEnums[tbl5.CustomBgScaleType] then
						tbl5.CustomBgScaleType = "Crop"
					end

					local v3 = tbl5
					v3.UIScale = tonumber(v3.UIScale) or 1
				end)()
				pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))

				local tbl6 = {
					SetApiEnv = true,
					ToggleApiMode = true,
					Ban = true,
					AdminGUI = true,
					WalkSpeedChanged = true,
					SpecialGloveAccess = true,
					PlaySoundRemote = true,
					GRAB = true,
					AntiMobileExploits = true,
					MusicLoaderI = true,
					DEATHBARRIER = true,
					DEATHBARRIER2 = true
				}

				local tbl7 = {
					game.Workspace,
					game.Players,
					game.ReplicatedStorage,
					game.StarterGui
				};
				(function()
					for _, v1 in ipairs(tbl7) do
						pcall(function()
							for _, descendant in ipairs(v1:GetDescendants()) do
								if tbl6[descendant.Name] then
									pcall(function()
										descendant:Destroy()
									end)
								end
							end
						end)
					end
				end)()

				for _, v5 in ipairs(tbl7) do
					pcall(function()
						v5.DescendantAdded:Connect(function(descendant)
							if tbl6[descendant.Name] then
								pcall(function()
									descendant:Destroy()
								end)
							end
						end)
					end)
				end

				function func1(arg1, arg2)
					local Character = tbl1[11].Character
					local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

					if v1 then
						local v2 = typeof(arg2) == "Vector3" and arg2 or Vector3.new(0, 3, 0)
						v1.CFrame = CFrame.new(arg1 + v2)
					end
				end

				if tbl1[2]:FindFirstChild("XursedHubGui") then
					tbl1[2].XursedHubGui:Destroy()
				end

				xursedHubGui = Instance.new("ScreenGui")
				xursedHubGui.Name = "XursedHubGui"
				xursedHubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				xursedHubGui.DisplayOrder = tbl5.AlwaysOnTop and 100000 or 0
				xursedHubGui.Parent = tbl1[2]
				decorativeOverlay = Instance.new("Frame")
				decorativeOverlay.Name = "DecorativeOverlay"
				decorativeOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
				decorativeOverlay.BackgroundTransparency = 1
				decorativeOverlay.BorderSizePixel = 0
				decorativeOverlay.Visible = false
				decorativeOverlay.Parent = xursedHubGui
				toggleGuiBtn = Instance.new("TextButton")
				toggleGuiBtn.Name = "ToggleGuiBtn"
				toggleGuiBtn.Size = UDim2.new(0, 118, 0, 34)
				toggleGuiBtn.Position = UDim2.new(0, 16, 0, 16)
				toggleGuiBtn.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
				toggleGuiBtn.BackgroundTransparency = 0.08
				toggleGuiBtn.BorderSizePixel = 0
				toggleGuiBtn.AutoButtonColor = false
				toggleGuiBtn.Text = ""
				toggleGuiBtn.Parent = xursedHubGui
				local uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = UDim.new(1, 0)
				uiCorner.Parent = toggleGuiBtn
				local toggleStroke = Instance.new("UIStroke")
				toggleStroke.Name = "ToggleStroke"
				toggleStroke.Color = Color3.fromRGB(220, 50, 100)
				toggleStroke.Thickness = 1.4
				toggleStroke.Transparency = 0.2
				toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				toggleStroke.Parent = toggleGuiBtn
				local toggleDot = Instance.new("Frame")
				toggleDot.Name = "ToggleDot"
				toggleDot.Size = UDim2.new(0, 8, 0, 8)
				toggleDot.Position = UDim2.new(0, 12, 0.5, -4)
				toggleDot.BackgroundColor3 = Color3.fromRGB(220, 50, 100)
				toggleDot.BorderSizePixel = 0
				toggleDot.Parent = toggleGuiBtn
				local toggleDotCorner = Instance.new("UICorner")
				toggleDotCorner.CornerRadius = UDim.new(1, 0)
				toggleDotCorner.Parent = toggleDot
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, -24, 1, 0)
				textLabel.Position = UDim2.new(0, 22, 0, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.FontFace = fontBold
				textLabel.TextSize = 12
				textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
				textLabel.Text = "Hide Xursed"
				textLabel.Parent = toggleGuiBtn
				local flag2 = false
				local toggleDragged = false
				local v66
				local vector3 = Vector3.new()
				local uDim2 = UDim2.new()
				toggleGuiBtn.InputBegan:Connect(function(input)
					if
						input.UserInputType == Enum.UserInputType.MouseButton1
							or input.UserInputType == Enum.UserInputType.Touch
					then
						flag2 = true
						toggleDragged = false
						v66 = input
						vector3 = input.Position
						uDim2 = toggleGuiBtn.Position
					end
				end)
				tbl1[3].InputChanged:Connect(function(input)
					if
						flag2
							and v66
							and v66.UserInputType == Enum.UserInputType.MouseButton1
							and not tbl1[3]:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					then
						flag2 = false
						v66 = nil
					end
					if flag2 and v66 then
						local v1 =
							v66.UserInputType == Enum.UserInputType.MouseButton1
								and input.UserInputType == Enum.UserInputType.MouseMovement
						local v2 = v66.UserInputType == Enum.UserInputType.Touch and input == v66

						if v1 or v2 then
							local v3 = input.Position - vector3
							if v3.Magnitude > 6 then
								toggleDragged = true
							end
							toggleGuiBtn.Position = UDim2.new(
								uDim2.X.Scale,
								uDim2.X.Offset + v3.X,
								uDim2.Y.Scale,
								uDim2.Y.Offset + v3.Y
							)
						end
					end
				end)
				tbl1[3].InputEnded:Connect(function(input)
					if
						v66
							and (input == v66
								or v66.UserInputType == Enum.UserInputType.MouseButton1
									and input.UserInputType == Enum.UserInputType.MouseButton1)
					then
						flag2 = false
						v66 = nil
					end
				end)
				container = Instance.new("Frame")
				container.Name = "Container"
				container.Size = UDim2.new(0, 0, 0, 0)
				container.Position = UDim2.new(0.5, 0, 0.5, 0)
				container.BackgroundColor3 = Color3.fromRGB(14, 13, 20)
				container.BorderSizePixel = 0
				container.ClipsDescendants = true
				container.BackgroundTransparency = 1
				container.Parent = xursedHubGui
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.Name = "CustomBgImage"
				imageLabel.Size = UDim2.new(1, 0, 1, 0)
				imageLabel.BackgroundTransparency = 1
				imageLabel.Image = ""
				imageLabel.ImageTransparency = 1
				imageLabel.ScaleType = Enum.ScaleType.Crop
				imageLabel.Visible = false
				imageLabel.ZIndex = 1
				imageLabel.ClipsDescendants = true
				imageLabel.Parent = container
				local bgCorner = Instance.new("UICorner")
				bgCorner.CornerRadius = UDim.new(0, 14)
				bgCorner.Parent = imageLabel
				decorativeOverlay.Size = UDim2.new(1, 0, 1, 0)
				decorativeOverlay.Position = UDim2.new(0, 0, 0, 0)
				decorativeOverlay.ZIndex = 2
				decorativeOverlay.Parent = container
				local dimCorner = Instance.new("UICorner")
				dimCorner.CornerRadius = UDim.new(0, 14)
				dimCorner.Parent = decorativeOverlay

				tbl8 = {
					Xursed = XursedThemes.Xursed.Base,
					Amethyst = XursedThemes.Amethyst.Base,
					Abyss = XursedThemes.Abyss.Base,
					Emerald = XursedThemes.Emerald.Base,
					Bloodmoon = XursedThemes.Bloodmoon.Base,
					Solaris = XursedThemes.Solaris.Base,
					Sakura = XursedThemes.Sakura.Base,
					Void = XursedThemes.Void.Base
				}

				color = XursedThemes.Xursed.Accent
				local bgPanelController
				local onThemeChanged

				function ApplyTheme(arg1)
					local v1 = XursedThemes[arg1] and arg1 or "Xursed"
					local spec = XursedThemes[v1] or XursedThemes.Xursed
					local v3 = spec.Base
					local surf = spec.Surface
					color = spec.Accent
					tbl5.Theme = v1
					pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))

					if onThemeChanged then
						pcall(onThemeChanged, color)
					end
					if toggleStroke then
						toggleStroke.Color = color
					end
					if toggleDot then
						toggleDot.BackgroundColor3 = color
					end
					if toggleGuiBtn then
						toggleGuiBtn.BackgroundColor3 = v3
					end
					if bgPanelController and bgPanelController.RefreshAccent then
						pcall(bgPanelController.RefreshAccent, color)
					end

					if container then
						container.BackgroundColor3 = v3
						local ThemeGradient = container:FindFirstChild("ThemeGradient")

						if not ThemeGradient then
							local uiGradient = Instance.new("UIGradient")
							ThemeGradient = uiGradient
							uiGradient.Name = "ThemeGradient"
							uiGradient.Parent = container
						end

						ThemeGradient.Color = ColorSequence.new(
							{
								ColorSequenceKeypoint.new(0, spec.GradA),
								ColorSequenceKeypoint.new(1, spec.GradB)
							}
						)
						ThemeGradient.Rotation = 135

						local winStroke = container:FindFirstChild("WindowStroke")
						if winStroke then
							winStroke.Color = color
						end
						local headerDot = container:FindFirstChild("HeaderDot")
						if headerDot then
							headerDot.BackgroundColor3 = color
						end
						local headerDivider = container:FindFirstChild("HeaderDivider")
						if headerDivider then
							headerDivider.BackgroundColor3 = color
						end
					end

					if container then
						for _, descendant in ipairs(container:GetDescendants()) do
							if
								descendant:IsA("TextLabel")
									or descendant:IsA("TextButton")
									or descendant:IsA("TextBox")
							then
								if
									descendant.Name ~= "BgStatus"
										and descendant.Name ~= "ConfigStatus"
								then
									descendant.TextColor3 = Color3.fromRGB(244, 245, 252)
								end
							end
							if descendant:IsA("UIStroke") then
								if
									descendant.Name == "TabStroke"
										or descendant.Name == "AccentStroke"
										or descendant.Name == "WindowStroke"
										or descendant.Name == "RowStroke"
								then
									descendant.Color = color
								end
							elseif descendant:IsA("ScrollingFrame") then
								descendant.ScrollBarImageColor3 = color
							elseif descendant:IsA("TextButton") then
								local ThemeOutline = descendant:FindFirstChild("ThemeOutline")

								if ThemeOutline then
									ThemeOutline:Destroy()
								end

								if
									descendant.BackgroundTransparency < 1
										and descendant.Name ~= "DestroyHubX"
										and descendant.Name ~= "MinimizeHubBtn"
										and descendant.Name ~= "BgApplyBtn"
										and descendant.Name ~= "BgClearBtn"
										and descendant.Name ~= "BgFitBtn"
										and descendant.Name ~= "ThemeSwatchBtn"
								then
									descendant.BackgroundColor3 = surf
									descendant.BackgroundTransparency = 0.22
								end
							elseif
								descendant:IsA("Frame")
									and (descendant.Name == "HubParagraph"
										or descendant.Name == "CustomBgPanel"
										or descendant.Name == "ProfileCard")
							then
								descendant.BackgroundColor3 = surf
								descendant.BackgroundTransparency = 0.25
							elseif
								descendant:IsA("Frame")
									and (descendant.Name == "ToggleRow"
										or descendant.Name == "SliderRow")
							then
								descendant.BackgroundColor3 = surf
								descendant.BackgroundTransparency = 0.22
							elseif descendant:IsA("Frame") and descendant.Name == "SliderFill" then
								descendant.BackgroundColor3 = color
							elseif descendant:IsA("Frame") and descendant.Name == "ToggleTrack" then
								if descendant:GetAttribute("IsOn") == true then
									descendant.BackgroundColor3 = color
								end
							end
						end
					end
				end

				ApplyTheme(tbl5.Theme)
				local uiCorner1 = Instance.new("UICorner")
				uiCorner1.CornerRadius = UDim.new(0, 14)
				uiCorner1.Parent = container
				local windowStroke = Instance.new("UIStroke")
				windowStroke.Name = "WindowStroke"
				windowStroke.Color = color
				windowStroke.Thickness = 1.5
				windowStroke.Transparency = 0.32
				windowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				windowStroke.Parent = container
				flag3 = true
				uDim21 = UDim2.new(0.5, -280, 0.5, -180)
				task.spawn(function()
					task.wait(0.1)
					local UIScale = container:FindFirstChildOfClass("UIScale")
					local v1 = UIScale and UIScale.Scale or 1
					uDim21 = UDim2.new(
						0.5,
						-280 + 560 * (1 - v1) / 2,
						0.5,
						-180 + 360 * (1 - v1) / 2
					)
					tbl1[7]:Create(
						container,
						TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{
							Size = UDim2.new(0, 560, 0, 360),
							Position = uDim21,
							BackgroundTransparency = 0.04
						}
					)
						:Play()
				end)
				toggleGuiBtn.MouseButton1Click:Connect(function()
					if toggleDragged then
						toggleDragged = false
						return
					end
					flag3 = not flag3
					if flag3 then
						textLabel.Text = "Hide Xursed"
						tbl1[7]:Create(
							container,
							TweenInfo.new(
								0.35,
								Enum.EasingStyle.Exponential,
								Enum.EasingDirection.Out
							),
							{Position = uDim21, Size = UDim2.new(0, 560, 0, 360)}
						)
							:Play()
					else
						uDim21 = container.Position
						textLabel.Text = "Show Xursed"
						tbl1[7]:Create(
							container,
							TweenInfo.new(
								0.35,
								Enum.EasingStyle.Exponential,
								Enum.EasingDirection.In
							),
							{
								Position = UDim2.new(uDim21.X.Scale, uDim21.X.Offset, 1.5, 0),
								Size = UDim2.new(0, 0, 0, 0)
							}
						)
							:Play()
					end
				end)
				local headerDot = Instance.new("Frame")
				headerDot.Name = "HeaderDot"
				headerDot.Size = UDim2.new(0, 9, 0, 9)
				headerDot.Position = UDim2.new(0, 14, 0, 14)
				headerDot.BackgroundColor3 = color
				headerDot.BorderSizePixel = 0
				headerDot.ZIndex = 5
				headerDot.Parent = container
				local headerDotCorner = Instance.new("UICorner")
				headerDotCorner.CornerRadius = UDim.new(1, 0)
				headerDotCorner.Parent = headerDot
				local textLabel1 = Instance.new("TextLabel")
				textLabel1.Size = UDim2.new(1, -100, 0, 26)
				textLabel1.Position = UDim2.new(0, 30, 0, 6)
				textLabel1.BackgroundTransparency = 1
				textLabel1.FontFace = fontBold
				textLabel1.TextSize = 15
				textLabel1.TextColor3 = Color3.fromRGB(245, 247, 252)
				textLabel1.Text = tbl1[12][game.PlaceId] or "Xursed Hub | Slap Battles"
				textLabel1.TextXAlignment = Enum.TextXAlignment.Left
				textLabel1.ZIndex = 5
				textLabel1.Parent = container
				local headerDivider = Instance.new("Frame")
				headerDivider.Name = "HeaderDivider"
				headerDivider.Size = UDim2.new(1, -24, 0, 1)
				headerDivider.Position = UDim2.new(0, 12, 0, 37)
				headerDivider.BackgroundColor3 = color
				headerDivider.BackgroundTransparency = 0.72
				headerDivider.BorderSizePixel = 0
				headerDivider.ZIndex = 5
				headerDivider.Parent = container
				tabContainer = Instance.new("ScrollingFrame")
				tabContainer.Name = "TabContainer"
				tabContainer.Size = UDim2.new(1, -24, 0, 30)
				tabContainer.Position = UDim2.new(0, 12, 0, 44)
				tabContainer.BackgroundTransparency = 1
				tabContainer.BorderSizePixel = 0
				tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
				tabContainer.ScrollBarThickness = 0
				tabContainer.ZIndex = 5
				tabContainer.Parent = container
				uiListLayout = Instance.new("UIListLayout")
				uiListLayout.FillDirection = Enum.FillDirection.Horizontal
				uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				uiListLayout.Padding = UDim.new(0, 6)
				uiListLayout.Parent = tabContainer
				frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, -24, 1, -88)
				frame.Position = UDim2.new(0, 12, 0, 80)
				frame.BackgroundTransparency = 1
				frame.ZIndex = 5
				frame.Parent = container
				tbl9 = {}
			end

			local v6, tbl10, func2, func4, func5, v7, v8, v9, v10, v11, v12, v13, v14, func7, v67,
				v68, connection, v69, v70, v71, v72, tbl12

			do
				v6 = (function(arg1)
					local tbl = {
						Toggles = {},
						Sliders = {},
						Pins = {},
						AutoRestore = true,
						Pending = {},
						SliderControls = {},
						SliderValues = {},
						Path = arg1,
						Ready = false,
						_queued = false
					}

					if type(readfile) == "function" then
						local ok, result = pcall(readfile, arg1)
						if ok and type(result) == "string" and result ~= "" then
							local ok1, result1 = pcall(function()
								return tbl1[9]:JSONDecode(result)
							end)
							if ok1 and type(result1) == "table" then
								if type(result1.Toggles) == "table" then
									for k, toggle in pairs(result1.Toggles) do
										if type(toggle) == "boolean" then
											tbl.Toggles[k] = toggle
										end
									end
								end

								if type(result1.Sliders) == "table" then
									for k1, slider in pairs(result1.Sliders) do
										if tonumber(slider) then
											tbl.Sliders[k1] = tonumber(slider)
										end
									end
								end

								if result1.AutoRestore == false then
									tbl.AutoRestore = false
								end

								if type(result1.Pins) == "table" then
									for k2, pin in pairs(result1.Pins) do
										if pin == true then
											tbl.Pins[k2] = true
										end
									end
								end
							end
						end
					end

					function tbl.Save()
						if type(writefile) ~= "function" then
							return false
						end
						return
							(pcall(
								writefile,
								arg1,
								tbl1[9]:JSONEncode(
									{
										Toggles = tbl.Toggles,
										Sliders = tbl.Sliders,
										Pins = tbl.Pins,
										AutoRestore = tbl.AutoRestore
									}
								)
							))
					end

					function tbl.QueueSave()
						if tbl._queued then
							return
						end

						tbl._queued = true
						task.delay(
							0.75,
							function()
								tbl._queued = false
								tbl.Save()
							end
						)
					end

					function tbl.Defer(arg1)
						if tbl.Ready then
							task.defer(arg1)
						else
							table.insert(tbl.Pending, arg1)
						end
					end

					function tbl.Start()
						task.spawn(function()
							pcall(function()
								local LocalPlayer = game:GetService("Players").LocalPlayer
								local num = 0

								while
									num < 10
										and not (LocalPlayer.Character
											and LocalPlayer.Character:FindFirstChild(
												"HumanoidRootPart"
											))
								do
									task.wait(0.25)
									num = num + 0.25
								end
							end)
							task.wait(0.9)
							tbl.Ready = true
							local Pending = tbl.Pending
							tbl.Pending = {}

							for _, v1 in ipairs(Pending) do
								pcall(v1)
							end
						end)
					end

					function tbl.SetPin(arg1, arg2)
						tbl.Pins[arg1] = arg2 and true or nil
						tbl.QueueSave()
					end

					function tbl.Count()
						local num = 0
						local num1 = 0

						for _ in pairs(tbl.Toggles) do
							num = num + 1
						end

						for _ in pairs(tbl.Sliders) do
							num1 = num1 + 1
						end

						return num, num1
					end

					function tbl.Reset()
						tbl.Toggles = {}
						tbl.Sliders = {}
						tbl.Save()
					end

					function tbl.SnapshotSliders()
						local tbl1 = {}

						for k, sliderValue in pairs(tbl.SliderValues) do
							tbl1[k] = sliderValue
						end

						return tbl1
					end

					return tbl
				end)("XursedHub_Controls_Main.json")

				tbl10 = {
					Registry = {},
					ByName = {},
					PinPainters = {},
					Accent = color,
					Dim = Color3.fromRGB(115, 118, 136)
				}
				onThemeChanged = function(acc)
					tbl10.Accent = acc
				end

				tbl10.Font = font

				function tbl10.refreshPinned() end

				tbl10.IconOrder = {Search = -3, Pinned = -2, Versions = -1}

				function tbl10.tabNameOf(arg1)
					for k, v1 in pairs(tbl9) do
						if v1.Scroll == arg1 then
							return k
						end
					end
					return "Other"
				end

				function tbl10.register(arg1)
					arg1.TabName = tbl10.tabNameOf(arg1.Tab)
					table.insert(tbl10.Registry, arg1)
					tbl10.ByName[arg1.Name] = arg1
				end

				function tbl10.part(parent, arg2, arg3, arg4, arg5, backgroundColor3, cornerRadius)
					local iconPart = Instance.new("Frame")
					iconPart.Name = "IconPart"
					iconPart.BackgroundColor3 = backgroundColor3
					iconPart.BorderSizePixel = 0
					iconPart.Position = UDim2.fromScale(arg2, arg3)
					iconPart.Size = UDim2.fromScale(arg4, arg5)
					iconPart.Parent = parent

					if cornerRadius then
						local uiCorner = Instance.new("UICorner")
						uiCorner.CornerRadius = cornerRadius
						uiCorner.Parent = iconPart
					end

					return iconPart
				end

				function tbl10.newIconFrame(parent, name)
					local frame = Instance.new("Frame")
					frame.Name = name
					frame.BackgroundTransparency = 1
					frame.Size = UDim2.new(0, 14, 0, 14)
					frame.AnchorPoint = Vector2.new(0.5, 0.5)
					frame.Position = UDim2.new(0.5, 0, 0.5, 0)
					frame.Parent = parent
					return frame
				end

				function tbl10.drawSearchIcon(arg1, color)
					local v1 = tbl10.newIconFrame(arg1, "SearchIcon")
					local iconRing = Instance.new("Frame")
					iconRing.Name = "IconRing"
					iconRing.BackgroundTransparency = 1
					iconRing.Size = UDim2.fromScale(0.66, 0.66)
					iconRing.Parent = v1
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(1, 0)
					uiCorner.Parent = iconRing
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = color
					uiStroke.Thickness = 1.6
					uiStroke.Parent = iconRing
					local v2 = tbl10.part(v1, 0.76, 0.76, 0.5, 0.12, color, UDim.new(1, 0))
					v2.AnchorPoint = Vector2.new(0.5, 0.5)
					v2.Rotation = 45
					return v1
				end

				function tbl10.drawPinIcon(arg1, arg2)
					local v1 = tbl10.newIconFrame(arg1, "PinIcon")
					tbl10.part(v1, 0.3, 0.06, 0.4, 0.16, arg2, UDim.new(0, 1))
					tbl10.part(v1, 0.38, 0.22, 0.24, 0.3, arg2)
					tbl10.part(v1, 0.16, 0.5, 0.68, 0.16, arg2, UDim.new(0, 1))
					tbl10.part(v1, 0.45, 0.66, 0.1, 0.3, arg2)
					return v1
				end

				function tbl10.setIconColor(arg1, backgroundColor3)
					for _, descendant in ipairs(arg1:GetDescendants()) do
						if descendant:IsA("UIStroke") then
							descendant.Color = backgroundColor3
						elseif descendant:IsA("Frame") and descendant.Name == "IconPart" then
							descendant.BackgroundColor3 = backgroundColor3
						end
					end
				end

				function tbl10.makePin(parent, arg2, position)
					local pinButton = Instance.new("TextButton")
					pinButton.Name = "PinButton"
					pinButton.Size = UDim2.new(0, 18, 0, 18)
					pinButton.Position = position
					pinButton.BackgroundTransparency = 1
					pinButton.Text = ""
					pinButton.AutoButtonColor = false
					pinButton.ZIndex = parent.ZIndex + 1
					pinButton.Parent = parent
					local v1 = tbl10.drawPinIcon(pinButton, tbl10.Dim)

					local function paint()
						tbl10.setIconColor(v1, v6.Pins[arg2] and tbl10.Accent or tbl10.Dim)
					end

					paint()
					local v2 = tbl10.PinPainters[arg2]

					if not v2 then
						v2 = {}
						tbl10.PinPainters[arg2] = v2
					end

					table.insert(v2, {button = pinButton, paint = paint})
					pinButton.MouseButton1Click:Connect(function()
						v6.SetPin(arg2, not v6.Pins[arg2])

						for i = #v2, 1, -1 do
							local v1 = v2[i]
							if v1.button.Parent then
								pcall(v1.paint)
							else
								table.remove(v2, i)
							end
						end

						tbl10.refreshPinned()
					end)
					return pinButton
				end

				function tbl10.styleRow(parent, arg2)
					parent.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					parent.BorderSizePixel = 0
					parent.Size = UDim2.new(1, 0, 0, arg2)
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 5)
					uiCorner.Parent = parent
				end

				function tbl10.newText(parent, text, size, position)
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = size
					textLabel.Position = position
					textLabel.BackgroundTransparency = 1
					textLabel.FontFace = tbl10.Font
					textLabel.TextSize = 11
					textLabel.TextColor3 = tbl10.Accent
					textLabel.Text = text
					textLabel.TextXAlignment = Enum.TextXAlignment.Left
					textLabel.Parent = parent
					return textLabel
				end

				function tbl10.buildProxyRow(parent, arg2)
					if arg2.Kind == "toggle" then
						local toggleRow = Instance.new("Frame")
						toggleRow.Name = "ToggleRow"
						toggleRow.Parent = parent
						tbl10.styleRow(toggleRow, 28)
						tbl10.newText(
							toggleRow,
							arg2.Name .. "  (" .. arg2.TabName .. ")",
							UDim2.new(1, -70, 1, 0),
							UDim2.new(0, 8, 0, 0)
						)
						local frame = Instance.new("Frame")
						frame.Size = UDim2.new(0, 28, 0, 14)
						frame.Position = UDim2.new(1, -34, 0.5, -7)
						frame.BorderSizePixel = 0
						frame.Parent = toggleRow
						local uiCorner = Instance.new("UICorner")
						uiCorner.CornerRadius = UDim.new(1, 0)
						uiCorner.Parent = frame
						local frame1 = Instance.new("Frame")
						frame1.Size = UDim2.new(0, 10, 0, 10)
						frame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						frame1.BorderSizePixel = 0
						frame1.Parent = frame
						local uiCorner1 = Instance.new("UICorner")
						uiCorner1.CornerRadius = UDim.new(1, 0)
						uiCorner1.Parent = frame1

						local function func()
							local v1 = arg2.Get() == true
							frame.BackgroundColor3 =
								v1 and tbl10.Accent or Color3.fromRGB(50, 50, 50)
							frame1.Position =
								v1 and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
						end

						func()
						local textButton = Instance.new("TextButton")
						textButton.Size = UDim2.new(1, 0, 1, 0)
						textButton.BackgroundTransparency = 1
						textButton.Text = ""
						textButton.Parent = toggleRow
						textButton.MouseButton1Click:Connect(function()
							arg2.Set(not (arg2.Get() == true), true)
							func()
						end)
						tbl10.makePin(toggleRow, arg2.Name, UDim2.new(1, -62, 0.5, -9))
					elseif arg2.Kind == "slider" then
						local sliderRow = Instance.new("Frame")
						sliderRow.Name = "SliderRow"
						sliderRow.Parent = parent
						tbl10.styleRow(sliderRow, 28)
						tbl10.newText(
							sliderRow,
							arg2.Name .. "  (" .. arg2.TabName .. ")",
							UDim2.new(1, -130, 1, 0),
							UDim2.new(0, 8, 0, 0)
						)
						local textBox = Instance.new("TextBox")
						textBox.Size = UDim2.new(0, 48, 0, 18)
						textBox.Position = UDim2.new(1, -78, 0.5, -9)
						textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
						textBox.BorderSizePixel = 0
						textBox.FontFace = tbl10.Font
						textBox.TextSize = 10
						textBox.TextColor3 = tbl10.Accent
						textBox.ClearTextOnFocus = false
						textBox.Text = tostring(arg2.Get())
						textBox.Parent = sliderRow
						local uiCorner2 = Instance.new("UICorner")
						uiCorner2.CornerRadius = UDim.new(0, 3)
						uiCorner2.Parent = textBox
						textBox.FocusLost:Connect(function()
							local num = tonumber(textBox.Text)

							if num then
								arg2.Set(num, true)
							end

							textBox.Text = tostring(arg2.Get())
						end)
						tbl10.makePin(sliderRow, arg2.Name, UDim2.new(1, -24, 0.5, -9))
					else
						local hubButton = Instance.new("TextButton")
						hubButton.Name = "HubButton"
						hubButton.BorderSizePixel = 0
						hubButton.FontFace = tbl10.Font
						hubButton.TextSize = 11
						hubButton.TextColor3 = tbl10.Accent
						hubButton.Text = arg2.Name .. "  (" .. arg2.TabName .. ")"
						hubButton.Parent = parent
						tbl10.styleRow(hubButton, 28)
						hubButton.MouseButton1Click:Connect(function()
							task.spawn(arg2.Run)
						end)
						tbl10.makePin(hubButton, arg2.Name, UDim2.new(1, -24, 0.5, -9))
					end
				end

				function tbl10.normalize(arg1)
					return (tostring(arg1):lower():gsub("[^%w]", ""))
				end

				function tbl10.subsequence(arg1, arg2)
					local num = 1

					for i = 1, #arg2 do
						local v1 = string.find(arg1, arg2:sub(i, i), num, true)

						if not v1 then
							return false
						end

						num = v1 + 1
					end

					return true
				end

				function tbl10.search(arg1)
					local tbl = {}

					for k in tostring(arg1):gmatch("%S+") do
						local v1 = tbl10.normalize(k)
						if v1 ~= "" then
							table.insert(tbl, v1)
						end
					end

					local tbl1 = {}

					for i, v2 in ipairs(tbl10.Registry) do
						local v3 = tbl10.normalize(v2.Name)
						local v4 = tbl10.normalize(v2.TabName)
						local num = 0
						local flag = true

						for _, v5 in ipairs(tbl) do
							local v6 = string.find(v3, v5, 1, true)
							if v6 then
								num = num + (v6 == 1 and 150 or 100)
							elseif string.find(v4, v5, 1, true) then
								num = num + 20
							elseif #v5 >= 2 and tbl10.subsequence(v3, v5) then
								num = num + 30
							else
								flag = false
								break
							end
						end

						if flag then
							table.insert(tbl1, {entry = v2, score = num - i * 0.001})
						end
					end

					table.sort(
						tbl1,
						function(a, b)
							return a.score > b.score
						end
					)
					return tbl1
				end

				function tbl10.clear(arg1)
					for _, child in ipairs(arg1:GetChildren()) do
						if not child:IsA("UIListLayout") then
							child:Destroy()
						end
					end
				end

				function tbl10.note(arg1, arg2)
					local v1 = tbl10.newText(
						arg1,
						arg2,
						UDim2.new(1, 0, 0, 40),
						UDim2.new(0, 0, 0, 0)
					)
					v1.TextWrapped = true
					v1.TextSize = 10
					return v1
				end

				function func2(text, arg2)
					local scrollingFrame = Instance.new("ScrollingFrame")
					scrollingFrame.Name = text .. "Content"
					scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
					scrollingFrame.BackgroundTransparency = 1
					scrollingFrame.BorderSizePixel = 0
					scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
					scrollingFrame.ScrollBarThickness = 3
					scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 50, 100)
					scrollingFrame.ScrollBarImageTransparency = 0.4
					scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
					scrollingFrame.Visible = false
					scrollingFrame.Parent = frame
					local uiListLayout1 = Instance.new("UIListLayout")
					uiListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
					uiListLayout1.Padding = UDim.new(0, 6)
					local uiPadding = Instance.new("UIPadding")
					uiPadding.PaddingRight = UDim.new(0, 6)
					uiPadding.PaddingTop = UDim.new(0, 2)
					uiPadding.Parent = scrollingFrame
					uiListLayout1.Parent = scrollingFrame
					uiListLayout1:GetPropertyChangedSignal("AbsoluteContentSize")
						:Connect(function()
							scrollingFrame.CanvasSize = UDim2.new(
								0,
								0,
								0,
								uiListLayout1.AbsoluteContentSize.Y + 8
							)
						end)
					local frame1 = Instance.new("Frame")
					frame1.Name = text .. "TabBtn"
					frame1.Size = UDim2.new(0, 0, 1, 0)
					frame1.AutomaticSize = Enum.AutomaticSize.X
					frame1.BackgroundTransparency = 0.8
					frame1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					frame1.Parent = tabContainer
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 7)
					local tabStroke = Instance.new("UIStroke")
					tabStroke.Name = "TabStroke"
					tabStroke.Color = Color3.fromRGB(220, 50, 100)
					tabStroke.Thickness = 1
					tabStroke.Transparency = 1
					tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					tabStroke.Parent = frame1
					uiCorner.Parent = frame1
					local uiPadding1 = Instance.new("UIPadding")
					uiPadding1.PaddingLeft = UDim.new(0, 10)
					uiPadding1.PaddingRight = UDim.new(0, 10)
					uiPadding1.Parent = frame1
					local textButton = Instance.new("TextButton")
					textButton.Size = UDim2.new(1, 0, 1, 0)
					textButton.BackgroundTransparency = 1
					textButton.FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					)
					textButton.TextSize = 12
					textButton.TextColor3 = Color3.fromRGB(245, 247, 252)
					textButton.Text = text
					textButton.AutomaticSize = Enum.AutomaticSize.X
					textButton.Parent = frame1

					if arg2 then
						textButton.Text = ""
						textButton.AutomaticSize = Enum.AutomaticSize.None
						textButton.Size = UDim2.new(0, 16, 1, 0)
						frame1.LayoutOrder = tbl10.IconOrder[text] or -1
						arg2(textButton, Color3.fromRGB(220, 50, 100))
					end

					uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize")
						:Connect(function()
							tabContainer.CanvasSize = UDim2.new(
								0,
								uiListLayout.AbsoluteContentSize.X,
								0,
								0
							)
						end)
					textButton.MouseButton1Click:Connect(function()
						for _, v1 in pairs(tbl9) do
							v1.Scroll.Visible = false
							local TabStroke = v1.Button:FindFirstChild("TabStroke")

							if TabStroke then
								TabStroke.Transparency = 1
							end

							v1.Button.BackgroundTransparency = 0.8
						end

						scrollingFrame.Visible = true
						local TabStroke1 = frame1:FindFirstChild("TabStroke")

						if TabStroke1 then
							TabStroke1.Transparency = 0.15
						end

						frame1.BackgroundTransparency = 0.55
						v65 = text
						local v2 = tbl9[text]

						if v2 and v2.OnShow then
							pcall(v2.OnShow)
						end
					end)

					if not v65 then
						scrollingFrame.Visible = true
						v65 = text
						tabStroke.Transparency = 0.15
						frame1.BackgroundTransparency = 0.55
					end

					tbl9[text] = {Scroll = scrollingFrame, Button = frame1}
					return scrollingFrame
				end

				function func3(parent, text, text1)
					local hubParagraph = Instance.new("Frame")
					hubParagraph.Name = "HubParagraph"
					hubParagraph.Size = UDim2.new(1, 0, 0, 56)
					hubParagraph.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					hubParagraph.BackgroundTransparency = 0.4
					hubParagraph.BorderSizePixel = 0
					hubParagraph.Parent = parent
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 8)
					uiCorner.Parent = hubParagraph
					local titleLabel = Instance.new("TextLabel")
					titleLabel.Name = "TitleLabel"
					titleLabel.Size = UDim2.new(1, -16, 0, 16)
					titleLabel.Position = UDim2.new(0, 10, 0, 4)
					titleLabel.BackgroundTransparency = 1
					titleLabel.FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					)
					titleLabel.TextSize = 12
					titleLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
					titleLabel.Text = text
					titleLabel.TextXAlignment = Enum.TextXAlignment.Left
					titleLabel.Parent = hubParagraph
					local contentLabel = Instance.new("TextBox")
					contentLabel.Name = "ContentLabel"
					contentLabel.Size = UDim2.new(1, -20, 0, 30)
					contentLabel.Position = UDim2.new(0, 10, 0, 21)
					contentLabel.BackgroundTransparency = 1
					contentLabel.TextSize = 11
					contentLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
					contentLabel.Text = text1
					contentLabel.TextWrapped = true
					contentLabel.TextXAlignment = Enum.TextXAlignment.Left
					contentLabel.TextYAlignment = Enum.TextYAlignment.Top
					contentLabel.TextEditable = false
					contentLabel.ClearTextOnFocus = false
					contentLabel.Parent = hubParagraph
					return hubParagraph
				end

				function func4(parent, text, arg3)
					local hubButton = Instance.new("TextButton")
					hubButton.Name = "HubButton"
					hubButton.Size = UDim2.new(1, 0, 0, 32)
					hubButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					hubButton.BorderSizePixel = 0
					hubButton.FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					)
					hubButton.TextSize = 12
					hubButton.TextColor3 = Color3.fromRGB(245, 247, 252)
					hubButton.Text = text
					hubButton.Parent = parent
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 8)
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = Color3.fromRGB(220, 50, 100)
					uiStroke.Thickness = 1
					uiStroke.Transparency = 0.82
					uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					uiStroke.Parent = hubButton
					uiCorner.Parent = hubButton
					tbl10.makePin(hubButton, text, UDim2.new(1, -24, 0.5, -9))
					tbl10.register({Kind = "button", Name = text, Tab = parent, Run = arg3})
					hubButton.MouseButton1Click:Connect(function()
						local BackgroundColor3 = hubButton.BackgroundColor3
						local v1 = BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.12)
						tbl1[7]:Create(hubButton, TweenInfo.new(0.1), {BackgroundColor3 = v1})
							:Play()
						task.wait(0.1)
						tbl1[7]:Create(
							hubButton,
							TweenInfo.new(0.1),
							{BackgroundColor3 = BackgroundColor3}
						)
							:Play()
						arg3()
					end)
					return hubButton
				end

				tbl1[15] = function(parent, text, arg3, arg4)
					local v1 = arg4
					local v3
					local v2 = arg4 == true

					if v6.AutoRestore and type(v6.Toggles[text]) == "boolean" then
						v3 = v6.Toggles[text]
						v1 = v3
					end

					local toggleRow = Instance.new("Frame")
					toggleRow.Name = "ToggleRow"
					toggleRow.Size = UDim2.new(1, 0, 0, 32)
					toggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					toggleRow.BorderSizePixel = 0
					toggleRow.Parent = parent
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 8)
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = Color3.fromRGB(220, 50, 100)
					uiStroke.Thickness = 1
					uiStroke.Transparency = 0.82
					uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					uiStroke.Parent = toggleRow
					uiCorner.Parent = toggleRow
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, -70, 1, 0)
					textLabel.Position = UDim2.new(0, 12, 0, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					)
					textLabel.TextSize = 12
					textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
					textLabel.Text = text
					textLabel.TextXAlignment = Enum.TextXAlignment.Left
					textLabel.Parent = toggleRow
					local frame = Instance.new("Frame")
					frame.Name = "ToggleTrack"
					frame:SetAttribute("IsOn", v1 == true)
					frame.Size = UDim2.new(0, 36, 0, 18)
					frame.Position = UDim2.new(1, -44, 0.5, -9)
					frame.BackgroundColor3 = v1 == true and color or Color3.fromRGB(44, 42, 58)
					frame.BorderSizePixel = 0
					frame.Parent = toggleRow
					local uiCorner1 = Instance.new("UICorner")
					uiCorner1.CornerRadius = UDim.new(1, 0)
					uiCorner1.Parent = frame
					local frame1 = Instance.new("Frame")
					frame1.Size = UDim2.new(0, 14, 0, 14)
					frame1.Position =
						v1 == true and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
					frame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					frame1.BorderSizePixel = 0
					frame1.Parent = frame
					local uiCorner2 = Instance.new("UICorner")
					uiCorner2.CornerRadius = UDim.new(1, 0)
					uiCorner2.Parent = frame1
					local v4 = v1 == true

					local function func(arg1, arg2)
						v4 = arg1 == true
						frame:SetAttribute("IsOn", v4)
						local tweenInfo = TweenInfo.new(
							0.16,
							Enum.EasingStyle.Quart,
							Enum.EasingDirection.Out
						)
						tbl1[7]:Create(
							frame,
							tweenInfo,
							{BackgroundColor3 = v4 and color or Color3.fromRGB(44, 42, 58)}
						)
							:Play()
						tbl1[7]:Create(
							frame1,
							tweenInfo,
							{
								Position = v4 and UDim2.new(1, -16, 0.5, -7)
									or UDim2.new(0, 2, 0.5, -7)
							}
						)
							:Play()
						tbl2[text] = v4
						v6.Toggles[text] = v4
						v6.QueueSave()

						if arg2 then
							pcall(arg3, v4)
						end
					end

					tbl3[text] = func
					tbl2[text] = v4
					local textButton = Instance.new("TextButton")
					textButton.Size = UDim2.new(1, 0, 1, 0)
					textButton.BackgroundTransparency = 1
					textButton.Text = ""
					textButton.Parent = toggleRow
					textButton.MouseButton1Click:Connect(function()
						func(not v4, true)
					end)
					tbl10.makePin(toggleRow, text, UDim2.new(1, -70, 0.5, -9))
					tbl10.register(
						{
							Kind = "toggle",
							Name = text,
							Tab = parent,
							Get = function()
								return v4
							end,
							Set = func,
						}
					)

					if v3 ~= nil and (v3 or v2) then
						v6.Defer(function()
							func(v3, false)
							local ok, result = pcall(arg3, v3)

							if not ok then
								warn(
									"[Xursed Hub] Could not restore toggle '"
										.. tostring(text) .. "': " .. tostring(result)
								)
								tbl.Log(
									"Could not restore saved toggle '" .. tostring(text) .. "'",
									"Turning it back on from your saved config threw an error: "
										.. tostring(result),
									nil,
									"Toggle it manually, or re-save your config."
								)
								func(not v3, false)
							end
						end)
					end
				end

				function func5(parent, text, arg3, arg4, arg5, arg6, arg7)
					local v1 = arg5
					local v2

					if v6.AutoRestore and tonumber(v6.Sliders[text]) then
						v2 = math.clamp(math.floor(tonumber(v6.Sliders[text]) + 0.5), arg3, arg4)
						v1 = v2
					end

					local sliderRow = Instance.new("Frame")
					sliderRow.Name = "SliderRow"
					sliderRow.Size = UDim2.new(1, 0, 0, 44)
					sliderRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					sliderRow.BorderSizePixel = 0
					sliderRow.Parent = parent
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 8)
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = Color3.fromRGB(220, 50, 100)
					uiStroke.Thickness = 1
					uiStroke.Transparency = 0.82
					uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					uiStroke.Parent = sliderRow
					uiCorner.Parent = sliderRow
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, -76, 0, 18)
					textLabel.Position = UDim2.new(0, 12, 0, 4)
					textLabel.BackgroundTransparency = 1
					textLabel.FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					)
					textLabel.TextSize = 12
					textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
					textLabel.Text = text
					textLabel.TextXAlignment = Enum.TextXAlignment.Left
					textLabel.Parent = sliderRow
					local textBox = Instance.new("TextBox")
					textBox.Size = UDim2.new(0, 40, 0, 16)
					textBox.Position = UDim2.new(1, -50, 0, 4)
					textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
					textBox.BorderSizePixel = 0
					textBox.FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Regular,
						Enum.FontStyle.Normal
					)
					textBox.TextSize = 10
					textBox.TextColor3 = Color3.fromRGB(245, 247, 252)
					textBox.Text = tostring(v1)
					textBox.Parent = sliderRow
					local uiCorner1 = Instance.new("UICorner")
					uiCorner1.CornerRadius = UDim.new(0, 5)
					uiCorner1.Parent = textBox
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, -24, 0, 7)
					frame.Position = UDim2.new(0, 12, 0, 28)
					frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
					frame.BorderSizePixel = 0
					frame.Parent = sliderRow
					local uiCorner2 = Instance.new("UICorner")
					uiCorner2.CornerRadius = UDim.new(1, 0)
					uiCorner2.Parent = frame
					local sliderFill = Instance.new("Frame")
					sliderFill.Name = "SliderFill"
					sliderFill.Size = UDim2.new((v1 - arg3) / (arg4 - arg3), 0, 1, 0)
					sliderFill.BackgroundColor3 = color
					sliderFill.BorderSizePixel = 0
					sliderFill.Parent = frame
					local uiCorner3 = Instance.new("UICorner")
					uiCorner3.CornerRadius = UDim.new(1, 0)
					uiCorner3.Parent = sliderFill
					local v3

					local function func(arg1)
						v6.Sliders[text] = arg1
						v6.SliderValues[text] = arg1
						v6.QueueSave()
					end

					local function func1(arg1)
						local X = frame.AbsoluteSize.X

						if X <= 0 then
							return
						end

						local v1 = math.clamp(arg1.Position.X - frame.AbsolutePosition.X, 0, X) / X
						sliderFill.Size = UDim2.new(v1, 0, 1, 0)
						local v2 = math.floor(arg3 + (arg4 - arg3) * v1)
						textBox.Text = tostring(v2)
						v6.Sliders[text] = v2
						v6.SliderValues[text] = v2
						v6.QueueSave()

						if arg7 then
							v3 = v2
						else
							arg6(v2)
						end
					end

					local flag = false
					frame.InputBegan:Connect(function(input)
						if
							input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.Touch
						then
							flag = true
							func1(input)
						end
					end)
					tbl1[3].InputChanged:Connect(function(input)
						if
							flag
								and (input.UserInputType == Enum.UserInputType.MouseMovement
									or input.UserInputType == Enum.UserInputType.Touch)
						then
							func1(input)
						end
					end)
					tbl1[3].InputEnded:Connect(function(input)
						if
							input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.Touch
						then
							if flag and arg7 and v3 ~= nil then
								local v1 = v3
								v3 = nil
								pcall(arg6, v1)
							end
							flag = false
						end
					end)
					textBox.FocusLost:Connect(function()
						local num = tonumber(textBox.Text)
						if num then
							local v1 = math.clamp(num, arg3, arg4)
							textBox.Text = tostring(v1)
							local v2 = arg4 - arg3
							sliderFill.Size = UDim2.new(
								v2 ~= 0 and math.clamp((v1 - arg3) / v2, 0, 1) or 0,
								0,
								1,
								0
							)
							func(v1)
							arg6(v1)
						else
							textBox.Text = tostring(arg5)
							sliderFill.Size = UDim2.new(
								math.clamp((arg5 - arg3) / (arg4 - arg3), 0, 1),
								0,
								1,
								0
							)
							v6.Sliders[text] = arg5
							v6.SliderValues[text] = arg5
							v6.QueueSave()
							arg6(arg5)
						end
					end)
					v6.SliderValues[text] = v1

					local function func2(arg1, arg2)
						local num = tonumber(arg1)

						if not num then
							return
						end

						local v1 = math.clamp(num, arg3, arg4)
						textBox.Text = tostring(v1)
						local v2 = arg4 - arg3
						sliderFill.Size = UDim2.new(
							v2 ~= 0 and math.clamp((v1 - arg3) / v2, 0, 1) or 0,
							0,
							1,
							0
						)
						func(v1)

						if arg2 then
							pcall(arg6, v1)
						end
					end

					v6.SliderControls[text] = func2

					if v2 ~= nil and v2 ~= arg5 then
						v6.Defer(function()
							pcall(arg6, v2)
						end)
					end

					tbl10.makePin(sliderRow, text, UDim2.new(1, -66, 0, 3))
					tbl10.register(
						{
							Kind = "slider",
							Name = text,
							Tab = parent,
							Get = function()
								return v6.SliderValues[text]
							end,
							Set = func2,
						}
					)
				end

				v7 = func2("Combat")
				v8 = func2("Badges")
				v9 = func2("Teleport")
				v10 = func2("Misc")
				v11 = func2("Settings")
				v12 = func2("Themes")
				v13 = func2("Credits")
				v14 = func2("Config")
				local PlaceId = game.PlaceId

				if PlaceId == 13833961666 then
					PlaceId = {}
					local tbl11 = {}

					function PlaceId:MakeWindow(_)
						return tbl11
					end

					function PlaceId:MakeNotification(arg2)
						tbl10.notify(arg2.Name or "Xursed Hub", arg2.Content or "", arg2.Time or 5)
					end

					function PlaceId:Destroy() end

					function tbl11:MakeTab(arg2)
						local v1 = func2("Rob " .. tostring(arg2.Name or "Features"))
						return
							{
								AddParagraph = function(_, arg2, arg3)
									local v2 = func3(v1, arg2, arg3)
									return
										{
											Set = function(_, arg2)
												local ContentLabel = v2:FindFirstChild("ContentLabel")
												if ContentLabel then
													ContentLabel.Text = tostring(arg2)
												end
											end,
										}
								end,
								AddSection = function(_, arg2)
									return (func3(v1, arg2.Name or "Section", ""))
								end,
								AddLabel = function(_, arg2)
									return (func3(v1, tostring(arg2), ""))
								end,
								AddButton = function(_, arg2)
									func4(
										v1,
										arg2.Name or "Action",
										function()
											task.spawn(function()
												local ok, result = pcall(arg2.Callback or function() end)
												if not ok then
													warn("[Xursed Hub] Rob feature failed: " .. tostring(result))
													tbl10.notify(
														"Rob feature",
														"Something went wrong. Check the executor console.",
														6
													)
												end
											end)
										end
									)
								end,
								AddToggle = function(_, arg2)
									local v2 = arg2.Name or "Toggle"
									tbl1[15](
										v1,
										v2,
										function(arg1)
											task.spawn(function()
												local ok, result = pcall(
													arg2.Callback or function() end,
													arg1
												)
												if not ok then
													warn("[Xursed Hub] Rob toggle failed: " .. tostring(result))
												end
											end)
										end,
										arg2.Default == true
									)
									return
										{
											Set = function(_, arg2)
												local v1 = tbl3[v2]
												if v1 then
													v1(arg2 == true, true)
												end
											end,
										}
								end,
								AddDropdown = function(_, arg2)
									func3(
										v1,
										arg2.Name or "Choose an option",
										"Select an option below."
									)
									for _, v2 in ipairs(arg2.Options or {}) do
										func4(
											v1,
											tostring(v2),
											function()
												if arg2.Callback then
													arg2.Callback(v2)
												end
											end
										)
									end
								end,
								AddThemeDropdown = function(_, _)
									func3(v1, "UI Theme", "Pick a colour you like below.")
								end,
							}
					end

					if game.PlaceId == 13833961666 then
						local Window = PlaceId:MakeWindow(
							{
								Name = "Rob Hub OP",
								HidePremium = true,
								IntroEnabled = true,
								IntroText = "Rob",
								IntroIcon = "rbxassetid://15315284749",
								ToggleIcon = "assetid://7734091286"
							}
						)

						if not workspace:FindFirstChild("VoidPart") then
							local voidPart = Instance.new("Part", workspace)
							voidPart.Name = "VoidPart"
							voidPart.Position = Vector3.new(-36, -3, 16)
							voidPart.Size = Vector3.new(2000, 1, 2000)
							voidPart.Anchored = true
							voidPart.Transparency = 1
							voidPart.CanCollide = false
						end

						local Tab = Window:MakeTab(
							{Name = "Combat", Icon = "rbxassetid://7733674079", PremiumOnly = false}
						)
						local playerInfoParagraph = Tab:AddParagraph("Player Info", "Loading...")

						local function func6()
							local tbl = {}
							local v1 = math.floor(workspace:GetRealPhysicsFPS())
							table.insert(tbl, "Your FPS: " .. v1)
							local ok, result = pcall(function()
								return game.Players.LocalPlayer.leaderstats.Slaps.Value
							end)
							table.insert(tbl, "Check Slap: " .. (ok and result or "N/A"))
							local ok1, result1 = pcall(function()
								return game.Players.LocalPlayer.Character.Humanoid.Health
							end)
							table.insert(
								tbl,
								"Check Health: " .. (ok1 and math.floor(result1) or "N/A")
							)
							local ok2, result2 = pcall(function()
								return game.Players.LocalPlayer.leaderstats.Glove.Value
							end)
							table.insert(tbl, "You're Using Glove: " .. (ok2 and result2 or "N/A"))
							table.insert(tbl, "Game's ID: " .. game.PlaceId)
							table.insert(tbl, "Server ID: " .. game.JobId)
							local v2 =
								game.Players.LocalPlayer.PlayerGui:FindFirstChild(
									"BossHealthDisplay"
								)
									~= nil
							table.insert(tbl, "Bob BOSS Is Spawned? " .. (v2 and "Yes ✅" or "No ❌"))
							local v3 = game.Players.LocalPlayer:GetAttribute("InGroup") == true
							table.insert(tbl, "In Group? " .. (v3 and "Yes ✅" or "No ❌"))
							local v4 = game.Players.LocalPlayer:GetAttribute("Saving") == true
							table.insert(tbl, "Progress Saves? " .. (v4 and "Yes ✅" or "No ❌"))
							playerInfoParagraph:Set(table.concat(tbl, "\n"))
						end

						Tab:AddToggle(
							{
								Name = "Auto Set Info",
								Default = false,
								Callback = function(value)
									_G.AutoSetInfo = value
									if value then
										game:GetService(
											"RunService"
										).RenderStepped:Connect(function()
											if _G.AutoSetInfo then
												pcall(func6)
											end
										end)
									end
								end,
							}
						)
						func6()
						Tab:AddSection({Name = "Combat"})
						Tab:AddButton(
							{
								Name = "Auto Use Time Stop Ability (Requires God's Hand Glove + DONT PRESS ON E ABILITY OTHERWISE U GONNA GET KICKED)",
								Callback = function()
									while true do
										game:GetService(
											"ReplicatedStorage"
										).TimestopJump:FireServer()
										game:GetService(
											"ReplicatedStorage"
										).Timestopchoir:FireServer()
										game:GetService("ReplicatedStorage").Timestop:FireServer()
										task.wait(60)
									end
								end,
							}
						)
						Tab:AddToggle(
							{
								Name = "Auto Slap Mr. Bob",
								Default = false,
								Callback = function(value)
									_G.DameBossBob = value
									while _G.DameBossBob do
										game.Workspace.bobBoss.DamageEvent:FireServer()
										task.wait()
									end
								end,
							}
						)
						Tab:AddToggle(
							{
								Name = "Auto Click Tycoon",
								Default = false,
								Callback = function(value)
									_G.AutoTycoon = value
									while _G.AutoTycoon do
										for _, child in pairs(workspace:GetChildren()) do
											if
												string.find(child.Name, "ÅTycoon")
													and child:FindFirstChild("Click")
											then
												fireclickdetector(child.Click.ClickDetector)
											end
										end
										task.wait()
									end
								end,
							}
						)
						local Toggle
						Toggle = Tab:AddToggle(
							{
								Name = "Auto Spawn Rob",
								Default = false,
								Callback = function(value)
									_G.AutoSpawnRob = value
									if
										game.Players.LocalPlayer.leaderstats.Glove.Value == "rob"
									then
										while _G.AutoSpawnRob do
											game:GetService("ReplicatedStorage").rob:FireServer()
											wait(15)
										end
									elseif value == true then
										PlaceId:MakeNotification(
											{
												Name = "Error",
												Content = "Get ethernal bob boss fight phase 6.",
												Image = "rbxassetid://7733658504",
												Time = 5
											}
										)
										wait(0.05)
										Toggle:Set(false)
									end
								end,
							}
						)
						local str = "Killstreak"
						Tab:AddDropdown(
							{
								Name = "Glove Slap Aura Minions",
								Default = "Killstreak",
								Options = {"Killstreak", "Reaper", "God's Hand", "Tycoon"},
								Callback = function(value)
									str = value
								end,
							}
						)
						Tab:AddToggle(
							{
								Name = "Slap Aura Minions",
								Default = false,
								Callback = function(value)
									_G.SlapBobClone = value
									while _G.SlapBobClone do
										if workspace:FindFirstChild("BobClone") then
											for _, child in pairs(workspace:GetChildren()) do
												if child.Name == "BobClone" then
													local HumanoidRootPart = child:FindFirstChild(
														"HumanoidRootPart"
													)
													if HumanoidRootPart then
														local ReplicatedStorage = game:GetService(
															"ReplicatedStorage"
														)
														if str == "Killstreak" then
															ReplicatedStorage.KSHit:FireServer(HumanoidRootPart)
														elseif str == "Reaper" then
															ReplicatedStorage.ReaperHit:FireServer(HumanoidRootPart)
														elseif str == "God's Hand" then
															ReplicatedStorage.Godshand:FireServer(HumanoidRootPart)
														elseif str == "Tycoon" then
															ReplicatedStorage.GeneralHit:FireServer(HumanoidRootPart)
														end
													end
												end
											end
										end
										task.wait(1.2)
									end
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "Slap Aura Bob",
								Callback = function()
									for _, descendant in ipairs(workspace:GetDescendants()) do
										if descendant.Name == "BobClone" then
											local HumanoidRootPart = descendant:FindFirstChild(
												"HumanoidRootPart"
											)
											if HumanoidRootPart then
												local ReplicatedStorage = game:GetService(
													"ReplicatedStorage"
												)
												if str == "Killstreak" then
													ReplicatedStorage.KSHit:FireServer(HumanoidRootPart)
												elseif str == "Reaper" then
													ReplicatedStorage.ReaperHit:FireServer(HumanoidRootPart)
												elseif str == "God's Hand" then
													ReplicatedStorage.Godshand:FireServer(HumanoidRootPart)
												elseif str == "Tycoon" then
													ReplicatedStorage.GeneralHit:FireServer(HumanoidRootPart)
												end
											end
										end
									end
								end,
							}
						)
						Tab:AddLabel("Script")
						Tab:AddButton(
							{
								Name = "Fe fly V3",
								Callback = function()
									loadstring(
										game:HttpGet(
											"https://raw.githubusercontent.com/Giangplay/Script/main/Fly_V3.lua"
										)
									)()
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "Anti Lag",
								Callback = function()
									loadstring(
										game:HttpGet(
											"https://raw.githubusercontent.com/Giangplay/Script/main/Anti-lag.lua"
										)
									)()
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "Inf Yield Delta",
								Callback = function()
									loadstring(
										game:HttpGet(
											"https://gist.githubusercontent.com/lxnnydev/c533c374ca4c1dcef4e1e10e33fa4a0c/raw/03e74f184f801dad77d3ebe1e2f18c6ac87ca612/delta_IY.gistfile1.txt.lua"
										)
									)()
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "Inf Yield",
								Callback = function()
									loadstring(
										game:HttpGet(
											"https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
											true
										)
									)()
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "RemoteSpy",
								Callback = function()
									loadstring(
										game:HttpGet(
											"https://raw.githubusercontent.com/Giangplay/Script/main/RemoteSpy-V2.lua",
											true
										)
									)()
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "TP back to Slap Battles",
								Callback = function()
									game:GetService("TeleportService"):Teleport(6403373529)
								end,
							}
						)
						Tab:AddButton(
							{
								Name = "[ Destroy GUI ] [ Toggle Gui ]",
								Callback = function()
									PlaceId:Destroy()
									if
										game.Players.LocalPlayer.PlayerGui:FindFirstChild(
											"ToggleUi"
										)
									then
										game.Players.LocalPlayer.PlayerGui:FindFirstChild(
											"ToggleUi"
										)
											:Destroy()
									end
								end,
							}
						)
						local Tab1 = Window:MakeTab(
							{Name = "Anti", Icon = "rbxassetid://4370318685", PremiumOnly = false}
						)
						Tab1:AddButton(
							{
								Name = "Anti VFX",
								Callback = function()
									local VFXListener = game.Players.LocalPlayer.PlayerScripts:FindFirstChild(
										"VFXListener"
									)
									if VFXListener then
										VFXListener.Parent = game.ReplicatedStorage
									else
										game.ReplicatedStorage.VFXListener.Parent =
											game.Players.LocalPlayer.PlayerScripts
									end
								end,
							}
						)
						Tab1:AddToggle(
							{
								Name = "Anti Ring",
								Default = false,
								Callback = function(value)
									_G.AntiRing = value
									while _G.AntiRing do
										local Ring = workspace:FindFirstChild("Ring")

										if Ring then
											Ring:Destroy()
										end

										task.wait()
									end
								end,
							}
						)
						Tab1:AddToggle(
							{
								Name = "Auto Remove Big Meteors",
								Default = false,
								Callback = function(value)
									_G.AutoRemoveBigMeteors = value
									while _G.AutoRemoveBigMeteors do
										local VFXListener =
											game.Players.LocalPlayer.PlayerScripts.VFXListener

										if VFXListener:FindFirstChild("BigExplosion") then
											VFXListener.BigExplosion:Destroy()
										end

										task.wait()
									end
								end,
							}
						)
						Tab1:AddToggle(
							{
								Name = "Auto Remove Small Meteors",
								Default = false,
								Callback = function(value)
									_G.AutoRemoveSmallMeteors = value
									while _G.AutoRemoveSmallMeteors do
										local VFXListener =
											game.Players.LocalPlayer.PlayerScripts.VFXListener

										if VFXListener:FindFirstChild("SmallMeteorVFX") then
											VFXListener.SmallMeteorVFX:Destroy()
										end

										task.wait()
									end
								end,
							}
						)
						Tab1:AddToggle(
							{
								Name = "Anti Void Damage",
								Default = false,
								Callback = function(value)
									local VoidPart = workspace:FindFirstChild("VoidPart")
									if VoidPart then
										VoidPart.CanCollide = value
										VoidPart.Transparency = value and 0.5 or 1
									end
								end,
							}
						)
						Tab1:AddButton(
							{
								Name = "Anti VFX",
								Callback = function()
									local VFXListener = game.Players.LocalPlayer.PlayerScripts:FindFirstChild(
										"VFXListener"
									)
									if VFXListener then
										VFXListener.Parent = game.ReplicatedStorage
									else
										game.ReplicatedStorage.VFXListener.Parent =
											game.Players.LocalPlayer.PlayerScripts
									end
								end,
							}
						)
						Tab1:AddButton(
							{
								Name = "Anti Lighting",
								Callback = function()
									game:GetService("Lighting").Atmosphere:destroy()
									game:GetService("Lighting").Bloom:destroy()
									game:GetService("Lighting").SunRays:destroy()
								end,
							}
						)
						Tab1:AddButton(
							{
								Name = "Anti Screenshake",
								Callback = function()
									for _, descendant in pairs(game:GetDescendants()) do
										if
											descendant.Name
												and descendant.Name:lower():find("screenshake")
										then
											pcall(function()
												descendant:Destroy()
											end)
										end
									end
								end,
							}
						)
						Section = Tab1:AddSection({Name = "Themes Stuff"})
						Tab1:AddThemeDropdown({Name = "UI Theme"})
						Section = Tab1:AddSection({Name = "Destroy Script"})
						Tab1:AddButton(
							{
								Name = "Destroy Gui",
								Callback = function()
									PlaceId:Destroy()
								end,
							}
						)
					end
				end

				PlaceId = func2
				PlaceId = PlaceId("Search", tbl10.drawSearchIcon)
				local v15 = func2("Pinned", tbl10.drawPinIcon)
				local searchInput = Instance.new("TextBox")
				searchInput.Name = "SearchInput"
				searchInput.Size = UDim2.new(1, 0, 0, 28)
				searchInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				searchInput.BorderSizePixel = 0
				searchInput.FontFace = tbl10.Font
				searchInput.TextSize = 11
				searchInput.TextColor3 = tbl10.Accent
				searchInput.PlaceholderText =
					"Find the thing you wanna enable using this search bar!"
				searchInput.Text = ""
				searchInput.TextXAlignment = Enum.TextXAlignment.Left
				searchInput.ClearTextOnFocus = false
				searchInput.Parent = PlaceId
				local uiCorner2 = Instance.new("UICorner")
				uiCorner2.CornerRadius = UDim.new(0, 5)
				uiCorner2.Parent = searchInput
				local uiPadding = Instance.new("UIPadding")
				uiPadding.PaddingLeft = UDim.new(0, 8)
				uiPadding.Parent = searchInput
				local searchResults = Instance.new("Frame")
				searchResults.Name = "SearchResults"
				searchResults.Size = UDim2.new(1, 0, 0, 0)
				searchResults.AutomaticSize = Enum.AutomaticSize.Y
				searchResults.BackgroundTransparency = 1
				searchResults.BorderSizePixel = 0
				searchResults.Parent = PlaceId
				local uiListLayout1 = Instance.new("UIListLayout")
				uiListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
				uiListLayout1.Padding = UDim.new(0, 5)
				uiListLayout1.Parent = searchResults

				local function OnShow()
					tbl10.clear(searchResults)
					local v1 = tbl10.search(searchInput.Text)

					if #v1 == 0 then
						tbl10.note(searchResults, "No matching functions.")
						return
					end

					local v2 = math.min(#v1, 30)

					for i = 1, v2 do
						tbl10.buildProxyRow(searchResults, v1[i].entry)
					end
				end

				searchInput:GetPropertyChangedSignal("Text"):Connect(OnShow)
				tbl9.Search.OnShow = OnShow

				function tbl10.refreshPinned()
					tbl10.clear(v15)
					local flag = false

					for _, v1 in ipairs(tbl10.Registry) do
						if v6.Pins[v1.Name] then
							flag = true
							tbl10.buildProxyRow(v15, v1)
						end
					end

					if not flag then
						tbl10.note(
							v15,
							"No pinned controls yet. Click the pin icon on any control to pin it here."
						)
					end
				end

				tbl9.Pinned.OnShow = tbl10.refreshPinned
				PlaceId = false
				local v73
				local vector31 = Vector3.new()
				local uDim22 = UDim2.new()
				container.InputBegan:Connect(function(input)
					if
						not v73
							and (input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.Touch)
					then
						local ok, result = pcall(function()
							return
								tbl1[3]:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
						end)

						if ok then
							for _, v1 in ipairs(result) do
								if
									v1:IsA("TextButton")
										or v1:IsA("TextBox")
										or v1.Name == "SliderRow"
								then
									return
								end
							end
						end

						v73 = input
						PlaceId = true
						vector31 = input.Position
						uDim22 = container.Position
					end
				end)
				tbl1[3].InputChanged:Connect(function(input)
					if
						PlaceId
							and v73
							and v73.UserInputType == Enum.UserInputType.MouseButton1
							and not tbl1[3]:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					then
						PlaceId = false
						v73 = nil
					end
					if PlaceId and v73 then
						local v1 =
							v73.UserInputType == Enum.UserInputType.MouseButton1
								and input.UserInputType == Enum.UserInputType.MouseMovement
						local v2 = v73.UserInputType == Enum.UserInputType.Touch and input == v73

						if v1 or v2 then
							local v3 = input.Position - vector31
							container.Position = UDim2.new(
								uDim22.X.Scale,
								uDim22.X.Offset + v3.X,
								uDim22.Y.Scale,
								uDim22.Y.Offset + v3.Y
							)
						end
					end
				end)
				tbl1[3].InputEnded:Connect(function(input)
					if
						v73
							and (input == v73
								or v73.UserInputType == Enum.UserInputType.MouseButton1
									and input.UserInputType == Enum.UserInputType.MouseButton1)
					then
						PlaceId = false
						v73 = nil
					end
				end)

				function func7()
					local Workspace = game:GetService("Workspace")
					local Safespot = Workspace:FindFirstChild("Safespot")

					if Safespot then
						Safespot:Destroy()
					end

					local ok, result = pcall(function()
						return
							tbl1[9]:JSONDecode(
								' [{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10000,-50,10000,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"Safespot","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":true,"Size":[500,10,500]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10000.2001953125,13,9752.4501953125,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[500,117,5]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10248.2001953125,13,10002.400390625,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart1","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[5,117,496]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[9998.1298828125,13,10247.2001953125,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart2","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[497,117,6]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[9752.7099609375,13,9999.2802734375,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart3","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[7,117,490]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10001.099609375,76,9999.66015625,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart4","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[491,10,491]}] '
							)
					end)

					if ok then
						local safespot = Instance.new("Folder")
						safespot.Name = "Safespot"
						safespot.Parent = Workspace

						for _, v1 in ipairs(result) do
							local instance = Instance.new(v1.ClassName)
							instance.Name = v1.Name
							instance.Size = Vector3.new(unpack(v1.Size))
							instance.CFrame = CFrame.new(unpack(v1.CFrame))
							instance.Transparency = v1.Transparency
							instance.CanCollide = v1.CanCollide
							instance.Anchored = v1.Anchored

							if v1.Color then
								instance.Color = Color3.new(unpack(v1.Color))
							end

							if v1.Material then
								local v2 = v1.Material:gsub("Enum.Material.", "")
								pcall(function()
									instance.Material = Enum.Material[v2]
								end)
							end

							instance.Parent = safespot
						end
					end

					return Workspace:FindFirstChild("Safespot")
				end

				tbl1[15](
					v7,
					"Anti-Void",
					function(arg1)
						if v67 then
							v67:Disconnect()
							v67 = nil
						end

						if v68 then
							v68:Destroy()
							v68 = nil
						end

						if arg1 then
							v68 = Instance.new("Part")
							local v1 = v68
							v1.Name = "AntiVoidPlatform"
							v1.Size = Vector3.new(150, 3, 150)
							v1.Anchored = true
							v1.CanCollide = false
							v1.Transparency = 0.3
							v1.Color = Color3.fromRGB(135, 206, 250)
							v1.Material = Enum.Material.Neon
							v1.Parent = workspace
							v67 = tbl1[4].RenderStepped:Connect(function()
								local Character = tbl1[11].Character
								local v1 =
									Character and Character:FindFirstChild("HumanoidRootPart")

								if v1 and v68 and v68.Parent then
									local raycastParams = RaycastParams.new()
									raycastParams.FilterDescendantsInstances = {Character, v68}
									raycastParams.FilterType = Enum.RaycastFilterType.Exclude

									if
										workspace:Raycast(
											v1.Position,
											Vector3.new(0, -500, 0),
											raycastParams
										)
									then
										local v2 = v68
										v2.CanCollide = false
										v2.Position = Vector3.new(0, -9999, 0)
									else
										local v3 = v68
										v3.CanCollide = true
										v3.Position = Vector3.new(v1.Position.X, -15, v1.Position.Z)
									end
								end
							end)
						end
					end
				)
				local num2 = 16
				local num3 = 50
				func5(
					v7,
					"WalkSpeed",
					16,
					500,
					16,
					function(arg1)
						num2 = arg1
					end
				)
				func5(
					v7,
					"JumpPower",
					50,
					500,
					50,
					function(arg1)
						num3 = arg1
					end
				)
				local flag4 = false
				local flag5 = false
				local WalkSpeed
				local JumpPower
				local UseJumpPower
				connection = tbl1[4].Heartbeat:Connect(function()
					if flag1 then
						return
					end
					pcall(function()
						local Character = tbl1[11].Character
						local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

						if v1 then
							if num2 ~= 16 then
								if not flag4 then
									flag4 = true
									WalkSpeed = v1.WalkSpeed
								end
								v1.WalkSpeed = num2
							elseif flag4 then
								flag4 = false
								v1.WalkSpeed = WalkSpeed or 16
							end
							if num3 ~= 50 then
								if not flag5 then
									flag5 = true
									JumpPower = v1.JumpPower
									UseJumpPower = v1.UseJumpPower
								end

								v1.UseJumpPower = true
								v1.JumpPower = num3
							elseif flag5 then
								flag5 = false
								v1.UseJumpPower = UseJumpPower ~= false
								v1.JumpPower = JumpPower or 50
							end
						end
					end)
				end)
				tbl1[15](
					v7,
					"Shiftlock",
					function(arg1)
						if v69 then
							v69:Disconnect()
							v69 = nil
						end
						if arg1 then
							v69 = tbl1[4].RenderStepped:Connect(function()
								local Character = tbl1[11].Character
								local v1 =
									Character and Character:FindFirstChild("HumanoidRootPart")
								local v2 = Character and Character:FindFirstChildOfClass("Humanoid")

								if Character and v1 and v2 then
									v2.AutoRotate = false
									local CurrentCamera = workspace.CurrentCamera

									if CurrentCamera then
										local LookVector = CurrentCamera.CFrame.LookVector
										local Unit = Vector3.new(LookVector.X, 0, LookVector.Z).Unit

										if Unit.Magnitude > 0 then
											v1.CFrame = CFrame.new(v1.Position, v1.Position + Unit)
										end
									end
								end
							end)
						else
							local Character = tbl1[11].Character
							local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

							if v1 then
								v1.AutoRotate = true
							end
						end
					end
				)
				tbl1[15](
					v7,
					"Anti Ragdoll",
					function(arg1)
						if v70 then
							v70:Disconnect()
							v70 = nil
						end

						if v71 then
							v71:Disconnect()
							v71 = nil
						end

						if arg1 then
							local function func(character)
								local Humanoid = character:WaitForChild("Humanoid", 5)

								if not Humanoid then
									return
								end

								pcall(function()
									Humanoid:SetStateEnabled(
										Enum.HumanoidStateType.FallingDown,
										false
									)
									Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
									Humanoid:SetStateEnabled(
										Enum.HumanoidStateType.PlatformStanding,
										false
									)
								end)

								local tbl = {
									"BodyVelocity",
									"LinearVelocity",
									"AngularVelocity",
									"BodyForce",
									"BodyThrust",
									"BodyGyro",
									"RocketPropulsion",
									"VectorForce"
								}

								v70 = tbl1[4].Stepped:Connect(function()
									if
										not character
											or not character.Parent
											or Humanoid.Health <= 0
									then
										if v70 then
											v70:Disconnect()
										end
										return
									end
									for _, descendant in ipairs(character:GetDescendants()) do
										if descendant:IsA("Motor6D") then
											descendant.Enabled = true
										else
											for _, v1 in ipairs(tbl) do
												if descendant:IsA(v1) then
													descendant:Destroy()
													break
												end
											end
										end
									end
								end)
							end

							if tbl1[11].Character then
								task.spawn(function()
									func(tbl1[11].Character)
								end)
							end

							v71 = tbl1[11].CharacterAdded:Connect(function(character)
								task.spawn(function()
									func(character)
								end)
							end)
						else
							pcall(function()
								local Character = tbl1[11].Character
								local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

								if v1 then
									v1:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
									v1:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
									v1:SetStateEnabled(
										Enum.HumanoidStateType.PlatformStanding,
										true
									)
								end
							end)
						end
					end
				)
				tbl1[15](
					v7,
					"ESP",
					function(arg1)
						if v72 then
							v72:Disconnect()
							v72 = nil
						end

						local function func()
							for _, player in ipairs(tbl1[5]:GetPlayers()) do
								if player.Character then
									local RainbowHighlight = player.Character:FindFirstChild(
										"RainbowHighlight"
									)
									if RainbowHighlight then
										RainbowHighlight:Destroy()
									end
								end
							end
						end

						if arg1 then
							local function func1(parent)
								if not parent then
									return
								end
								if not parent:FindFirstChild("RainbowHighlight") then
									local rainbowHighlight = Instance.new("Highlight")
									rainbowHighlight.Name = "RainbowHighlight"
									rainbowHighlight.FillTransparency = 0.5
									rainbowHighlight.OutlineTransparency = 0
									rainbowHighlight.Parent = parent
								end
							end
							v72 = tbl1[4].RenderStepped:Connect(function()
								local color = Color3.fromHSV(tick() * 1 % 1, 1, 1)
								for _, player in ipairs(tbl1[5]:GetPlayers()) do
									if player ~= tbl1[11] and player.Character then
										local RainbowHighlight = player.Character:FindFirstChild(
											"RainbowHighlight"
										)
										if
											RainbowHighlight and RainbowHighlight:IsA("Highlight")
										then
											RainbowHighlight.FillColor = color
											RainbowHighlight.OutlineColor = color
										else
											func1(player.Character)
										end
									end
								end
							end)
						else
							func()
						end
					end
				)

				tbl12 = {
					AcHit = true,
					BlockedHit = true,
					BombHit = true,
					BrazilHit = true,
					BrickHit = true,
					BubbleHit = true,
					BullHit = true,
					CULTHit = true,
					CelestialHit = true,
					CloudHit = true,
					ConvHit = true,
					CoolerDefaultHit = true,
					CustomHit = true,
					DefenseHit = true,
					DetonatorHit = true,
					DiamondHit = true,
					DiceHit = true,
					DominanceHit = true,
					DualHit = true,
					DuelistHit = true,
					Errorhit = true,
					FlashHit = true,
					FlexHit = true,
					FloweryHit = true,
					Framework_OnHit = true,
					GeneralHit = true,
					GhostHit = true,
					GoldenHit = true,
					HallowHIT = true,
					HitSwapper = true,
					HitmanAbility = true,
					HitmanHit = true,
					IceHit = true,
					ImpostorHit = true,
					JetHit = true,
					KSHit = true,
					LeafblowerHit = true,
					LinkHit = true,
					MagnetHIT = true,
					MailHit = true,
					MisterHit = true,
					MisterWasHit = true,
					MittenHit = true,
					MoyaiMasteryStatueHit = true,
					NimbusHit = true,
					NullHit = true,
					Orbihit = true,
					Overkillhit = true,
					PebbleHit = true,
					PhantomHit = true,
					PlagueHit = true,
					PullHit = true,
					PusherHit = true,
					PylonHit = true,
					ReHit = true,
					ReaperHit = true,
					ReplicaHit = true,
					RetributionHit = true,
					RetroHit = true,
					ReverseHit = true,
					RockyHit = true,
					RojoHit = true,
					ShardHIT = true,
					ShukuchiHit = true,
					SlappleHit = true,
					SnowHit = true,
					Speedrunhit = true,
					SpyHit = true,
					ThorHit = true,
					TinkererHit = true,
					UTGHit = true,
					WalrusHit = true,
					WormHit = true,
					ZZZZZZZHit = true,
					bobhit = true,
					buddiesHIT = true,
					engiehit = true,
					hitAdios = true,
					hitAnchor = true,
					hitbus = true,
					nightmarehit = true,
					potatohit = true,
					rhythmhit = true,
					robhit = true,
					spinhit = true,
					springhit = true,
					woahHit = true
				}
			end

			local tbl13, v74, v75, v76, v77, v78, v18, tbl14

			do
				local num4 = 25
				local num5 = 0
				tbl13 = {}

				local function func8()
					local v1 = tbl1[11] and tbl1[11].Character
					local v2 = v1 and v1:FindFirstChild("HumanoidRootPart")

					if not v2 then
						return {}
					end

					local tbl = {}

					for _, player in ipairs(tbl1[5]:GetPlayers()) do
						if player ~= tbl1[11] then
							local v3 = player and player.Character
							local v4 = v3 and v3:FindFirstChild("HumanoidRootPart")

							if v4 then
								local Magnitude = (v4.Position - v2.Position).Magnitude
								tbl[#tbl + 1] = {player = player, root = v4, dist = Magnitude}
							end
						end
					end

					table.sort(
						tbl,
						function(a, b)
							return a.dist < b.dist
						end
					)
					return tbl
				end

				local function func9(player)
					if tbl13[player] and tbl13[player].Parent then
						return tbl13[player]
					end

					local v1 =
						player.Character and player.Character:FindFirstChild("HumanoidRootPart")

					if not v1 then
						return nil
					end

					local selectionBox = Instance.new("SelectionBox")
					selectionBox.Adornee = v1
					selectionBox.Color3 = Color3.fromRGB(255, 255, 255)
					selectionBox.LineThickness = 0.04
					selectionBox.SurfaceTransparency = 1
					selectionBox.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
					selectionBox.Parent = workspace
					tbl13[player] = selectionBox
					return selectionBox
				end

				local function func10(arg1)
					if not arg1 then
						return
					end

					local v1 = tick()

					if v1 - num5 < 0.15 then
						return
					end

					num5 = v1
					local Character = tbl1[11].Character

					if not Character then
						return
					end

					local Tool = Character:FindFirstChildOfClass("Tool")

					if not Tool then
						return
					end

					local v2 =
						Tool:FindFirstChild("SlapRemote")
							or Tool:FindFirstChild("HitRemote")
							or Tool:FindFirstChild("DamageRemote")

					if v2 and v2:IsA("RemoteEvent") then
						v2:FireServer(arg1.Parent)
					else
						pcall(function()
							Tool:Activate()
						end)
					end
				end

				func5(
					v7,
					"Hitbox Size",
					2,
					100,
					25,
					function(arg1)
						num4 = arg1
					end
				)
				local v16 = setmetatable({}, {__mode = "k"})
				tbl1[15](
					v7,
					"Triggerbot + Hitbox",
					function(arg1)
						if v74 then
							v74:Disconnect()
							v74 = nil
						end

						if v75 then
							v75:Disconnect()
							v75 = nil
						end

						if arg1 then
							v74 = tbl1[4].RenderStepped:Connect(function()
								for _, player in ipairs(tbl1[5]:GetPlayers()) do
									if player ~= tbl1[11] then
										pcall(function()
											local HumanoidRootPart = player.Character.HumanoidRootPart

											if not v16[HumanoidRootPart] then
												v16[HumanoidRootPart] = {
													Size = HumanoidRootPart.Size,
													CanCollide = HumanoidRootPart.CanCollide,
													Transparency = HumanoidRootPart.Transparency
												}
											end

											HumanoidRootPart.Size = Vector3.new(num4, num4, num4)
											HumanoidRootPart.Transparency = 1
											HumanoidRootPart.CanCollide = false
											local v1 = func9(player)

											if v1 then
												v1.Adornee = HumanoidRootPart
											end
										end)
									end
								end
							end)
							v75 = tbl1[4].Heartbeat:Connect(function()
								local v1 = tbl1[11] and tbl1[11].Character
								local v2 = v1 and v1:FindFirstChild("HumanoidRootPart")

								if not v2 then
									return
								end

								for _, v3 in ipairs((func8())) do
									local v4 = v3.root.Position.X - v2.Position.X
									local v5 = v3.root.Position.Z - v2.Position.Z

									if math.sqrt(v4 * v4 + v5 * v5) <= num4 then
										func10(v3.root)
										break
									end
								end
							end)
						else
							for k in pairs(tbl13) do
								if tbl13[k] then
									pcall(function()
										tbl13[k]:Destroy()
									end)
									tbl13[k] = nil
								end
							end

							for k1, v1 in pairs(v16) do
								pcall(function()
									if k1 and k1.Parent then
										k1.Size = v1.Size
										k1.CanCollide = v1.CanCollide
										k1.Transparency = v1.Transparency
									end
								end)
							end

							table.clear(v16)
						end
					end
				)
				local flag6 = false
				local num6 = 0

				local function func11()
					if v76 then
						v76:Destroy()
						v76 = nil
					end

					local Character = tbl1[11].Character
					local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

					if not v1 then
						return
					end

					v76 = Instance.new("Part")
					local v2 = v76
					v2.Name = "AuraSphere"
					v2.Shape = Enum.PartType.Ball
					v2.Size = Vector3.new(40, 40, 40)
					v2.CFrame = v1.CFrame
					v2.Transparency = 0.5
					v2.Material = Enum.Material.ForceField
					v2.Anchored = true
					v2.CanCollide = false
					v2.Parent = workspace
				end

				tbl1[15](
					v7,
					"Slap Aura",
					function(arg1)
						flag6 = arg1

						if v77 then
							v77:Disconnect()
							v77 = nil
						end

						if v78 then
							v78:Disconnect()
							v78 = nil
						end

						if flag6 then
							func11()
							v77 = tbl1[4].RenderStepped:Connect(function()
								local Character = tbl1[11].Character
								local v1 =
									Character and Character:FindFirstChild("HumanoidRootPart")

								if v1 then
									if not v76 or not v76.Parent then
										func11()
									else
										local v2 = v76
										v2.CFrame = v1.CFrame
										v2.Color = Color3.fromHSV(tick() * 1 % 1, 1, 1)
									end
								end
							end)
							v78 = tbl1[4].Heartbeat:Connect(function()
								if tick() - num6 < 0.35 then
									return
								end
								pcall(function()
									local Character = tbl1[11].Character
									local v1 =
										Character and Character:FindFirstChild("HumanoidRootPart")
									local v2 =
										Character and Character:FindFirstChildOfClass("Humanoid")

									if v1 and v2 and v2.Health > 0 then
										local v3 =
											Character and Character:FindFirstChildOfClass("Tool")
												or tbl1[11].Backpack:FindFirstChildOfClass("Tool")
										local v4 = v3 and v3.Name or ""
										local str = "GeneralHit"

										if v4 == "Default" then
											str = "b"
										else
											for k in pairs(tbl12) do
												if
													k:lower() == (v4 .. "hit"):lower()
														or k:lower() == v4:lower()
												then
													str = k
													break
												end
											end
										end

										local v5 =
											tbl1[6]:FindFirstChild(str)
												or tbl1[6]:FindFirstChild("GeneralHit")

										for _, player in ipairs(tbl1[5]:GetPlayers()) do
											if player ~= tbl1[11] and player.Character then
												local Character1 = player.Character
												local Humanoid = Character1:FindFirstChildOfClass(
													"Humanoid"
												)
												local HumanoidRootPart = Character1:FindFirstChild(
													"HumanoidRootPart"
												)
												local Head = Character1:FindFirstChild("Head")

												if
													HumanoidRootPart and Humanoid and Humanoid.Health > 0
												then
													if
														(HumanoidRootPart.Position - v1.Position).Magnitude <= 20
													then
														local v6 = Head or HumanoidRootPart

														if v4 == "Default" then
															v6 =
																Character1:FindFirstChild("Right Arm")
																	or Head
																	or HumanoidRootPart
														end

														if v5 then
															v5:FireServer(v6)
															num6 = tick()
															break
														end
													end
												end
											end
										end
									end
								end)
							end)
						elseif v76 then
							v76:Destroy()
							v76 = nil
						end
					end
				)
				func3(
					v8,
					"Notice",
					"If you are using the delta executor, please make sure to turn off the 'Verify Teleports' toggle in ur delta settings. Otherwise these (some) badges will NOT work."
				)

				local function func12(arg1, arg2)
					local v1, v2 = loadstring(arg2)

					if not v1 then
						local str = tostring(v2)
						warn("[Xursed Hub] Could not load " .. arg1 .. ": " .. str)
						tbl.Log(
							"Could not load the '" .. arg1 .. "' badge script",
							"loadstring failed to compile it: " .. tostring(v2),
							nil,
							"Re-run Xursed Hub. If it keeps happening, report it to the developers with this log."
						)
						return
					end

					task.spawn(function()
						local ok, result = pcall(v1)
						if not ok then
							warn("[Xursed Hub] " .. arg1 .. " failed: " .. tostring(result))
							tbl.Log(
								"The '" .. arg1 .. "' badge script failed",
								"It threw an error while running: " .. tostring(result),
								"Current Place ID: " .. tostring(game.PlaceId),
								"Make sure you are in the right game for this badge. On Delta, turn off 'Verify Teleports' in the Delta settings."
							)
						end
					end)
				end

				func4(
					v8,
					"Get Riftshot",
					function()
						func12(
							"Riftshot",
							[=[
if game.PlaceId ~= 7234087065 then
    local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if queueFunction then
        pcall(function()
            queueFunction([[
                if game.PlaceId ~= 7234087065 then
                    game:GetService("TeleportService"):Teleport(7234087065, game:GetService("Players").LocalPlayer)
                end

                task.spawn(function()
                    local lp = game:GetService("Players").LocalPlayer
                    local char = lp.Character or lp.CharacterAdded:Wait()
                    local hrp = char:WaitForChild("HumanoidRootPart")
                    
                    hrp.CFrame = CFrame.new(-260, 16, 477)
                    task.wait(1)
                    
                    pcall(function()
                        game:GetService("ReplicatedStorage").RemoteEvents.TargetPractice.OnComplete:FireServer()
                    end)
                end)
            ]])
        end)
    end
    game:GetService("TeleportService"):Teleport(7234087065, game:GetService("Players").LocalPlayer)
    return
end

task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    hrp.CFrame = CFrame.new(-260, 16, 477)
    task.wait(1)
    
    pcall(function()
        game:GetService("ReplicatedStorage").RemoteEvents.TargetPractice.OnComplete:FireServer()
    end)
end)

]=]
						)
					end
				)
				func4(
					v8,
					"Get Guide Gloves",
					function()
						if game.PlaceId ~= 18550498098 then
							tbl10.notify(
								"Guide Gloves",
								"Click this button once in the Guide Bossfight",
								7
							)
							return
						end

						local v1 = func2("Guide Bossfight")

						function _G.XursedHubAddGuideButton(arg1)
							func4(
								v1,
								arg1.Title or "Guide action",
								function()
									task.spawn(function()
										local ok, result = pcall(arg1.Callback or function() end)
										if not ok then
											warn(
												"[Xursed Hub] Guide action failed: " .. tostring(result)
											)
											tbl10.notify(
												"Guide Gloves",
												"The action failed. Check the executor console.",
												6
											)
										end
									end)
								end
							)
						end

						func12(
							"Guide Gloves",
							[[
if game.PlaceId ~= 18550498098 then return end
local Tab = {}

_G.XursedHubAddGuideButton({
    Title = "Avatar + Relude",
    Desc = "Run Avatar + Relude script",
    Callback = function()
        task.spawn(function()
            local plrs = game:GetService("Players")
            local storage = game:GetService("ReplicatedStorage")
            local lp = plrs.LocalPlayer

            local function getChar()
                local char = lp.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        return char, hrp
                    end
                end
            end

            local function freeze(hrp, enable)
                if not hrp then return end
                local bv = hrp:FindFirstChild("ServerHoldVelocity")
                if enable then
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "ServerHoldVelocity"
                        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                        bv.Velocity = Vector3.zero
                        bv.Parent = hrp
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                elseif bv then
                    bv:Destroy()
                end
            end

            task.spawn(function()
                local cf = CFrame.new(3249.47, -58.50, 821.98, 0.017, 0, -1, 0, 1, 0, 1, 0, 0.017)
                local t = tick()
                while tick() - t < 26 do
                    local _, hrp = getChar()
                    if hrp then
                        hrp.CFrame = cf
                    end
                    task.wait()
                end
            end)

            task.wait(5)

            for _, v in workspace:GetDescendants() do
                if v.Name == "ShackLever" then
                    local cd = v:FindFirstChildWhichIsA("ClickDetector")
                    if cd then
                        pcall(function()
                            for _ = 1, 10 do
                                fireclickdetector(cd)
                                task.wait(0.1)
                            end
                        end)
                    end
                end
            end

            repeat
                task.wait(0.5)
            until workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Components") and workspace.Map.Components:FindFirstChild("GuideNPC")

            local cf2 = CFrame.new(589.10, 189.86, -246.86, -1, 0, 0.012, 0, 1, -0.004, -0.012, -0.004, -1)
            task.spawn(function()
                while true do
                    local char, hrp = getChar()
                    if char and hrp then
                        char:PivotTo(cf2)
                        freeze(hrp, true)
                    end
                    task.wait()
                end
            end)

            while task.wait(0.1) do
                local char, hrp = getChar()
                if char then
                    local item = lp.Backpack:FindFirstChild("Lantern")
                    if item then
                        item.Parent = char
                    end

                    pcall(function()
                        local remotes = storage:FindFirstChild("Remotes")
                        if remotes and remotes:FindFirstChild("Data") and remotes.Data:FindFirstChild("AnswerInCutscene") then
                            remotes.Data.AnswerInCutscene:FireServer("Spare")
                        end
                    end)

                    local lantern = char:FindFirstChild("Lantern")
                    if lantern then
                        lantern:Activate()
                        local net = lantern:FindFirstChild("Network")
                        if net then
                            for _, v in workspace:GetChildren() do
                                if v.Name == "PusherWall" and v:IsA("BasePart") then
                                    v.CanCollide = false
                                elseif v.Name == "golem" and v:FindFirstChild("Hitbox") then
                                    net:FireServer("Hit", v.Hitbox)
                                elseif (v.Name == "GuideNPC" or v.Name == "ReplicaNPC") and v:FindFirstChild("HumanoidRootPart") then
                                    net:FireServer("Hit", v.HumanoidRootPart)
                                elseif v.Name == "TrackGloveMissile" then
                                    net:FireServer("Hit", v)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

_G.XursedHubAddGuideButton({
    Title = "Avatar + Hunters",
    Desc = "Run Avatar + Hunters script",
    Callback = function()
        task.spawn(function()
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer

            local function getChar()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                    if char.Humanoid.Health > 0 then
                        return char, char.HumanoidRootPart
                    end
                end
                return nil, nil
            end

            local function setPhysicsFreeze(hrp, state)
                if not hrp then return end
                local bv = hrp:FindFirstChild("ServerHoldVelocity")
                if state then
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "ServerHoldVelocity"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.Parent = hrp
                    end
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                else
                    if bv then
                        bv:Destroy()
                    end
                end
            end

            task.spawn(function()
                local targetCFrame = CFrame.new(3249.47, -58.50, 821.98, 0.017, -0.000, -1.000, -0.000, 1.000, -0.000, 1.000, 0.000, 0.017)
                local start = tick()
                while tick() - start < 26 do
                    local char, hrp = getChar()
                    if char and hrp then
                        hrp.CFrame = targetCFrame
                    end
                    task.wait()
                end
            end)

            task.wait(5)

            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name == "ShackLever" then
                    local detector = v:FindFirstChildWhichIsA("ClickDetector")
                    if detector then
                        pcall(function()
                            for i = 1, 10 do
                                fireclickdetector(detector)
                                task.wait(0.1)
                            end
                        end)
                    end
                end
            end

            repeat
                task.wait(0.5)
            until workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Components") and workspace.Map.Components:FindFirstChild("GuideNPC")

            local targetCFrame2 = CFrame.new(589.10, 189.86, -246.86, -1.000, 0.000, 0.012, 0.000, 1.000, -0.004, -0.012, -0.004, -1.000)
            task.spawn(function()
                repeat
                    local char, hrp = getChar()
                    if char and hrp then
                        char:PivotTo(targetCFrame2)
                        setPhysicsFreeze(hrp, true)
                    end
                    task.wait()
                until false
            end)

            while task.wait(0.1) do
                local char, hrp = getChar()
                if char then
                    local backpackLantern = LocalPlayer.Backpack:FindFirstChild("Lantern")
                    if backpackLantern then
                        backpackLantern.Parent = char
                    end

                    local lantern = char:FindFirstChild("Lantern")
                    if lantern then
                        lantern:Activate()
                        local network = lantern:FindFirstChild("Network")
                        if network then
                            for _, v in ipairs(workspace:GetChildren()) do
                                if v.Name == "PusherWall" and v:IsA("BasePart") then
                                    v.CanCollide = false
                                end
                                if v.Name == "golem" and v:FindFirstChild("Hitbox") then
                                    network:FireServer("Hit", v.Hitbox)
                                end
                                if (v.Name == "GuideNPC" or v.Name == "ReplicaNPC") and v:FindFirstChild("HumanoidRootPart") then
                                    network:FireServer("Hit", v.HumanoidRootPart)
                                end
                                if v.Name == "TrackGloveMissile" then
                                    network:FireServer("Hit", v)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

_G.XursedHubAddGuideButton({
    Title = "Hunters",
    Desc = "Run Hunters script",
    Callback = function()
        task.spawn(function()
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer

            local function getChar()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                    if char.Humanoid.Health > 0 then
                        return char, char.HumanoidRootPart
                    end
                end
            end

            local function setPhysicsFreeze(hrp, state)
                if not hrp then return end
                local bv = hrp:FindFirstChild("ServerHoldVelocity")
                if state then
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "ServerHoldVelocity"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.Parent = hrp
                    end
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                elseif bv then
                    bv:Destroy()
                end
            end

            local initStart = tick()
            while tick() - initStart < 0.5 do
                local char, hrp = getChar()
                if char and hrp then
                    hrp.CFrame = CFrame.new(3270.68, -227.50, 822.93, 0.580, 0.000, -0.814, -0.000, 1.000, 0.000, 0.814, 0.000, 0.580)
                end
                task.wait()
            end

            task.spawn(function()
                local targetCFrame = CFrame.new(3249.47, -58.50, 821.98, 0.017, -0.000, -1.000, -0.000, 1.000, -0.000, 1.000, 0.000, 0.017)
                local start = tick()
                while tick() - start < 26 do
                    local char, hrp = getChar()
                    if char and hrp then
                        hrp.CFrame = targetCFrame
                    end
                    task.wait()
                end
            end)

            task.wait(5)

            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name == "ShackLever" then
                    local detector = v:FindFirstChildWhichIsA("ClickDetector")
                    if detector then
                        pcall(function()
                            for i = 1, 10 do
                                fireclickdetector(detector)
                                task.wait(0.1)
                            end
                        end)
                    end
                end
            end

            repeat
                task.wait(0.5)
            until workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Components") and workspace.Map.Components:FindFirstChild("GuideNPC")

            local targetCFrame2 = CFrame.new(589.10, 189.86, -246.86, -1.000, 0.000, 0.012, 0.000, 1.000, -0.004, -0.012, -0.004, -1.000)
            task.spawn(function()
                while true do
                    local char, hrp = getChar()
                    if char and hrp then
                        char:PivotTo(targetCFrame2)
                        setPhysicsFreeze(hrp, true)
                    end
                    task.wait()
                end
            end)

            while task.wait(0.1) do
                local char, hrp = getChar()
                if char then
                    local backpackLantern = LocalPlayer.Backpack:FindFirstChild("Lantern")
                    if backpackLantern then
                        backpackLantern.Parent = char
                    end

                    local lantern = char:FindFirstChild("Lantern")
                    if lantern then
                        lantern:Activate()
                        local network = lantern:FindFirstChild("Network")
                        if network then
                            for _, v in ipairs(workspace:GetChildren()) do
                                if v.Name == "PusherWall" and v:IsA("BasePart") then
                                    v.CanCollide = false
                                end
                                if v.Name == "golem" and v:FindFirstChild("Hitbox") then
                                    network:FireServer("Hit", v.Hitbox)
                                end
                                if (v.Name == "GuideNPC" or v.Name == "ReplicaNPC") and v:FindFirstChild("HumanoidRootPart") then
                                    network:FireServer("Hit", v.HumanoidRootPart)
                                end
                                if v.Name == "TrackGloveMissile" then
                                    network:FireServer("Hit", v)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

_G.XursedHubAddGuideButton({
    Title = "Relude",
    Desc = "Run Relude script",
    Callback = function()
        task.spawn(function()
            local plrs = game:GetService("Players")
            local storage = game:GetService("ReplicatedStorage")
            local lp = plrs.LocalPlayer

            local function getChar()
                local char = lp.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        return char, hrp
                    end
                end
            end

            local function freeze(hrp, enable)
                if not hrp then return end
                local bv = hrp:FindFirstChild("ServerHoldVelocity")
                if enable then
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "ServerHoldVelocity"
                        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                        bv.Velocity = Vector3.zero
                        bv.Parent = hrp
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                elseif bv then
                    bv:Destroy()
                end
            end

            local startCF = CFrame.new(3270.68, -227.50, 822.93, 0.580, 0.000, -0.814, -0.000, 1.000, 0.000, 0.814, 0.000, 0.580)
            local t0 = tick()
            while tick() - t0 < 1.2 do
                local char, hrp = getChar()
                if char and hrp then
                    char:PivotTo(startCF)
                end
                task.wait()
            end

            task.spawn(function()
                local cf = CFrame.new(3249.47, -58.50, 821.98, 0.017, 0, -1, 0, 1, 0, 1, 0, 0.017)
                local t = tick()
                while tick() - t < 26 do
                    local _, hrp = getChar()
                    if hrp then
                        hrp.CFrame = cf
                    end
                    task.wait()
                end
            end)

            task.wait(5)

            for _, v in workspace:GetDescendants() do
                if v.Name == "ShackLever" then
                    local cd = v:FindFirstChildWhichIsA("ClickDetector")
                    if cd then
                        pcall(function()
                            for _ = 1, 10 do
                                fireclickdetector(cd)
                                task.wait(0.1)
                            end
                        end)
                    end
                end
            end

            repeat
                task.wait(0.5)
            until workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Components") and workspace.Map.Components:FindFirstChild("GuideNPC")

            local cf2 = CFrame.new(589.10, 189.86, -246.86, -1, 0, 0.012, 0, 1, -0.004, -0.012, -0.004, -1)
            task.spawn(function()
                while true do
                    local char, hrp = getChar()
                    if char and hrp then
                        char:PivotTo(cf2)
                        freeze(hrp, true)
                    end
                    task.wait()
                end
            end)

            while task.wait(0.1) do
                local char, hrp = getChar()
                if char then
                    local item = lp.Backpack:FindFirstChild("Lantern")
                    if item then
                        item.Parent = char
                    end

                    pcall(function()
                        local remotes = storage:FindFirstChild("Remotes")
                        if remotes and remotes:FindFirstChild("Data") and remotes.Data:FindFirstChild("AnswerInCutscene") then
                            remotes.Data.AnswerInCutscene:FireServer("Spare")
                        end
                    end)

                    local lantern = char:FindFirstChild("Lantern")
                    if lantern then
                        lantern:Activate()
                        local net = lantern:FindFirstChild("Network")
                        if net then
                            for _, v in workspace:GetChildren() do
                                if v.Name == "PusherWall" and v:IsA("BasePart") then
                                    v.CanCollide = false
                                elseif v.Name == "golem" and v:FindFirstChild("Hitbox") then
                                    net:FireServer("Hit", v.Hitbox)
                                elseif (v.Name == "GuideNPC" or v.Name == "ReplicaNPC") and v:FindFirstChild("HumanoidRootPart") then
                                    net:FireServer("Hit", v.HumanoidRootPart)
                                elseif v.Name == "TrackGloveMissile" then
                                    net:FireServer("Hit", v)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

]]
						)
					end
				)
				func4(
					v8,
					"Get Sand",
					function()
						func12(
							"Sand",
							[=[
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local queue = queueonteleport or queue_on_teleport
local targetPlace = 122902713960550

local function executeRoutine()
	repeat task.wait() until Workspace:FindFirstChild("Island") and Workspace.Island:FindFirstChild("John Surfboard")
	
	LocalPlayer.Character:PivotTo(Workspace.Island["John Surfboard"].Head:GetPivot())
	task.wait(0.3)
	
	fireproximityprompt(Workspace.Island["John Surfboard"].Head:FindFirstChildWhichIsA("ProximityPrompt"))
	task.wait(0.1)
	
	for _ = 1, 20 do
		ReplicatedStorage.Modules.Common.Dialogue.Remotes.ResondToDialogue:FireServer(0)
		task.wait()
	end
	
	task.wait(1)
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	
	task.spawn(function()
		while true do
			for _, v in ipairs(Workspace.ObjectSpawner_Objects:GetChildren()) do
				v:Destroy()
			end
			task.wait()
		end
	end)
end

if game.PlaceId ~= targetPlace then
	TeleportService:Teleport(targetPlace)
	if queue then
		queue([[
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end
			
			if game.PlaceId ~= 122902713960550 then return end
			
			local Players = game:GetService("Players")
			local Workspace = game:GetService("Workspace")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local LocalPlayer = Players.LocalPlayer
			local Camera = Workspace.CurrentCamera
			
			repeat task.wait() until Workspace:FindFirstChild("Island") and Workspace.Island:FindFirstChild("John Surfboard")
			
			LocalPlayer.Character:PivotTo(Workspace.Island["John Surfboard"].Head:GetPivot())
			task.wait(0.3)
			
			fireproximityprompt(Workspace.Island["John Surfboard"].Head:FindFirstChildWhichIsA("ProximityPrompt"))
			task.wait(0.1)
			
			for _ = 1, 20 do
				ReplicatedStorage.Modules.Common.Dialogue.Remotes.ResondToDialogue:FireServer(0)
				task.wait()
			end
			
			task.wait(1)
			Camera.CameraType = Enum.CameraType.Custom
			Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			
			task.spawn(function()
				while true do
					for _, v in ipairs(Workspace.ObjectSpawner_Objects:GetChildren()) do
						v:Destroy()
					end
					task.wait()
				end
			end)
		]])
	end
	return
end

executeRoutine()

]=]
						)
					end
				)
				func4(
					v8,
					"Get Conker Glove",
					function()
						func12(
							"Get Conker Glove",
							[=[
local queueonteleport = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport)
local gay = game
gay:service'TeleportService':Teleport(101113181694564, game['Players']['LocalPlayer'])
queueonteleport([[
local gay = game
local self = gay['Players']['LocalPlayer']
local humanoidr = self['Character']['HumanoidRootPart']
local CF = CFrame.new
gay:service'ReplicatedStorage'.Remotes.Dialogue.FinishedNPCDialogue:FireServer()
task.wait(2.5)
fireclickdetector(workspace.Map.Props.BasketCollection.Basket.ClickDetector)
local bv = Instance.new'BodyVelocity'
bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
bv.Velocity = (Vector3.new(37, 4, 1) - humanoidr.Position).Unit * 40
bv.Parent = humanoidr
repeat
task.wait()
until (humanoidr.Position - Vector3.new(37, 4, 1)).Magnitude < 2
bv:Destroy()
gay:service'RunService'.PostSimulation:Connect(function()
self['Character']:PivotTo(CF(37, 4, 1)) 
gay:service'ReplicatedStorage'.Remotes.tool.use:FireServer(
'slap') end)
gay:service'Workspace'.NPCs.DescendantAdded:Connect(function(squir)
if squir.Name == 'squirrel'
then local squirhr = squir:WaitForChild'HumanoidRootPart'
while task.wait() and squirhr.Parent do
gay:service'ReplicatedStorage'.Remotes.tool.hit:FireServer('slap', { Instance = squirhr })
end end end)
gay:service'Workspace'.DescendantAdded:Connect(function(conk)
if conk.Name == 'Conker'
then local trans = conk:FindFirstChildOfClass'TouchTransmitter'
if trans
then firetouchinterest(conk, humanoidr, 0)
firetouchinterest(conk, humanoidr, 1)
task.delay(.1, function()
fireproximityprompt(workspace.Map.CoreAssets.Bowl.ProximityPrompt)
end) end end end)]])
]=]
						)
					end
				)
				func4(
					v8,
					"Get Rob",
					function()
						tbl10.notify("Get Rob", "Execute the hub once in the Rob place.", 7)
					end
				)
				func4(
					v8,
					"Inst Bob Glove",
					function()
						loadstring(
							game:HttpGet(
								"https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/SB/P/Autobob.luau"
							)
						)()
					end
				)
				func4(
					v8,
					"ELUDE",
					function()
						if game.PlaceId ~= 11828384869 then
							tbl1[10]:Teleport(11828384869, tbl1[11])
						else
							task.spawn(function()
								local Collectable = workspace:FindFirstChild("Collectable")
								if Collectable then
									for _, child in ipairs(Collectable:GetChildren()) do
										local CFrame1

										if child:IsA("BasePart") then
											CFrame1 = child.CFrame
										else
											local BasePart = child:FindFirstChildWhichIsA(
												"BasePart",
												true
											)
											if BasePart then
												CFrame1 = BasePart.CFrame
											end
										end

										if CFrame1 then
											local Character = tbl1[11].Character
											local v1 =
												Character and Character:FindFirstChild("HumanoidRootPart")

											if v1 then
												v1.CFrame = CFrame1
												task.wait(0.6)
											end
										end
									end
								end
							end)
						end
					end
				)
				func4(
					v8,
					"COUNTER",
					function()
						if game.PlaceId ~= 11828384869 then
							tbl1[10]:Teleport(11828384869, tbl1[11])
						else
							task.spawn(function()
								local HumanoidRootPart = (tbl1[11].Character
									or tbl1[11].CharacterAdded:Wait()):WaitForChild(
									"HumanoidRootPart",
									10
								)

								if not HumanoidRootPart then
									return
								end

								local part = Instance.new("Part")
								part.Size = Vector3.new(100, 5, 100)
								part.Position = Vector3.new(0, 1500, 0)
								part.Anchored = true
								part.CanCollide = true
								part.Material = Enum.Material.SmoothPlastic
								part.Color = Color3.fromRGB(35, 35, 35)
								part.Parent = workspace
								HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 8, 0)
								local counterNoticeGui = Instance.new("ScreenGui")
								counterNoticeGui.Name = "CounterNoticeGui"
								counterNoticeGui.Parent = tbl1[1]
								local frame = Instance.new("Frame")
								frame.Size = UDim2.new(0, 300, 0, 70)
								frame.Position = UDim2.new(0.5, -150, 0.15, 0)
								frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
								frame.BorderSizePixel = 0
								frame.Parent = counterNoticeGui
								local uiCorner = Instance.new("UICorner")
								uiCorner.CornerRadius = UDim.new(0, 8)
								uiCorner.Parent = frame
								local uiStroke = Instance.new("UIStroke")
								uiStroke.Color = Color3.fromRGB(220, 50, 100)
								uiStroke.Thickness = 1.5
								uiStroke.Parent = frame
								local textLabel = Instance.new("TextLabel")
								textLabel.Size = UDim2.new(1, -20, 1, -10)
								textLabel.Position = UDim2.new(0, 10, 0, 5)
								textLabel.BackgroundTransparency = 1
								textLabel.FontFace = Font.new(
									"rbxasset://fonts/families/GothamSSm.json",
									Enum.FontWeight.Regular,
									Enum.FontStyle.Normal
								)
								textLabel.TextSize = 13
								textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
								textLabel.Text = "Please wait until the glove appears..."
								textLabel.TextWrapped = true
								textLabel.Parent = frame
								task.wait(1)
								local flag = false

								for _, descendant in ipairs(workspace:GetDescendants()) do
									if
										descendant.Name == "CounterLever"
											or descendant.Name == "Lever"
									then
										local v1 =
											descendant:FindFirstChildOfClass("ClickDetector")
												or descendant:FindFirstChild("ClickDetector", true)
										if v1 then
											fireclickdetector(v1)
										end
									end
								end

								while not flag and not flag1 do
									for _, descendant1 in ipairs(workspace:GetDescendants()) do
										if descendant1:IsA("ClickDetector") then
											local Parent = descendant1.Parent
											if
												Parent
													and (Parent.Name:lower():find("counter")
														or Parent.Name == "Part")
											then
												if
													Parent:FindFirstChild("SparkleSound")
														or Parent:FindFirstChild("Fragments")
														or Parent.Name:lower():find("counter")
												then
													fireclickdetector(descendant1)
													flag = true
													break
												end
											end
										end
									end
									task.wait(0.5)
								end

								counterNoticeGui:Destroy()
							end)
						end
					end
				)
				func4(
					v8,
					"RECALL",
					function()
						loadstring(
							game:HttpGet(
								"https://raw.githubusercontent.com/nerna-coder/Recall/refs/heads/main/slap-battlea.lua"
							)
						)()
					end
				)
				func4(
					v8,
					"FROSTBITE",
					function()
						if game.PlaceId == 17290438723 then
							local flag = false
							local Character = tbl1[11].Character

							for _, descendant in ipairs(workspace:GetDescendants()) do
								if descendant:IsA("ProximityPrompt") then
									if
										Character and Character:FindFirstChild("HumanoidRootPart")
									then
										local Parent

										if
											descendant.Parent and descendant.Parent:IsA("BasePart")
										then
											Parent = descendant.Parent
										elseif
											descendant.Parent
												and descendant.Parent:IsA("Model")
												and descendant.Parent.PrimaryPart
										then
											Parent = descendant.Parent.PrimaryPart
										else
											for _, child in ipairs(descendant.Parent:GetChildren()) do
												if child:IsA("BasePart") then
													Parent = child
													break
												end
											end
										end

										if Parent then
											Character.HumanoidRootPart.CFrame = Parent.CFrame
											task.wait(0.3)
										end
									end

									descendant.RequiresLineOfSight = false
									descendant.MaxActivationDistance = math.huge

									if fireproximityprompt then
										fireproximityprompt(descendant)
										flag = true
									end
								end
							end

							local StarterGui = game:GetService("StarterGui")

							if flag then
								StarterGui:SetCore(
									"SendNotification",
									{
										Title = "Badge Acquired",
										Text = "ProximityPrompts successfully activated!",
										Duration = 5
									}
								)
							else
								StarterGui:SetCore(
									"SendNotification",
									{
										Title = "Error",
										Text = "ProximityPrompt not found.",
										Duration = 5
									}
								)
							end
						else
							game:GetService("StarterGui")
								:SetCore(
									"SendNotification",
									{
										Title = "Teleporting...",
										Text = "Redirecting to the target place. Click again after loading.",
										Duration = 4
									}
								)
							tbl1[10]:Teleport(17290438723, tbl1[11])
						end
					end
				)
				func4(
					v8,
					"ICESKATE",
					function()
						local ok, result = pcall(function()
							tbl1[6].IceSkate:FireServer("Freeze")
						end)
						local StarterGui = game:GetService("StarterGui")

						if ok then
							StarterGui:SetCore(
								"SendNotification",
								{Title = "Ice Skate", Text = "Badge request sent!", Duration = 3}
							)
						else
							StarterGui:SetCore(
								"SendNotification",
								{
									Title = "Error",
									Text = "Failed to send request: " .. tostring(result),
									Duration = 3
								}
							)
						end
					end
				)
				func4(
					v9,
					"Teleport To Main Island",
					function()
						func1(Vector3.new(-2, -5, 1))
					end
				)
				func4(
					v9,
					"Slapple Island",
					function()
						func1(Vector3.new(-419, 50, -14))
					end
				)
				func4(
					v9,
					"Moai Island",
					function()
						func1(Vector3.new(236, -16, 2))
					end
				)
				func4(
					v9,
					"Cannon Island",
					function()
						func1(Vector3.new(286, 13, 255))
					end
				)
				func4(
					v9,
					"Rainbow Clouds",
					function()
						func1(Vector3.new(-125, -7, 122))
					end
				)
				func4(
					v9,
					"Cube of Death",
					function()
						func1(Vector3.new(-256, -5, 0), Vector3.new(0, 10, 0))
					end
				)
				func4(
					v9,
					"Arena Default",
					function()
						func1(Vector3.new(126, 360, -2))
					end
				)
				func4(
					v9,
					"Tp to Safe Place",
					function()
						local v1 = func7()
						local v2 = v1 and v1:FindFirstChild("Safespot")

						if v2 and tbl1[11].Character then
							if tbl1[11].Character:FindFirstChild("HumanoidRootPart") then
								tbl1[11].Character.HumanoidRootPart.CFrame =
									v2.CFrame + Vector3.new(0, 5, 0)
							end
						end
					end
				)
				local flag7 = false
				tbl1[15](
					v10,
					"Charge Kinetic",
					function(arg1)
						flag7 = arg1
						if arg1 then
							task.spawn(function()
								while flag7 and not flag1 do
									pcall(function()
										local SelfKnockback = tbl1[6]:FindFirstChild(
											"SelfKnockback"
										)
										if SelfKnockback then
											SelfKnockback:FireServer(
												{Force = 0, Direction = Vector3.new(-1, 0, 0)}
											)
										end
									end)
									task.wait(0.01)
								end
							end)
						end
					end
				)
				func4(
					v10,
					"INVISIBLE",
					function()
						local v1 =
							tbl1[11].leaderstats
								and tbl1[11].leaderstats:FindFirstChild("Glove")
								and tbl1[11].leaderstats.Glove.Value

						if
							workspace.Lobby:FindFirstChild("Ghost")
								and workspace.Lobby.Ghost:FindFirstChild("ClickDetector")
						then
							fireclickdetector(workspace.Lobby.Ghost.ClickDetector)
						end

						local Ghostinvisibilityactivated = tbl1[6]:FindFirstChild(
							"Ghostinvisibilityactivated"
						)

						if Ghostinvisibilityactivated then
							Ghostinvisibilityactivated:FireServer()
						end

						task.wait(0.1)

						if v1 and workspace.Lobby:FindFirstChild(v1) then
							local v2 = workspace.Lobby[v1]
							if v2:FindFirstChild("ClickDetector") then
								fireclickdetector(v2.ClickDetector)
							end
						end
					end
				)

				function tbl10.line(parent, arg2, arg3, arg4, arg5, arg6, backgroundColor3)
					local v1 = arg4 - arg2
					local v2 = arg5 - arg3
					local v3 = math.sqrt(v1 * v1 + v2 * v2)
					local iconPart = Instance.new("Frame")
					iconPart.Name = "IconPart"
					iconPart.AnchorPoint = Vector2.new(0.5, 0.5)
					iconPart.BackgroundColor3 = backgroundColor3
					iconPart.BorderSizePixel = 0
					iconPart.Position = UDim2.fromOffset((arg2 + arg4) / 2, (arg3 + arg5) / 2)
					iconPart.Size = UDim2.fromOffset(v3 + arg6 * 0.4, arg6)
					iconPart.Rotation = math.deg(math.atan2(v2, v1))
					iconPart.Parent = parent
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(1, 0)
					uiCorner.Parent = iconPart
					return iconPart
				end

				function tbl10.drawVersionIcon(arg1, arg2)
					local v1 = tbl10.newIconFrame(arg1, "VersionIcon")
					tbl10.line(v1, 7, 1.5, 7, 9.5, 1.6, arg2)
					tbl10.line(v1, 3.2, 6, 7, 9.8, 1.6, arg2)
					tbl10.line(v1, 10.8, 6, 7, 9.8, 1.6, arg2)
					tbl10.line(v1, 2.5, 12.5, 11.5, 12.5, 1.6, arg2)
					return v1
				end

				function tbl10.drawRocketIcon(arg1, color)
					local v1 = tbl10.newIconFrame(arg1, "RocketIcon")
					local iconOutline = Instance.new("Frame")
					iconOutline.Name = "IconOutline"
					iconOutline.AnchorPoint = Vector2.new(0.5, 0.5)
					iconOutline.BackgroundTransparency = 1
					iconOutline.BorderSizePixel = 0
					iconOutline.Position = UDim2.fromOffset(8.2, 5.8)
					iconOutline.Size = UDim2.fromOffset(4.6, 9.4)
					iconOutline.Rotation = 45
					iconOutline.Parent = v1
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(1, 0)
					uiCorner.Parent = iconOutline
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = color
					uiStroke.Thickness = 1.3
					uiStroke.Parent = iconOutline
					tbl10.part(
						v1,
						0.53,
						0.3,
						0.16,
						0.16,
						color,
						UDim.new(1, 0)
					).AnchorPoint = Vector2.new(0.5, 0.5)
					tbl10.line(v1, 1.8, 12.2, 4.8, 9.2, 1.5, color)
					tbl10.line(v1, 1.6, 8.6, 3.6, 6.6, 1.2, color)
					tbl10.line(v1, 5.4, 12.4, 7.4, 10.4, 1.2, color)
					return v1
				end

				function tbl10.notify(text, text1, arg3)
					local v1 = arg3 or 8
					if
						not pcall(function()
							local CurrentCamera = workspace.CurrentCamera
							local v2 =
								CurrentCamera and CurrentCamera.ViewportSize
									or Vector2.new(800, 600)
							local v3 = math.clamp(v2.X - 40, 200, 300)
							local HubNotifications = xursedHubGui:FindFirstChild("HubNotifications")

							if not HubNotifications then
								local frame = Instance.new("Frame")
								HubNotifications = frame
								frame.Name = "HubNotifications"
								frame.AnchorPoint = Vector2.new(1, 1)
								frame.BackgroundTransparency = 1
								frame.ZIndex = 50
								frame.Parent = xursedHubGui
								local uiListLayout = Instance.new("UIListLayout")
								uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
								uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
								uiListLayout.Padding = UDim.new(0, 8)
								uiListLayout.Parent = frame
							end

							HubNotifications.Position = UDim2.new(1, -16, 1, -28)
							HubNotifications.Size = UDim2.new(0, v3, 1, -56)
							local tbl = {}

							for _, child in ipairs(HubNotifications:GetChildren()) do
								if child.Name == "HubNotification" then
									table.insert(tbl, child)
								end
							end

							while #tbl >= 4 do
								tbl[1]:Destroy()
								table.remove(tbl, 1)
							end

							local v4 = v3 - 24
							local ok, result = pcall(function()
								return
									game:GetService("TextService")
										:GetTextSize(
											text1,
											12,
											Enum.Font.GothamMedium,
											Vector2.new(v4, 10000)
										)
							end)
							local v5

							if ok and result then
								v5 = math.ceil(result.Y) + 4
							else
								v5 = math.ceil(#text1 * 7 / v4) * 15 + 4
							end

							local v6 = 33 + v5 + 5 + 3 + 10
							local hubNotification = Instance.new("Frame")
							hubNotification.Name = "HubNotification"
							hubNotification.Size = UDim2.new(1, 0, 0, v6)
							hubNotification.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
							hubNotification.BackgroundTransparency = 1
							hubNotification.BorderSizePixel = 0
							hubNotification.ZIndex = 50
							hubNotification.Parent = HubNotifications
							local uiCorner = Instance.new("UICorner")
							uiCorner.CornerRadius = UDim.new(0, 8)
							uiCorner.Parent = hubNotification
							local uiStroke = Instance.new("UIStroke")
							uiStroke.Color = tbl10.Accent
							uiStroke.Thickness = 1.5
							uiStroke.Transparency = 1
							uiStroke.Parent = hubNotification
							local textLabel = Instance.new("TextLabel")
							textLabel.Position = UDim2.new(0, 12, 0, 10)
							textLabel.Size = UDim2.new(1, -24, 0, 18)
							textLabel.BackgroundTransparency = 1
							textLabel.FontFace = tbl10.Font
							textLabel.TextSize = 15
							textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
							textLabel.TextXAlignment = Enum.TextXAlignment.Left
							textLabel.TextTransparency = 1
							textLabel.Text = text
							textLabel.ZIndex = 51
							textLabel.Parent = hubNotification
							local textLabel1 = Instance.new("TextLabel")
							textLabel1.Position = UDim2.new(0, 12, 0, 33)
							textLabel1.Size = UDim2.new(1, -24, 0, v5)
							textLabel1.BackgroundTransparency = 1
							textLabel1.FontFace = tbl10.Font
							textLabel1.TextSize = 12
							textLabel1.TextColor3 = Color3.fromRGB(225, 225, 225)
							textLabel1.TextWrapped = true
							textLabel1.TextXAlignment = Enum.TextXAlignment.Left
							textLabel1.TextYAlignment = Enum.TextYAlignment.Top
							textLabel1.TextTransparency = 1
							textLabel1.Text = text1
							textLabel1.ZIndex = 51
							textLabel1.Parent = hubNotification
							local frame1 = Instance.new("Frame")
							frame1.Position = UDim2.new(0, 12, 1, -13)
							frame1.Size = UDim2.new(1, -24, 0, 3)
							frame1.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
							frame1.BackgroundTransparency = 1
							frame1.BorderSizePixel = 0
							frame1.ZIndex = 51
							frame1.Parent = hubNotification
							local uiCorner1 = Instance.new("UICorner")
							uiCorner1.CornerRadius = UDim.new(1, 0)
							uiCorner1.Parent = frame1
							local frame2 = Instance.new("Frame")
							frame2.Size = UDim2.new(1, 0, 1, 0)
							frame2.BackgroundColor3 = tbl10.Accent
							frame2.BackgroundTransparency = 1
							frame2.BorderSizePixel = 0
							frame2.ZIndex = 52
							frame2.Parent = frame1
							local uiCorner2 = Instance.new("UICorner")
							uiCorner2.CornerRadius = UDim.new(1, 0)
							uiCorner2.Parent = frame2
							local tweenInfo = TweenInfo.new(
								0.25,
								Enum.EasingStyle.Quad,
								Enum.EasingDirection.Out
							)
							tbl1[7]:Create(
								hubNotification,
								tweenInfo,
								{BackgroundTransparency = 0.05}
							)
								:Play()
							tbl1[7]:Create(uiStroke, tweenInfo, {Transparency = 0}):Play()
							tbl1[7]:Create(textLabel, tweenInfo, {TextTransparency = 0}):Play()
							tbl1[7]:Create(textLabel1, tweenInfo, {TextTransparency = 0}):Play()
							tbl1[7]:Create(frame1, tweenInfo, {BackgroundTransparency = 0}):Play()
							tbl1[7]:Create(frame2, tweenInfo, {BackgroundTransparency = 0}):Play()
							tbl1[7]:Create(
								frame2,
								TweenInfo.new(v1, Enum.EasingStyle.Linear),
								{Size = UDim2.new(0, 0, 1, 0)}
							)
								:Play()
							local flag = false

							local function func()
								if flag then
									return
								end

								flag = true
								local tweenInfo = TweenInfo.new(
									0.25,
									Enum.EasingStyle.Quad,
									Enum.EasingDirection.In
								)
								tbl1[7]:Create(
									hubNotification,
									tweenInfo,
									{BackgroundTransparency = 1}
								)
									:Play()
								tbl1[7]:Create(uiStroke, tweenInfo, {Transparency = 1}):Play()
								tbl1[7]:Create(textLabel, tweenInfo, {TextTransparency = 1}):Play()
								tbl1[7]:Create(textLabel1, tweenInfo, {TextTransparency = 1}):Play()
								tbl1[7]:Create(frame1, tweenInfo, {BackgroundTransparency = 1})
									:Play()
								tbl1[7]:Create(frame2, tweenInfo, {BackgroundTransparency = 1})
									:Play()
								task.delay(
									0.3,
									function()
										hubNotification:Destroy()
									end
								)
							end

							local textButton = Instance.new("TextButton")
							textButton.Size = UDim2.new(1, 0, 1, 0)
							textButton.BackgroundTransparency = 1
							textButton.Text = ""
							textButton.ZIndex = 53
							textButton.Parent = hubNotification
							textButton.MouseButton1Click:Connect(func)
							task.delay(v1, func)
						end)
					then
						pcall(function()
							game:GetService("StarterGui")
								:SetCore(
									"SendNotification",
									{Title = text, Text = text1, Duration = v1}
								)
						end)
					end
				end

				local v79
				tbl1[15](
					v10,
					"Infinite Jump",
					function(arg1)
						if v79 then
							v79:Disconnect()
							v79 = nil
						end
						if arg1 then
							v79 = tbl1[3].JumpRequest:Connect(function()
								if flag1 then
									return
								end

								local Character = tbl1[11].Character
								local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

								if v1 and v1.Health > 0 then
									v1:ChangeState(Enum.HumanoidStateType.Jumping)
								end
							end)
						end
					end
				)
				local v80
				local num7 = 0
				tbl1[15](
					v10,
					"Anti AFK",
					function(arg1)
						num7 = num7 + 1
						local v1 = num7

						if v80 then
							v80:Disconnect()
							v80 = nil
						end

						if not arg1 then
							return
						end

						local VirtualUser = game:GetService("VirtualUser")
						v80 = tbl1[11].Idled:Connect(function()
							pcall(function()
								VirtualUser:CaptureController()
								VirtualUser:ClickButton2(Vector2.new())
							end)
						end)
						task.spawn(function()
							while task.wait(300) do
								if num7 ~= v1 or flag1 then
									return
								end
								pcall(function()
									VirtualUser:CaptureController()
									VirtualUser:ClickButton2(Vector2.new())
								end)
							end
						end)
					end
				)
				func4(
					v10,
					"Collect All Candy Corns",
					function()
						task.spawn(function()
							local ok, result = pcall(function()
								local v1 =
									workspace:FindFirstChild("CandyCorns")
										or workspace:WaitForChild("CandyCorns", 5)

								if not v1 then
									tbl10.notify(
										"No Candy Corns Found",
										"There are no candy corns in this server right now. Try again when the event is active.",
										5
									)
									return
								end

								local HumanoidRootPart = (tbl1[11].Character
									or tbl1[11].CharacterAdded:Wait()):WaitForChild(
									"HumanoidRootPart"
								)

								for _, descendant in ipairs(v1:GetDescendants()) do
									if descendant:IsA("BasePart") then
										descendant.CFrame = HumanoidRootPart.CFrame
									end
								end
							end)
							if not ok then
								warn(
									"[Xursed Hub] Collect All Candy Corns failed: "
										.. tostring(result)
								)
							end
						end)
					end
				)
				func4(
					v10,
					"Autofarm Candy Corns Script",
					function()
						local flag = false

						if type(v3) == "function" then
							flag = pcall(
								v3,
								'loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmaayyy/candy-farm/refs/heads/main/candy-corn-farm"))()'
							)
						end

						if flag then
							tbl10.notify(
								"Xursed Hub",
								"The script has been copied to your clipboard. Paste this script in your AutoExecute folder to start autofarming!",
								10
							)
						else
							tbl10.notify(
								"Xursed Hub",
								"Your executor can't copy to the clipboard, so copy this script yourself and paste it in your AutoExecute folder to start autofarming:\nloadstring(game:HttpGet(\"https://raw.githubusercontent.com/sigmaayyy/candy-farm/refs/heads/main/candy-corn-farm\"))()",
								14
							)
						end
					end
				)
				local v17 = func2("Versions", tbl10.drawVersionIcon)
				local updatesPausedStatus = Instance.new("Frame")
				updatesPausedStatus.Name = "UpdatesPausedStatus"
				updatesPausedStatus.Size = UDim2.new(1, 0, 0, 26)
				updatesPausedStatus.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				updatesPausedStatus.BackgroundTransparency = 0.25
				updatesPausedStatus.BorderSizePixel = 0
				updatesPausedStatus.Parent = v17
				local uiCorner3 = Instance.new("UICorner")
				uiCorner3.CornerRadius = UDim.new(0, 7)
				uiCorner3.Parent = updatesPausedStatus
				local statusIcon = Instance.new("TextLabel")
				statusIcon.Name = "StatusIcon"
				statusIcon.Size = UDim2.new(0, 24, 1, 0)
				statusIcon.Position = UDim2.new(0, 8, 0, 0)
				statusIcon.BackgroundTransparency = 1
				statusIcon.FontFace = tbl10.Font
				statusIcon.Text = "●"
				statusIcon.TextSize = 13
				statusIcon.TextColor3 = Color3.fromRGB(255, 145, 35)
				statusIcon.Parent = updatesPausedStatus
				local textLabel2 = Instance.new("TextLabel")
				textLabel2.Size = UDim2.new(1, -40, 1, 0)
				textLabel2.Position = UDim2.new(0, 30, 0, 0)
				textLabel2.BackgroundTransparency = 1
				textLabel2.FontFace = tbl10.Font
				textLabel2.TextSize = 11
				textLabel2.TextColor3 = Color3.fromRGB(225, 155, 90)
				textLabel2.TextXAlignment = Enum.TextXAlignment.Left
				textLabel2.Text = "Updates Paused"
				textLabel2.Parent = updatesPausedStatus
				local tweenInfo = TweenInfo.new(
					1,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut,
					-1,
					true
				)
				tbl1[7]:Create(statusIcon, tweenInfo, {TextTransparency = 0.72}):Play()
				local versionBox = Instance.new("Frame")
				versionBox.Name = "VersionBox"
				versionBox.Size = UDim2.new(1, 0, 0, 100)
				versionBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				versionBox.BackgroundTransparency = 0.2
				versionBox.BorderSizePixel = 0
				versionBox.Parent = v17
				local uiCorner4 = Instance.new("UICorner")
				uiCorner4.CornerRadius = UDim.new(0, 8)
				uiCorner4.Parent = versionBox
				local uiStroke = Instance.new("UIStroke")
				uiStroke.Color = tbl10.Accent
				uiStroke.Thickness = 1.5
				uiStroke.Parent = versionBox
				local textLabel3 = Instance.new("TextLabel")
				textLabel3.Size = UDim2.new(1, 0, 0, 16)
				textLabel3.Position = UDim2.new(0, 0, 0, 10)
				textLabel3.BackgroundTransparency = 1
				textLabel3.FontFace = tbl10.Font
				textLabel3.TextSize = 10
				textLabel3.TextColor3 = Color3.fromRGB(150, 150, 150)
				textLabel3.Text = "VERSION"
				textLabel3.Parent = versionBox
				local versionLabel = Instance.new("TextLabel")
				versionLabel.Name = "VersionLabel"
				versionLabel.Size = UDim2.new(1, 0, 0, 44)
				versionLabel.Position = UDim2.new(0, 0, 0, 28)
				versionLabel.BackgroundTransparency = 1
				versionLabel.FontFace = tbl10.Font
				versionLabel.TextSize = 36
				versionLabel.TextColor3 = tbl10.Accent
				versionLabel.Text = "v1.5.5"
				versionLabel.Parent = versionBox
				local textLabel4 = Instance.new("TextLabel")
				textLabel4.Size = UDim2.new(1, 0, 0, 16)
				textLabel4.Position = UDim2.new(0, 0, 0, 76)
				textLabel4.BackgroundTransparency = 1
				textLabel4.FontFace = tbl10.Font
				textLabel4.TextSize = 10
				textLabel4.TextColor3 = Color3.fromRGB(150, 150, 150)
				textLabel4.Text = "Current build"
				textLabel4.Parent = versionBox
				local changelogBox = Instance.new("Frame")
				changelogBox.Name = "ChangelogBox"
				changelogBox.Size = UDim2.new(1, 0, 0, 0)
				changelogBox.AutomaticSize = Enum.AutomaticSize.Y
				changelogBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				changelogBox.BackgroundTransparency = 0.4
				changelogBox.BorderSizePixel = 0
				changelogBox.Parent = v17
				local uiCorner5 = Instance.new("UICorner")
				uiCorner5.CornerRadius = UDim.new(0, 5)
				uiCorner5.Parent = changelogBox
				local uiPadding1 = Instance.new("UIPadding")
				uiPadding1.PaddingLeft = UDim.new(0, 8)
				uiPadding1.PaddingRight = UDim.new(0, 8)
				uiPadding1.PaddingTop = UDim.new(0, 6)
				uiPadding1.PaddingBottom = UDim.new(0, 8)
				uiPadding1.Parent = changelogBox
				local uiListLayout2 = Instance.new("UIListLayout")
				uiListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
				uiListLayout2.Padding = UDim.new(0, 4)
				uiListLayout2.Parent = changelogBox
				local textLabel5 = Instance.new("TextLabel")
				textLabel5.LayoutOrder = 1
				textLabel5.Size = UDim2.new(1, 0, 0, 16)
				textLabel5.BackgroundTransparency = 1
				textLabel5.FontFace = tbl10.Font
				textLabel5.TextSize = 11
				textLabel5.TextColor3 = tbl10.Accent
				textLabel5.TextXAlignment = Enum.TextXAlignment.Left
				textLabel5.Text = "v1.5.5 changes"
				textLabel5.Parent = changelogBox
				local textLabel6 = Instance.new("TextLabel")
				textLabel6.LayoutOrder = 2
				textLabel6.Size = UDim2.new(1, 0, 0, 0)
				textLabel6.AutomaticSize = Enum.AutomaticSize.Y
				textLabel6.BackgroundTransparency = 1
				textLabel6.FontFace = tbl10.Font
				textLabel6.TextSize = 10
				textLabel6.TextColor3 = tbl10.Accent
				textLabel6.TextWrapped = true
				textLabel6.TextXAlignment = Enum.TextXAlignment.Left
				textLabel6.TextYAlignment = Enum.TextYAlignment.Top
				textLabel6.Text =
					"• Added the Rob features for the Dark Realm\n• Get Guide Gloves now runs in the Guide Bossfight\n• Removed Get Harvester\n• Added new colour themes\n• Cleaned up the hub text and colours"
				textLabel6.Parent = changelogBox
				v18 = func2("Leaderboard")
				tbl14 = {}
			end

			do
				local str1 = "Stat"
				local str2 = ""
				local v81
				local color1 = Color3.fromRGB(205, 205, 205)

				local tbl15 = {
					Color3.fromRGB(255, 205, 70),
					Color3.fromRGB(200, 205, 215),
					Color3.fromRGB(205, 140, 85)
				}

				local function func13(parent, arg2, arg3, arg4, arg5, textSize, textColor3, arg8)
					local textLabel = Instance.new("TextLabel")
					textLabel.BackgroundTransparency = 1
					textLabel.Size = UDim2.new(arg4.Scale, arg4.Offset, 0, arg5)
					textLabel.Position = UDim2.new(arg2.Scale, arg2.Offset, 0, arg3)
					textLabel.FontFace = tbl10.Font
					textLabel.TextSize = textSize
					textLabel.TextColor3 = textColor3
					textLabel.TextXAlignment = arg8 or Enum.TextXAlignment.Left
					textLabel.TextTruncate = Enum.TextTruncate.AtEnd
					textLabel.Text = ""
					textLabel.Parent = parent
					return textLabel
				end

				local function func14(parent, arg2)
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, arg2)
					uiCorner.Parent = parent
					return uiCorner
				end

				local function func15(arg1)
					local str = tostring(math.floor(arg1 + 0.5))
					local v1 = string.reverse(str)
					local v2 = string.gsub(v1, "(%d%d%d)", "%1,")
					local v3 = string.reverse(v2)
					return (string.gsub(v3, "^,", ""))
				end

				local leaderboardHeader = Instance.new("Frame")
				leaderboardHeader.Name = "LeaderboardHeader"
				leaderboardHeader.LayoutOrder = 1
				leaderboardHeader.Size = UDim2.new(1, 0, 0, 52)
				leaderboardHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				leaderboardHeader.BackgroundTransparency = 0.4
				leaderboardHeader.BorderSizePixel = 0
				leaderboardHeader.Parent = v18
				func14(leaderboardHeader, 5)
				func13(
					leaderboardHeader,
					UDim.new(0, 8),
					4,
					UDim.new(1, -16),
					18,
					13,
					tbl10.Accent
				).Text =
					"Server Leaderboard"
				local v19 = func13(
					leaderboardHeader,
					UDim.new(0, 8),
					24,
					UDim.new(1, -16),
					24,
					10,
					color1
				)
				v19.TextWrapped = true
				v19.TextYAlignment = Enum.TextYAlignment.Top
				local leaderboardControls = Instance.new("Frame")
				leaderboardControls.Name = "LeaderboardControls"
				leaderboardControls.LayoutOrder = 2
				leaderboardControls.Size = UDim2.new(1, 0, 0, 28)
				leaderboardControls.BackgroundTransparency = 1
				leaderboardControls.Parent = v18
				local leaderboardSearch = Instance.new("TextBox")
				leaderboardSearch.Name = "LeaderboardSearch"
				leaderboardSearch.Size = UDim2.new(1, -240, 1, 0)
				leaderboardSearch.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				leaderboardSearch.BorderSizePixel = 0
				leaderboardSearch.FontFace = tbl10.Font
				leaderboardSearch.TextSize = 11
				leaderboardSearch.TextColor3 = tbl10.Accent
				leaderboardSearch.PlaceholderText = "Search players..."
				leaderboardSearch.Text = ""
				leaderboardSearch.TextXAlignment = Enum.TextXAlignment.Left
				leaderboardSearch.ClearTextOnFocus = false
				leaderboardSearch.Parent = leaderboardControls
				func14(leaderboardSearch, 5)
				local uiPadding2 = Instance.new("UIPadding")
				uiPadding2.PaddingLeft = UDim.new(0, 8)
				uiPadding2.Parent = leaderboardSearch
				local tbl16 = {}
				local tbl17 = {"Stat", "Distance", "Health", "Name"}

				local function func16()
					for k, v1 in pairs(tbl16) do
						local v2 = k == str1
						v1.BackgroundColor3 = v2 and tbl10.Accent or Color3.fromRGB(30, 30, 30)
						v1.TextColor3 = v2 and Color3.fromRGB(20, 20, 20) or tbl10.Accent
					end
				end

				local leaderboardRows = Instance.new("Frame")
				leaderboardRows.Name = "LeaderboardRows"
				leaderboardRows.LayoutOrder = 3
				leaderboardRows.Size = UDim2.new(1, 0, 0, 0)
				leaderboardRows.AutomaticSize = Enum.AutomaticSize.Y
				leaderboardRows.BackgroundTransparency = 1
				leaderboardRows.Parent = v18
				local uiListLayout3 = Instance.new("UIListLayout")
				uiListLayout3.SortOrder = Enum.SortOrder.LayoutOrder
				uiListLayout3.Padding = UDim.new(0, 5)
				uiListLayout3.Parent = leaderboardRows
				local v20 = func13(
					leaderboardRows,
					UDim.new(0, 0),
					0,
					UDim.new(1, 0),
					24,
					11,
					Color3.fromRGB(130, 130, 130),
					Enum.TextXAlignment.Center
				)
				v20.LayoutOrder = 100000
				v20.Text = "No players match your search."
				v20.Visible = false

				local function func17()
					local leaderstats = tbl1[11]:FindFirstChild("leaderstats")

					if not leaderstats then
						return nil
					end

					if leaderstats:FindFirstChild("Slaps") then
						return "Slaps"
					end

					for _, child in ipairs(leaderstats:GetChildren()) do
						if child:IsA("IntValue") or child:IsA("NumberValue") then
							return child.Name
						end
					end

					return nil
				end

				local function func18(player)
					if player == tbl1[11] then
						return
					end

					local Character = tbl1[11].Character
					local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

					if not v1 then
						tbl10.notify("Can't teleport", "Your character isn't loaded yet.", 3)
						return
					end

					local Character1 = player.Character
					local v2 = Character1 and Character1:FindFirstChild("HumanoidRootPart")

					if not v2 then
						tbl10.notify(
							"Can't teleport",
							player.DisplayName .. " doesn't have a character right now.",
							3
						)
						return
					end

					v1.CFrame = v2.CFrame * CFrame.new(0, 0, 3)
					v1.AssemblyLinearVelocity = Vector3.zero
					tbl10.notify(
						"Teleported",
						"You teleported to " .. player.DisplayName .. " (@" .. player.Name .. ").",
						3
					)
				end

				local function func19(player)
					local leaderboardRow = Instance.new("Frame")
					leaderboardRow.Name = "LeaderboardRow"
					leaderboardRow.Size = UDim2.new(1, 0, 0, 52)
					leaderboardRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					leaderboardRow.BorderSizePixel = 0
					leaderboardRow.Parent = leaderboardRows
					func14(leaderboardRow, 6)
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = tbl10.Accent
					uiStroke.Thickness = 1.2
					uiStroke.Transparency = player == tbl1[11] and 0.2 or 1
					uiStroke.Parent = leaderboardRow

					local tbl = {
						Frame = leaderboardRow,
						Rank = func13(
							leaderboardRow,
							UDim.new(0, 4),
							15,
							UDim.new(0, 24),
							20,
							13,
							tbl10.Dim,
							Enum.TextXAlignment.Center
						)
					}

					local avatar = Instance.new("ImageLabel")
					avatar.Name = "Avatar"
					avatar.Size = UDim2.new(0, 36, 0, 36)
					avatar.Position = UDim2.new(0, 30, 0, 8)
					avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
					avatar.BorderSizePixel = 0
					avatar.Image = string.format(
						"rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60",
						player.UserId
					)
					avatar.Parent = leaderboardRow
					func14(avatar, 18)
					tbl.Name = func13(
						leaderboardRow,
						UDim.new(0, 72),
						5,
						UDim.new(1, -118),
						15,
						12,
						tbl10.Accent
					)
					tbl.Sub = func13(
						leaderboardRow,
						UDim.new(0, 72),
						20,
						UDim.new(1, -118),
						12,
						9,
						Color3.fromRGB(140, 140, 140)
					)
					tbl.Stats = func13(
						leaderboardRow,
						UDim.new(0, 72),
						32,
						UDim.new(1, -118),
						12,
						10,
						color1
					)
					local healthTrack = Instance.new("Frame")
					healthTrack.Name = "HealthTrack"
					healthTrack.Position = UDim2.new(0, 72, 0, 46)
					healthTrack.Size = UDim2.new(1, -118, 0, 3)
					healthTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					healthTrack.BorderSizePixel = 0
					healthTrack.Parent = leaderboardRow
					func14(healthTrack, 2)
					local healthFill = Instance.new("Frame")
					healthFill.Name = "HealthFill"
					healthFill.Size = UDim2.new(1, 0, 1, 0)
					healthFill.BackgroundColor3 = Color3.fromRGB(90, 220, 110)
					healthFill.BorderSizePixel = 0
					healthFill.Parent = healthTrack
					func14(healthFill, 2)
					tbl.HpFill = healthFill
					local teleportButton = Instance.new("TextButton")
					teleportButton.Name = "TeleportButton"
					teleportButton.Size = UDim2.new(0, 32, 0, 32)
					teleportButton.Position = UDim2.new(1, -40, 0.5, -16)
					teleportButton.BackgroundColor3 = Color3.fromRGB(48, 32, 22)
					teleportButton.BorderSizePixel = 0
					teleportButton.AutoButtonColor = true
					teleportButton.Text = ""
					teleportButton.Parent = leaderboardRow
					func14(teleportButton, 6)
					tbl.RocketIcon = tbl10.drawRocketIcon(
						teleportButton,
						player == tbl1[11] and tbl10.Dim or tbl10.Accent
					)
					tbl.Rocket = teleportButton
					teleportButton.MouseButton1Click:Connect(function()
						func18(player)
					end)
					tbl14[player] = tbl
					return tbl
				end

				local function func20(player, arg2)
					local tbl = {Player = player, Stat = 0}
					tbl.Glove = nil
					tbl.Health = 0
					tbl.MaxHealth = 100
					tbl.Distance = nil
					tbl.Alive = false
					tbl.Arena = nil
					local leaderstats = player:FindFirstChild("leaderstats")

					if leaderstats then
						if v81 then
							local v1 = leaderstats:FindFirstChild(v81)
							if v1 and v1:IsA("ValueBase") then
								tbl.Stat = tonumber(v1.Value) or 0
							end
						end

						local Glove = leaderstats:FindFirstChild("Glove")

						if Glove and Glove:IsA("ValueBase") then
							tbl.Glove = tostring(Glove.Value)
						end
					end

					local Character = player.Character
					local v2 = Character and Character:FindFirstChildOfClass("Humanoid")
					local v3 = Character and Character:FindFirstChild("HumanoidRootPart")

					if v2 then
						tbl.Health = v2.Health
						tbl.MaxHealth = math.max(v2.MaxHealth, 1)
						tbl.Alive = v2.Health > 0
					end

					if v3 and arg2 then
						tbl.Distance = (v3.Position - arg2.Position).Magnitude
					end

					local v4 = Character and Character:FindFirstChild("isInArena")

					if v4 and v4:IsA("ValueBase") then
						tbl.Arena = v4.Value == true
					end

					return tbl
				end

				local function func21(player)
					if str2 == "" then
						return true
					end
					return
						string.find(string.lower(player.Name), str2, 1, true) ~= nil
							or string.find(string.lower(player.DisplayName), str2, 1, true) ~= nil
				end

				local function func22(arg1, arg2, layoutOrder)
					local Player = arg2.Player
					arg1.Frame.LayoutOrder = layoutOrder
					arg1.Rank.Text = tostring(layoutOrder)
					arg1.Rank.TextColor3 =
						str1 == "Stat" and v81 and tbl15[layoutOrder] or tbl10.Dim
					arg1.Name.Text = Player.DisplayName .. (Player == tbl1[11] and "  (You)" or "")
					arg1.Sub.Text = "@" .. Player.Name .. "  •  ID " .. tostring(Player.UserId)
					local tbl = {}

					if v81 then
						table.insert(tbl, v81 .. " " .. func15(arg2.Stat))
					end

					if arg2.Glove then
						table.insert(tbl, arg2.Glove)
					end

					if arg2.Distance and Player ~= tbl1[11] then
						table.insert(tbl, func15(arg2.Distance) .. " studs")
					end

					if arg2.Arena ~= nil then
						table.insert(tbl, arg2.Arena and "Arena" or "Lobby")
					end

					if not arg2.Alive then
						table.insert(tbl, "No character")
					end

					arg1.Stats.Text = table.concat(tbl, "  •  ")
					local v1 = math.clamp(arg2.Health / arg2.MaxHealth, 0, 1)
					arg1.HpFill.Size = UDim2.new(v1, 0, 1, 0)
					arg1.HpFill.BackgroundColor3 = Color3.fromRGB(
						235,
						70,
						70
					):Lerp(Color3.fromRGB(90, 220, 110), v1)
				end

				local function func23()
					v81 = func17()
					tbl16.Stat.Text = v81 or "Stat"
					local Character = tbl1[11].Character
					local v1 = Character and Character:FindFirstChild("HumanoidRootPart")
					local tbl = {}
					local tbl2 = {}

					for _, player in ipairs(tbl1[5]:GetPlayers()) do
						tbl2[player] = true
						table.insert(tbl, (func20(player, v1)))
					end

					table.sort(
						tbl,
						function(a, b)
							if str1 == "Distance" then
								local v1 = a.Distance or math.huge
								local v2 = b.Distance or math.huge

								if v1 ~= v2 then
									return v1 < v2
								end
							elseif str1 == "Health" then
								local v3 = a.Health / a.MaxHealth
								local v4 = b.Health / b.MaxHealth

								if v3 ~= v4 then
									return v3 > v4
								end
							elseif str1 == "Name" then
								local v5 = string.lower(a.Player.DisplayName)
								local v6 = string.lower(b.Player.DisplayName)

								if v5 ~= v6 then
									return v5 < v6
								end
							elseif a.Stat ~= b.Stat then
								return a.Stat > b.Stat
							end
							return string.lower(a.Player.Name) < string.lower(b.Player.Name)
						end
					)
					local num = 0
					local v3

					for _, v2 in ipairs(tbl) do
						if not v3 or v2.Stat > v3.Stat then
							v3 = v2
						end

						local v4 = tbl14[v2.Player] or func19(v2.Player)
						local v5 = func21(v2.Player)
						v4.Frame.Visible = v5

						if v5 then
							num = num + 1
							func22(v4, v2, num)
						end
					end

					for k, v6 in pairs(tbl14) do
						if not tbl2[k] then
							v6.Frame:Destroy()
							tbl14[k] = nil
						end
					end

					v20.Visible = num == 0
					local v7 = str1 == "Stat" and (v81 or "Name") or str1
					local v8 = string.format(
						"%d players in this server  •  Showing %d  •  Sorted by %s",
						#tbl,
						num,
						v7
					)

					if v81 and v3 then
						v8 =
							v8
								.. string.format(
									"\nTop player: %s (%s %s)",
									v3.Player.DisplayName,
									v81,
									(func15(v3.Stat))
								)
					end

					v19.Text = v8
				end

				for i, v21 in ipairs(tbl17) do
					local textButton = Instance.new("TextButton")
					textButton.Name = v21 .. "Sort"
					textButton.Size = UDim2.new(0, 54, 1, 0)
					textButton.Position = UDim2.new(1, -(5 - i) * 58 + 4, 0, 0)
					textButton.BorderSizePixel = 0
					textButton.FontFace = tbl10.Font
					textButton.TextSize = 10
					textButton.Text = v21
					textButton.AutoButtonColor = false
					textButton.Parent = leaderboardControls
					local uiCorner6 = Instance.new("UICorner")
					uiCorner6.CornerRadius = UDim.new(0, 5)
					uiCorner6.Parent = textButton
					tbl16[v21] = textButton
					textButton.MouseButton1Click:Connect(function()
						str1 = v21
						func16()
						pcall(func23)
					end)
				end

				func16()
				leaderboardSearch:GetPropertyChangedSignal("Text")
					:Connect(function()
						str2 = string.lower(leaderboardSearch.Text)
						pcall(func23)
					end)
				tbl1[5].PlayerRemoving:Connect(function(player)
					local v1 = tbl14[player]
					if v1 then
						v1.Frame:Destroy()
						tbl14[player] = nil
					end
				end)

				function tbl9.Leaderboard.OnShow()
					pcall(func23)
				end

				task.spawn(function()
					while not flag1 do
						task.wait(1)
						if v65 == "Leaderboard" and flag3 then
							pcall(func23)
						end
					end
				end)
				local v82
				tbl1[15](
					v11,
					"Always Die When In Void",
					function(arg1)
						if v82 then
							v82:Destroy()
							v82 = nil
						end

						if not arg1 then
							return
						end

						local xursedHubVoidKill = Instance.new("Folder")
						xursedHubVoidKill.Name = "XursedHubVoidKill"
						xursedHubVoidKill.Parent = workspace
						v82 = xursedHubVoidKill
						local vector3 = Vector3.new(-39, -75, 107)

						for i = -2, 2 do
							for i1 = -2, 2 do
								local voidKillPart = Instance.new("Part")
								voidKillPart.Name = "VoidKillPart"
								voidKillPart.Size = Vector3.new(2048, 50, 2048)
								voidKillPart.Position =
									vector3 + Vector3.new(i * 2048, 0, i1 * 2048)
								voidKillPart.Anchored = true
								voidKillPart.CanCollide = false
								voidKillPart.CanQuery = false
								voidKillPart.CanTouch = true
								voidKillPart.CastShadow = false
								voidKillPart.Transparency = 0.85
								voidKillPart.Color = Color3.fromRGB(255, 0, 0)
								voidKillPart.Material = Enum.Material.Neon
								voidKillPart.Parent = xursedHubVoidKill
								voidKillPart.Touched:Connect(function(hit)
									local Character = tbl1[11].Character

									if
										not Character
											or not hit
											or not hit:IsDescendantOf(Character)
									then
										return
									end

									local Humanoid = Character:FindFirstChildOfClass("Humanoid")

									if Humanoid and Humanoid.Health > 0 then
										Humanoid.Health = 0
									end
								end)
							end
						end
					end
				)
				tbl1[15](
					v11,
					"Always On-Top",
					function(alwaysOnTop)
						tbl5.AlwaysOnTop = alwaysOnTop
						xursedHubGui.DisplayOrder = alwaysOnTop and 100000 or 0
						pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))
					end,
					tbl5.AlwaysOnTop == true
				)
				tbl1[15](
					v11,
					"Hide Username & ID",
					function(hideUsernameAndID)
						tbl5.HideUsernameAndID = hideUsernameAndID

						for _, descendant in ipairs(xursedHubGui:GetDescendants()) do
							if
								descendant.Name == "ProfileUsername"
									or descendant.Name == "ProfileUserId"
							then
								descendant.Visible = not hideUsernameAndID
							end
						end

						pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))
					end,
					tbl5.HideUsernameAndID == true
				)
				local v22 = tbl1[3].TouchEnabled and not tbl1[3].KeyboardEnabled
				local flag8 = false
				local mouseFreeModal = Instance.new("TextButton")
				mouseFreeModal.Name = "MouseFreeModal"
				mouseFreeModal.BackgroundTransparency = 1
				mouseFreeModal.Size = UDim2.new(0, 0, 0, 0)
				mouseFreeModal.Text = ""
				mouseFreeModal.Active = false
				mouseFreeModal.Selectable = false
				mouseFreeModal.Modal = false
				mouseFreeModal.Parent = xursedHubGui

				local function func24(arg1)
					flag8 = arg1 == true

					if v22 then
						return
					end

					pcall(function()
						tbl1[4]:UnbindFromRenderStep("XursedHubMouse")
					end)
					mouseFreeModal.Modal = false

					if flag8 then
						tbl1[4]:BindToRenderStep(
							"XursedHubMouse",
							Enum.RenderPriority.Camera.Value + 1,
							function()
								if flag1 then
									mouseFreeModal.Modal = false
									return
								end

								local rmbHeld = tbl1[3]:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
								if rmbHeld or not flag3 then
									mouseFreeModal.Modal = false
									return
								end

								mouseFreeModal.Modal = true
								if tbl1[3].MouseBehavior == Enum.MouseBehavior.LockCenter then
									tbl1[3].MouseBehavior = Enum.MouseBehavior.Default
								end
								tbl1[3].MouseIconEnabled = true
							end
						)
					end
				end

				local v23 = v6.Toggles["Lock/Free Mouse"]
				func24(not v22 and v6.AutoRestore and v23 == true)
				tbl1[15](v11, "Lock/Free Mouse", func24, false)
				local v24 = type(tbl5.MouseKeybind) == "string" and tbl5.MouseKeybind or "M"
				local flag9 = false
				local hubButton = Instance.new("TextButton")
				hubButton.Name = "HubButton"
				hubButton.Size = UDim2.new(1, 0, 0, 28)
				hubButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				hubButton.BorderSizePixel = 0
				hubButton.FontFace = tbl10.Font
				hubButton.TextSize = 11
				hubButton.TextColor3 = tbl10.Accent
				hubButton.Parent = v11
				local uiCorner7 = Instance.new("UICorner")
				uiCorner7.CornerRadius = UDim.new(0, 5)
				uiCorner7.Parent = hubButton

				if v22 then
					hubButton.Text = "Lock/Free Mouse Keybind: not available on mobile"
					hubButton.AutoButtonColor = false
					hubButton.Active = false
					hubButton.TextTransparency = 0.5
				else
					hubButton.Text = "Lock/Free Mouse Keybind: " .. v24
					hubButton.MouseButton1Click:Connect(function()
						if flag9 then
							return
						end

						flag9 = true
						hubButton.Text = "Press a key... (Esc to cancel)"
					end)
					tbl1[3].InputBegan:Connect(function(input, gameProcessed)
						if flag1 or input.UserInputType ~= Enum.UserInputType.Keyboard then
							return
						end

						if flag9 then
							flag9 = false

							if
								input.KeyCode ~= Enum.KeyCode.Escape
									and input.KeyCode ~= Enum.KeyCode.Unknown
							then
								v24 = input.KeyCode.Name
								tbl5.MouseKeybind = v24
								pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))
							end

							hubButton.Text = "Lock/Free Mouse Keybind: " .. v24
							return
						end

						if gameProcessed then
							return
						end

						if input.KeyCode.Name == v24 then
							local v1 = tbl3["Lock/Free Mouse"]
							if v1 then
								v1(not flag8, true)
							end
						end
					end)
				end

				local tbl18 = {
					{"ParticleEmitter", {Enabled = false}},
					{"Trail", {Enabled = false}},
					{"Beam", {Enabled = false}},
					{"Fire", {Enabled = false}},
					{"Smoke", {Enabled = false}},
					{"Sparkles", {Enabled = false}},
					{"PointLight", {Enabled = false}},
					{"SpotLight", {Enabled = false}},
					{"SurfaceLight", {Enabled = false}},
					{"PostEffect", {Enabled = false}},
					{"Explosion", {Visible = false}},
					{"ForceField", {Visible = false}},
					{"Atmosphere", {Density = 0, Haze = 0, Glare = 0}},
					{"Clouds", {Enabled = false}}
				}

				local v25 = setmetatable({}, {__mode = "k"})
				local v83
				local v84
				local v85
				local v86
				local num8 = 0
				local num9 = 0

				local function func25(arg1)
					pcall(function()
						if arg1:IsA("BasePart") then
							if arg1:IsA("Terrain") then
								return
							end

							if not v25[arg1] then
								v25[arg1] = {CastShadow = arg1.CastShadow, Material = arg1.Material}

								if arg1:IsA("MeshPart") then
									v25[arg1].RenderFidelity = arg1.RenderFidelity
									arg1.RenderFidelity = Enum.RenderFidelity.Performance
								end

								arg1.CastShadow = false
								arg1.Material = Enum.Material.SmoothPlastic
								num9 = num9 + 1
							end

							return
						end

						if arg1:IsA("Highlight") then
							if arg1.Name == "RainbowHighlight" then
								return
							end
						end

						for _, v1 in ipairs(tbl18) do
							if arg1:IsA(v1[1]) then
								local v2 = tbl4[arg1]

								if not v2 then
									local tbl = {}
									v2 = tbl
									tbl4[arg1] = tbl
									num9 = num9 + 1
								end

								for k, v3 in pairs(v1[2]) do
									if v2[k] == nil then
										v2[k] = arg1[k]
									end
									arg1[k] = v3
								end

								return
							end
						end
					end)
				end

				tbl1[15](
					v11,
					"Boost Performance",
					function(arg1)
						flag = arg1 == true
						num8 = num8 + 1
						local v1 = num8
						local Lighting = game:GetService("Lighting")
						local Terrain = workspace:FindFirstChildOfClass("Terrain")

						if v85 then
							v85:Disconnect()
							v85 = nil
						end

						if v86 then
							v86:Disconnect()
							v86 = nil
						end

						local pcallRef, pcallRef1

						if decorativeOverlay then
							decorativeOverlay.Visible = false
							if flag then
								for _, child in ipairs(decorativeOverlay:GetChildren()) do
									child:Destroy()
								end
							else
								for k, v2 in pairs(tbl4) do
									if k and k.Parent then
										for k1, v3 in pairs(v2) do
											pcall(function()
												k[k1] = v3
											end)
										end
									end
								end

								table.clear(tbl4)

								for k2, v4 in pairs(v25) do
									if k2 and k2.Parent then
										pcall(function()
											k2.CastShadow = v4.CastShadow
											k2.Material = v4.Material

											if v4.RenderFidelity then
												k2.RenderFidelity = v4.RenderFidelity
											end
										end)
									end
								end

								table.clear(v25)

								if v83 then
									pcallRef = pcall
									pcallRef(function()
										Lighting.GlobalShadows = v83.GlobalShadows
									end)
									pcallRef(function()
										Lighting.EnvironmentSpecularScale =
											v83.EnvironmentSpecularScale
									end)
									pcallRef(function()
										Lighting.ShadowSoftness = v83.ShadowSoftness
									end)
									pcallRef(function()
										Lighting.Brightness = v83.Brightness
									end)

									if v83.Technology ~= nil then
										pcall(function()
											sethiddenproperty(Lighting, "Technology", v83.Technology)
										end)
									end

									if v83.Quality then
										pcall(function()
											settings().Rendering.QualityLevel = v83.Quality
										end)
									end

									v83 = nil
								end

								if v84 and Terrain then
									pcallRef1 = pcall
									pcallRef1(function()
										Terrain.WaterWaveSize = v84.WaterWaveSize
									end)
									pcallRef1(function()
										Terrain.WaterWaveSpeed = v84.WaterWaveSpeed
									end)
									pcallRef1(function()
										Terrain.WaterReflectance = v84.WaterReflectance
									end)

									if v84.Decoration ~= nil then
										pcall(function()
											sethiddenproperty(Terrain, "Decoration", v84.Decoration)
										end)
									end
								end

								v84 = nil
								return
							end
						end

						if flag then
							num9 = 0

							if not v83 then
								v83 = {
									GlobalShadows = Lighting.GlobalShadows,
									EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
									ShadowSoftness = Lighting.ShadowSoftness,
									Brightness = Lighting.Brightness
								}

								pcall(function()
									v83.Quality = settings().Rendering.QualityLevel
								end)
								pcall(function()
									v83.Technology = gethiddenproperty(Lighting, "Technology")
								end)
							end

							pcall(function()
								Lighting.GlobalShadows = false
							end)
							pcall(function()
								Lighting.EnvironmentSpecularScale = 0
							end)
							pcall(function()
								Lighting.ShadowSoftness = 0
							end)
							pcall(function()
								sethiddenproperty(
									Lighting,
									"Technology",
									Enum.Technology.Compatibility
								)
							end)
							pcall(function()
								settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
							end)

							if Terrain and not v84 then
								v84 = {
									WaterWaveSize = Terrain.WaterWaveSize,
									WaterWaveSpeed = Terrain.WaterWaveSpeed,
									WaterReflectance = Terrain.WaterReflectance
								}

								pcall(function()
									v84.Decoration = gethiddenproperty(Terrain, "Decoration")
								end)
								pcall(function()
									Terrain.WaterWaveSize = 0
								end)
								pcall(function()
									Terrain.WaterWaveSpeed = 0
								end)
								pcall(function()
									Terrain.WaterReflectance = 0
								end)
								pcall(function()
									sethiddenproperty(Terrain, "Decoration", false)
								end)
							end

							v85 = workspace.DescendantAdded:Connect(func25)
							v86 = Lighting.DescendantAdded:Connect(func25)

							for _, descendant in ipairs(Lighting:GetDescendants()) do
								pcall(function()
									if descendant:IsA("BasePart") then
										if descendant:IsA("Terrain") then
											return
										end

										if not v25[descendant] then
											v25[descendant] = {
												CastShadow = descendant.CastShadow,
												Material = descendant.Material
											}

											if descendant:IsA("MeshPart") then
												v25[descendant].RenderFidelity = descendant.RenderFidelity
												descendant.RenderFidelity = Enum.RenderFidelity.Performance
											end

											descendant.CastShadow = false
											descendant.Material = Enum.Material.SmoothPlastic
											num9 = num9 + 1
										end

										return
									end

									if descendant:IsA("Highlight") then
										if descendant.Name == "RainbowHighlight" then
											return
										end
									end

									for _, v1 in ipairs(tbl18) do
										if descendant:IsA(v1[1]) then
											local v2 = tbl4[descendant]

											if not v2 then
												local tbl = {}
												v2 = tbl
												tbl4[descendant] = tbl
												num9 = num9 + 1
											end

											for k, v3 in pairs(v1[2]) do
												if v2[k] == nil then
													v2[k] = descendant[k]
												end
												descendant[k] = v3
											end

											return
										end
									end
								end)
							end

							task.spawn(function()
								local num = 0

								for _, descendant in ipairs(workspace:GetDescendants()) do
									if num8 ~= v1 then
										return
									end

									pcall(function()
										if descendant:IsA("BasePart") then
											if descendant:IsA("Terrain") then
												return
											end

											if not v25[descendant] then
												v25[descendant] = {
													CastShadow = descendant.CastShadow,
													Material = descendant.Material
												}

												if descendant:IsA("MeshPart") then
													v25[descendant].RenderFidelity = descendant.RenderFidelity
													descendant.RenderFidelity = Enum.RenderFidelity.Performance
												end

												descendant.CastShadow = false
												descendant.Material = Enum.Material.SmoothPlastic
												num9 = num9 + 1
											end

											return
										end

										if descendant:IsA("Highlight") then
											if descendant.Name == "RainbowHighlight" then
												return
											end
										end

										for _, v1 in ipairs(tbl18) do
											if descendant:IsA(v1[1]) then
												local v2 = tbl4[descendant]

												if not v2 then
													local tbl = {}
													v2 = tbl
													tbl4[descendant] = tbl
													num9 = num9 + 1
												end

												for k, v3 in pairs(v1[2]) do
													if v2[k] == nil then
														v2[k] = descendant[k]
													end
													descendant[k] = v3
												end

												return
											end
										end
									end)
									num = num + 1

									if num % 300 == 0 then
										task.wait()
									end
								end

								if num8 == v1 and tbl10 and tbl10.notify then
									pcall(
										tbl10.notify,
										"Boost Performance",
										string.format(
											"Lowered graphics on %d objects. Switch it off to restore them.",
											num9
										),
										5
									)
								end
							end)
						else
							for k3, v5 in pairs(tbl4) do
								if k3 and k3.Parent then
									for k4, v6 in pairs(v5) do
										pcall(function()
											k3[k4] = v6
										end)
									end
								end
							end

							table.clear(tbl4)

							for k5, v7 in pairs(v25) do
								if k5 and k5.Parent then
									pcall(function()
										k5.CastShadow = v7.CastShadow
										k5.Material = v7.Material

										if v7.RenderFidelity then
											k5.RenderFidelity = v7.RenderFidelity
										end
									end)
								end
							end

							table.clear(v25)

							if v83 then
								pcallRef = pcall
								pcallRef(function()
									Lighting.GlobalShadows = v83.GlobalShadows
								end)
								pcallRef(function()
									Lighting.EnvironmentSpecularScale = v83.EnvironmentSpecularScale
								end)
								pcallRef(function()
									Lighting.ShadowSoftness = v83.ShadowSoftness
								end)
								pcallRef(function()
									Lighting.Brightness = v83.Brightness
								end)

								if v83.Technology ~= nil then
									pcall(function()
										sethiddenproperty(Lighting, "Technology", v83.Technology)
									end)
								end

								if v83.Quality then
									pcall(function()
										settings().Rendering.QualityLevel = v83.Quality
									end)
								end

								v83 = nil
							end

							if v84 and Terrain then
								pcallRef1 = pcall
								pcallRef1(function()
									Terrain.WaterWaveSize = v84.WaterWaveSize
								end)
								pcallRef1(function()
									Terrain.WaterWaveSpeed = v84.WaterWaveSpeed
								end)
								pcallRef1(function()
									Terrain.WaterReflectance = v84.WaterReflectance
								end)

								if v84.Decoration ~= nil then
									pcall(function()
										sethiddenproperty(Terrain, "Decoration", v84.Decoration)
									end)
								end
							end

							v84 = nil
						end
					end,
					false
				)
			end

			local v26 = container:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			v26.Scale = tonumber(tbl5.UIScale) or 1
			v26.Parent = container
			bgPanelController = XursedBG.BuildSettingsPanel({
				Parent = v11,
				Config = tbl5,
				BgImage = container:FindFirstChild("CustomBgImage"),
				DimOverlay = decorativeOverlay,
				SaveConfig = function()
					pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))
				end,
				CreateSlider = func5,
				GetAccent = function()
					return color
				end
			})
			func5(
				v11,
				"UI Size",
				70,
				125,
				math.floor(v26.Scale * 100),
				function(arg1)
					local v1 = arg1 / 100
					local Scale = v26.Scale
					v26.Scale = v1
					local v3 = 560 * (Scale - v1) / 2
					local v4 = 360 * (Scale - v1) / 2

					local function func(arg1)
						return
							UDim2.new(
								arg1.X.Scale,
								arg1.X.Offset + v3,
								arg1.Y.Scale,
								arg1.Y.Offset + v4
							)
					end

					uDim21 = func(uDim21)

					if flag3 then
						container.Position = func(container.Position)
					end

					tbl5.UIScale = v1
					pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))
				end,
				true
			)
			tbl1[14](
				{
					Tab = v14,
					Store = v6,
					Folder = "XursedHub",
					HubName = "Main",
					ToggleStates = tbl2,
					ToggleControls = tbl3,
					Config = tbl5,
					Themes = tbl8,
					ApplyTheme = ApplyTheme
				}
			)
			local fpsConn
			local destroyHubX = Instance.new("TextButton")
			destroyHubX.Name = "DestroyHubX"
			destroyHubX.Size = UDim2.new(0, 26, 0, 24)
			destroyHubX.Position = UDim2.new(1, -34, 0, 7)
			destroyHubX.BackgroundColor3 = Color3.fromRGB(190, 38, 62)
			destroyHubX.BorderSizePixel = 0
			destroyHubX.FontFace = fontBold
			destroyHubX.TextSize = 13
			destroyHubX.TextColor3 = Color3.fromRGB(255, 255, 255)
			destroyHubX.Text = "X"
			destroyHubX.ZIndex = 10
			destroyHubX.Parent = container
			local uiCorner8 = Instance.new("UICorner")
			uiCorner8.CornerRadius = UDim.new(0, 7)
			uiCorner8.Parent = destroyHubX
			destroyHubX.MouseButton1Click:Connect(function()
				flag1 = true
				pcall(function()
					tbl1[4]:UnbindFromRenderStep("XursedHubMouse")
				end)
				if fpsConn then
					fpsConn:Disconnect()
				end

				if xursedHubGui then
					xursedHubGui:Destroy()
				end

				if toggleGuiBtn then
					toggleGuiBtn:Destroy()
				end

				if connection then
					connection:Disconnect()
				end

				if v72 then
					v72:Disconnect()
				end

				if v70 then
					v70:Disconnect()
				end

				if v71 then
					v71:Disconnect()
				end

				if v77 then
					v77:Disconnect()
				end

				if v78 then
					v78:Disconnect()
				end

				if v69 then
					v69:Disconnect()
				end

				if v67 then
					v67:Disconnect()
				end

				if v68 then
					v68:Destroy()
				end

				if v74 then
					v74:Disconnect()
				end

				if v75 then
					v75:Disconnect()
				end

				for k in pairs(tbl13) do
					if tbl13[k] then
						pcall(function()
							tbl13[k]:Destroy()
						end)
						tbl13[k] = nil
					end
				end

				if v76 then
					v76:Destroy()
				end

				for _, player in ipairs(tbl1[5]:GetPlayers()) do
					if player.Character then
						local RainbowHighlight = player.Character:FindFirstChild("RainbowHighlight")
						if RainbowHighlight then
							RainbowHighlight:Destroy()
						end
					end
				end

				local XursedHubVoidKill = workspace:FindFirstChild("XursedHubVoidKill")

				if XursedHubVoidKill then
					XursedHubVoidKill:Destroy()
				end
			end)
			local frame1 = Instance.new("Frame")
			frame1.Name = "ProfileCard"
			frame1.Size = UDim2.new(1, 0, 0, 84)
			frame1.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
			frame1.BackgroundTransparency = 0.25
			frame1.BorderSizePixel = 0
			frame1.Parent = v11
			local uiCorner9 = Instance.new("UICorner")
			uiCorner9.CornerRadius = UDim.new(0, 10)
			uiCorner9.Parent = frame1
			local imageLabel1 = Instance.new("ImageLabel")
			imageLabel1.Size = UDim2.new(0, 48, 0, 48)
			imageLabel1.Position = UDim2.new(0, 10, 0.5, -24)
			imageLabel1.BackgroundTransparency = 1
			imageLabel1.Image = ""
			imageLabel1.Parent = frame1
			task.spawn(function()
				pcall(function()
					imageLabel1.Image = tbl1[5]:GetUserThumbnailAsync(
						tbl1[11].UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size150x150
					)
				end)
			end)
			local uiCorner10 = Instance.new("UICorner")
			uiCorner10.CornerRadius = UDim.new(1, 0)
			uiCorner10.Parent = imageLabel1
			local profileUsername = Instance.new("TextBox")
			profileUsername.Name = "ProfileUsername"
			profileUsername.Visible = not tbl5.HideUsernameAndID
			profileUsername.Size = UDim2.new(1, -70, 0, 20)
			profileUsername.Position = UDim2.new(0, 68, 0, 12)
			profileUsername.BackgroundTransparency = 1
			profileUsername.FontFace = fontBold
			profileUsername.TextSize = 13
			profileUsername.TextColor3 = Color3.fromRGB(245, 247, 252)
			profileUsername.Text = tbl1[11].Name
			profileUsername.TextXAlignment = Enum.TextXAlignment.Left
			profileUsername.TextEditable = false
			profileUsername.ClearTextOnFocus = false
			profileUsername.Parent = frame1
			local profileUserId = Instance.new("TextBox")
			profileUserId.Name = "ProfileUserId"
			profileUserId.Visible = not tbl5.HideUsernameAndID
			profileUserId.Size = UDim2.new(1, -70, 0, 20)
			profileUserId.Position = UDim2.new(0, 68, 0, 32)
			profileUserId.BackgroundTransparency = 1
			profileUserId.FontFace = font
			profileUserId.TextSize = 11
			profileUserId.TextColor3 = Color3.fromRGB(200, 204, 220)
			profileUserId.Text = "ID: " .. tostring(tbl1[11].UserId)
			profileUserId.TextXAlignment = Enum.TextXAlignment.Left
			profileUserId.TextEditable = false
			profileUserId.ClearTextOnFocus = false
			profileUserId.Parent = frame1
			local textBox = Instance.new("TextBox")
			textBox.Size = UDim2.new(1, -70, 0, 20)
			textBox.Position = UDim2.new(0, 68, 0, 52)
			textBox.BackgroundTransparency = 1
			textBox.FontFace = font
			textBox.TextSize = 11
			textBox.TextColor3 = Color3.fromRGB(200, 204, 220)
			textBox.Text = "Game ID: " .. tostring(game.PlaceId)
			textBox.TextXAlignment = Enum.TextXAlignment.Left
			textBox.TextEditable = false
			textBox.ClearTextOnFocus = false
			textBox.Parent = frame1

			for _, v27 in ipairs(XursedThemeOrder) do
				local btn = func4(
					v12,
					v27,
					function()
						ApplyTheme(v27)
					end
				)
				btn.Name = "ThemeSwatchBtn"
				btn.BackgroundColor3 = XursedThemes[v27].Surface
				local swatch = Instance.new("Frame")
				swatch.Size = UDim2.new(0, 12, 0, 12)
				swatch.Position = UDim2.new(0, 10, 0.5, -6)
				swatch.BackgroundColor3 = XursedThemes[v27].Accent
				swatch.BorderSizePixel = 0
				swatch.Parent = btn
				local sc = Instance.new("UICorner")
				sc.CornerRadius = UDim.new(1, 0)
				sc.Parent = swatch
			end

			func4(
				v12,
				"Reset Theme",
				function()
					ApplyTheme("Xursed")
				end
			)
			ApplyTheme(tbl5.Theme)

			local function func26()
				local num = 0
				pcall(function()
					num = math.floor(tbl1[11]:GetNetworkPing() * 1000)
				end)

				if num == 0 then
					pcall(function()
						local DataPing = tbl1[8].Network.ServerStatsItem:FindFirstChild("Data Ping")
						if DataPing then
							num = tonumber(tostring(DataPing:GetValue()):match("%d+")) or 0
						end
					end)
				end

				return num
			end

			local function func27(arg1)
				if arg1 <= 0 then
					return "0s"
				end

				local v1 = math.floor(arg1 / 86400)
				local v2 = math.floor(arg1 % 86400 / 3600)
				local v3 = math.floor(arg1 % 3600 / 60)
				local v4 = arg1 % 60

				if v1 > 0 then
					return string.format("%dd %dh %dm %ds", v1, v2, v3, v4)
				end

				if v2 > 0 then
					return string.format("%dh %dm %ds", v2, v3, v4)
				end

				if v3 > 0 then
					return string.format("%dm %ds", v3, v4)
				end

				return string.format("%ds", v4)
			end

			local v28 = os.time()
			local v29 = tbl5.TotalTime or 0
			local v30 = func3(v11, "Total Session Time", "Time used: 0s")
			local v31 = func3(v11, "FPS Counter", "FPS: 0")
			local v32 = func3(v11, "Ping Counter", "Ping: 0 ms")
			fpsConn = tbl1[4].RenderStepped:Connect(function()
				num1 = num1 + 1
			end)
			task.spawn(function()
				while not flag1 do
					num = num1
					num1 = 0
					task.wait(1)
				end
			end)
			task.spawn(function()
				while not flag1 do
					task.wait(1)
					local v1 = os.time() - v28
					tbl5.TotalTime = v29 + v1

					if v1 % 5 == 0 then
						pcall(v2, "XursedHub_Settings.json", tbl1[9]:JSONEncode(tbl5))
					end

					pcall(function()
						v30.ContentLabel.Text = "Time used: " .. func27(tbl5.TotalTime)
						v31.ContentLabel.Text = "FPS: " .. tostring(num)
						v32.ContentLabel.Text = "Ping: " .. tostring((func26())) .. " ms"
					end)
				end
			end)
			func3(v13, "Hub", "Xursed Hub — Slap Battles Edition")
			func3(v13, "UI & Custom Backgrounds", "Xursed Obsidian Glass Engine (Catbox / URL / Asset ID)")
			v6.Start()
		end

		if game.PlaceId ~= 11520107397 then
			return
		end

		local CoreGui = game:GetService("CoreGui")
		pcall(function()
			if type(gethui) == "function" then
				local v1 = gethui()
				if v1 then
					CoreGui = v1
				end
			end
		end)
		local UserInputService = game:GetService("UserInputService")
		local RunService = game:GetService("RunService")
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local TweenService = game:GetService("TweenService")
		local Stats = game:GetService("Stats")
		local HttpService = game:GetService("HttpService")
		game:GetService("TeleportService")
		game:GetService("RbxAnalyticsService")
		local LocalPlayer = Players.LocalPlayer
		local v33 =
			readfile
				or function()
					return nil
				end
		local v34 = writefile or function() end
		local v35 = setclipboard or toclipboard
		local v36 =
			syn and syn.request
				or http and http.request
				or http_request
				or fluxus and fluxus.request
				or request
				or function() end
		local flag10 = false
		local flag11 = false
		local tbl19 = {}

		local function func28()
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				return "Mobile"
			end

			if UserInputService.KeyboardEnabled then
				return "PC"
			end

			if UserInputService.GamepadEnabled then
				return "Console"
			end

			return "Unknown Device"
		end

		local tbl20 = {
			Theme = "Xursed",
			TotalTime = 0,
			AlwaysOnTop = false,
			HideUsernameAndID = false,
			CustomBgUrl = "",
			CustomBgOpacity = 75,
			CustomBgDim = 45,
			CustomBgScaleType = "Crop"
		};
		(function()
			local ok, result = pcall(v33, "XursedHub_Settings.json")

			if ok and type(result) == "string" and result ~= "" then
				local ok1, result1 = pcall(function()
					return HttpService:JSONDecode(result)
				end)
				if ok1 and type(result1) == "table" then
					tbl20 = result1
				end
			end

			local v1 = tbl20
			v1.TotalTime = math.max(0, tonumber(v1.TotalTime) or 0)

			if not tbl20.Theme or not XursedThemes[tbl20.Theme] then
				tbl20.Theme = "Xursed"
			end

			if tbl20.AlwaysOnTop == nil then
				tbl20.AlwaysOnTop = false
			end

			if tbl20.HideUsernameAndID == nil then
				tbl20.HideUsernameAndID = false
			end

			if type(tbl20.CustomBgUrl) ~= "string" then
				tbl20.CustomBgUrl = ""
			end

			tbl20.CustomBgOpacity = math.clamp(tonumber(tbl20.CustomBgOpacity) or 75, 0, 100)
			tbl20.CustomBgDim = math.clamp(tonumber(tbl20.CustomBgDim) or 45, 0, 95)
			if type(tbl20.CustomBgScaleType) ~= "string" or not XursedBG.ScaleEnums[tbl20.CustomBgScaleType] then
				tbl20.CustomBgScaleType = "Crop"
			end
		end)()
		pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))

		local tbl21 = {
			SetApiEnv = true,
			ToggleApiMode = true,
			Ban = true,
			AdminGUI = true,
			WalkSpeedChanged = true,
			SpecialGloveAccess = true,
			PlaySoundRemote = true,
			GRAB = true,
			AntiMobileExploits = true,
			MusicLoaderI = true,
			DEATHBARRIER = true,
			DEATHBARRIER2 = true
		}

		local tbl22 = {game.Workspace, game.Players, game.ReplicatedStorage, game.StarterGui};
		(function()
			for _, v1 in ipairs(tbl22) do
				pcall(function()
					for _, descendant in ipairs(v1:GetDescendants()) do
						if tbl21[descendant.Name] then
							pcall(function()
								descendant:Destroy()
							end)
						end
					end
				end)
			end
		end)()

		for _, v37 in ipairs(tbl22) do
			pcall(function()
				v37.DescendantAdded:Connect(function(descendant)
					if tbl21[descendant.Name] then
						pcall(function()
							descendant:Destroy()
						end)
					end
				end)
			end)
		end

		local function func29(arg1, arg2)
			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if v1 then
				local v2 = typeof(arg2) == "Vector3" and arg2 or Vector3.new(0, 3, 0)
				v1.CFrame = CFrame.new(arg1 + v2)
			end
		end

		if CoreGui:FindFirstChild("XursedHubGui") then
			CoreGui.XursedHubGui:Destroy()
		end

		local xursedHubGui1 = Instance.new("ScreenGui")
		xursedHubGui1.Name = "XursedHubGui"
		xursedHubGui1.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		xursedHubGui1.DisplayOrder = tbl20.AlwaysOnTop and 100000 or 0
		xursedHubGui1.Parent = CoreGui
		local decorativeOverlay1 = Instance.new("Frame")
		decorativeOverlay1.Name = "DecorativeOverlay"
		decorativeOverlay1.Size = UDim2.new(1, 0, 1, 0)
		decorativeOverlay1.Position = UDim2.new(0, 0, 0, 0)
		decorativeOverlay1.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
		decorativeOverlay1.BackgroundTransparency = 1
		decorativeOverlay1.BorderSizePixel = 0
		decorativeOverlay1.ZIndex = 2
		decorativeOverlay1.Visible = false
		decorativeOverlay1.Parent = xursedHubGui1
		local toggleGuiBtn1 = Instance.new("TextButton")
		toggleGuiBtn1.Name = "ToggleGuiBtn"
		toggleGuiBtn1.Size = UDim2.new(0, 118, 0, 34)
		toggleGuiBtn1.Position = UDim2.new(0, 16, 0, 16)
		toggleGuiBtn1.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
		toggleGuiBtn1.BackgroundTransparency = 0.08
		toggleGuiBtn1.BorderSizePixel = 0
		toggleGuiBtn1.AutoButtonColor = false
		toggleGuiBtn1.Text = ""
		toggleGuiBtn1.Parent = xursedHubGui1
		local uiCorner11 = Instance.new("UICorner")
		uiCorner11.CornerRadius = UDim.new(1, 0)
		uiCorner11.Parent = toggleGuiBtn1
		local toggleStroke1 = Instance.new("UIStroke")
		toggleStroke1.Name = "ToggleStroke"
		toggleStroke1.Color = XursedThemes.Xursed.Accent
		toggleStroke1.Thickness = 1.4
		toggleStroke1.Transparency = 0.2
		toggleStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		toggleStroke1.Parent = toggleGuiBtn1
		local toggleDot1 = Instance.new("Frame")
		toggleDot1.Name = "ToggleDot"
		toggleDot1.Size = UDim2.new(0, 8, 0, 8)
		toggleDot1.Position = UDim2.new(0, 12, 0.5, -4)
		toggleDot1.BackgroundColor3 = XursedThemes.Xursed.Accent
		toggleDot1.BorderSizePixel = 0
		toggleDot1.Parent = toggleGuiBtn1
		local toggleDotCorner1 = Instance.new("UICorner")
		toggleDotCorner1.CornerRadius = UDim.new(1, 0)
		toggleDotCorner1.Parent = toggleDot1
		local textLabel7 = Instance.new("TextLabel")
		textLabel7.Size = UDim2.new(1, -24, 1, 0)
		textLabel7.Position = UDim2.new(0, 22, 0, 0)
		textLabel7.BackgroundTransparency = 1
		textLabel7.FontFace = fontBold
		textLabel7.TextSize = 12
		textLabel7.TextColor3 = Color3.fromRGB(245, 247, 252)
		textLabel7.Text = "Hide Xursed"
		textLabel7.Parent = toggleGuiBtn1
		local flag12 = false
		local toggleDragged1 = false
		local v87
		local vector32 = Vector3.new()
		local uDim23 = UDim2.new()
		toggleGuiBtn1.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
			then
				flag12 = true
				toggleDragged1 = false
				v87 = input
				vector32 = input.Position
				uDim23 = toggleGuiBtn1.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if
				flag12
					and v87
					and v87.UserInputType == Enum.UserInputType.MouseButton1
					and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			then
				flag12 = false
				v87 = nil
			end
			if flag12 and v87 then
				local v1 =
					v87.UserInputType == Enum.UserInputType.MouseButton1
						and input.UserInputType == Enum.UserInputType.MouseMovement
				local v2 = v87.UserInputType == Enum.UserInputType.Touch and input == v87

				if v1 or v2 then
					local v3 = input.Position - vector32
					if v3.Magnitude > 6 then
						toggleDragged1 = true
					end
					toggleGuiBtn1.Position = UDim2.new(
						uDim23.X.Scale,
						uDim23.X.Offset + v3.X,
						uDim23.Y.Scale,
						uDim23.Y.Offset + v3.Y
					)
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if
				v87
					and (input == v87
						or v87.UserInputType == Enum.UserInputType.MouseButton1
							and input.UserInputType == Enum.UserInputType.MouseButton1)
			then
				flag12 = false
				v87 = nil
			end
		end)
		local container1 = Instance.new("Frame")
		container1.Name = "Container"
		container1.Size = UDim2.new(0, 0, 0, 0)
		container1.Position = UDim2.new(0.5, 0, 0.5, 0)
		container1.BackgroundColor3 = Color3.fromRGB(14, 13, 20)
		container1.BorderSizePixel = 0
		container1.ClipsDescendants = true
		container1.BackgroundTransparency = 1
		container1.Parent = xursedHubGui1
		local imageLabel2 = Instance.new("ImageLabel")
		imageLabel2.Name = "CustomBgImage"
		imageLabel2.Size = UDim2.new(1, 0, 1, 0)
		imageLabel2.BackgroundTransparency = 1
		imageLabel2.Image = ""
		imageLabel2.ImageTransparency = 1
		imageLabel2.ScaleType = Enum.ScaleType.Crop
		imageLabel2.Visible = false
		imageLabel2.ZIndex = 1
		imageLabel2.ClipsDescendants = true
		imageLabel2.Parent = container1
		local bgCorner1 = Instance.new("UICorner")
		bgCorner1.CornerRadius = UDim.new(0, 14)
		bgCorner1.Parent = imageLabel2
		decorativeOverlay1.Size = UDim2.new(1, 0, 1, 0)
		decorativeOverlay1.Position = UDim2.new(0, 0, 0, 0)
		decorativeOverlay1.ZIndex = 2
		decorativeOverlay1.Parent = container1
		local dimCorner1 = Instance.new("UICorner")
		dimCorner1.CornerRadius = UDim.new(0, 14)
		dimCorner1.Parent = decorativeOverlay1

		local tbl23 = {
			Xursed = XursedThemes.Xursed.Base,
			Amethyst = XursedThemes.Amethyst.Base,
			Abyss = XursedThemes.Abyss.Base,
			Emerald = XursedThemes.Emerald.Base,
			Bloodmoon = XursedThemes.Bloodmoon.Base,
			Solaris = XursedThemes.Solaris.Base,
			Sakura = XursedThemes.Sakura.Base,
			Void = XursedThemes.Void.Base
		}

		local color2 = XursedThemes.Xursed.Accent
		local bgPanelController1
		local onThemeChanged1

		local function ApplyTheme1(arg1)
			local v1 = XursedThemes[arg1] and arg1 or "Xursed"
			local spec = XursedThemes[v1] or XursedThemes.Xursed
			local v2 = spec.Base
			local surf = spec.Surface
			color2 = spec.Accent
			tbl20.Theme = v1
			pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))

			if onThemeChanged1 then
				pcall(onThemeChanged1, color2)
			end
			if toggleStroke1 then
				toggleStroke1.Color = color2
			end
			if toggleDot1 then
				toggleDot1.BackgroundColor3 = color2
			end
			if toggleGuiBtn1 then
				toggleGuiBtn1.BackgroundColor3 = v2
			end
			if bgPanelController1 and bgPanelController1.RefreshAccent then
				pcall(bgPanelController1.RefreshAccent, color2)
			end

			if container1 then
				container1.BackgroundColor3 = v2
				local ThemeGradient = container1:FindFirstChild("ThemeGradient")

				if not ThemeGradient then
					local uiGradient = Instance.new("UIGradient")
					ThemeGradient = uiGradient
					uiGradient.Name = "ThemeGradient"
					uiGradient.Parent = container1
				end

				ThemeGradient.Color = ColorSequence.new(
					{
						ColorSequenceKeypoint.new(0, spec.GradA),
						ColorSequenceKeypoint.new(1, spec.GradB)
					}
				)
				ThemeGradient.Rotation = 135

				local winStroke = container1:FindFirstChild("WindowStroke")
				if winStroke then
					winStroke.Color = color2
				end
				local headerDot = container1:FindFirstChild("HeaderDot")
				if headerDot then
					headerDot.BackgroundColor3 = color2
				end
				local headerDivider = container1:FindFirstChild("HeaderDivider")
				if headerDivider then
					headerDivider.BackgroundColor3 = color2
				end
			end

			if container1 then
				for _, descendant in ipairs(container1:GetDescendants()) do
					if
						descendant:IsA("TextLabel")
							or descendant:IsA("TextButton")
							or descendant:IsA("TextBox")
					then
						if descendant.Name ~= "BgStatus" and descendant.Name ~= "ConfigStatus" then
							descendant.TextColor3 = Color3.fromRGB(244, 245, 252)
						end
					end
					if descendant:IsA("UIStroke") then
						if
							descendant.Name == "TabStroke"
								or descendant.Name == "AccentStroke"
								or descendant.Name == "WindowStroke"
								or descendant.Name == "RowStroke"
						then
							descendant.Color = color2
						end
					elseif descendant:IsA("ScrollingFrame") then
						descendant.ScrollBarImageColor3 = color2
					elseif descendant:IsA("TextButton") then
						local ThemeOutline = descendant:FindFirstChild("ThemeOutline")

						if ThemeOutline then
							ThemeOutline:Destroy()
						end

						if
							descendant.BackgroundTransparency < 1
								and descendant.Name ~= "DestroyHubX"
								and descendant.Name ~= "BgApplyBtn"
								and descendant.Name ~= "BgClearBtn"
								and descendant.Name ~= "BgFitBtn"
								and descendant.Name ~= "ThemeSwatchBtn"
						then
							descendant.BackgroundColor3 = surf
							descendant.BackgroundTransparency = 0.22
						end
					elseif
						descendant:IsA("Frame")
							and (descendant.Name == "HubParagraph"
								or descendant.Name == "CustomBgPanel"
								or descendant.Name == "ProfileCard")
					then
						descendant.BackgroundColor3 = surf
						descendant.BackgroundTransparency = 0.25
					elseif
						descendant:IsA("Frame")
							and (descendant.Name == "ToggleRow" or descendant.Name == "SliderRow")
					then
						descendant.BackgroundColor3 = surf
						descendant.BackgroundTransparency = 0.22
					elseif descendant:IsA("Frame") and descendant.Name == "SliderFill" then
						descendant.BackgroundColor3 = color2
					elseif descendant:IsA("Frame") and descendant.Name == "ToggleTrack" then
						if descendant:GetAttribute("IsOn") == true then
							descendant.BackgroundColor3 = color2
						end
					end
				end
			end
		end

		ApplyTheme1(tbl20.Theme)
		local uiCorner12 = Instance.new("UICorner")
		uiCorner12.CornerRadius = UDim.new(0, 14)
		uiCorner12.Parent = container1
		local windowStroke1 = Instance.new("UIStroke")
		windowStroke1.Name = "WindowStroke"
		windowStroke1.Color = color2
		windowStroke1.Thickness = 1.5
		windowStroke1.Transparency = 0.32
		windowStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		windowStroke1.Parent = container1

		task.spawn(function()
			task.wait(0.1)
			TweenService:Create(
				container1,
				TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0, 560, 0, 360),
					Position = UDim2.new(0.5, -280, 0.5, -180),
					BackgroundTransparency = 0.04
				}
			)
				:Play()
		end)

		local flag13 = true
		func3 = UDim2.new(0.5, -280, 0.5, -180)
		toggleGuiBtn1.MouseButton1Click:Connect(function()
			if toggleDragged1 then
				toggleDragged1 = false
				return
			end
			flag13 = not flag13
			if flag13 then
				textLabel7.Text = "Hide Xursed"
				TweenService:Create(
					container1,
					TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
					{Position = func3, Size = UDim2.new(0, 560, 0, 360)}
				)
					:Play()
			else
				func3 = container1.Position
				textLabel7.Text = "Show Xursed"
				TweenService:Create(
					container1,
					TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
					{
						Position = UDim2.new(func3.X.Scale, func3.X.Offset, 1.5, 0),
						Size = UDim2.new(0, 0, 0, 0)
					}
				)
					:Play()
			end
		end)
		local headerDot1 = Instance.new("Frame")
		headerDot1.Name = "HeaderDot"
		headerDot1.Size = UDim2.new(0, 9, 0, 9)
		headerDot1.Position = UDim2.new(0, 14, 0, 14)
		headerDot1.BackgroundColor3 = color2
		headerDot1.BorderSizePixel = 0
		headerDot1.ZIndex = 5
		headerDot1.Parent = container1
		local headerDotCorner1 = Instance.new("UICorner")
		headerDotCorner1.CornerRadius = UDim.new(1, 0)
		headerDotCorner1.Parent = headerDot1
		local v38 = Instance.new("TextLabel")
		v38.Size = UDim2.new(1, -100, 0, 26)
		v38.Position = UDim2.new(0, 30, 0, 6)
		v38.BackgroundTransparency = 1
		v38.FontFace = fontBold
		v38.TextSize = 15
		v38.TextColor3 = Color3.fromRGB(245, 247, 252)
		v38.Text = "Xursed Hub | Killstreak Only"
		v38.TextXAlignment = Enum.TextXAlignment.Left
		v38.ZIndex = 5
		v38.Parent = container1
		local headerDivider1 = Instance.new("Frame")
		headerDivider1.Name = "HeaderDivider"
		headerDivider1.Size = UDim2.new(1, -24, 0, 1)
		headerDivider1.Position = UDim2.new(0, 12, 0, 37)
		headerDivider1.BackgroundColor3 = color2
		headerDivider1.BackgroundTransparency = 0.72
		headerDivider1.BorderSizePixel = 0
		headerDivider1.ZIndex = 5
		headerDivider1.Parent = container1
		tbl1[15] = Instance.new("ScrollingFrame")
		tbl1[15].Name = "TabContainer"
		tbl1[15].Size = UDim2.new(1, -24, 0, 30)
		tbl1[15].Position = UDim2.new(0, 12, 0, 44)
		tbl1[15].BackgroundTransparency = 1
		tbl1[15].BorderSizePixel = 0
		tbl1[15].CanvasSize = UDim2.new(0, 0, 0, 0)
		tbl1[15].ScrollBarThickness = 0
		tbl1[15].ZIndex = 5
		tbl1[15].Parent = container1
		local uiListLayout4 = Instance.new("UIListLayout")
		uiListLayout4.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout4.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout4.Padding = UDim.new(0, 6)
		uiListLayout4.Parent = tbl1[15]
		local frame2 = Instance.new("Frame")
		frame2.Size = UDim2.new(1, -24, 1, -88)
		frame2.Position = UDim2.new(0, 12, 0, 80)
		frame2.BackgroundTransparency = 1
		frame2.ZIndex = 5
		frame2.Parent = container1
		local tbl24 = {}
		local v88
		local v39 = (function(arg1)
			local tbl = {
				Toggles = {},
				Sliders = {},
				Pins = {},
				AutoRestore = true,
				Pending = {},
				SliderControls = {},
				SliderValues = {},
				Path = arg1,
				Ready = false,
				_queued = false
			}

			if type(readfile) == "function" then
				local ok, result = pcall(readfile, arg1)
				if ok and type(result) == "string" and result ~= "" then
					local ok1, result1 = pcall(function()
						return HttpService:JSONDecode(result)
					end)
					if ok1 and type(result1) == "table" then
						if type(result1.Toggles) == "table" then
							for k, toggle in pairs(result1.Toggles) do
								if type(toggle) == "boolean" then
									tbl.Toggles[k] = toggle
								end
							end
						end

						if type(result1.Sliders) == "table" then
							for k1, slider in pairs(result1.Sliders) do
								if tonumber(slider) then
									tbl.Sliders[k1] = tonumber(slider)
								end
							end
						end

						if result1.AutoRestore == false then
							tbl.AutoRestore = false
						end

						if type(result1.Pins) == "table" then
							for k2, pin in pairs(result1.Pins) do
								if pin == true then
									tbl.Pins[k2] = true
								end
							end
						end
					end
				end
			end

			function tbl.Save()
				if type(writefile) ~= "function" then
					return false
				end
				return
					(pcall(
						writefile,
						arg1,
						HttpService:JSONEncode(
							{
								Toggles = tbl.Toggles,
								Sliders = tbl.Sliders,
								Pins = tbl.Pins,
								AutoRestore = tbl.AutoRestore
							}
						)
					))
			end

			function tbl.QueueSave()
				if tbl._queued then
					return
				end

				tbl._queued = true
				task.delay(
					0.75,
					function()
						tbl._queued = false
						tbl.Save()
					end
				)
			end

			function tbl.Defer(arg1)
				if tbl.Ready then
					task.defer(arg1)
				else
					table.insert(tbl.Pending, arg1)
				end
			end

			function tbl.Start()
				task.spawn(function()
					pcall(function()
						local LocalPlayer = game:GetService("Players").LocalPlayer
						local num = 0

						while
							num < 10
								and not (LocalPlayer.Character
									and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
						do
							task.wait(0.25)
							num = num + 0.25
						end
					end)
					task.wait(0.9)
					tbl.Ready = true
					local Pending = tbl.Pending
					tbl.Pending = {}

					for _, v1 in ipairs(Pending) do
						pcall(v1)
					end
				end)
			end

			function tbl.SetPin(arg1, arg2)
				tbl.Pins[arg1] = arg2 and true or nil
				tbl.QueueSave()
			end

			function tbl.Count()
				local num = 0
				local num1 = 0

				for _ in pairs(tbl.Toggles) do
					num = num + 1
				end

				for _ in pairs(tbl.Sliders) do
					num1 = num1 + 1
				end

				return num, num1
			end

			function tbl.Reset()
				tbl.Toggles = {}
				tbl.Sliders = {}
				tbl.Save()
			end

			function tbl.SnapshotSliders()
				local tbl1 = {}

				for k, sliderValue in pairs(tbl.SliderValues) do
					tbl1[k] = sliderValue
				end

				return tbl1
			end

			return tbl
		end)("XursedHub_Controls_Killstreak.json")

		local tbl25 = {
			Registry = {},
			ByName = {},
			PinPainters = {},
			Accent = color2,
			Dim = Color3.fromRGB(115, 118, 136)
		}
		onThemeChanged1 = function(acc)
			tbl25.Accent = acc
		end

		tbl25.Font = font

		function tbl25.refreshPinned() end

		tbl25.IconOrder = {Search = -3, Pinned = -2, Versions = -1}

		function tbl25.tabNameOf(arg1)
			for k, v1 in pairs(tbl24) do
				if v1.Scroll == arg1 then
					return k
				end
			end
			return "Other"
		end

		function tbl25.register(arg1)
			arg1.TabName = tbl25.tabNameOf(arg1.Tab)
			table.insert(tbl25.Registry, arg1)
			tbl25.ByName[arg1.Name] = arg1
		end

		function tbl25.part(parent, arg2, arg3, arg4, arg5, backgroundColor3, cornerRadius)
			local iconPart = Instance.new("Frame")
			iconPart.Name = "IconPart"
			iconPart.BackgroundColor3 = backgroundColor3
			iconPart.BorderSizePixel = 0
			iconPart.Position = UDim2.fromScale(arg2, arg3)
			iconPart.Size = UDim2.fromScale(arg4, arg5)
			iconPart.Parent = parent

			if cornerRadius then
				local uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = cornerRadius
				uiCorner.Parent = iconPart
			end

			return iconPart
		end

		function tbl25.newIconFrame(parent, name)
			local frame = Instance.new("Frame")
			frame.Name = name
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(0, 14, 0, 14)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.new(0.5, 0, 0.5, 0)
			frame.Parent = parent
			return frame
		end

		function tbl25.drawSearchIcon(arg1, color)
			local v1 = tbl25.newIconFrame(arg1, "SearchIcon")
			local iconRing = Instance.new("Frame")
			iconRing.Name = "IconRing"
			iconRing.BackgroundTransparency = 1
			iconRing.Size = UDim2.fromScale(0.66, 0.66)
			iconRing.Parent = v1
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = iconRing
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = color
			uiStroke.Thickness = 1.6
			uiStroke.Parent = iconRing
			local v2 = tbl25.part(v1, 0.76, 0.76, 0.5, 0.12, color, UDim.new(1, 0))
			v2.AnchorPoint = Vector2.new(0.5, 0.5)
			v2.Rotation = 45
			return v1
		end

		function tbl25.drawPinIcon(arg1, arg2)
			local v1 = tbl25.newIconFrame(arg1, "PinIcon")
			tbl25.part(v1, 0.3, 0.06, 0.4, 0.16, arg2, UDim.new(0, 1))
			tbl25.part(v1, 0.38, 0.22, 0.24, 0.3, arg2)
			tbl25.part(v1, 0.16, 0.5, 0.68, 0.16, arg2, UDim.new(0, 1))
			tbl25.part(v1, 0.45, 0.66, 0.1, 0.3, arg2)
			return v1
		end

		function tbl25.setIconColor(arg1, backgroundColor3)
			for _, descendant in ipairs(arg1:GetDescendants()) do
				if descendant:IsA("UIStroke") then
					descendant.Color = backgroundColor3
				elseif descendant:IsA("Frame") and descendant.Name == "IconPart" then
					descendant.BackgroundColor3 = backgroundColor3
				end
			end
		end

		function tbl25.makePin(parent, arg2, position)
			local pinButton = Instance.new("TextButton")
			pinButton.Name = "PinButton"
			pinButton.Size = UDim2.new(0, 18, 0, 18)
			pinButton.Position = position
			pinButton.BackgroundTransparency = 1
			pinButton.Text = ""
			pinButton.AutoButtonColor = false
			pinButton.ZIndex = parent.ZIndex + 1
			pinButton.Parent = parent
			local v1 = tbl25.drawPinIcon(pinButton, tbl25.Dim)

			local function paint()
				tbl25.setIconColor(v1, v39.Pins[arg2] and tbl25.Accent or tbl25.Dim)
			end

			paint()
			local v2 = tbl25.PinPainters[arg2]

			if not v2 then
				v2 = {}
				tbl25.PinPainters[arg2] = v2
			end

			table.insert(v2, {button = pinButton, paint = paint})
			pinButton.MouseButton1Click:Connect(function()
				v39.SetPin(arg2, not v39.Pins[arg2])

				for i = #v2, 1, -1 do
					local v1 = v2[i]
					if v1.button.Parent then
						pcall(v1.paint)
					else
						table.remove(v2, i)
					end
				end

				tbl25.refreshPinned()
			end)
			return pinButton
		end

		function tbl25.styleRow(parent, arg2)
			parent.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			parent.BorderSizePixel = 0
			parent.Size = UDim2.new(1, 0, 0, arg2)
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 5)
			uiCorner.Parent = parent
		end

		function tbl25.newText(parent, text, size, position)
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = size
			textLabel.Position = position
			textLabel.BackgroundTransparency = 1
			textLabel.FontFace = tbl25.Font
			textLabel.TextSize = 11
			textLabel.TextColor3 = tbl25.Accent
			textLabel.Text = text
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.Parent = parent
			return textLabel
		end

		function tbl25.buildProxyRow(parent, arg2)
			if arg2.Kind == "toggle" then
				local toggleRow = Instance.new("Frame")
				toggleRow.Name = "ToggleRow"
				toggleRow.Parent = parent
				tbl25.styleRow(toggleRow, 28)
				tbl25.newText(
					toggleRow,
					arg2.Name .. "  (" .. arg2.TabName .. ")",
					UDim2.new(1, -70, 1, 0),
					UDim2.new(0, 8, 0, 0)
				)
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(0, 28, 0, 14)
				frame.Position = UDim2.new(1, -34, 0.5, -7)
				frame.BorderSizePixel = 0
				frame.Parent = toggleRow
				local uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = UDim.new(1, 0)
				uiCorner.Parent = frame
				local frame1 = Instance.new("Frame")
				frame1.Size = UDim2.new(0, 10, 0, 10)
				frame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				frame1.BorderSizePixel = 0
				frame1.Parent = frame
				local uiCorner1 = Instance.new("UICorner")
				uiCorner1.CornerRadius = UDim.new(1, 0)
				uiCorner1.Parent = frame1

				local function func()
					local v1 = arg2.Get() == true
					frame.BackgroundColor3 = v1 and tbl25.Accent or Color3.fromRGB(50, 50, 50)
					frame1.Position = v1 and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
				end

				func()
				local textButton = Instance.new("TextButton")
				textButton.Size = UDim2.new(1, 0, 1, 0)
				textButton.BackgroundTransparency = 1
				textButton.Text = ""
				textButton.Parent = toggleRow
				textButton.MouseButton1Click:Connect(function()
					arg2.Set(not (arg2.Get() == true), true)
					func()
				end)
				tbl25.makePin(toggleRow, arg2.Name, UDim2.new(1, -62, 0.5, -9))
			elseif arg2.Kind == "slider" then
				local sliderRow = Instance.new("Frame")
				sliderRow.Name = "SliderRow"
				sliderRow.Parent = parent
				tbl25.styleRow(sliderRow, 28)
				tbl25.newText(
					sliderRow,
					arg2.Name .. "  (" .. arg2.TabName .. ")",
					UDim2.new(1, -130, 1, 0),
					UDim2.new(0, 8, 0, 0)
				)
				local textBox = Instance.new("TextBox")
				textBox.Size = UDim2.new(0, 48, 0, 18)
				textBox.Position = UDim2.new(1, -78, 0.5, -9)
				textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				textBox.BorderSizePixel = 0
				textBox.FontFace = tbl25.Font
				textBox.TextSize = 10
				textBox.TextColor3 = tbl25.Accent
				textBox.ClearTextOnFocus = false
				textBox.Text = tostring(arg2.Get())
				textBox.Parent = sliderRow
				local uiCorner2 = Instance.new("UICorner")
				uiCorner2.CornerRadius = UDim.new(0, 3)
				uiCorner2.Parent = textBox
				textBox.FocusLost:Connect(function()
					local num = tonumber(textBox.Text)

					if num then
						arg2.Set(num, true)
					end

					textBox.Text = tostring(arg2.Get())
				end)
				tbl25.makePin(sliderRow, arg2.Name, UDim2.new(1, -24, 0.5, -9))
			else
				local hubButton = Instance.new("TextButton")
				hubButton.Name = "HubButton"
				hubButton.BorderSizePixel = 0
				hubButton.FontFace = tbl25.Font
				hubButton.TextSize = 11
				hubButton.TextColor3 = tbl25.Accent
				hubButton.Text = arg2.Name .. "  (" .. arg2.TabName .. ")"
				hubButton.Parent = parent
				tbl25.styleRow(hubButton, 28)
				hubButton.MouseButton1Click:Connect(function()
					task.spawn(arg2.Run)
				end)
				tbl25.makePin(hubButton, arg2.Name, UDim2.new(1, -24, 0.5, -9))
			end
		end

		function tbl25.normalize(arg1)
			return (tostring(arg1):lower():gsub("[^%w]", ""))
		end

		function tbl25.subsequence(arg1, arg2)
			local num = 1

			for i = 1, #arg2 do
				local v1 = string.find(arg1, arg2:sub(i, i), num, true)

				if not v1 then
					return false
				end

				num = v1 + 1
			end

			return true
		end

		function tbl25.search(arg1)
			local tbl = {}

			for k in tostring(arg1):gmatch("%S+") do
				local v1 = tbl25.normalize(k)
				if v1 ~= "" then
					table.insert(tbl, v1)
				end
			end

			local tbl1 = {}

			for i, v2 in ipairs(tbl25.Registry) do
				local v3 = tbl25.normalize(v2.Name)
				local v4 = tbl25.normalize(v2.TabName)
				local num = 0
				local flag = true

				for _, v5 in ipairs(tbl) do
					local v6 = string.find(v3, v5, 1, true)
					if v6 then
						num = num + (v6 == 1 and 150 or 100)
					elseif string.find(v4, v5, 1, true) then
						num = num + 20
					elseif #v5 >= 2 and tbl25.subsequence(v3, v5) then
						num = num + 30
					else
						flag = false
						break
					end
				end

				if flag then
					table.insert(tbl1, {entry = v2, score = num - i * 0.001})
				end
			end

			table.sort(
				tbl1,
				function(a, b)
					return a.score > b.score
				end
			)
			return tbl1
		end

		function tbl25.clear(arg1)
			for _, child in ipairs(arg1:GetChildren()) do
				if not child:IsA("UIListLayout") then
					child:Destroy()
				end
			end
		end

		function tbl25.note(arg1, arg2)
			local v1 = tbl25.newText(arg1, arg2, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0))
			v1.TextWrapped = true
			v1.TextSize = 10
			return v1
		end

		local function func31(text, arg2)
			local scrollingFrame = Instance.new("ScrollingFrame")
			scrollingFrame.Name = text .. "Content"
			scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
			scrollingFrame.BackgroundTransparency = 1
			scrollingFrame.BorderSizePixel = 0
			scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			scrollingFrame.ScrollBarThickness = 3
			scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 50, 100)
			scrollingFrame.ScrollBarImageTransparency = 0.4
			scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
			scrollingFrame.Visible = false
			scrollingFrame.Parent = frame2
			local uiListLayout = Instance.new("UIListLayout")
			uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			uiListLayout.Padding = UDim.new(0, 6)
			local uiPadding = Instance.new("UIPadding")
			uiPadding.PaddingRight = UDim.new(0, 6)
			uiPadding.PaddingTop = UDim.new(0, 2)
			uiPadding.Parent = scrollingFrame
			uiListLayout.Parent = scrollingFrame
			uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize")
				:Connect(function()
					scrollingFrame.CanvasSize = UDim2.new(
						0,
						0,
						0,
						uiListLayout.AbsoluteContentSize.Y + 8
					)
				end)
			local frame = Instance.new("Frame")
			frame.Name = text .. "TabBtn"
			frame.Size = UDim2.new(0, 0, 1, 0)
			frame.AutomaticSize = Enum.AutomaticSize.X
			frame.BackgroundTransparency = 0.8
			frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			frame.Parent = tbl1[15]
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 7)
			local tabStroke = Instance.new("UIStroke")
			tabStroke.Name = "TabStroke"
			tabStroke.Color = Color3.fromRGB(220, 50, 100)
			tabStroke.Thickness = 1
			tabStroke.Transparency = 1
			tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			tabStroke.Parent = frame
			uiCorner.Parent = frame
			local uiPadding1 = Instance.new("UIPadding")
			uiPadding1.PaddingLeft = UDim.new(0, 10)
			uiPadding1.PaddingRight = UDim.new(0, 10)
			uiPadding1.Parent = frame
			local textButton = Instance.new("TextButton")
			textButton.Size = UDim2.new(1, 0, 1, 0)
			textButton.BackgroundTransparency = 1
			textButton.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			textButton.TextSize = 12
			textButton.TextColor3 = Color3.fromRGB(245, 247, 252)
			textButton.Text = text
			textButton.AutomaticSize = Enum.AutomaticSize.X
			textButton.Parent = frame

			if arg2 then
				textButton.Text = ""
				textButton.AutomaticSize = Enum.AutomaticSize.None
				textButton.Size = UDim2.new(0, 16, 1, 0)
				frame.LayoutOrder = tbl25.IconOrder[text] or -1
				arg2(textButton, Color3.fromRGB(220, 50, 100))
			end

			uiListLayout4:GetPropertyChangedSignal("AbsoluteContentSize")
				:Connect(function()
					tbl1[15].CanvasSize = UDim2.new(0, uiListLayout4.AbsoluteContentSize.X, 0, 0)
				end)
			textButton.MouseButton1Click:Connect(function()
				for _, v1 in pairs(tbl24) do
					v1.Scroll.Visible = false
					local TabStroke = v1.Button:FindFirstChild("TabStroke")

					if TabStroke then
						TabStroke.Transparency = 1
					end

					v1.Button.BackgroundTransparency = 0.8
				end

				scrollingFrame.Visible = true
				local TabStroke1 = frame:FindFirstChild("TabStroke")

				if TabStroke1 then
					TabStroke1.Transparency = 0.15
				end

				frame.BackgroundTransparency = 0.55
				v88 = text
				local v2 = tbl24[text]

				if v2 and v2.OnShow then
					pcall(v2.OnShow)
				end
			end)

			if not v88 then
				scrollingFrame.Visible = true
				v88 = text
				tabStroke.Transparency = 0.15
				frame.BackgroundTransparency = 0.55
			end

			tbl24[text] = {Scroll = scrollingFrame, Button = frame}
			return scrollingFrame
		end

		local function func32(parent, text, text1)
			local hubParagraph = Instance.new("Frame")
			hubParagraph.Name = "HubParagraph"
			hubParagraph.Size = UDim2.new(1, 0, 0, 56)
			hubParagraph.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			hubParagraph.BackgroundTransparency = 0.4
			hubParagraph.BorderSizePixel = 0
			hubParagraph.Parent = parent
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 8)
			uiCorner.Parent = hubParagraph
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Size = UDim2.new(1, -16, 0, 16)
			titleLabel.Position = UDim2.new(0, 10, 0, 4)
			titleLabel.BackgroundTransparency = 1
			titleLabel.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			titleLabel.TextSize = 12
			titleLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
			titleLabel.Text = text
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.Parent = hubParagraph
			local contentLabel = Instance.new("TextBox")
			contentLabel.Name = "ContentLabel"
			contentLabel.Size = UDim2.new(1, -20, 0, 30)
			contentLabel.Position = UDim2.new(0, 10, 0, 21)
			contentLabel.BackgroundTransparency = 1
			contentLabel.TextSize = 11
			contentLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
			contentLabel.Text = text1
			contentLabel.TextWrapped = true
			contentLabel.TextXAlignment = Enum.TextXAlignment.Left
			contentLabel.TextYAlignment = Enum.TextYAlignment.Top
			contentLabel.TextEditable = false
			contentLabel.ClearTextOnFocus = false
			contentLabel.Parent = hubParagraph
			return hubParagraph
		end

		local function func33(parent, text, arg3)
			local hubButton = Instance.new("TextButton")
			hubButton.Name = "HubButton"
			hubButton.Size = UDim2.new(1, 0, 0, 32)
			hubButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			hubButton.BorderSizePixel = 0
			hubButton.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			hubButton.TextSize = 12
			hubButton.TextColor3 = Color3.fromRGB(245, 247, 252)
			hubButton.Text = text
			hubButton.Parent = parent
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 8)
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = Color3.fromRGB(220, 50, 100)
			uiStroke.Thickness = 1
			uiStroke.Transparency = 0.82
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Parent = hubButton
			uiCorner.Parent = hubButton
			tbl25.makePin(hubButton, text, UDim2.new(1, -24, 0.5, -9))
			tbl25.register({Kind = "button", Name = text, Tab = parent, Run = arg3})
			hubButton.MouseButton1Click:Connect(function()
				local BackgroundColor3 = hubButton.BackgroundColor3
				local v1 = BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.12)
				TweenService:Create(hubButton, TweenInfo.new(0.1), {BackgroundColor3 = v1}):Play()
				task.wait(0.1)
				TweenService:Create(
					hubButton,
					TweenInfo.new(0.1),
					{BackgroundColor3 = BackgroundColor3}
				)
					:Play()
				arg3()
			end)
			return hubButton
		end

		local tbl26 = {}
		local tbl27 = {}

		local function func34(parent, text, arg3, arg4)
			local v1 = arg4
			local v3
			local v2 = arg4 == true

			if v39.AutoRestore and type(v39.Toggles[text]) == "boolean" then
				v3 = v39.Toggles[text]
				v1 = v3
			end

			local toggleRow = Instance.new("Frame")
			toggleRow.Name = "ToggleRow"
			toggleRow.Size = UDim2.new(1, 0, 0, 32)
			toggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			toggleRow.BorderSizePixel = 0
			toggleRow.Parent = parent
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 8)
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = Color3.fromRGB(220, 50, 100)
			uiStroke.Thickness = 1
			uiStroke.Transparency = 0.82
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Parent = toggleRow
			uiCorner.Parent = toggleRow
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, -70, 1, 0)
			textLabel.Position = UDim2.new(0, 12, 0, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			textLabel.TextSize = 12
			textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
			textLabel.Text = text
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.Parent = toggleRow
			local frame = Instance.new("Frame")
			frame.Name = "ToggleTrack"
			frame:SetAttribute("IsOn", v1 == true)
			frame.Size = UDim2.new(0, 36, 0, 18)
			frame.Position = UDim2.new(1, -44, 0.5, -9)
			frame.BackgroundColor3 = v1 == true and color2 or Color3.fromRGB(44, 42, 58)
			frame.BorderSizePixel = 0
			frame.Parent = toggleRow
			local uiCorner1 = Instance.new("UICorner")
			uiCorner1.CornerRadius = UDim.new(1, 0)
			uiCorner1.Parent = frame
			local frame1 = Instance.new("Frame")
			frame1.Size = UDim2.new(0, 14, 0, 14)
			frame1.Position = v1 == true and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			frame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			frame1.BorderSizePixel = 0
			frame1.Parent = frame
			local uiCorner2 = Instance.new("UICorner")
			uiCorner2.CornerRadius = UDim.new(1, 0)
			uiCorner2.Parent = frame1
			local v4 = v1 == true
			tbl26[text] = v4

			local function func(arg1, arg2)
				v4 = arg1 == true
				frame:SetAttribute("IsOn", v4)
				tbl26[text] = v4
				v39.Toggles[text] = v4
				v39.QueueSave()
				local tweenInfo = TweenInfo.new(
					0.16,
					Enum.EasingStyle.Quart,
					Enum.EasingDirection.Out
				)

				if v4 then
					TweenService:Create(frame, tweenInfo, {BackgroundColor3 = color2}):Play()
					TweenService:Create(frame1, tweenInfo, {Position = UDim2.new(1, -16, 0.5, -7)})
						:Play()
				else
					TweenService:Create(
						frame,
						tweenInfo,
						{BackgroundColor3 = Color3.fromRGB(44, 42, 58)}
					)
						:Play()
					TweenService:Create(frame1, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -7)})
						:Play()
				end

				if arg2 then
					pcall(arg3, v4)
				end
			end

			tbl27[text] = func
			local textButton = Instance.new("TextButton")
			textButton.Size = UDim2.new(1, 0, 1, 0)
			textButton.BackgroundTransparency = 1
			textButton.Text = ""
			textButton.Parent = toggleRow
			textButton.MouseButton1Click:Connect(function()
				func(not v4, true)
			end)
			tbl25.makePin(toggleRow, text, UDim2.new(1, -70, 0.5, -9))
			tbl25.register(
				{
					Kind = "toggle",
					Name = text,
					Tab = parent,
					Get = function()
						return v4
					end,
					Set = func,
				}
			)

			if v3 ~= nil and (v3 or v2) then
				v39.Defer(function()
					func(v3, false)
					local ok, result = pcall(arg3, v3)

					if not ok then
						warn(
							"[Xursed Hub] Could not restore toggle '"
								.. tostring(text) .. "': " .. tostring(result)
						)
						tbl.Log(
							"Could not restore saved toggle '" .. tostring(text) .. "'",
							"Turning it back on from your saved config threw an error: "
								.. tostring(result),
							nil,
							"Toggle it manually, or re-save your config."
						)
						func(not v3, false)
					end
				end)
			end
		end

		local function func35(parent, text, arg3, arg4, arg5, arg6, arg7)
			local v1 = arg5
			local v2

			if v39.AutoRestore and tonumber(v39.Sliders[text]) then
				v2 = math.clamp(math.floor(tonumber(v39.Sliders[text]) + 0.5), arg3, arg4)
				v1 = v2
			end

			local sliderRow = Instance.new("Frame")
			sliderRow.Name = "SliderRow"
			sliderRow.Size = UDim2.new(1, 0, 0, 44)
			sliderRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			sliderRow.BorderSizePixel = 0
			sliderRow.Parent = parent
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 8)
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = Color3.fromRGB(220, 50, 100)
			uiStroke.Thickness = 1
			uiStroke.Transparency = 0.82
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Parent = sliderRow
			uiCorner.Parent = sliderRow
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, -76, 0, 18)
			textLabel.Position = UDim2.new(0, 12, 0, 4)
			textLabel.BackgroundTransparency = 1
			textLabel.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			textLabel.TextSize = 12
			textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
			textLabel.Text = text
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.Parent = sliderRow
			local textBox = Instance.new("TextBox")
			textBox.Size = UDim2.new(0, 40, 0, 16)
			textBox.Position = UDim2.new(1, -50, 0, 4)
			textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			textBox.BorderSizePixel = 0
			textBox.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			)
			textBox.TextSize = 10
			textBox.TextColor3 = Color3.fromRGB(245, 247, 252)
			textBox.Text = tostring(v1)
			textBox.Parent = sliderRow
			local uiCorner1 = Instance.new("UICorner")
			uiCorner1.CornerRadius = UDim.new(0, 5)
			uiCorner1.Parent = textBox
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, -24, 0, 7)
			frame.Position = UDim2.new(0, 12, 0, 28)
			frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			frame.BorderSizePixel = 0
			frame.Parent = sliderRow
			local uiCorner2 = Instance.new("UICorner")
			uiCorner2.CornerRadius = UDim.new(1, 0)
			uiCorner2.Parent = frame
			local sliderFill = Instance.new("Frame")
			sliderFill.Name = "SliderFill"
			sliderFill.Size = UDim2.new((v1 - arg3) / (arg4 - arg3), 0, 1, 0)
			sliderFill.BackgroundColor3 = color2
			sliderFill.BorderSizePixel = 0
			sliderFill.Parent = frame
			local uiCorner3 = Instance.new("UICorner")
			uiCorner3.CornerRadius = UDim.new(1, 0)
			uiCorner3.Parent = sliderFill
			local v3

			local function func(arg1)
				v39.Sliders[text] = arg1
				v39.SliderValues[text] = arg1
				v39.QueueSave()
			end

			local function func1(arg1)
				local X = frame.AbsoluteSize.X

				if X <= 0 then
					return
				end

				local v1 = math.clamp(arg1.Position.X - frame.AbsolutePosition.X, 0, X) / X
				sliderFill.Size = UDim2.new(v1, 0, 1, 0)
				local v2 = math.floor(arg3 + (arg4 - arg3) * v1)
				textBox.Text = tostring(v2)
				v39.Sliders[text] = v2
				v39.SliderValues[text] = v2
				v39.QueueSave()

				if arg7 then
					v3 = v2
				else
					arg6(v2)
				end
			end

			local flag = false
			frame.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
				then
					flag = true
					func1(input)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if
					flag
						and (input.UserInputType == Enum.UserInputType.MouseMovement
							or input.UserInputType == Enum.UserInputType.Touch)
				then
					func1(input)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
				then
					if flag and arg7 and v3 ~= nil then
						local v1 = v3
						v3 = nil
						pcall(arg6, v1)
					end
					flag = false
				end
			end)
			textBox.FocusLost:Connect(function()
				local num = tonumber(textBox.Text)
				if num then
					local v1 = math.clamp(num, arg3, arg4)
					textBox.Text = tostring(v1)
					local v2 = arg4 - arg3
					sliderFill.Size = UDim2.new(
						v2 ~= 0 and math.clamp((v1 - arg3) / v2, 0, 1) or 0,
						0,
						1,
						0
					)
					func(v1)
					arg6(v1)
				else
					textBox.Text = tostring(arg5)
					sliderFill.Size = UDim2.new(
						math.clamp((arg5 - arg3) / (arg4 - arg3), 0, 1),
						0,
						1,
						0
					)
					v39.Sliders[text] = arg5
					v39.SliderValues[text] = arg5
					v39.QueueSave()
					arg6(arg5)
				end
			end)
			v39.SliderValues[text] = v1

			local function func2(arg1, arg2)
				local num = tonumber(arg1)

				if not num then
					return
				end

				local v1 = math.clamp(num, arg3, arg4)
				textBox.Text = tostring(v1)
				local v2 = arg4 - arg3
				sliderFill.Size = UDim2.new(
					v2 ~= 0 and math.clamp((v1 - arg3) / v2, 0, 1) or 0,
					0,
					1,
					0
				)
				func(v1)

				if arg2 then
					pcall(arg6, v1)
				end
			end

			v39.SliderControls[text] = func2

			if v2 ~= nil and v2 ~= arg5 then
				v39.Defer(function()
					pcall(arg6, v2)
				end)
			end

			tbl25.makePin(sliderRow, text, UDim2.new(1, -66, 0, 3))
			tbl25.register(
				{
					Kind = "slider",
					Name = text,
					Tab = parent,
					Get = function()
						return v39.SliderValues[text]
					end,
					Set = func2,
				}
			)
		end

		local v40 = func31("Combat")
		local v41 = func31("Teleport")
		local v42 = func31("Misc")
		local v43 = func31("Settings")
		local v44 = func31("Themes")
		local v45 = func31("Credits")
		local v46 = func31("Config")
		local v47 = func31("Search", tbl25.drawSearchIcon)
		local v48 = func31("Pinned", tbl25.drawPinIcon)
		local searchInput1 = Instance.new("TextBox")
		searchInput1.Name = "SearchInput"
		searchInput1.Size = UDim2.new(1, 0, 0, 28)
		searchInput1.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		searchInput1.BorderSizePixel = 0
		searchInput1.FontFace = tbl25.Font
		searchInput1.TextSize = 11
		searchInput1.TextColor3 = tbl25.Accent
		searchInput1.PlaceholderText = "Find the thing you wanna enable using this search bar!"
		searchInput1.Text = ""
		searchInput1.TextXAlignment = Enum.TextXAlignment.Left
		searchInput1.ClearTextOnFocus = false
		searchInput1.Parent = v47
		local uiCorner13 = Instance.new("UICorner")
		uiCorner13.CornerRadius = UDim.new(0, 5)
		uiCorner13.Parent = searchInput1
		local uiPadding3 = Instance.new("UIPadding")
		uiPadding3.PaddingLeft = UDim.new(0, 8)
		uiPadding3.Parent = searchInput1
		local searchResults1 = Instance.new("Frame")
		searchResults1.Name = "SearchResults"
		searchResults1.Size = UDim2.new(1, 0, 0, 0)
		searchResults1.AutomaticSize = Enum.AutomaticSize.Y
		searchResults1.BackgroundTransparency = 1
		searchResults1.BorderSizePixel = 0
		searchResults1.Parent = v47
		local uiListLayout5 = Instance.new("UIListLayout")
		uiListLayout5.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout5.Padding = UDim.new(0, 5)
		uiListLayout5.Parent = searchResults1

		local function OnShow1()
			tbl25.clear(searchResults1)
			local v1 = tbl25.search(searchInput1.Text)

			if #v1 == 0 then
				tbl25.note(searchResults1, "No matching functions.")
				return
			end

			local v2 = math.min(#v1, 30)

			for i = 1, v2 do
				tbl25.buildProxyRow(searchResults1, v1[i].entry)
			end
		end

		searchInput1:GetPropertyChangedSignal("Text"):Connect(OnShow1)
		tbl24.Search.OnShow = OnShow1

		function tbl25.refreshPinned()
			tbl25.clear(v48)
			local flag = false

			for _, v1 in ipairs(tbl25.Registry) do
				if v39.Pins[v1.Name] then
					flag = true
					tbl25.buildProxyRow(v48, v1)
				end
			end

			if not flag then
				tbl25.note(v48, "No pinned controls yet. Click the pin icon on any control to pin it here.")
			end
		end

		tbl24.Pinned.OnShow = tbl25.refreshPinned
		tbl1[14](
			{
				Tab = v46,
				Store = v39,
				Folder = "XursedHub",
				HubName = "Killstreak",
				ToggleStates = tbl26,
				ToggleControls = tbl27,
				Config = tbl20,
				Themes = tbl23,
				ApplyTheme = ApplyTheme1
			}
		)
		local flag14 = false
		local v89
		local vector33 = Vector3.new()
		local uDim24 = UDim2.new()
		container1.InputBegan:Connect(function(input)
			if
				not v89
					and (input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch)
			then
				local ok, result = pcall(function()
					return
						UserInputService:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
				end)

				if ok then
					for _, v1 in ipairs(result) do
						if v1:IsA("TextButton") or v1:IsA("TextBox") or v1.Name == "SliderRow" then
							return
						end
					end
				end

				v89 = input
				flag14 = true
				vector33 = input.Position
				uDim24 = container1.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if
				flag14
					and v89
					and v89.UserInputType == Enum.UserInputType.MouseButton1
					and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			then
				flag14 = false
				v89 = nil
			end
			if flag14 and v89 then
				local v1 =
					v89.UserInputType == Enum.UserInputType.MouseButton1
						and input.UserInputType == Enum.UserInputType.MouseMovement
				local v2 = v89.UserInputType == Enum.UserInputType.Touch and input == v89

				if v1 or v2 then
					local v3 = input.Position - vector33
					container1.Position = UDim2.new(
						uDim24.X.Scale,
						uDim24.X.Offset + v3.X,
						uDim24.Y.Scale,
						uDim24.Y.Offset + v3.Y
					)
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if
				v89
					and (input == v89
						or v89.UserInputType == Enum.UserInputType.MouseButton1
							and input.UserInputType == Enum.UserInputType.MouseButton1)
			then
				flag14 = false
				v89 = nil
			end
		end)

		local function func36()
			local Workspace = game:GetService("Workspace")
			local Safespot = Workspace:FindFirstChild("Safespot")

			if Safespot then
				Safespot:Destroy()
			end

			local ok, result = pcall(function()
				return
					HttpService:JSONDecode(
						' [{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10000,-50,10000,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"Safespot","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":true,"Size":[500,10,500]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10000.2001953125,13,9752.4501953125,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[500,117,5]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10248.2001953125,13,10002.400390625,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart1","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[5,117,496]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[9998.1298828125,13,10247.2001953125,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart2","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[497,117,6]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[9752.7099609375,13,9999.2802734375,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart3","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[7,117,490]},{"CanCollide":true,"Color":[0.6392157077789307,0.6352941393852234,0.6470588445663452],"CFrame":[10001.099609375,76,9999.66015625,1,0,0,0,1,0,0,0,1],"Transparency":0.5,"Name":"DefendPart4","ClassName":"Part","Material":"Enum.Material.Plastic","Anchored":false,"Size":[491,10,491]}] '
					)
			end)

			if ok then
				local safespot = Instance.new("Folder")
				safespot.Name = "Safespot"
				safespot.Parent = Workspace

				for _, v1 in ipairs(result) do
					local instance = Instance.new(v1.ClassName)
					instance.Name = v1.Name
					instance.Size = Vector3.new(unpack(v1.Size))
					instance.CFrame = CFrame.new(unpack(v1.CFrame))
					instance.Transparency = v1.Transparency
					instance.CanCollide = v1.CanCollide
					instance.Anchored = v1.Anchored

					if v1.Color then
						instance.Color = Color3.new(unpack(v1.Color))
					end

					if v1.Material then
						local v2 = v1.Material:gsub("Enum.Material.", "")
						pcall(function()
							instance.Material = Enum.Material[v2]
						end)
					end

					instance.Parent = safespot
				end
			end

			return Workspace:FindFirstChild("Safespot")
		end

		local v90
		local v91
		func34(
			v40,
			"Anti-Void",
			function(arg1)
				if v90 then
					v90:Disconnect()
					v90 = nil
				end

				if v91 then
					v91:Destroy()
					v91 = nil
				end

				if arg1 then
					v91 = Instance.new("Part")
					local v1 = v91
					v1.Name = "AntiVoidPlatform"
					v1.Size = Vector3.new(150, 3, 150)
					v1.Anchored = true
					v1.CanCollide = false
					v1.Transparency = 0.3
					v1.Color = Color3.fromRGB(135, 206, 250)
					v1.Material = Enum.Material.Neon
					v1.Parent = workspace
					v90 = RunService.RenderStepped:Connect(function()
						local Character = LocalPlayer.Character
						local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

						if v1 and v91 and v91.Parent then
							local raycastParams = RaycastParams.new()
							raycastParams.FilterDescendantsInstances = {Character, v91}
							raycastParams.FilterType = Enum.RaycastFilterType.Exclude

							if
								workspace:Raycast(
									v1.Position,
									Vector3.new(0, -500, 0),
									raycastParams
								)
							then
								local v2 = v91
								v2.CanCollide = false
								v2.Position = Vector3.new(0, -9999, 0)
							else
								local v3 = v91
								v3.CanCollide = true
								v3.Position = Vector3.new(v1.Position.X, -15, v1.Position.Z)
							end
						end
					end)
				end
			end
		)
		local num10 = 16
		local num11 = 50
		func35(
			v40,
			"WalkSpeed",
			16,
			500,
			16,
			function(arg1)
				num10 = arg1
			end
		)
		func35(
			v40,
			"JumpPower",
			50,
			500,
			50,
			function(arg1)
				num11 = arg1
			end
		)
		local flag15 = false
		local flag16 = false
		local WalkSpeed1
		local JumpPower1
		local UseJumpPower1
		local connection1 = RunService.Heartbeat:Connect(function()
			if flag10 then
				return
			end
			pcall(function()
				local Character = LocalPlayer.Character
				local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

				if v1 then
					if num10 ~= 16 then
						if not flag15 then
							flag15 = true
							WalkSpeed1 = v1.WalkSpeed
						end
						v1.WalkSpeed = num10
					elseif flag15 then
						flag15 = false
						v1.WalkSpeed = WalkSpeed1 or 16
					end
					if num11 ~= 50 then
						if not flag16 then
							flag16 = true
							JumpPower1 = v1.JumpPower
							UseJumpPower1 = v1.UseJumpPower
						end

						v1.UseJumpPower = true
						v1.JumpPower = num11
					elseif flag16 then
						flag16 = false
						v1.UseJumpPower = UseJumpPower1 ~= false
						v1.JumpPower = JumpPower1 or 50
					end
				end
			end)
		end)
		local v92
		func34(
			v40,
			"Shiftlock",
			function(arg1)
				if v92 then
					v92:Disconnect()
					v92 = nil
				end
				if arg1 then
					v92 = RunService.RenderStepped:Connect(function()
						local Character = LocalPlayer.Character
						local v1 = Character and Character:FindFirstChild("HumanoidRootPart")
						local v2 = Character and Character:FindFirstChildOfClass("Humanoid")

						if Character and v1 and v2 then
							v2.AutoRotate = false
							local CurrentCamera = workspace.CurrentCamera

							if CurrentCamera then
								local LookVector = CurrentCamera.CFrame.LookVector
								local Unit = Vector3.new(LookVector.X, 0, LookVector.Z).Unit

								if Unit.Magnitude > 0 then
									v1.CFrame = CFrame.new(v1.Position, v1.Position + Unit)
								end
							end
						end
					end)
				else
					local Character = LocalPlayer.Character
					local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

					if v1 then
						v1.AutoRotate = true
					end
				end
			end
		)
		local v93
		local v94
		func34(
			v40,
			"Anti Ragdoll",
			function(arg1)
				if v93 then
					v93:Disconnect()
					v93 = nil
				end

				if v94 then
					v94:Disconnect()
					v94 = nil
				end

				if arg1 then
					local function func(character)
						local Humanoid = character:WaitForChild("Humanoid", 5)

						if not Humanoid then
							return
						end

						pcall(function()
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
						end)

						local tbl = {
							"BodyVelocity",
							"LinearVelocity",
							"AngularVelocity",
							"BodyForce",
							"BodyThrust",
							"BodyGyro",
							"RocketPropulsion",
							"VectorForce"
						}

						v93 = RunService.Stepped:Connect(function()
							if not character or not character.Parent or Humanoid.Health <= 0 then
								if v93 then
									v93:Disconnect()
								end
								return
							end
							for _, descendant in ipairs(character:GetDescendants()) do
								if descendant:IsA("Motor6D") then
									descendant.Enabled = true
								else
									for _, v1 in ipairs(tbl) do
										if descendant:IsA(v1) then
											descendant:Destroy()
											break
										end
									end
								end
							end
						end)
					end

					if LocalPlayer.Character then
						task.spawn(function()
							func(LocalPlayer.Character)
						end)
					end

					v94 = LocalPlayer.CharacterAdded:Connect(function(character)
						task.spawn(function()
							func(character)
						end)
					end)
				else
					pcall(function()
						local Character = LocalPlayer.Character
						local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

						if v1 then
							v1:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
							v1:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
							v1:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
						end
					end)
				end
			end
		)
		local v95
		func34(
			v40,
			"ESP",
			function(arg1)
				if v95 then
					v95:Disconnect()
					v95 = nil
				end

				local function func()
					for _, player in ipairs(Players:GetPlayers()) do
						if player.Character then
							local RainbowHighlight = player.Character:FindFirstChild(
								"RainbowHighlight"
							)
							if RainbowHighlight then
								RainbowHighlight:Destroy()
							end
						end
					end
				end

				if arg1 then
					local function func1(parent)
						if not parent then
							return
						end
						if not parent:FindFirstChild("RainbowHighlight") then
							local rainbowHighlight = Instance.new("Highlight")
							rainbowHighlight.Name = "RainbowHighlight"
							rainbowHighlight.FillTransparency = 0.5
							rainbowHighlight.OutlineTransparency = 0
							rainbowHighlight.Parent = parent
						end
					end
					v95 = RunService.RenderStepped:Connect(function()
						local color = Color3.fromHSV(tick() * 1 % 1, 1, 1)
						for _, player in ipairs(Players:GetPlayers()) do
							if player ~= LocalPlayer and player.Character then
								local RainbowHighlight = player.Character:FindFirstChild(
									"RainbowHighlight"
								)
								if RainbowHighlight and RainbowHighlight:IsA("Highlight") then
									RainbowHighlight.FillColor = color
									RainbowHighlight.OutlineColor = color
								else
									func1(player.Character)
								end
							end
						end
					end)
				else
					func()
				end
			end
		)
		local num12 = 25
		local num13 = 0
		local tbl28 = {}
		local v96
		local v97

		local function func37()
			local v1 = LocalPlayer and LocalPlayer.Character
			local v2 = v1 and v1:FindFirstChild("HumanoidRootPart")

			if not v2 then
				return {}
			end

			local tbl = {}

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local v3 = player and player.Character
					local v4 = v3 and v3:FindFirstChild("HumanoidRootPart")

					if v4 then
						local Magnitude = (v4.Position - v2.Position).Magnitude
						tbl[#tbl + 1] = {player = player, root = v4, dist = Magnitude}
					end
				end
			end

			table.sort(
				tbl,
				function(a, b)
					return a.dist < b.dist
				end
			)
			return tbl
		end

		local function func38(player)
			if tbl28[player] and tbl28[player].Parent then
				return tbl28[player]
			end

			local v1 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

			if not v1 then
				return nil
			end

			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Adornee = v1
			selectionBox.Color3 = Color3.fromRGB(255, 255, 255)
			selectionBox.LineThickness = 0.04
			selectionBox.SurfaceTransparency = 1
			selectionBox.Parent = workspace
			tbl28[player] = selectionBox
			return selectionBox
		end

		local function func39(arg1)
			if not arg1 then
				return
			end

			local v1 = tick()

			if v1 - num13 < 0.15 then
				return
			end

			num13 = v1
			local Character = LocalPlayer.Character

			if not Character then
				return
			end

			local Tool = Character:FindFirstChildOfClass("Tool")

			if not Tool then
				return
			end

			local v2 =
				Tool:FindFirstChild("SlapRemote")
					or Tool:FindFirstChild("HitRemote")
					or Tool:FindFirstChild("DamageRemote")

			if v2 and v2:IsA("RemoteEvent") then
				v2:FireServer(arg1.Parent)
			else
				pcall(function()
					Tool:Activate()
				end)
			end
		end

		func35(
			v40,
			"Hitbox Size",
			2,
			100,
			25,
			function(arg1)
				num12 = arg1
			end
		)
		local v49 = setmetatable({}, {__mode = "k"})
		func34(
			v40,
			"Triggerbot + Hitbox",
			function(arg1)
				if v96 then
					v96:Disconnect()
					v96 = nil
				end

				if v97 then
					v97:Disconnect()
					v97 = nil
				end

				if arg1 then
					v96 = RunService.RenderStepped:Connect(function()
						for _, player in ipairs(Players:GetPlayers()) do
							if player ~= LocalPlayer then
								pcall(function()
									local HumanoidRootPart = player.Character.HumanoidRootPart

									if not v49[HumanoidRootPart] then
										v49[HumanoidRootPart] = {
											Size = HumanoidRootPart.Size,
											CanCollide = HumanoidRootPart.CanCollide,
											Transparency = HumanoidRootPart.Transparency
										}
									end

									HumanoidRootPart.Size = Vector3.new(num12, num12, num12)
									HumanoidRootPart.Transparency = 1
									HumanoidRootPart.CanCollide = false
									local v1 = func38(player)

									if v1 then
										v1.Adornee = HumanoidRootPart
									end
								end)
							end
						end
					end)
					v97 = RunService.Heartbeat:Connect(function()
						local v1 = LocalPlayer and LocalPlayer.Character
						local v2 = v1 and v1:FindFirstChild("HumanoidRootPart")

						if not v2 then
							return
						end

						for _, v3 in ipairs((func37())) do
							local v4 = v3.root.Position.X - v2.Position.X
							local v5 = v3.root.Position.Z - v2.Position.Z

							if math.sqrt(v4 * v4 + v5 * v5) <= num12 then
								func39(v3.root)
								break
							end
						end
					end)
				else
					for k in pairs(tbl28) do
						if tbl28[k] then
							pcall(function()
								tbl28[k]:Destroy()
							end)
							tbl28[k] = nil
						end
					end

					for k1, v1 in pairs(v49) do
						pcall(function()
							if k1 and k1.Parent then
								k1.Size = v1.Size
								k1.CanCollide = v1.CanCollide
								k1.Transparency = v1.Transparency
							end
						end)
					end

					table.clear(v49)
				end
			end
		)
		local flag17 = false
		local v98
		local num14 = 0
		local v99
		local v100

		local function func40()
			if v98 then
				v98:Destroy()
				v98 = nil
			end

			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if not v1 then
				return
			end

			v98 = Instance.new("Part")
			local v2 = v98
			v2.Name = "AuraSphere"
			v2.Shape = Enum.PartType.Ball
			v2.Size = Vector3.new(40, 40, 40)
			v2.CFrame = v1.CFrame
			v2.Transparency = 0.5
			v2.Material = Enum.Material.ForceField
			v2.Anchored = true
			v2.CanCollide = false
			v2.Parent = workspace
		end

		func34(
			v40,
			"Slap Aura",
			function(arg1)
				flag17 = arg1

				if v99 then
					v99:Disconnect()
					v99 = nil
				end

				if v100 then
					v100:Disconnect()
					v100 = nil
				end

				if flag17 then
					func40()
					v99 = RunService.RenderStepped:Connect(function()
						local Character = LocalPlayer.Character
						local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

						if v1 then
							if not v98 or not v98.Parent then
								func40()
							else
								local v2 = v98
								v2.CFrame = v1.CFrame
								v2.Color = Color3.fromHSV(tick() * 1 % 1, 1, 1)
							end
						end
					end)
					v100 = RunService.Heartbeat:Connect(function()
						if tick() - num14 < 0.35 then
							return
						end
						pcall(function()
							local Character = LocalPlayer.Character
							local v1 = Character and Character:FindFirstChild("HumanoidRootPart")
							local v2 = Character and Character:FindFirstChildOfClass("Humanoid")

							if v1 and v2 and v2.Health > 0 then
								local v3 =
									Character and Character:FindFirstChildOfClass("Tool")
										or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
								local v4 = v3 and v3.Name or ""
								local str = "GeneralHit"

								if v4 == "Default" then
									str = "b"
								end

								local v5 =
									ReplicatedStorage:FindFirstChild(str)
										or ReplicatedStorage:FindFirstChild("GeneralHit")

								for _, player in ipairs(Players:GetPlayers()) do
									if player ~= LocalPlayer and player.Character then
										local Character1 = player.Character
										local Humanoid = Character1:FindFirstChildOfClass(
											"Humanoid"
										)
										local HumanoidRootPart = Character1:FindFirstChild(
											"HumanoidRootPart"
										)
										local Head = Character1:FindFirstChild("Head")

										if
											HumanoidRootPart and Humanoid and Humanoid.Health > 0
										then
											if
												(HumanoidRootPart.Position - v1.Position).Magnitude <= 20
											then
												local v6 = Head or HumanoidRootPart

												if v4 == "Default" then
													v6 =
														Character1:FindFirstChild("Right Arm")
															or Head
															or HumanoidRootPart
												end

												if v5 then
													v5:FireServer(v6)
													num14 = tick()
													break
												end
											end
										end
									end
								end
							end
						end)
					end)
				elseif v98 then
					v98:Destroy()
					v98 = nil
				end
			end
		)
		func33(
			v41,
			"Teleport To Main Island",
			function()
				func29(Vector3.new(-2, -5, 1))
			end
		)
		func33(
			v41,
			"Slapple Island",
			function()
				func29(Vector3.new(-419, 50, -14))
			end
		)
		func33(
			v41,
			"Moai Island",
			function()
				func29(Vector3.new(236, -16, 2))
			end
		)
		func33(
			v41,
			"Cannon Island",
			function()
				func29(Vector3.new(286, 13, 255))
			end
		)
		func33(
			v41,
			"Rainbow Clouds",
			function()
				func29(Vector3.new(-125, -7, 122))
			end
		)
		func33(
			v41,
			"Cube of Death",
			function()
				func29(Vector3.new(-256, -5, 0), Vector3.new(0, 10, 0))
			end
		)
		func33(
			v41,
			"Arena Default",
			function()
				func29(Vector3.new(126, 360, -2))
			end
		)
		func33(
			v41,
			"Tp to Safe Place",
			function()
				local v1 = func36()
				local v2 = v1 and v1:FindFirstChild("Safespot")

				if v2 and LocalPlayer.Character then
					if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						LocalPlayer.Character.HumanoidRootPart.CFrame =
							v2.CFrame + Vector3.new(0, 5, 0)
					end
				end
			end
		)
		local flag18 = false
		func34(
			v42,
			"Charge Kinetic",
			function(arg1)
				flag18 = arg1
				if arg1 then
					task.spawn(function()
						while flag18 and not flag10 do
							pcall(function()
								local SelfKnockback = ReplicatedStorage:FindFirstChild(
									"SelfKnockback"
								)
								if SelfKnockback then
									SelfKnockback:FireServer(
										{Force = 0, Direction = Vector3.new(-1, 0, 0)}
									)
								end
							end)
							task.wait(0.01)
						end
					end)
				end
			end
		)
		func33(
			v42,
			"INVISIBLE",
			function()
				local v1 =
					LocalPlayer.leaderstats
						and LocalPlayer.leaderstats:FindFirstChild("Glove")
						and LocalPlayer.leaderstats.Glove.Value

				if
					workspace.Lobby:FindFirstChild("Ghost")
						and workspace.Lobby.Ghost:FindFirstChild("ClickDetector")
				then
					fireclickdetector(workspace.Lobby.Ghost.ClickDetector)
				end

				local Ghostinvisibilityactivated = ReplicatedStorage:FindFirstChild(
					"Ghostinvisibilityactivated"
				)

				if Ghostinvisibilityactivated then
					Ghostinvisibilityactivated:FireServer()
				end

				task.wait(0.1)

				if v1 and workspace.Lobby:FindFirstChild(v1) then
					local v2 = workspace.Lobby[v1]
					if v2:FindFirstChild("ClickDetector") then
						fireclickdetector(v2.ClickDetector)
					end
				end
			end
		)

		function tbl25.line(parent, arg2, arg3, arg4, arg5, arg6, backgroundColor3)
			local v1 = arg4 - arg2
			local v2 = arg5 - arg3
			local v3 = math.sqrt(v1 * v1 + v2 * v2)
			local iconPart = Instance.new("Frame")
			iconPart.Name = "IconPart"
			iconPart.AnchorPoint = Vector2.new(0.5, 0.5)
			iconPart.BackgroundColor3 = backgroundColor3
			iconPart.BorderSizePixel = 0
			iconPart.Position = UDim2.fromOffset((arg2 + arg4) / 2, (arg3 + arg5) / 2)
			iconPart.Size = UDim2.fromOffset(v3 + arg6 * 0.4, arg6)
			iconPart.Rotation = math.deg(math.atan2(v2, v1))
			iconPart.Parent = parent
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = iconPart
			return iconPart
		end

		function tbl25.drawVersionIcon(arg1, arg2)
			local v1 = tbl25.newIconFrame(arg1, "VersionIcon")
			tbl25.line(v1, 7, 1.5, 7, 9.5, 1.6, arg2)
			tbl25.line(v1, 3.2, 6, 7, 9.8, 1.6, arg2)
			tbl25.line(v1, 10.8, 6, 7, 9.8, 1.6, arg2)
			tbl25.line(v1, 2.5, 12.5, 11.5, 12.5, 1.6, arg2)
			return v1
		end

		function tbl25.drawRocketIcon(arg1, color)
			local v1 = tbl25.newIconFrame(arg1, "RocketIcon")
			local iconOutline = Instance.new("Frame")
			iconOutline.Name = "IconOutline"
			iconOutline.AnchorPoint = Vector2.new(0.5, 0.5)
			iconOutline.BackgroundTransparency = 1
			iconOutline.BorderSizePixel = 0
			iconOutline.Position = UDim2.fromOffset(8.2, 5.8)
			iconOutline.Size = UDim2.fromOffset(4.6, 9.4)
			iconOutline.Rotation = 45
			iconOutline.Parent = v1
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = iconOutline
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = color
			uiStroke.Thickness = 1.3
			uiStroke.Parent = iconOutline
			tbl25.part(
				v1,
				0.53,
				0.3,
				0.16,
				0.16,
				color,
				UDim.new(1, 0)
			).AnchorPoint = Vector2.new(0.5, 0.5)
			tbl25.line(v1, 1.8, 12.2, 4.8, 9.2, 1.5, color)
			tbl25.line(v1, 1.6, 8.6, 3.6, 6.6, 1.2, color)
			tbl25.line(v1, 5.4, 12.4, 7.4, 10.4, 1.2, color)
			return v1
		end

		function tbl25.notify(text, text1, arg3)
			local v1 = arg3 or 8
			if
				not pcall(function()
					local CurrentCamera = workspace.CurrentCamera
					local v2 = CurrentCamera and CurrentCamera.ViewportSize or Vector2.new(800, 600)
					local v3 = math.clamp(v2.X - 40, 200, 300)
					local HubNotifications = xursedHubGui1:FindFirstChild("HubNotifications")

					if not HubNotifications then
						local frame = Instance.new("Frame")
						HubNotifications = frame
						frame.Name = "HubNotifications"
						frame.AnchorPoint = Vector2.new(1, 1)
						frame.BackgroundTransparency = 1
						frame.ZIndex = 50
						frame.Parent = xursedHubGui1
						local uiListLayout = Instance.new("UIListLayout")
						uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
						uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
						uiListLayout.Padding = UDim.new(0, 8)
						uiListLayout.Parent = frame
					end

					HubNotifications.Position = UDim2.new(1, -16, 1, -28)
					HubNotifications.Size = UDim2.new(0, v3, 1, -56)
					local tbl = {}

					for _, child in ipairs(HubNotifications:GetChildren()) do
						if child.Name == "HubNotification" then
							table.insert(tbl, child)
						end
					end

					while #tbl >= 4 do
						tbl[1]:Destroy()
						table.remove(tbl, 1)
					end

					local v4 = v3 - 24
					local ok, result = pcall(function()
						return
							game:GetService("TextService")
								:GetTextSize(
									text1,
									12,
									Enum.Font.GothamMedium,
									Vector2.new(v4, 10000)
								)
					end)
					local v5

					if ok and result then
						v5 = math.ceil(result.Y) + 4
					else
						v5 = math.ceil(#text1 * 7 / v4) * 15 + 4
					end

					local v6 = 33 + v5 + 5 + 3 + 10
					local hubNotification = Instance.new("Frame")
					hubNotification.Name = "HubNotification"
					hubNotification.Size = UDim2.new(1, 0, 0, v6)
					hubNotification.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
					hubNotification.BackgroundTransparency = 1
					hubNotification.BorderSizePixel = 0
					hubNotification.ZIndex = 50
					hubNotification.Parent = HubNotifications
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 8)
					uiCorner.Parent = hubNotification
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Color = tbl25.Accent
					uiStroke.Thickness = 1.5
					uiStroke.Transparency = 1
					uiStroke.Parent = hubNotification
					local textLabel = Instance.new("TextLabel")
					textLabel.Position = UDim2.new(0, 12, 0, 10)
					textLabel.Size = UDim2.new(1, -24, 0, 18)
					textLabel.BackgroundTransparency = 1
					textLabel.FontFace = tbl25.Font
					textLabel.TextSize = 15
					textLabel.TextColor3 = Color3.fromRGB(245, 247, 252)
					textLabel.TextXAlignment = Enum.TextXAlignment.Left
					textLabel.TextTransparency = 1
					textLabel.Text = text
					textLabel.ZIndex = 51
					textLabel.Parent = hubNotification
					local textLabel1 = Instance.new("TextLabel")
					textLabel1.Position = UDim2.new(0, 12, 0, 33)
					textLabel1.Size = UDim2.new(1, -24, 0, v5)
					textLabel1.BackgroundTransparency = 1
					textLabel1.FontFace = tbl25.Font
					textLabel1.TextSize = 12
					textLabel1.TextColor3 = Color3.fromRGB(225, 225, 225)
					textLabel1.TextWrapped = true
					textLabel1.TextXAlignment = Enum.TextXAlignment.Left
					textLabel1.TextYAlignment = Enum.TextYAlignment.Top
					textLabel1.TextTransparency = 1
					textLabel1.Text = text1
					textLabel1.ZIndex = 51
					textLabel1.Parent = hubNotification
					local frame1 = Instance.new("Frame")
					frame1.Position = UDim2.new(0, 12, 1, -13)
					frame1.Size = UDim2.new(1, -24, 0, 3)
					frame1.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
					frame1.BackgroundTransparency = 1
					frame1.BorderSizePixel = 0
					frame1.ZIndex = 51
					frame1.Parent = hubNotification
					local uiCorner1 = Instance.new("UICorner")
					uiCorner1.CornerRadius = UDim.new(1, 0)
					uiCorner1.Parent = frame1
					local frame2 = Instance.new("Frame")
					frame2.Size = UDim2.new(1, 0, 1, 0)
					frame2.BackgroundColor3 = tbl25.Accent
					frame2.BackgroundTransparency = 1
					frame2.BorderSizePixel = 0
					frame2.ZIndex = 52
					frame2.Parent = frame1
					local uiCorner2 = Instance.new("UICorner")
					uiCorner2.CornerRadius = UDim.new(1, 0)
					uiCorner2.Parent = frame2
					local tweenInfo = TweenInfo.new(
						0.25,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out
					)
					TweenService:Create(hubNotification, tweenInfo, {BackgroundTransparency = 0.05})
						:Play()
					TweenService:Create(uiStroke, tweenInfo, {Transparency = 0}):Play()
					TweenService:Create(textLabel, tweenInfo, {TextTransparency = 0}):Play()
					TweenService:Create(textLabel1, tweenInfo, {TextTransparency = 0}):Play()
					TweenService:Create(frame1, tweenInfo, {BackgroundTransparency = 0}):Play()
					TweenService:Create(frame2, tweenInfo, {BackgroundTransparency = 0}):Play()
					TweenService:Create(
						frame2,
						TweenInfo.new(v1, Enum.EasingStyle.Linear),
						{Size = UDim2.new(0, 0, 1, 0)}
					)
						:Play()
					local flag = false

					local function func()
						if flag then
							return
						end

						flag = true
						local tweenInfo = TweenInfo.new(
							0.25,
							Enum.EasingStyle.Quad,
							Enum.EasingDirection.In
						)
						TweenService:Create(
							hubNotification,
							tweenInfo,
							{BackgroundTransparency = 1}
						)
							:Play()
						TweenService:Create(uiStroke, tweenInfo, {Transparency = 1}):Play()
						TweenService:Create(textLabel, tweenInfo, {TextTransparency = 1}):Play()
						TweenService:Create(textLabel1, tweenInfo, {TextTransparency = 1}):Play()
						TweenService:Create(frame1, tweenInfo, {BackgroundTransparency = 1}):Play()
						TweenService:Create(frame2, tweenInfo, {BackgroundTransparency = 1}):Play()
						task.delay(
							0.3,
							function()
								hubNotification:Destroy()
							end
						)
					end

					local textButton = Instance.new("TextButton")
					textButton.Size = UDim2.new(1, 0, 1, 0)
					textButton.BackgroundTransparency = 1
					textButton.Text = ""
					textButton.ZIndex = 53
					textButton.Parent = hubNotification
					textButton.MouseButton1Click:Connect(func)
					task.delay(v1, func)
				end)
			then
				pcall(function()
					game:GetService("StarterGui")
						:SetCore("SendNotification", {Title = text, Text = text1, Duration = v1})
				end)
			end
		end

		local v101
		func34(
			v42,
			"Infinite Jump",
			function(arg1)
				if v101 then
					v101:Disconnect()
					v101 = nil
				end
				if arg1 then
					v101 = UserInputService.JumpRequest:Connect(function()
						if flag10 then
							return
						end

						local Character = LocalPlayer.Character
						local v1 = Character and Character:FindFirstChildOfClass("Humanoid")

						if v1 and v1.Health > 0 then
							v1:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end)
				end
			end
		)
		local v102
		local num15 = 0
		func34(
			v42,
			"Anti AFK",
			function(arg1)
				num15 = num15 + 1
				local v1 = num15

				if v102 then
					v102:Disconnect()
					v102 = nil
				end

				if not arg1 then
					return
				end

				local VirtualUser = game:GetService("VirtualUser")
				v102 = LocalPlayer.Idled:Connect(function()
					pcall(function()
						VirtualUser:CaptureController()
						VirtualUser:ClickButton2(Vector2.new())
					end)
				end)
				task.spawn(function()
					while task.wait(300) do
						if num15 ~= v1 or flag10 then
							return
						end
						pcall(function()
							VirtualUser:CaptureController()
							VirtualUser:ClickButton2(Vector2.new())
						end)
					end
				end)
			end
		)
		func33(
			v42,
			"Collect All Candy Corns",
			function()
				task.spawn(function()
					local ok, result = pcall(function()
						local v1 =
							workspace:FindFirstChild("CandyCorns")
								or workspace:WaitForChild("CandyCorns", 5)

						if not v1 then
							tbl25.notify(
								"No Candy Corns Found",
								"There are no candy corns in this server right now. Try again when the event is active.",
								5
							)
							return
						end

						local HumanoidRootPart = (LocalPlayer.Character
							or LocalPlayer.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")

						for _, descendant in ipairs(v1:GetDescendants()) do
							if descendant:IsA("BasePart") then
								descendant.CFrame = HumanoidRootPart.CFrame
							end
						end
					end)
					if not ok then
						warn("[Xursed Hub] Collect All Candy Corns failed: " .. tostring(result))
					end
				end)
			end
		)
		func33(
			v42,
			"Autofarm Candy Corns Script",
			function()
				local flag = false

				if type(v35) == "function" then
					flag = pcall(
						v35,
						'loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmaayyy/candy-farm/refs/heads/main/candy-corn-farm"))()'
					)
				end

				if flag then
					tbl25.notify(
						"Xursed Hub",
						"The script has been copied to your clipboard. Paste this script in your AutoExecute folder to start autofarming!",
						10
					)
				else
					tbl25.notify(
						"Xursed Hub",
						"Your executor can't copy to the clipboard, so copy this script yourself and paste it in your AutoExecute folder to start autofarming:\nloadstring(game:HttpGet(\"https://raw.githubusercontent.com/sigmaayyy/candy-farm/refs/heads/main/candy-corn-farm\"))()",
						14
					)
				end
			end
		)
		local v50 = func31("Versions", tbl25.drawVersionIcon)
		local updatesPausedStatus1 = Instance.new("Frame")
		updatesPausedStatus1.Name = "UpdatesPausedStatus"
		updatesPausedStatus1.Size = UDim2.new(1, 0, 0, 26)
		updatesPausedStatus1.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		updatesPausedStatus1.BackgroundTransparency = 0.25
		updatesPausedStatus1.BorderSizePixel = 0
		updatesPausedStatus1.Parent = v50
		local uiCorner14 = Instance.new("UICorner")
		uiCorner14.CornerRadius = UDim.new(0, 7)
		uiCorner14.Parent = updatesPausedStatus1
		local statusIcon1 = Instance.new("TextLabel")
		statusIcon1.Name = "StatusIcon"
		statusIcon1.Size = UDim2.new(0, 24, 1, 0)
		statusIcon1.Position = UDim2.new(0, 8, 0, 0)
		statusIcon1.BackgroundTransparency = 1
		statusIcon1.FontFace = tbl25.Font
		statusIcon1.Text = "●"
		statusIcon1.TextSize = 13
		statusIcon1.TextColor3 = Color3.fromRGB(255, 145, 35)
		statusIcon1.Parent = updatesPausedStatus1
		local textLabel8 = Instance.new("TextLabel")
		textLabel8.Size = UDim2.new(1, -40, 1, 0)
		textLabel8.Position = UDim2.new(0, 30, 0, 0)
		textLabel8.BackgroundTransparency = 1
		textLabel8.FontFace = tbl25.Font
		textLabel8.TextSize = 11
		textLabel8.TextColor3 = Color3.fromRGB(225, 155, 90)
		textLabel8.TextXAlignment = Enum.TextXAlignment.Left
		textLabel8.Text = "Updates Paused"
		textLabel8.Parent = updatesPausedStatus1
		local tweenInfo1 = TweenInfo.new(
			1,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		)
		TweenService:Create(statusIcon1, tweenInfo1, {TextTransparency = 0.72}):Play()
		local versionBox1 = Instance.new("Frame")
		versionBox1.Name = "VersionBox"
		versionBox1.Size = UDim2.new(1, 0, 0, 100)
		versionBox1.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		versionBox1.BackgroundTransparency = 0.2
		versionBox1.BorderSizePixel = 0
		versionBox1.Parent = v50
		local uiCorner15 = Instance.new("UICorner")
		uiCorner15.CornerRadius = UDim.new(0, 8)
		uiCorner15.Parent = versionBox1
		local uiStroke1 = Instance.new("UIStroke")
		uiStroke1.Color = tbl25.Accent
		uiStroke1.Thickness = 1.5
		uiStroke1.Parent = versionBox1
		local textLabel9 = Instance.new("TextLabel")
		textLabel9.Size = UDim2.new(1, 0, 0, 16)
		textLabel9.Position = UDim2.new(0, 0, 0, 10)
		textLabel9.BackgroundTransparency = 1
		textLabel9.FontFace = tbl25.Font
		textLabel9.TextSize = 10
		textLabel9.TextColor3 = Color3.fromRGB(150, 150, 150)
		textLabel9.Text = "VERSION"
		textLabel9.Parent = versionBox1
		local versionLabel1 = Instance.new("TextLabel")
		versionLabel1.Name = "VersionLabel"
		versionLabel1.Size = UDim2.new(1, 0, 0, 44)
		versionLabel1.Position = UDim2.new(0, 0, 0, 28)
		versionLabel1.BackgroundTransparency = 1
		versionLabel1.FontFace = tbl25.Font
		versionLabel1.TextSize = 36
		versionLabel1.TextColor3 = tbl25.Accent
		versionLabel1.Text = "v1.5.5"
		versionLabel1.Parent = versionBox1
		local textLabel10 = Instance.new("TextLabel")
		textLabel10.Size = UDim2.new(1, 0, 0, 16)
		textLabel10.Position = UDim2.new(0, 0, 0, 76)
		textLabel10.BackgroundTransparency = 1
		textLabel10.FontFace = tbl25.Font
		textLabel10.TextSize = 10
		textLabel10.TextColor3 = Color3.fromRGB(150, 150, 150)
		textLabel10.Text = "Current build"
		textLabel10.Parent = versionBox1
		local changelogBox1 = Instance.new("Frame")
		changelogBox1.Name = "ChangelogBox"
		changelogBox1.Size = UDim2.new(1, 0, 0, 0)
		changelogBox1.AutomaticSize = Enum.AutomaticSize.Y
		changelogBox1.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		changelogBox1.BackgroundTransparency = 0.4
		changelogBox1.BorderSizePixel = 0
		changelogBox1.Parent = v50
		local uiCorner16 = Instance.new("UICorner")
		uiCorner16.CornerRadius = UDim.new(0, 5)
		uiCorner16.Parent = changelogBox1
		local uiPadding4 = Instance.new("UIPadding")
		uiPadding4.PaddingLeft = UDim.new(0, 8)
		uiPadding4.PaddingRight = UDim.new(0, 8)
		uiPadding4.PaddingTop = UDim.new(0, 6)
		uiPadding4.PaddingBottom = UDim.new(0, 8)
		uiPadding4.Parent = changelogBox1
		local uiListLayout6 = Instance.new("UIListLayout")
		uiListLayout6.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout6.Padding = UDim.new(0, 4)
		uiListLayout6.Parent = changelogBox1
		local textLabel11 = Instance.new("TextLabel")
		textLabel11.LayoutOrder = 1
		textLabel11.Size = UDim2.new(1, 0, 0, 16)
		textLabel11.BackgroundTransparency = 1
		textLabel11.FontFace = tbl25.Font
		textLabel11.TextSize = 11
		textLabel11.TextColor3 = tbl25.Accent
		textLabel11.TextXAlignment = Enum.TextXAlignment.Left
		textLabel11.Text = "v1.5.5 changes"
		textLabel11.Parent = changelogBox1
		local textLabel12 = Instance.new("TextLabel")
		textLabel12.LayoutOrder = 2
		textLabel12.Size = UDim2.new(1, 0, 0, 0)
		textLabel12.AutomaticSize = Enum.AutomaticSize.Y
		textLabel12.BackgroundTransparency = 1
		textLabel12.FontFace = tbl25.Font
		textLabel12.TextSize = 10
		textLabel12.TextColor3 = tbl25.Accent
		textLabel12.TextWrapped = true
		textLabel12.TextXAlignment = Enum.TextXAlignment.Left
		textLabel12.TextYAlignment = Enum.TextYAlignment.Top
		textLabel12.Text =
			"• Added the Rob features for the Dark Realm\n• Get Guide Gloves now runs in the Guide Bossfight\n• Removed Get Harvester\n• Added new colour themes\n• Cleaned up the hub text and colours"
		textLabel12.Parent = changelogBox1
		local v51 = func31("Leaderboard")
		local tbl29 = {}
		local str3 = "Stat"
		local str4 = ""
		local v103
		local color3 = Color3.fromRGB(205, 205, 205)

		local tbl30 = {
			Color3.fromRGB(255, 205, 70),
			Color3.fromRGB(200, 205, 215),
			Color3.fromRGB(205, 140, 85)
		}

		local function func41(parent, arg2, arg3, arg4, arg5, textSize, textColor3, arg8)
			local textLabel = Instance.new("TextLabel")
			textLabel.BackgroundTransparency = 1
			textLabel.Size = UDim2.new(arg4.Scale, arg4.Offset, 0, arg5)
			textLabel.Position = UDim2.new(arg2.Scale, arg2.Offset, 0, arg3)
			textLabel.FontFace = tbl25.Font
			textLabel.TextSize = textSize
			textLabel.TextColor3 = textColor3
			textLabel.TextXAlignment = arg8 or Enum.TextXAlignment.Left
			textLabel.TextTruncate = Enum.TextTruncate.AtEnd
			textLabel.Text = ""
			textLabel.Parent = parent
			return textLabel
		end

		local function func42(parent, arg2)
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, arg2)
			uiCorner.Parent = parent
			return uiCorner
		end

		local function func43(arg1)
			local str = tostring(math.floor(arg1 + 0.5))
			local v1 = string.reverse(str)
			local v2 = string.gsub(v1, "(%d%d%d)", "%1,")
			local v3 = string.reverse(v2)
			return (string.gsub(v3, "^,", ""))
		end

		local leaderboardHeader1 = Instance.new("Frame")
		leaderboardHeader1.Name = "LeaderboardHeader"
		leaderboardHeader1.LayoutOrder = 1
		leaderboardHeader1.Size = UDim2.new(1, 0, 0, 52)
		leaderboardHeader1.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		leaderboardHeader1.BackgroundTransparency = 0.4
		leaderboardHeader1.BorderSizePixel = 0
		leaderboardHeader1.Parent = v51
		func42(leaderboardHeader1, 5)
		func41(leaderboardHeader1, UDim.new(0, 8), 4, UDim.new(1, -16), 18, 13, tbl25.Accent).Text =
			"Server Leaderboard"
		local v52 = func41(leaderboardHeader1, UDim.new(0, 8), 24, UDim.new(1, -16), 24, 10, color3)
		v52.TextWrapped = true
		v52.TextYAlignment = Enum.TextYAlignment.Top
		local leaderboardControls1 = Instance.new("Frame")
		leaderboardControls1.Name = "LeaderboardControls"
		leaderboardControls1.LayoutOrder = 2
		leaderboardControls1.Size = UDim2.new(1, 0, 0, 28)
		leaderboardControls1.BackgroundTransparency = 1
		leaderboardControls1.Parent = v51
		local leaderboardSearch1 = Instance.new("TextBox")
		leaderboardSearch1.Name = "LeaderboardSearch"
		leaderboardSearch1.Size = UDim2.new(1, -240, 1, 0)
		leaderboardSearch1.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		leaderboardSearch1.BorderSizePixel = 0
		leaderboardSearch1.FontFace = tbl25.Font
		leaderboardSearch1.TextSize = 11
		leaderboardSearch1.TextColor3 = tbl25.Accent
		leaderboardSearch1.PlaceholderText = "Search players..."
		leaderboardSearch1.Text = ""
		leaderboardSearch1.TextXAlignment = Enum.TextXAlignment.Left
		leaderboardSearch1.ClearTextOnFocus = false
		leaderboardSearch1.Parent = leaderboardControls1
		func42(leaderboardSearch1, 5)
		local uiPadding5 = Instance.new("UIPadding")
		uiPadding5.PaddingLeft = UDim.new(0, 8)
		uiPadding5.Parent = leaderboardSearch1
		local tbl31 = {}
		local tbl32 = {"Stat", "Distance", "Health", "Name"}

		local function func44()
			for k, v1 in pairs(tbl31) do
				local v2 = k == str3
				v1.BackgroundColor3 = v2 and tbl25.Accent or Color3.fromRGB(30, 30, 30)
				v1.TextColor3 = v2 and Color3.fromRGB(20, 20, 20) or tbl25.Accent
			end
		end

		local leaderboardRows1 = Instance.new("Frame")
		leaderboardRows1.Name = "LeaderboardRows"
		leaderboardRows1.LayoutOrder = 3
		leaderboardRows1.Size = UDim2.new(1, 0, 0, 0)
		leaderboardRows1.AutomaticSize = Enum.AutomaticSize.Y
		leaderboardRows1.BackgroundTransparency = 1
		leaderboardRows1.Parent = v51
		local uiListLayout7 = Instance.new("UIListLayout")
		uiListLayout7.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout7.Padding = UDim.new(0, 5)
		uiListLayout7.Parent = leaderboardRows1
		local v53 = func41(
			leaderboardRows1,
			UDim.new(0, 0),
			0,
			UDim.new(1, 0),
			24,
			11,
			Color3.fromRGB(130, 130, 130),
			Enum.TextXAlignment.Center
		)
		v53.LayoutOrder = 100000
		v53.Text = "No players match your search."
		v53.Visible = false

		local function func45()
			local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

			if not leaderstats then
				return nil
			end

			if leaderstats:FindFirstChild("Slaps") then
				return "Slaps"
			end

			for _, child in ipairs(leaderstats:GetChildren()) do
				if child:IsA("IntValue") or child:IsA("NumberValue") then
					return child.Name
				end
			end

			return nil
		end

		local function func46(player)
			if player == LocalPlayer then
				return
			end

			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if not v1 then
				tbl25.notify("Can't teleport", "Your character isn't loaded yet.", 3)
				return
			end

			local Character1 = player.Character
			local v2 = Character1 and Character1:FindFirstChild("HumanoidRootPart")

			if not v2 then
				tbl25.notify(
					"Can't teleport",
					player.DisplayName .. " doesn't have a character right now.",
					3
				)
				return
			end

			v1.CFrame = v2.CFrame * CFrame.new(0, 0, 3)
			v1.AssemblyLinearVelocity = Vector3.zero
			tbl25.notify(
				"Teleported",
				"You teleported to " .. player.DisplayName .. " (@" .. player.Name .. ").",
				3
			)
		end

		local function func47(player)
			local leaderboardRow = Instance.new("Frame")
			leaderboardRow.Name = "LeaderboardRow"
			leaderboardRow.Size = UDim2.new(1, 0, 0, 52)
			leaderboardRow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			leaderboardRow.BorderSizePixel = 0
			leaderboardRow.Parent = leaderboardRows1
			func42(leaderboardRow, 6)
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = tbl25.Accent
			uiStroke.Thickness = 1.2
			uiStroke.Transparency = player == LocalPlayer and 0.2 or 1
			uiStroke.Parent = leaderboardRow

			local tbl = {
				Frame = leaderboardRow,
				Rank = func41(
					leaderboardRow,
					UDim.new(0, 4),
					15,
					UDim.new(0, 24),
					20,
					13,
					tbl25.Dim,
					Enum.TextXAlignment.Center
				)
			}

			local avatar = Instance.new("ImageLabel")
			avatar.Name = "Avatar"
			avatar.Size = UDim2.new(0, 36, 0, 36)
			avatar.Position = UDim2.new(0, 30, 0, 8)
			avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			avatar.BorderSizePixel = 0
			avatar.Image = string.format(
				"rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60",
				player.UserId
			)
			avatar.Parent = leaderboardRow
			func42(avatar, 18)
			tbl.Name = func41(
				leaderboardRow,
				UDim.new(0, 72),
				5,
				UDim.new(1, -118),
				15,
				12,
				tbl25.Accent
			)
			tbl.Sub = func41(
				leaderboardRow,
				UDim.new(0, 72),
				20,
				UDim.new(1, -118),
				12,
				9,
				Color3.fromRGB(140, 140, 140)
			)
			tbl.Stats = func41(
				leaderboardRow,
				UDim.new(0, 72),
				32,
				UDim.new(1, -118),
				12,
				10,
				color3
			)
			local healthTrack = Instance.new("Frame")
			healthTrack.Name = "HealthTrack"
			healthTrack.Position = UDim2.new(0, 72, 0, 46)
			healthTrack.Size = UDim2.new(1, -118, 0, 3)
			healthTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			healthTrack.BorderSizePixel = 0
			healthTrack.Parent = leaderboardRow
			func42(healthTrack, 2)
			local healthFill = Instance.new("Frame")
			healthFill.Name = "HealthFill"
			healthFill.Size = UDim2.new(1, 0, 1, 0)
			healthFill.BackgroundColor3 = Color3.fromRGB(90, 220, 110)
			healthFill.BorderSizePixel = 0
			healthFill.Parent = healthTrack
			func42(healthFill, 2)
			tbl.HpFill = healthFill
			local teleportButton = Instance.new("TextButton")
			teleportButton.Name = "TeleportButton"
			teleportButton.Size = UDim2.new(0, 32, 0, 32)
			teleportButton.Position = UDim2.new(1, -40, 0.5, -16)
			teleportButton.BackgroundColor3 = Color3.fromRGB(48, 32, 22)
			teleportButton.BorderSizePixel = 0
			teleportButton.AutoButtonColor = true
			teleportButton.Text = ""
			teleportButton.Parent = leaderboardRow
			func42(teleportButton, 6)
			tbl.RocketIcon = tbl25.drawRocketIcon(
				teleportButton,
				player == LocalPlayer and tbl25.Dim or tbl25.Accent
			)
			tbl.Rocket = teleportButton
			teleportButton.MouseButton1Click:Connect(function()
				func46(player)
			end)
			tbl29[player] = tbl
			return tbl
		end

		local function func48(player, arg2)
			local tbl = {Player = player, Stat = 0}
			tbl.Glove = nil
			tbl.Health = 0
			tbl.MaxHealth = 100
			tbl.Distance = nil
			tbl.Alive = false
			tbl.Arena = nil
			local leaderstats = player:FindFirstChild("leaderstats")

			if leaderstats then
				if v103 then
					local v1 = leaderstats:FindFirstChild(v103)
					if v1 and v1:IsA("ValueBase") then
						tbl.Stat = tonumber(v1.Value) or 0
					end
				end

				local Glove = leaderstats:FindFirstChild("Glove")

				if Glove and Glove:IsA("ValueBase") then
					tbl.Glove = tostring(Glove.Value)
				end
			end

			local Character = player.Character
			local v2 = Character and Character:FindFirstChildOfClass("Humanoid")
			local v3 = Character and Character:FindFirstChild("HumanoidRootPart")

			if v2 then
				tbl.Health = v2.Health
				tbl.MaxHealth = math.max(v2.MaxHealth, 1)
				tbl.Alive = v2.Health > 0
			end

			if v3 and arg2 then
				tbl.Distance = (v3.Position - arg2.Position).Magnitude
			end

			local v4 = Character and Character:FindFirstChild("isInArena")

			if v4 and v4:IsA("ValueBase") then
				tbl.Arena = v4.Value == true
			end

			return tbl
		end

		local function func49(player)
			if str4 == "" then
				return true
			end
			return
				string.find(string.lower(player.Name), str4, 1, true) ~= nil
					or string.find(string.lower(player.DisplayName), str4, 1, true) ~= nil
		end

		local function func50(arg1, arg2, layoutOrder)
			local Player = arg2.Player
			arg1.Frame.LayoutOrder = layoutOrder
			arg1.Rank.Text = tostring(layoutOrder)
			arg1.Rank.TextColor3 = str3 == "Stat" and v103 and tbl30[layoutOrder] or tbl25.Dim
			arg1.Name.Text = Player.DisplayName .. (Player == LocalPlayer and "  (You)" or "")
			arg1.Sub.Text = "@" .. Player.Name .. "  •  ID " .. tostring(Player.UserId)
			local tbl = {}

			if v103 then
				table.insert(tbl, v103 .. " " .. func43(arg2.Stat))
			end

			if arg2.Glove then
				table.insert(tbl, arg2.Glove)
			end

			if arg2.Distance and Player ~= LocalPlayer then
				table.insert(tbl, func43(arg2.Distance) .. " studs")
			end

			if arg2.Arena ~= nil then
				table.insert(tbl, arg2.Arena and "Arena" or "Lobby")
			end

			if not arg2.Alive then
				table.insert(tbl, "No character")
			end

			arg1.Stats.Text = table.concat(tbl, "  •  ")
			local v1 = math.clamp(arg2.Health / arg2.MaxHealth, 0, 1)
			arg1.HpFill.Size = UDim2.new(v1, 0, 1, 0)
			arg1.HpFill.BackgroundColor3 = Color3.fromRGB(
				235,
				70,
				70
			):Lerp(Color3.fromRGB(90, 220, 110), v1)
		end

		local function func51()
			v103 = func45()
			tbl31.Stat.Text = v103 or "Stat"
			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")
			local tbl = {}
			local tbl1 = {}

			for _, player in ipairs(Players:GetPlayers()) do
				tbl1[player] = true
				table.insert(tbl, (func48(player, v1)))
			end

			table.sort(
				tbl,
				function(a, b)
					if str3 == "Distance" then
						local v1 = a.Distance or math.huge
						local v2 = b.Distance or math.huge

						if v1 ~= v2 then
							return v1 < v2
						end
					elseif str3 == "Health" then
						local v3 = a.Health / a.MaxHealth
						local v4 = b.Health / b.MaxHealth

						if v3 ~= v4 then
							return v3 > v4
						end
					elseif str3 == "Name" then
						local v5 = string.lower(a.Player.DisplayName)
						local v6 = string.lower(b.Player.DisplayName)

						if v5 ~= v6 then
							return v5 < v6
						end
					elseif a.Stat ~= b.Stat then
						return a.Stat > b.Stat
					end
					return string.lower(a.Player.Name) < string.lower(b.Player.Name)
				end
			)
			local num = 0
			local v3

			for _, v2 in ipairs(tbl) do
				if not v3 or v2.Stat > v3.Stat then
					v3 = v2
				end

				local v4 = tbl29[v2.Player] or func47(v2.Player)
				local v5 = func49(v2.Player)
				v4.Frame.Visible = v5

				if v5 then
					num = num + 1
					func50(v4, v2, num)
				end
			end

			for k, v6 in pairs(tbl29) do
				if not tbl1[k] then
					v6.Frame:Destroy()
					tbl29[k] = nil
				end
			end

			v53.Visible = num == 0
			local v7 = str3 == "Stat" and (v103 or "Name") or str3
			local v8 = string.format(
				"%d players in this server  •  Showing %d  •  Sorted by %s",
				#tbl,
				num,
				v7
			)

			if v103 and v3 then
				v8 =
					v8
						.. string.format(
							"\nTop player: %s (%s %s)",
							v3.Player.DisplayName,
							v103,
							(func43(v3.Stat))
						)
			end

			v52.Text = v8
		end

		for i1, v54 in ipairs(tbl32) do
			local textButton1 = Instance.new("TextButton")
			textButton1.Name = v54 .. "Sort"
			textButton1.Size = UDim2.new(0, 54, 1, 0)
			textButton1.Position = UDim2.new(1, -(5 - i1) * 58 + 4, 0, 0)
			textButton1.BorderSizePixel = 0
			textButton1.FontFace = tbl25.Font
			textButton1.TextSize = 10
			textButton1.Text = v54
			textButton1.AutoButtonColor = false
			textButton1.Parent = leaderboardControls1
			local uiCorner17 = Instance.new("UICorner")
			uiCorner17.CornerRadius = UDim.new(0, 5)
			uiCorner17.Parent = textButton1
			tbl31[v54] = textButton1
			textButton1.MouseButton1Click:Connect(function()
				str3 = v54
				func44()
				pcall(func51)
			end)
		end

		func44()
		leaderboardSearch1:GetPropertyChangedSignal("Text")
			:Connect(function()
				str4 = string.lower(leaderboardSearch1.Text)
				pcall(func51)
			end)
		Players.PlayerRemoving:Connect(function(player)
			local v1 = tbl29[player]
			if v1 then
				v1.Frame:Destroy()
				tbl29[player] = nil
			end
		end)

		function tbl24.Leaderboard.OnShow()
			pcall(func51)
		end

		task.spawn(function()
			while not flag10 do
				task.wait(1)
				if v88 == "Leaderboard" and flag13 then
					pcall(func51)
				end
			end
		end)
		local v104
		func34(
			v43,
			"Always Die When In Void",
			function(arg1)
				if v104 then
					v104:Destroy()
					v104 = nil
				end

				if not arg1 then
					return
				end

				local xursedHubVoidKill = Instance.new("Folder")
				xursedHubVoidKill.Name = "XursedHubVoidKill"
				xursedHubVoidKill.Parent = workspace
				v104 = xursedHubVoidKill
				local vector3 = Vector3.new(-39, -75, 107)

				for i = -2, 2 do
					for i1 = -2, 2 do
						local voidKillPart = Instance.new("Part")
						voidKillPart.Name = "VoidKillPart"
						voidKillPart.Size = Vector3.new(2048, 50, 2048)
						voidKillPart.Position = vector3 + Vector3.new(i * 2048, 0, i1 * 2048)
						voidKillPart.Anchored = true
						voidKillPart.CanCollide = false
						voidKillPart.CanQuery = false
						voidKillPart.CanTouch = true
						voidKillPart.CastShadow = false
						voidKillPart.Transparency = 0.85
						voidKillPart.Color = Color3.fromRGB(255, 0, 0)
						voidKillPart.Material = Enum.Material.Neon
						voidKillPart.Parent = xursedHubVoidKill
						voidKillPart.Touched:Connect(function(hit)
							local Character = LocalPlayer.Character

							if not Character or not hit or not hit:IsDescendantOf(Character) then
								return
							end

							local Humanoid = Character:FindFirstChildOfClass("Humanoid")

							if Humanoid and Humanoid.Health > 0 then
								Humanoid.Health = 0
							end
						end)
					end
				end
			end
		)
		func34(
			v43,
			"Always On-Top",
			function(alwaysOnTop)
				tbl20.AlwaysOnTop = alwaysOnTop
				xursedHubGui1.DisplayOrder = alwaysOnTop and 100000 or 0
				pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))
			end,
			tbl20.AlwaysOnTop == true
		)
		func34(
			v43,
			"Hide Username & ID",
			function(hideUsernameAndID)
				tbl20.HideUsernameAndID = hideUsernameAndID

				for _, descendant in ipairs(xursedHubGui1:GetDescendants()) do
					if
						descendant.Name == "ProfileUsername" or descendant.Name == "ProfileUserId"
					then
						descendant.Visible = not hideUsernameAndID
					end
				end

				pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))
			end,
			tbl20.HideUsernameAndID == true
		)
		local v55 = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local flag19 = false
		local mouseFreeModal1 = Instance.new("TextButton")
		mouseFreeModal1.Name = "MouseFreeModal"
		mouseFreeModal1.BackgroundTransparency = 1
		mouseFreeModal1.Size = UDim2.new(0, 0, 0, 0)
		mouseFreeModal1.Text = ""
		mouseFreeModal1.Active = false
		mouseFreeModal1.Selectable = false
		mouseFreeModal1.Modal = false
		mouseFreeModal1.Parent = xursedHubGui1

		local function func52(arg1)
			flag19 = arg1 == true

			if v55 then
				return
			end

			pcall(function()
				RunService:UnbindFromRenderStep("XursedHubMouse")
			end)
			mouseFreeModal1.Modal = false

			if flag19 then
				RunService:BindToRenderStep(
					"XursedHubMouse",
					Enum.RenderPriority.Camera.Value + 1,
					function()
						if flag10 then
							mouseFreeModal1.Modal = false
							return
						end

						local rmbHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
						if rmbHeld or not flag13 then
							mouseFreeModal1.Modal = false
							return
						end

						mouseFreeModal1.Modal = true
						if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
							UserInputService.MouseBehavior = Enum.MouseBehavior.Default
						end
						UserInputService.MouseIconEnabled = true
					end
				)
			end
		end

		local v56 = v39.Toggles["Lock/Free Mouse"]
		func52(not v55 and v39.AutoRestore and v56 == true)
		func34(v43, "Lock/Free Mouse", func52, false)
		local v57 = type(tbl20.MouseKeybind) == "string" and tbl20.MouseKeybind or "M"
		local flag20 = false
		local hubButton1 = Instance.new("TextButton")
		hubButton1.Name = "HubButton"
		hubButton1.Size = UDim2.new(1, 0, 0, 28)
		hubButton1.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		hubButton1.BorderSizePixel = 0
		hubButton1.FontFace = tbl25.Font
		hubButton1.TextSize = 11
		hubButton1.TextColor3 = tbl25.Accent
		hubButton1.Parent = v43
		local uiCorner18 = Instance.new("UICorner")
		uiCorner18.CornerRadius = UDim.new(0, 5)
		uiCorner18.Parent = hubButton1

		if v55 then
			hubButton1.Text = "Lock/Free Mouse Keybind: not available on mobile"
			hubButton1.AutoButtonColor = false
			hubButton1.Active = false
			hubButton1.TextTransparency = 0.5
		else
			hubButton1.Text = "Lock/Free Mouse Keybind: " .. v57
			hubButton1.MouseButton1Click:Connect(function()
				if flag20 then
					return
				end

				flag20 = true
				hubButton1.Text = "Press a key... (Esc to cancel)"
			end)
			UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if flag10 or input.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end

				if flag20 then
					flag20 = false

					if
						input.KeyCode ~= Enum.KeyCode.Escape
							and input.KeyCode ~= Enum.KeyCode.Unknown
					then
						v57 = input.KeyCode.Name
						tbl20.MouseKeybind = v57
						pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))
					end

					hubButton1.Text = "Lock/Free Mouse Keybind: " .. v57
					return
				end

				if gameProcessed then
					return
				end

				if input.KeyCode.Name == v57 then
					local v1 = tbl27["Lock/Free Mouse"]
					if v1 then
						v1(not flag19, true)
					end
				end
			end)
		end

		local tbl33 = {
			{"ParticleEmitter", {Enabled = false}},
			{"Trail", {Enabled = false}},
			{"Beam", {Enabled = false}},
			{"Fire", {Enabled = false}},
			{"Smoke", {Enabled = false}},
			{"Sparkles", {Enabled = false}},
			{"PointLight", {Enabled = false}},
			{"SpotLight", {Enabled = false}},
			{"SurfaceLight", {Enabled = false}},
			{"PostEffect", {Enabled = false}},
			{"Explosion", {Visible = false}},
			{"ForceField", {Visible = false}},
			{"Atmosphere", {Density = 0, Haze = 0, Glare = 0}},
			{"Clouds", {Enabled = false}}
		}

		local v58 = setmetatable({}, {__mode = "k"})
		local v105
		local v106
		local v107
		local v108
		local num16 = 0
		local num17 = 0

		local function func53(arg1)
			pcall(function()
				if arg1:IsA("BasePart") then
					if arg1:IsA("Terrain") then
						return
					end

					if not v58[arg1] then
						v58[arg1] = {CastShadow = arg1.CastShadow, Material = arg1.Material}

						if arg1:IsA("MeshPart") then
							v58[arg1].RenderFidelity = arg1.RenderFidelity
							arg1.RenderFidelity = Enum.RenderFidelity.Performance
						end

						arg1.CastShadow = false
						arg1.Material = Enum.Material.SmoothPlastic
						num17 = num17 + 1
					end

					return
				end

				if arg1:IsA("Highlight") then
					if arg1.Name == "RainbowHighlight" then
						return
					end
				end

				for _, v1 in ipairs(tbl33) do
					if arg1:IsA(v1[1]) then
						local v2 = tbl19[arg1]

						if not v2 then
							local tbl = {}
							v2 = tbl
							tbl19[arg1] = tbl
							num17 = num17 + 1
						end

						for k, v3 in pairs(v1[2]) do
							if v2[k] == nil then
								v2[k] = arg1[k]
							end
							arg1[k] = v3
						end

						return
					end
				end
			end)
		end

		func34(
			v43,
			"Boost Performance",
			function(arg1)
				flag11 = arg1 == true
				num16 = num16 + 1
				local v1 = num16
				local Lighting = game:GetService("Lighting")
				local Terrain = workspace:FindFirstChildOfClass("Terrain")

				if v107 then
					v107:Disconnect()
					v107 = nil
				end

				if v108 then
					v108:Disconnect()
					v108 = nil
				end

				local pcallRef, pcallRef1

				if decorativeOverlay1 then
					decorativeOverlay1.Visible = false
					if flag11 then
						for _, child in ipairs(decorativeOverlay1:GetChildren()) do
							child:Destroy()
						end
					else
						for k, v2 in pairs(tbl19) do
							if k and k.Parent then
								for k1, v3 in pairs(v2) do
									pcall(function()
										k[k1] = v3
									end)
								end
							end
						end

						table.clear(tbl19)

						for k2, v4 in pairs(v58) do
							if k2 and k2.Parent then
								pcall(function()
									k2.CastShadow = v4.CastShadow
									k2.Material = v4.Material

									if v4.RenderFidelity then
										k2.RenderFidelity = v4.RenderFidelity
									end
								end)
							end
						end

						table.clear(v58)

						if v105 then
							pcallRef = pcall
							pcallRef(function()
								Lighting.GlobalShadows = v105.GlobalShadows
							end)
							pcallRef(function()
								Lighting.EnvironmentSpecularScale = v105.EnvironmentSpecularScale
							end)
							pcallRef(function()
								Lighting.ShadowSoftness = v105.ShadowSoftness
							end)
							pcallRef(function()
								Lighting.Brightness = v105.Brightness
							end)

							if v105.Technology ~= nil then
								pcall(function()
									sethiddenproperty(Lighting, "Technology", v105.Technology)
								end)
							end

							if v105.Quality then
								pcall(function()
									settings().Rendering.QualityLevel = v105.Quality
								end)
							end

							v105 = nil
						end

						if v106 and Terrain then
							pcallRef1 = pcall
							pcallRef1(function()
								Terrain.WaterWaveSize = v106.WaterWaveSize
							end)
							pcallRef1(function()
								Terrain.WaterWaveSpeed = v106.WaterWaveSpeed
							end)
							pcallRef1(function()
								Terrain.WaterReflectance = v106.WaterReflectance
							end)

							if v106.Decoration ~= nil then
								pcall(function()
									sethiddenproperty(Terrain, "Decoration", v106.Decoration)
								end)
							end
						end

						v106 = nil
						return
					end
				end

				if flag11 then
					num17 = 0

					if not v105 then
						v105 = {
							GlobalShadows = Lighting.GlobalShadows,
							EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
							ShadowSoftness = Lighting.ShadowSoftness,
							Brightness = Lighting.Brightness
						}

						pcall(function()
							v105.Quality = settings().Rendering.QualityLevel
						end)
						pcall(function()
							v105.Technology = gethiddenproperty(Lighting, "Technology")
						end)
					end

					pcall(function()
						Lighting.GlobalShadows = false
					end)
					pcall(function()
						Lighting.EnvironmentSpecularScale = 0
					end)
					pcall(function()
						Lighting.ShadowSoftness = 0
					end)
					pcall(function()
						sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
					end)
					pcall(function()
						settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
					end)

					if Terrain and not v106 then
						v106 = {
							WaterWaveSize = Terrain.WaterWaveSize,
							WaterWaveSpeed = Terrain.WaterWaveSpeed,
							WaterReflectance = Terrain.WaterReflectance
						}

						pcall(function()
							v106.Decoration = gethiddenproperty(Terrain, "Decoration")
						end)
						pcall(function()
							Terrain.WaterWaveSize = 0
						end)
						pcall(function()
							Terrain.WaterWaveSpeed = 0
						end)
						pcall(function()
							Terrain.WaterReflectance = 0
						end)
						pcall(function()
							sethiddenproperty(Terrain, "Decoration", false)
						end)
					end

					v107 = workspace.DescendantAdded:Connect(func53)
					v108 = Lighting.DescendantAdded:Connect(func53)

					for _, descendant in ipairs(Lighting:GetDescendants()) do
						pcall(function()
							if descendant:IsA("BasePart") then
								if descendant:IsA("Terrain") then
									return
								end

								if not v58[descendant] then
									v58[descendant] = {
										CastShadow = descendant.CastShadow,
										Material = descendant.Material
									}

									if descendant:IsA("MeshPart") then
										v58[descendant].RenderFidelity = descendant.RenderFidelity
										descendant.RenderFidelity = Enum.RenderFidelity.Performance
									end

									descendant.CastShadow = false
									descendant.Material = Enum.Material.SmoothPlastic
									num17 = num17 + 1
								end

								return
							end

							if descendant:IsA("Highlight") then
								if descendant.Name == "RainbowHighlight" then
									return
								end
							end

							for _, v1 in ipairs(tbl33) do
								if descendant:IsA(v1[1]) then
									local v2 = tbl19[descendant]

									if not v2 then
										local tbl = {}
										v2 = tbl
										tbl19[descendant] = tbl
										num17 = num17 + 1
									end

									for k, v3 in pairs(v1[2]) do
										if v2[k] == nil then
											v2[k] = descendant[k]
										end
										descendant[k] = v3
									end

									return
								end
							end
						end)
					end

					task.spawn(function()
						local num = 0

						for _, descendant in ipairs(workspace:GetDescendants()) do
							if num16 ~= v1 then
								return
							end

							pcall(function()
								if descendant:IsA("BasePart") then
									if descendant:IsA("Terrain") then
										return
									end

									if not v58[descendant] then
										v58[descendant] = {
											CastShadow = descendant.CastShadow,
											Material = descendant.Material
										}

										if descendant:IsA("MeshPart") then
											v58[descendant].RenderFidelity = descendant.RenderFidelity
											descendant.RenderFidelity = Enum.RenderFidelity.Performance
										end

										descendant.CastShadow = false
										descendant.Material = Enum.Material.SmoothPlastic
										num17 = num17 + 1
									end

									return
								end

								if descendant:IsA("Highlight") then
									if descendant.Name == "RainbowHighlight" then
										return
									end
								end

								for _, v1 in ipairs(tbl33) do
									if descendant:IsA(v1[1]) then
										local v2 = tbl19[descendant]

										if not v2 then
											local tbl = {}
											v2 = tbl
											tbl19[descendant] = tbl
											num17 = num17 + 1
										end

										for k, v3 in pairs(v1[2]) do
											if v2[k] == nil then
												v2[k] = descendant[k]
											end
											descendant[k] = v3
										end

										return
									end
								end
							end)
							num = num + 1

							if num % 300 == 0 then
								task.wait()
							end
						end

						if num16 == v1 and tbl25 and tbl25.notify then
							pcall(
								tbl25.notify,
								"Boost Performance",
								string.format(
									"Lowered graphics on %d objects. Switch it off to restore them.",
									num17
								),
								5
							)
						end
					end)
				else
					for k3, v5 in pairs(tbl19) do
						if k3 and k3.Parent then
							for k4, v6 in pairs(v5) do
								pcall(function()
									k3[k4] = v6
								end)
							end
						end
					end

					table.clear(tbl19)

					for k5, v7 in pairs(v58) do
						if k5 and k5.Parent then
							pcall(function()
								k5.CastShadow = v7.CastShadow
								k5.Material = v7.Material

								if v7.RenderFidelity then
									k5.RenderFidelity = v7.RenderFidelity
								end
							end)
						end
					end

					table.clear(v58)

					if v105 then
						pcallRef = pcall
						pcallRef(function()
							Lighting.GlobalShadows = v105.GlobalShadows
						end)
						pcallRef(function()
							Lighting.EnvironmentSpecularScale = v105.EnvironmentSpecularScale
						end)
						pcallRef(function()
							Lighting.ShadowSoftness = v105.ShadowSoftness
						end)
						pcallRef(function()
							Lighting.Brightness = v105.Brightness
						end)

						if v105.Technology ~= nil then
							pcall(function()
								sethiddenproperty(Lighting, "Technology", v105.Technology)
							end)
						end

						if v105.Quality then
							pcall(function()
								settings().Rendering.QualityLevel = v105.Quality
							end)
						end

						v105 = nil
					end

					if v106 and Terrain then
						pcallRef1 = pcall
						pcallRef1(function()
							Terrain.WaterWaveSize = v106.WaterWaveSize
						end)
						pcallRef1(function()
							Terrain.WaterWaveSpeed = v106.WaterWaveSpeed
						end)
						pcallRef1(function()
							Terrain.WaterReflectance = v106.WaterReflectance
						end)

						if v106.Decoration ~= nil then
							pcall(function()
								sethiddenproperty(Terrain, "Decoration", v106.Decoration)
							end)
						end
					end

					v106 = nil
				end
			end,
			false
		)
		bgPanelController1 = XursedBG.BuildSettingsPanel({
			Parent = v43,
			Config = tbl20,
			BgImage = container1:FindFirstChild("CustomBgImage"),
			DimOverlay = decorativeOverlay1,
			SaveConfig = function()
				pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))
			end,
			CreateSlider = func35,
			GetAccent = function()
				return color2
			end
		})
		local fpsConn1
		local destroyHubX1 = Instance.new("TextButton")
		destroyHubX1.Name = "DestroyHubX"
		destroyHubX1.Size = UDim2.new(0, 26, 0, 24)
		destroyHubX1.Position = UDim2.new(1, -34, 0, 7)
		destroyHubX1.BackgroundColor3 = Color3.fromRGB(190, 38, 62)
		destroyHubX1.BorderSizePixel = 0
		destroyHubX1.FontFace = fontBold
		destroyHubX1.TextSize = 13
		destroyHubX1.TextColor3 = Color3.fromRGB(255, 255, 255)
		destroyHubX1.Text = "X"
		destroyHubX1.ZIndex = 10
		destroyHubX1.Parent = container1
		local uiCorner19 = Instance.new("UICorner")
		uiCorner19.CornerRadius = UDim.new(0, 7)
		uiCorner19.Parent = destroyHubX1
		destroyHubX1.MouseButton1Click:Connect(function()
			flag10 = true
			pcall(function()
				RunService:UnbindFromRenderStep("XursedHubMouse")
			end)
			if fpsConn1 then
				fpsConn1:Disconnect()
			end

			if xursedHubGui1 then
				xursedHubGui1:Destroy()
			end

			if toggleGuiBtn1 then
				toggleGuiBtn1:Destroy()
			end

			if connection1 then
				connection1:Disconnect()
			end

			if v95 then
				v95:Disconnect()
			end

			if v93 then
				v93:Disconnect()
			end

			if v94 then
				v94:Disconnect()
			end

			if v99 then
				v99:Disconnect()
			end

			if v100 then
				v100:Disconnect()
			end

			if v92 then
				v92:Disconnect()
			end

			if v90 then
				v90:Disconnect()
			end

			if v91 then
				v91:Destroy()
			end

			if v96 then
				v96:Disconnect()
			end

			if v97 then
				v97:Disconnect()
			end

			for k in pairs(tbl28) do
				if tbl28[k] then
					pcall(function()
						tbl28[k]:Destroy()
					end)
					tbl28[k] = nil
				end
			end

			if v98 then
				v98:Destroy()
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local RainbowHighlight = player.Character:FindFirstChild("RainbowHighlight")
					if RainbowHighlight then
						RainbowHighlight:Destroy()
					end
				end
			end

			local XursedHubVoidKill = workspace:FindFirstChild("XursedHubVoidKill")

			if XursedHubVoidKill then
				XursedHubVoidKill:Destroy()
			end
		end)
		local frame3 = Instance.new("Frame")
		frame3.Name = "ProfileCard"
		frame3.Size = UDim2.new(1, 0, 0, 64)
		frame3.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
		frame3.BackgroundTransparency = 0.25
		frame3.BorderSizePixel = 0
		frame3.Parent = v43
		local uiCorner20 = Instance.new("UICorner")
		uiCorner20.CornerRadius = UDim.new(0, 10)
		uiCorner20.Parent = frame3
		local imageLabel3 = Instance.new("ImageLabel")
		imageLabel3.Size = UDim2.new(0, 48, 0, 48)
		imageLabel3.Position = UDim2.new(0, 8, 0.5, -24)
		imageLabel3.BackgroundTransparency = 1
		imageLabel3.Image = ""
		imageLabel3.Parent = frame3
		task.spawn(function()
			pcall(function()
				imageLabel3.Image = Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
			end)
		end)
		local uiCorner21 = Instance.new("UICorner")
		uiCorner21.CornerRadius = UDim.new(1, 0)
		uiCorner21.Parent = imageLabel3
		local profileUsername1 = Instance.new("TextLabel")
		profileUsername1.Name = "ProfileUsername"
		profileUsername1.Visible = not tbl20.HideUsernameAndID
		profileUsername1.Size = UDim2.new(1, -70, 0, 20)
		profileUsername1.Position = UDim2.new(0, 66, 0, 12)
		profileUsername1.BackgroundTransparency = 1
		profileUsername1.FontFace = fontBold
		profileUsername1.TextSize = 13
		profileUsername1.TextColor3 = Color3.fromRGB(245, 247, 252)
		profileUsername1.Text = LocalPlayer.Name
		profileUsername1.TextXAlignment = Enum.TextXAlignment.Left
		profileUsername1.Parent = frame3
		local profileUserId1 = Instance.new("TextLabel")
		profileUserId1.Name = "ProfileUserId"
		profileUserId1.Visible = not tbl20.HideUsernameAndID
		profileUserId1.Size = UDim2.new(1, -70, 0, 20)
		profileUserId1.Position = UDim2.new(0, 66, 0, 32)
		profileUserId1.BackgroundTransparency = 1
		profileUserId1.FontFace = font
		profileUserId1.TextSize = 11
		profileUserId1.TextColor3 = Color3.fromRGB(200, 204, 220)
		profileUserId1.Text = "ID: " .. tostring(LocalPlayer.UserId)
		profileUserId1.TextXAlignment = Enum.TextXAlignment.Left
		profileUserId1.Parent = frame3

		for _, v59 in ipairs(XursedThemeOrder) do
			local btn = func33(
				v44,
				v59,
				function()
					ApplyTheme1(v59)
				end
			)
			btn.Name = "ThemeSwatchBtn"
			btn.BackgroundColor3 = XursedThemes[v59].Surface
			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.new(0, 12, 0, 12)
			swatch.Position = UDim2.new(0, 10, 0.5, -6)
			swatch.BackgroundColor3 = XursedThemes[v59].Accent
			swatch.BorderSizePixel = 0
			swatch.Parent = btn
			local sc = Instance.new("UICorner")
			sc.CornerRadius = UDim.new(1, 0)
			sc.Parent = swatch
		end

		func33(
			v44,
			"Reset Theme",
			function()
				ApplyTheme1("Xursed")
			end
		)
		ApplyTheme1(tbl20.Theme)

		local function func54()
			local num = 0
			pcall(function()
				num = math.floor(LocalPlayer:GetNetworkPing() * 1000)
			end)

			if num == 0 then
				pcall(function()
					local DataPing = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
					if DataPing then
						num = tonumber(tostring(DataPing:GetValue()):match("%d+")) or 0
					end
				end)
			end

			return num
		end

		local function func55(arg1)
			if arg1 <= 0 then
				return "0s"
			end

			local v1 = math.floor(arg1 / 86400)
			local v2 = math.floor(arg1 % 86400 / 3600)
			local v3 = math.floor(arg1 % 3600 / 60)
			local v4 = arg1 % 60

			if v1 > 0 then
				return string.format("%dd %dh %dm %ds", v1, v2, v3, v4)
			end

			if v2 > 0 then
				return string.format("%dh %dm %ds", v2, v3, v4)
			end

			if v3 > 0 then
				return string.format("%dm %ds", v3, v4)
			end

			return string.format("%ds", v4)
		end

		local v60 = os.time()
		local v61 = tbl20.TotalTime or 0
		local v62 = func32(v43, "Total Session Time", "Time used: 0s")
		local v63 = func32(v43, "FPS Counter", "FPS: 0")
		local v64 = func32(v43, "Ping Counter", "Ping: 0 ms")
		local num18 = 0
		local num19 = 0
		fpsConn1 = RunService.RenderStepped:Connect(function()
			num19 = num19 + 1
		end)
		task.spawn(function()
			while not flag10 do
				num18 = num19
				num19 = 0
				task.wait(1)
			end
		end)
		task.spawn(function()
			while not flag10 do
				task.wait(1)
				local v1 = os.time() - v60
				tbl20.TotalTime = v61 + v1

				if v1 % 5 == 0 then
					pcall(v34, "XursedHub_Settings.json", HttpService:JSONEncode(tbl20))
				end

				pcall(function()
					v62.ContentLabel.Text = "Time used: " .. func55(tbl20.TotalTime)
					v63.ContentLabel.Text = "FPS: " .. tostring(num18)
					v64.ContentLabel.Text = "Ping: " .. tostring((func54())) .. " ms"
				end)
			end
		end)
		func32(v45, "Hub", "Xursed Hub — Killstreak Only Edition")
		func32(v45, "UI & Custom Backgrounds", "Xursed Obsidian Glass Engine (Catbox / URL / Asset ID)")
		v39.Start()
	end,
	function(arg1)
		local str = tostring(arg1)
		pcall(function()
			if debug and debug.traceback then
				str = debug.traceback(str, 2)
			end
		end)
		return str
	end
)

if not ok then
	local v1 = "[Xursed Hub] Startup failed:\\n" .. tostring(result)
	warn("[Xursed Hub Diagnostic] STARTUP ERROR: " .. tostring(result))
	pcall(function()
		local v1 = tostring(result):match("^[^\n]*") or tostring(result)
		tbl.Log(
			"Xursed Hub crashed during startup",
			"An unhandled Lua error stopped the script: " .. v1,
			"Full error and stack trace:\n" .. tostring(result),
			"Re-run the script. If it keeps happening, send this log to the developers."
		)
	end)
	pcall(function()
		local xursedHubStartupError = Instance.new("ScreenGui")
		xursedHubStartupError.Name = "XursedHubStartupError"
		xursedHubStartupError.ResetOnSpawn = false
		xursedHubStartupError.DisplayOrder = 1000000
		local CoreGui = game:GetService("CoreGui")
		pcall(function()
			if type(gethui) == "function" then
				local v1 = gethui()
				if v1 then
					CoreGui = v1
				end
			end
		end)
		xursedHubStartupError.Parent = CoreGui
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.new(0.8, 0, 0, 170)
		frame.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
		frame.BorderSizePixel = 0
		frame.Parent = xursedHubStartupError
		local textLabel = Instance.new("TextLabel")
		textLabel.BackgroundTransparency = 1
		textLabel.Position = UDim2.new(0, 12, 0, 12)
		textLabel.Size = UDim2.new(1, -24, 1, -24)
		textLabel.Font = Enum.Font.Code
		textLabel.TextSize = 13
		textLabel.TextColor3 = Color3.fromRGB(255, 220, 220)
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.Text = v1
		textLabel.Parent = frame
	end)
end

-- Xursed Hub
