--[[
    VaeronLib 1.0.0
    Single-file Roblox executor UI library.

    Architecture:
      Core        - lifecycle, safe callbacks, cleanup and executor capability checks
      Renderer    - responsive window, mobile controls, themes and animation helpers
      Components  - tabs, groups and stateful widgets
      Persistence - JSON configuration and optional key storage

    Lucide icons are provided by lucide-roblox (MIT/ISC):
    https://github.com/latte-soft/lucide-roblox
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local VaeronLib = {
    Version = "1.0.0",
    Flags = {},
    Windows = {},
    Themes = {},
    LucideSource = "https://github.com/latte-soft/lucide-roblox/releases/download/0.1.3/lucide-roblox.luau",
}

local activeWindow
local activeScreen
local globalConnections = {}
local themeBindings = {}
local notificationSerial = 0
local unpackValues = table.unpack or unpack

VaeronLib.Themes.Vaeron = {
    Background = Color3.fromRGB(8, 10, 14),
    Surface = Color3.fromRGB(14, 17, 23),
    SurfaceAlt = Color3.fromRGB(19, 23, 31),
    SurfaceHover = Color3.fromRGB(25, 31, 41),
    Stroke = Color3.fromRGB(39, 48, 62),
    StrokeSoft = Color3.fromRGB(28, 35, 46),
    Accent = Color3.fromRGB(102, 204, 255),
    AccentDark = Color3.fromRGB(41, 132, 181),
    AccentSoft = Color3.fromRGB(22, 58, 78),
    Text = Color3.fromRGB(245, 248, 255),
    TextMuted = Color3.fromRGB(151, 163, 184),
    TextDark = Color3.fromRGB(8, 14, 20),
    Success = Color3.fromRGB(93, 220, 151),
    Warning = Color3.fromRGB(255, 194, 92),
    Danger = Color3.fromRGB(255, 103, 125),
    Shadow = Color3.fromRGB(0, 0, 0),
}

VaeronLib.Themes.Midnight = {
    Background = Color3.fromRGB(7, 9, 17),
    Surface = Color3.fromRGB(13, 16, 28),
    SurfaceAlt = Color3.fromRGB(18, 22, 37),
    SurfaceHover = Color3.fromRGB(27, 33, 53),
    Stroke = Color3.fromRGB(46, 55, 82),
    StrokeSoft = Color3.fromRGB(31, 38, 59),
    Accent = Color3.fromRGB(115, 145, 255),
    AccentDark = Color3.fromRGB(63, 82, 174),
    AccentSoft = Color3.fromRGB(28, 38, 84),
    Text = Color3.fromRGB(244, 246, 255),
    TextMuted = Color3.fromRGB(150, 158, 187),
    TextDark = Color3.fromRGB(8, 12, 26),
    Success = Color3.fromRGB(91, 218, 158),
    Warning = Color3.fromRGB(255, 194, 96),
    Danger = Color3.fromRGB(255, 102, 132),
    Shadow = Color3.fromRGB(0, 0, 0),
}

VaeronLib.Themes.Ocean = {
    Background = Color3.fromRGB(4, 14, 19),
    Surface = Color3.fromRGB(8, 24, 31),
    SurfaceAlt = Color3.fromRGB(11, 32, 41),
    SurfaceHover = Color3.fromRGB(15, 43, 54),
    Stroke = Color3.fromRGB(31, 69, 82),
    StrokeSoft = Color3.fromRGB(18, 49, 61),
    Accent = Color3.fromRGB(68, 218, 224),
    AccentDark = Color3.fromRGB(23, 139, 151),
    AccentSoft = Color3.fromRGB(13, 68, 75),
    Text = Color3.fromRGB(239, 253, 255),
    TextMuted = Color3.fromRGB(142, 179, 186),
    TextDark = Color3.fromRGB(4, 22, 25),
    Success = Color3.fromRGB(91, 224, 158),
    Warning = Color3.fromRGB(255, 195, 94),
    Danger = Color3.fromRGB(255, 102, 127),
    Shadow = Color3.fromRGB(0, 0, 0),
}

VaeronLib.Themes.Light = {
    Background = Color3.fromRGB(231, 237, 245),
    Surface = Color3.fromRGB(250, 252, 255),
    SurfaceAlt = Color3.fromRGB(240, 245, 251),
    SurfaceHover = Color3.fromRGB(226, 235, 245),
    Stroke = Color3.fromRGB(190, 204, 220),
    StrokeSoft = Color3.fromRGB(214, 224, 236),
    Accent = Color3.fromRGB(41, 157, 219),
    AccentDark = Color3.fromRGB(23, 109, 159),
    AccentSoft = Color3.fromRGB(188, 228, 249),
    Text = Color3.fromRGB(22, 31, 43),
    TextMuted = Color3.fromRGB(90, 106, 126),
    TextDark = Color3.fromRGB(250, 253, 255),
    Success = Color3.fromRGB(34, 158, 99),
    Warning = Color3.fromRGB(190, 124, 20),
    Danger = Color3.fromRGB(211, 65, 88),
    Shadow = Color3.fromRGB(94, 112, 135),
}

local FALLBACK_ICONS = {
    house = {16898613869, 967, 661}, settings = {16898613777, 771, 257},
    search = {16898613699, 918, 857}, x = {16898613869, 869, 906},
    minus = {16898613613, 771, 196}, ["maximize-2"] = {16898613613, 820, 514},
    ["panel-left"] = {16898613613, 967, 453}, menu = {16898613613, 49, 820},
    bell = {16898612819, 820, 257}, info = {16898613509, 612, 869},
    ["circle-check"] = {16898612819, 869, 955}, ["triangle-alert"] = {16898613869, 967, 0},
    ["circle-x"] = {16898613044, 820, 306}, ["key-round"] = {16898613509, 967, 306},
    copy = {16898613044, 918, 612}, save = {16898613699, 918, 453},
    ["folder-open"] = {16898613353, 820, 759}, palette = {16898613613, 453, 918},
    ["sliders-horizontal"] = {16898613777, 820, 355}, ["mouse-pointer-click"] = {16898613613, 771, 710},
    ["toggle-left"] = {16898613869, 869, 49}, ["chevron-down"] = {16898612819, 196, 918},
    ["chevron-right"] = {16898612819, 869, 759}, user = {16898613869, 661, 869},
    sparkles = {16898613777, 918, 49}, terminal = {16898613869, 820, 257},
    command = {16898613044, 563, 918}, ["layout-dashboard"] = {16898613509, 967, 355},
    eye = {16898613353, 771, 563}, crosshair = {16898613044, 453, 869},
    ["gamepad-2"] = {16898613353, 710, 967},
}

local lucideModule
local lucideAttempted = false

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return true
    end
    local args = {...}
    local ok, result = pcall(function()
        return callback(unpackValues(args))
    end)
    if not ok then
        warn("VaeronLib callback error: " .. tostring(result))
    end
    return ok, result
end

local function connect(signal, callback, bucket)
    local connection = signal:Connect(callback)
    table.insert(bucket or globalConnections, connection)
    return connection
end

local function disconnectBucket(bucket)
    for i = #bucket, 1, -1 do
        local item = bucket[i]
        pcall(function()
            item:Disconnect()
        end)
        bucket[i] = nil
    end
end

local function create(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        if key ~= "Parent" then
            local ok = pcall(function()
                object[key] = value
            end)
            if not ok then
                warn("VaeronLib ignored invalid " .. className .. "." .. tostring(key))
            end
        end
    end
    if properties and properties.Parent then
        object.Parent = properties.Parent
    end
    return object
end

local function addCorner(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = object,
    })
end

local function addStroke(object, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = object,
    })
end

local function addPadding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
        Parent = object,
    })
end

local function addList(object, padding, direction, alignment)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = object,
    })
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function round(value, increment)
    increment = increment or 1
    if increment == 0 then
        return value
    end
    return math.floor((value / increment) + 0.5) * increment
end

local function formatNumber(value)
    if math.abs(value - math.floor(value)) < 0.0001 then
        return tostring(math.floor(value))
    end
    return string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function currentTheme()
    if activeWindow and activeWindow.Theme then
        return activeWindow.Theme
    end
    return VaeronLib.Themes.Vaeron
end

local function bindTheme(object, property, key)
    table.insert(themeBindings, {Object = object, Property = property, Key = key})
    local theme = currentTheme()
    if object and object.Parent and theme[key]
        and object:GetAttribute("VaeronIgnoreTheme" .. property) ~= true then
        pcall(function()
            object[property] = theme[key]
        end)
    end
end

local function applyTheme(theme)
    for i = #themeBindings, 1, -1 do
        local binding = themeBindings[i]
        if not binding.Object or not binding.Object.Parent then
            table.remove(themeBindings, i)
        elseif theme[binding.Key]
            and binding.Object:GetAttribute("VaeronIgnoreTheme" .. binding.Property) ~= true then
            pcall(function()
                binding.Object[binding.Property] = theme[binding.Key]
            end)
        end
    end
end

local function tween(object, duration, goal, style, direction)
    if not object or not object.Parent then
        return nil
    end
    local speed = 1
    if activeWindow and activeWindow.AnimationSpeed then
        speed = math.max(activeWindow.AnimationSpeed, 0.05)
    end
    if activeWindow and activeWindow.ReducedMotion then
        duration = 0
    else
        duration = (duration or 0.2) / speed
    end
    local info = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local ok, animation = pcall(function()
        return TweenService:Create(object, info, goal)
    end)
    if ok and animation then
        animation:Play()
        return animation
    end
    for property, value in pairs(goal) do
        pcall(function()
            object[property] = value
        end)
    end
    return nil
end

local function normalizeIconName(name)
    return tostring(name or ""):lower():gsub("_", "-"):gsub("%s+", "-")
end

local function loadLucide()
    if lucideAttempted then
        return lucideModule
    end
    lucideAttempted = true
    local ok, result = pcall(function()
        local source = game:HttpGet(VaeronLib.LucideSource)
        local loader = loadstring(source)
        if not loader then
            return nil
        end
        return loader()
    end)
    if ok and type(result) == "table" then
        lucideModule = result
    end
    return lucideModule
end

local function resolveIcon(icon)
    if icon == nil or icon == 0 or icon == "" then
        return nil
    end
    if type(icon) == "number" then
        return {Image = "rbxassetid://" .. tostring(icon)}
    end
    if type(icon) ~= "string" then
        return nil
    end
    if icon:find("rbxassetid://", 1, true) or icon:find("http", 1, true) == 1 then
        return {Image = icon}
    end
    local name = normalizeIconName(icon)
    local fallback = FALLBACK_ICONS[name]
    if fallback then
        return {
            Image = "rbxassetid://" .. tostring(fallback[1]),
            ImageRectSize = Vector2.new(48, 48),
            ImageRectOffset = Vector2.new(fallback[2], fallback[3]),
        }
    end
    local lucide = loadLucide()
    if lucide and type(lucide.GetAsset) == "function" then
        local ok, asset = pcall(lucide.GetAsset, name, 48)
        if ok and asset then
            return {
                Image = asset.Url or ("rbxassetid://" .. tostring(asset.Id)),
                ImageRectSize = asset.ImageRectSize,
                ImageRectOffset = asset.ImageRectOffset,
            }
        end
    end
    return nil
end

local function applyIcon(imageObject, icon)
    local data = resolveIcon(icon)
    if not data then
        imageObject.Visible = false
        return false
    end
    imageObject.Visible = true
    imageObject.Image = data.Image
    imageObject.ImageRectSize = data.ImageRectSize or Vector2.new(0, 0)
    imageObject.ImageRectOffset = data.ImageRectOffset or Vector2.new(0, 0)
    return true
end

local function makeIcon(parent, icon, size, colorKey)
    local image = create("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size or 18, size or 18),
        ImageColor3 = currentTheme()[colorKey or "Text"],
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
    bindTheme(image, "ImageColor3", colorKey or "Text")
    applyIcon(image, icon)
    return image
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end
    if CoreGui then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(screen)
    if syn and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, screen)
    elseif type(protectgui) == "function" then
        pcall(protectgui, screen)
    end
end

local function enumKey(value, fallback)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end
    if type(value) == "string" then
        local cleaned = value:gsub("Enum.KeyCode.", ""):gsub("%s+", "")
        if Enum.KeyCode[cleaned] then
            return Enum.KeyCode[cleaned]
        end
        local upper = cleaned:upper()
        if #upper == 1 and Enum.KeyCode[upper] then
            return Enum.KeyCode[upper]
        end
    end
    return fallback or Enum.KeyCode.RightControl
end

local function inputPosition(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

local function pointInside(guiObject, point)
    local position = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return point.X >= position.X and point.Y >= position.Y
        and point.X <= position.X + size.X and point.Y <= position.Y + size.Y
end

local function addHover(frame, hoverKey, normalKey)
    hoverKey = hoverKey or "SurfaceHover"
    normalKey = normalKey or "SurfaceAlt"
    local bucket = activeWindow and activeWindow._connections or nil
    connect(frame.MouseEnter, function()
        tween(frame, 0.16, {BackgroundColor3 = currentTheme()[hoverKey]})
    end, bucket)
    connect(frame.MouseLeave, function()
        tween(frame, 0.2, {BackgroundColor3 = currentTheme()[normalKey]})
    end, bucket)
end

local function ripple(button, point)
    if activeWindow and activeWindow.ReducedMotion then
        return
    end
    local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.7
    local localPoint = point - button.AbsolutePosition
    local circle = create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(localPoint.X, localPoint.Y),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = currentTheme().Text,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = button.ZIndex + 2,
        Parent = button,
    })
    addCorner(circle, 999)
    tween(circle, 0.45, {
        Size = UDim2.fromOffset(diameter, diameter),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Exponential)
    task.delay(0.5, function()
        if circle then
            circle:Destroy()
        end
    end)
end

local function makeClickArea(parent, callback)
    local button = create("TextButton", {
        Name = "ClickArea",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = parent.ZIndex + 5,
        ClipsDescendants = true,
        Parent = parent,
    })
    connect(button.Activated, function(inputObject)
        local point = UserInputService:GetMouseLocation()
        if inputObject and inputObject.Position then
            point = inputPosition(inputObject)
        end
        ripple(button, point)
        safeCall(callback)
    end, activeWindow and activeWindow._connections or nil)
    return button
end

local function makeDraggable(handle, target, bucket)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inputPosition(input)
            startPosition = target.Position
            dragInput = input
            if input.UserInputType == Enum.UserInputType.Touch then
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end, bucket)

    connect(handle.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end, bucket)

    connect(UserInputService.InputChanged, function(input)
        if dragging and input == dragInput and dragStart and startPosition then
            local delta = inputPosition(input) - dragStart
            local nextPosition = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
            local anchor = target.AnchorPoint
            local size = target.AbsoluteSize
            local centerX = viewport.X * nextPosition.X.Scale + nextPosition.X.Offset
            local centerY = viewport.Y * nextPosition.Y.Scale + nextPosition.Y.Offset
            local minimumX = size.X * anchor.X + 6
            local maximumX = viewport.X - size.X * (1 - anchor.X) - 6
            local minimumY = size.Y * anchor.Y + 6
            local maximumY = viewport.Y - size.Y * (1 - anchor.Y) - 6
            if minimumX <= maximumX then
                centerX = clamp(centerX, minimumX, maximumX)
            end
            if minimumY <= maximumY then
                centerY = clamp(centerY, minimumY, maximumY)
            end
            target.Position = UDim2.new(
                nextPosition.X.Scale,
                centerX - viewport.X * nextPosition.X.Scale,
                nextPosition.Y.Scale,
                centerY - viewport.Y * nextPosition.Y.Scale
            )
        end
    end, bucket)

    connect(UserInputService.InputEnded, function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end, bucket)
end

local function sanitizeFileName(value)
    local result = tostring(value or "VaeronConfig"):gsub("[^%w%-%_ ]", "")
    result = result:gsub("%s+", "_")
    if result == "" then
        result = "VaeronConfig"
    end
    return result
end

local function filesystemReady()
    return type(writefile) == "function" and type(readfile) == "function"
end

local function ensureFolder(path)
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return false
    end
    local ok, exists = pcall(isfolder, path)
    if ok and exists then
        return true
    end
    return pcall(makefolder, path)
end

local function fileExists(path)
    if type(isfile) ~= "function" then
        return false
    end
    local ok, result = pcall(isfile, path)
    return ok and result == true
end

local function serialize(value)
    local valueType = typeof(value)
    if valueType == "Color3" then
        return {__type = "Color3", R = value.R, G = value.G, B = value.B}
    elseif valueType == "EnumItem" then
        return {__type = "EnumItem", Value = tostring(value)}
    elseif type(value) == "table" then
        local output = {}
        for key, item in pairs(value) do
            output[key] = serialize(item)
        end
        return output
    elseif type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
        return value
    end
    return nil
end

local function deserialize(value)
    if type(value) ~= "table" then
        return value
    end
    if value.__type == "Color3" then
        return Color3.new(value.R or 1, value.G or 1, value.B or 1)
    elseif value.__type == "EnumItem" then
        return enumKey(value.Value)
    end
    local output = {}
    for key, item in pairs(value) do
        output[key] = deserialize(item)
    end
    return output
end

local function configurationPath(window)
    local settings = window.ConfigurationSaving or {}
    local folder = sanitizeFileName(settings.FolderName or "VaeronLib")
    local fileName = sanitizeFileName(settings.FileName or window.Name or "Config")
    return folder, folder .. "/" .. fileName .. ".json"
end

local function scheduleSave(window)
    if not window or not window.ConfigurationSaving or not window.ConfigurationSaving.Enabled then
        return
    end
    window._saveSerial = (window._saveSerial or 0) + 1
    local serial = window._saveSerial
    task.delay(0.4, function()
        if window._saveSerial == serial and not window.Destroyed then
            VaeronLib:SaveConfiguration()
        end
    end)
end

local function registerFlag(window, control, flag, kind, initialValue)
    control.Flag = flag
    control.Kind = kind
    if flag and flag ~= "" then
        if window._controls[flag] then
            warn("VaeronLib duplicate flag replaced: " .. tostring(flag))
        end
        window._controls[flag] = control
        VaeronLib.Flags[flag] = initialValue
    end
end

function VaeronLib:SaveConfiguration()
    local window = activeWindow
    if not window or window.Destroyed then
        return false, "No active window"
    end
    local settings = window.ConfigurationSaving or {}
    if not settings.Enabled then
        return false, "Configuration saving is disabled"
    end
    if not filesystemReady() then
        return false, "Executor filesystem API is unavailable"
    end
    local folder, path = configurationPath(window)
    if not ensureFolder(folder) then
        return false, "Configuration folder could not be created"
    end
    local payload = {
        Version = VaeronLib.Version,
        UpdatedAt = os.time(),
        Values = {},
    }
    for flag, control in pairs(window._controls) do
        payload.Values[flag] = serialize(control:Get())
    end
    local okEncode, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
    if not okEncode then
        return false, tostring(encoded)
    end
    local okWrite, writeError = pcall(writefile, path, encoded)
    if not okWrite then
        return false, tostring(writeError)
    end
    return true, path
end

function VaeronLib:LoadConfiguration()
    local window = activeWindow
    if not window or window.Destroyed then
        return false, "No active window"
    end
    local settings = window.ConfigurationSaving or {}
    if not settings.Enabled then
        return false, "Configuration saving is disabled"
    end
    if not filesystemReady() then
        return false, "Executor filesystem API is unavailable"
    end
    local _, path = configurationPath(window)
    if not fileExists(path) then
        return false, "Configuration file does not exist"
    end
    local okRead, content = pcall(readfile, path)
    if not okRead or type(content) ~= "string" then
        return false, tostring(content)
    end
    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, content)
    if not okDecode or type(data) ~= "table" or type(data.Values) ~= "table" then
        return false, "Configuration JSON is invalid"
    end
    window._loadingConfiguration = true
    for flag, value in pairs(data.Values) do
        local control = window._controls[flag]
        if control and type(control.Set) == "function" then
            control:Set(deserialize(value), false)
        end
    end
    window._loadingConfiguration = false
    return true, path
end

function VaeronLib:DeleteConfiguration()
    local window = activeWindow
    if not window or not window.ConfigurationSaving or not window.ConfigurationSaving.Enabled then
        return false, "Configuration saving is disabled"
    end
    if type(delfile) ~= "function" then
        return false, "Executor delfile API is unavailable"
    end
    local _, path = configurationPath(window)
    if not fileExists(path) then
        return false, "Configuration file does not exist"
    end
    local ok, result = pcall(delfile, path)
    return ok, ok and path or tostring(result)
end

local function keyFilePath(settings)
    local folder = "VaeronLib/Keys"
    local name = sanitizeFileName(settings.FileName or settings.Title or "Key")
    return folder, folder .. "/" .. name .. ".key"
end

local function fetchRemoteText(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(result) == "string" then
        return result
    end
    return nil
end

local function collectAcceptedKeys(settings)
    local source = settings.Key or settings.Keys or {}
    if type(source) ~= "table" then
        source = {source}
    end
    local accepted = {}
    for _, value in ipairs(source) do
        local text = tostring(value)
        if settings.GrabKeyFromSite and text:match("^https?://") then
            local remote = fetchRemoteText(text)
            if remote then
                for line in remote:gmatch("[^\r\n,]+") do
                    line = line:match("^%s*(.-)%s*$")
                    if line ~= "" then
                        accepted[line] = true
                    end
                end
            end
        else
            accepted[text] = true
        end
    end
    return accepted
end

local function validateKey(settings, key)
    key = tostring(key or "")
    if type(settings.Validate) == "function" then
        local ok, valid, message = pcall(settings.Validate, key)
        if not ok then
            return false, "Validation error: " .. tostring(valid)
        end
        return valid == true, message
    end
    local accepted = collectAcceptedKeys(settings)
    return accepted[key] == true, accepted[key] and "Accepted" or "Invalid key"
end

local function loadSavedKey(settings)
    if not settings.SaveKey or not filesystemReady() then
        return nil
    end
    local _, path = keyFilePath(settings)
    if not fileExists(path) then
        return nil
    end
    local ok, value = pcall(readfile, path)
    if ok and type(value) == "string" then
        return value
    end
    return nil
end

local function saveKey(settings, key)
    if not settings.SaveKey or not filesystemReady() then
        return false
    end
    local folder, path = keyFilePath(settings)
    if not ensureFolder("VaeronLib") or not ensureFolder(folder) then
        return false
    end
    return pcall(writefile, path, tostring(key))
end

local function showLoading(screen, settings)
    local theme = currentTheme()
    local overlay = create("Frame", {
        Name = "Loading",
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ZIndex = 900,
        Parent = screen,
    })
    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52),
        Size = UDim2.new(1, -30, 0, 156),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 901,
        Parent = overlay,
    })
    addCorner(card, 18)
    create("UISizeConstraint", {
        MinSize = Vector2.new(260, 156),
        MaxSize = Vector2.new(350, 156),
        Parent = card,
    })
    local cardStroke = addStroke(card, theme.Stroke, 1, 1)
    local logo = create("Frame", {
        Position = UDim2.fromOffset(24, 24),
        Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 902,
        Parent = card,
    })
    addCorner(logo, 12)
    local logoText = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = "V",
        TextColor3 = theme.TextDark,
        TextSize = 19,
        TextTransparency = 1,
        ZIndex = 903,
        Parent = logo,
    })
    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(80, 25),
        Size = UDim2.new(1, -104, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = tostring(settings.LoadingTitle or settings.Name or "VaeronLib"),
        TextColor3 = theme.Text,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 902,
        Parent = card,
    })
    local subtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(80, 50),
        Size = UDim2.new(1, -104, 0, 18),
        Font = Enum.Font.Gotham,
        Text = tostring(settings.LoadingSubtitle or "Interface is loading"),
        TextColor3 = theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 902,
        Parent = card,
    })
    local barBack = create("Frame", {
        Position = UDim2.new(0, 24, 1, -38),
        Size = UDim2.new(1, -48, 0, 5),
        BackgroundColor3 = theme.SurfaceAlt,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 902,
        Parent = card,
    })
    addCorner(barBack, 99)
    local bar = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 903,
        Parent = barBack,
    })
    addCorner(bar, 99)

    tween(card, 0.42, {Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0}, Enum.EasingStyle.Exponential)
    tween(cardStroke, 0.42, {Transparency = 0.15})
    tween(logo, 0.35, {BackgroundTransparency = 0}, Enum.EasingStyle.Back)
    tween(logoText, 0.3, {TextTransparency = 0})
    tween(title, 0.35, {TextTransparency = 0})
    tween(subtitle, 0.4, {TextTransparency = 0})
    tween(barBack, 0.35, {BackgroundTransparency = 0})
    tween(bar, settings.LoadingDuration or 0.7, {Size = UDim2.fromScale(1, 1)}, Enum.EasingStyle.Exponential)
    task.wait(settings.LoadingDuration or 0.7)
    tween(card, 0.25, {Position = UDim2.fromScale(0.5, 0.47), BackgroundTransparency = 1}, Enum.EasingStyle.Exponential)
    tween(overlay, 0.3, {BackgroundTransparency = 1})
    task.wait(0.3)
    overlay:Destroy()
end

local function runKeyGate(screen, settings)
    local saved = loadSavedKey(settings)
    if saved then
        local valid = validateKey(settings, saved)
        if valid then
            return true
        end
    end

    local theme = currentTheme()
    local accepted = Instance.new("BindableEvent")
    local completed = false
    local gateConnections = {}
    local overlay = create("Frame", {
        Name = "KeySystem",
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.08,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ZIndex = 800,
        Parent = screen,
    })
    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.53),
        Size = UDim2.new(1, -30, 0, 320),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 801,
        Parent = overlay,
    })
    addCorner(card, 18)
    addStroke(card, theme.Stroke, 1, 0.08)
    create("UISizeConstraint", {
        MinSize = Vector2.new(270, 300),
        MaxSize = Vector2.new(410, 340),
        Parent = card,
    })
    local accent = create("Frame", {
        Position = UDim2.fromOffset(24, 24),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 802,
        Parent = card,
    })
    addCorner(accent, 12)
    local keyIcon = makeIcon(accent, "key-round", 22, "TextDark")
    keyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    keyIcon.Position = UDim2.fromScale(0.5, 0.5)
    keyIcon.ZIndex = 803
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(82, 25),
        Size = UDim2.new(1, -106, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = tostring(settings.Title or "Vaeron Access"),
        TextColor3 = theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 802,
        Parent = card,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(82, 50),
        Size = UDim2.new(1, -106, 0, 18),
        Font = Enum.Font.Gotham,
        Text = tostring(settings.Subtitle or "Enter your key to continue"),
        TextColor3 = theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 802,
        Parent = card,
    })
    local note = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(24, 88),
        Size = UDim2.new(1, -48, 0, 44),
        Font = Enum.Font.Gotham,
        Text = tostring(settings.Note or "Obtain a key, paste it below, then press Verify."),
        TextColor3 = theme.TextMuted,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 802,
        Parent = card,
    })
    local inputBack = create("Frame", {
        Position = UDim2.fromOffset(24, 142),
        Size = UDim2.new(1, -48, 0, 46),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        ZIndex = 802,
        Parent = card,
    })
    addCorner(inputBack, 10)
    addStroke(inputBack, theme.Stroke, 1, 0.2)
    local keyInput = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = tostring(settings.Placeholder or "Paste key here"),
        PlaceholderColor3 = theme.TextMuted,
        Text = "",
        TextColor3 = theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 803,
        Parent = inputBack,
    })
    local errorLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(24, 194),
        Size = UDim2.new(1, -48, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = "",
        TextColor3 = theme.Danger,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 802,
        Parent = card,
    })
    local verify = create("TextButton", {
        Position = UDim2.new(0, 24, 1, -72),
        Size = UDim2.new(1, settings.GetKeyURL and -134 or -48, 0, 46),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "Verify key",
        TextColor3 = theme.TextDark,
        TextSize = 13,
        ZIndex = 802,
        Parent = card,
    })
    addCorner(verify, 10)
    local getKeyButton
    if settings.GetKeyURL then
        getKeyButton = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -24, 1, -72),
            Size = UDim2.fromOffset(100, 46),
            BackgroundColor3 = theme.SurfaceAlt,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold,
            Text = "Get key",
            TextColor3 = theme.Text,
            TextSize = 12,
            ZIndex = 802,
            Parent = card,
        })
        addCorner(getKeyButton, 10)
        addStroke(getKeyButton, theme.Stroke, 1, 0.2)
        connect(getKeyButton.Activated, function()
            if type(setclipboard) == "function" then
                local ok = pcall(setclipboard, tostring(settings.GetKeyURL))
                errorLabel.Text = ok and "Key link copied." or tostring(settings.GetKeyURL)
                errorLabel.TextColor3 = ok and theme.Success or theme.TextMuted
            else
                errorLabel.Text = tostring(settings.GetKeyURL)
                errorLabel.TextColor3 = theme.TextMuted
            end
        end, gateConnections)
    end

    local function submit()
        if completed then
            return
        end
        verify.Text = "Checking..."
        local valid, message = validateKey(settings, keyInput.Text)
        if valid then
            completed = true
            saveKey(settings, keyInput.Text)
            errorLabel.Text = tostring(message or "Access granted")
            errorLabel.TextColor3 = theme.Success
            verify.Text = "Accepted"
            tween(card, 0.3, {Position = UDim2.fromScale(0.5, 0.47), BackgroundTransparency = 1}, Enum.EasingStyle.Exponential)
            tween(overlay, 0.3, {BackgroundTransparency = 1})
            task.delay(0.3, function()
                accepted:Fire()
            end)
        else
            errorLabel.Text = tostring(message or "Invalid key")
            errorLabel.TextColor3 = theme.Danger
            verify.Text = "Verify key"
            tween(card, 0.08, {Position = UDim2.new(0.5, -7, 0.5, 0)}, Enum.EasingStyle.Linear)
            task.delay(0.08, function()
                tween(card, 0.18, {Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Back)
            end)
        end
    end

    connect(verify.Activated, submit, gateConnections)
    connect(keyInput.FocusLost, function(enterPressed)
        if enterPressed then
            submit()
        end
    end, gateConnections)
    tween(card, 0.42, {Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Exponential)
    keyInput:CaptureFocus()
    accepted.Event:Wait()
    disconnectBucket(gateConnections)
    overlay:Destroy()
    accepted:Destroy()
    safeCall(settings.OnSuccess)
    return true
end

local function addTooltip(target, text)
    if not text or text == "" then
        return
    end
    local tooltip
    local serial = 0
    local bucket = activeWindow and activeWindow._connections or nil
    connect(target.MouseEnter, function()
        serial = serial + 1
        local ownSerial = serial
        task.delay(0.45, function()
            if ownSerial ~= serial or not activeScreen or not target.Parent then
                return
            end
            tooltip = create("TextLabel", {
                Name = "Tooltip",
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = currentTheme().SurfaceAlt,
                BackgroundTransparency = 0.04,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamMedium,
                Text = tostring(text),
                TextColor3 = currentTheme().Text,
                TextSize = 11,
                TextWrapped = true,
                TextTransparency = 1,
                ZIndex = 950,
                Parent = activeScreen,
            })
            addPadding(tooltip, 10, 10, 7, 7)
            addCorner(tooltip, 7)
            addStroke(tooltip, currentTheme().Stroke, 1, 0.2)
            local mouse = UserInputService:GetMouseLocation()
            tooltip.Position = UDim2.fromOffset(mouse.X + 12, mouse.Y + 12)
            tween(tooltip, 0.16, {TextTransparency = 0})
        end)
    end, bucket)
    connect(target.MouseLeave, function()
        serial = serial + 1
        if tooltip then
            tooltip:Destroy()
            tooltip = nil
        end
    end, bucket)
end

local function ensureNotificationHolder(screen)
    local holder = screen:FindFirstChild("Notifications")
    if holder then
        return holder
    end
    holder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(1, -28, 1, -28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 700,
        Parent = screen,
    })
    create("UISizeConstraint", {
        MinSize = Vector2.new(250, 0),
        MaxSize = Vector2.new(330, 100000),
        Parent = holder,
    })
    addList(holder, 10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right)
    return holder
end

function VaeronLib:Notify(data)
    data = data or {}
    if not activeScreen or not activeScreen.Parent then
        return nil
    end
    local holder = ensureNotificationHolder(activeScreen)
    notificationSerial = notificationSerial + 1
    local theme = currentTheme()
    local toast = create("Frame", {
        Name = "Notification_" .. notificationSerial,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = -notificationSerial,
        ZIndex = 701,
        Parent = holder,
    })
    addCorner(toast, 13)
    local outline = addStroke(toast, theme.Stroke, 1, 0.15)
    bindTheme(toast, "BackgroundColor3", "Surface")
    bindTheme(outline, "Color", "Stroke")

    local accent = create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = data.Color or theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 702,
        Parent = toast,
    })
    local iconBack = create("Frame", {
        Position = UDim2.fromOffset(18, 18),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = theme.AccentSoft,
        BorderSizePixel = 0,
        ZIndex = 702,
        Parent = toast,
    })
    addCorner(iconBack, 9)
    bindTheme(iconBack, "BackgroundColor3", "AccentSoft")
    local icon = makeIcon(iconBack, data.Image or data.Icon or "bell", 18, "Accent")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.ZIndex = 703

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(64, 16),
        Size = UDim2.new(1, -104, 0, 21),
        Font = Enum.Font.GothamBold,
        Text = tostring(data.Title or "Notification"),
        TextColor3 = theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 702,
        Parent = toast,
    })
    bindTheme(title, "TextColor3", "Text")
    local content = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(64, 39),
        Size = UDim2.new(1, -84, 0, 34),
        Font = Enum.Font.Gotham,
        Text = tostring(data.Content or data.Description or ""),
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 702,
        Parent = toast,
    })
    bindTheme(content, "TextColor3", "TextMuted")
    local closeButton = create("TextButton", {
        Position = UDim2.new(1, -35, 0, 12),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = theme.TextMuted,
        TextSize = 18,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 704,
        Parent = toast,
    })
    bindTheme(closeButton, "TextColor3", "TextMuted")

    local actions = data.Actions
    local totalHeight = 88
    if type(actions) == "table" and #actions > 0 then
        totalHeight = 130
        local actionHolder = create("Frame", {
            Position = UDim2.fromOffset(64, 82),
            Size = UDim2.new(1, -84, 0, 32),
            BackgroundTransparency = 1,
            ZIndex = 702,
            Parent = toast,
        })
        addList(actionHolder, 7, Enum.FillDirection.Horizontal)
        for _, action in ipairs(actions) do
            local actionButton = create("TextButton", {
                Size = UDim2.fromOffset(92, 32),
                BackgroundColor3 = action.Primary and theme.Accent or theme.SurfaceAlt,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.GothamSemibold,
                Text = tostring(action.Name or "Action"),
                TextColor3 = action.Primary and theme.TextDark or theme.Text,
                TextSize = 11,
                ZIndex = 703,
                Parent = actionHolder,
            })
            addCorner(actionButton, 8)
            connect(actionButton.Activated, function()
                safeCall(action.Callback)
            end, activeWindow and activeWindow._connections or nil)
        end
    end

    local progress = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 3, 1, 0),
        Size = UDim2.new(1, -3, 0, 2),
        BackgroundColor3 = data.Color or theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 703,
        Parent = toast,
    })

    local closed = false
    local notification = {}
    function notification:Close()
        if closed then
            return
        end
        closed = true
        tween(toast, 0.3, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Exponential)
        task.delay(0.32, function()
            if toast then
                toast:Destroy()
            end
        end)
    end
    connect(closeButton.Activated, function()
        notification:Close()
    end, activeWindow and activeWindow._connections or nil)
    tween(toast, 0.38, {Size = UDim2.new(1, 0, 0, totalHeight)}, Enum.EasingStyle.Back)
    local duration = tonumber(data.Duration) or 5
    if duration > 0 then
        tween(progress, duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
        task.delay(duration, function()
            notification:Close()
        end)
    end
    return notification
end

local WidgetHost = {}
WidgetHost.__index = WidgetHost

local function baseElement(host, name, height, tooltip)
    local theme = currentTheme()
    local frame = create("Frame", {
        Name = "Element",
        Size = UDim2.new(1, 0, 0, height or 54),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = host._container,
    })
    addCorner(frame, 11)
    local border = addStroke(frame, theme.StrokeSoft, 1, 0.18)
    bindTheme(frame, "BackgroundColor3", "SurfaceAlt")
    bindTheme(border, "Color", "StrokeSoft")
    addHover(frame)
    local label = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -86, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = tostring(name or "Element"),
        TextColor3 = theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = frame.ZIndex + 1,
        Parent = frame,
    })
    bindTheme(label, "TextColor3", "Text")
    host:_registerSearch(name, frame)
    addTooltip(frame, tooltip)
    return frame, label
end

function WidgetHost:_registerSearch(name, frame)
    table.insert(self._window._searchItems, {
        Name = tostring(name or ""):lower(),
        Frame = frame,
        Tab = self._tab or self,
    })
end

local function makeWindowButton(parent, iconName, order, callback, tooltip)
    local theme = currentTheme()
    local button = create("TextButton", {
        Name = tostring(iconName),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = theme.SurfaceAlt,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = order,
        Parent = parent,
    })
    addCorner(button, 9)
    bindTheme(button, "BackgroundColor3", "SurfaceAlt")
    local icon = makeIcon(button, iconName, 16, "TextMuted")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    addHover(button)
    addTooltip(button, tooltip)
    connect(button.Activated, function()
        tween(button, 0.08, {Size = UDim2.fromOffset(30, 30)}, Enum.EasingStyle.Quint)
        task.delay(0.08, function()
            tween(button, 0.18, {Size = UDim2.fromOffset(34, 34)}, Enum.EasingStyle.Back)
        end)
        safeCall(callback)
    end)
    return button
end

local function createSearchBox(window, parent)
    local theme = currentTheme()
    local searchBack = create("Frame", {
        Name = "Search",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.58, 0.5),
        Size = UDim2.fromOffset(250, 36),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = parent,
    })
    addCorner(searchBack, 10)
    local searchStroke = addStroke(searchBack, theme.StrokeSoft, 1, 0.15)
    bindTheme(searchBack, "BackgroundColor3", "SurfaceAlt")
    bindTheme(searchStroke, "Color", "StrokeSoft")
    local icon = makeIcon(searchBack, "search", 15, "TextMuted")
    icon.Position = UDim2.fromOffset(12, 10)
    local box = create("TextBox", {
        Name = "Input",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -74, 1, 0),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search current tab...",
        PlaceholderColor3 = theme.TextMuted,
        Text = "",
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchBack,
    })
    bindTheme(box, "TextColor3", "Text")
    bindTheme(box, "PlaceholderColor3", "TextMuted")
    local shortcut = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(26, 20),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold,
        Text = "/",
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        Parent = searchBack,
    })
    addCorner(shortcut, 6)
    bindTheme(shortcut, "BackgroundColor3", "Surface")
    bindTheme(shortcut, "TextColor3", "TextMuted")

    local function filter()
        local query = box.Text:lower():match("^%s*(.-)%s*$")
        for _, item in ipairs(window._searchItems) do
            if item.Tab == window.SelectedTab then
                local manuallyVisible = item.Frame:GetAttribute("VaeronVisible") ~= false
                item.Frame.Visible = manuallyVisible and (query == "" or item.Name:find(query, 1, true) ~= nil)
            end
        end
    end
    connect(box:GetPropertyChangedSignal("Text"), filter, window._connections)
    window.SearchBox = box
    window.SearchFrame = searchBack
    return searchBack
end

local function createMobileToggle(window, screen, text)
    local theme = currentTheme()
    local button = create("TextButton", {
        Name = "MobileToggle",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(126, 46),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 650,
        Parent = screen,
    })
    addCorner(button, 14)
    local stroke = addStroke(button, theme.Accent, 1, 0.2)
    bindTheme(button, "BackgroundColor3", "Surface")
    bindTheme(stroke, "Color", "Accent")
    local icon = makeIcon(button, "panel-left", 18, "Accent")
    icon.Position = UDim2.fromOffset(14, 14)
    icon.ZIndex = 651
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -52, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = tostring(text or "Open Vaeron"),
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 651,
        Parent = button,
    })
    bindTheme(label, "TextColor3", "Text")
    connect(button.Activated, function()
        window:Show()
    end, window._connections)
    makeDraggable(button, button, window._connections)
    return button
end

local function createWindowShell(window, screen, settings)
    local theme = window.Theme
    local root = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(860, 560),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screen,
    })
    addCorner(root, 16)
    local rootStroke = addStroke(root, theme.Stroke, 1, 1)
    bindTheme(root, "BackgroundColor3", "Background")
    bindTheme(rootStroke, "Color", "Stroke")
    local shadow = create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = root.Position,
        Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset + 48, root.Size.Y.Scale, root.Size.Y.Offset + 48),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = screen,
    })
    bindTheme(shadow, "ImageColor3", "Shadow")

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    bindTheme(topbar, "BackgroundColor3", "Surface")
    local topbarMask = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    bindTheme(topbarMask, "BackgroundColor3", "Surface")
    addCorner(topbar, 16)
    local topLine = create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    bindTheme(topLine, "BackgroundColor3", "StrokeSoft")

    local brandIcon = create("Frame", {
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    addCorner(brandIcon, 11)
    bindTheme(brandIcon, "BackgroundColor3", "Accent")
    local brandImage
    if settings.Icon and settings.Icon ~= 0 then
        brandImage = makeIcon(brandIcon, settings.Icon, 20, "TextDark")
        brandImage.AnchorPoint = Vector2.new(0.5, 0.5)
        brandImage.Position = UDim2.fromScale(0.5, 0.5)
    else
        brandImage = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = Enum.Font.GothamBold,
            Text = tostring(window.Name):sub(1, 1):upper(),
            TextColor3 = theme.TextDark,
            TextSize = 18,
            Parent = brandIcon,
        })
        bindTheme(brandImage, "TextColor3", "TextDark")
    end
    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(68, 12),
        Size = UDim2.fromOffset(170, 21),
        Font = Enum.Font.GothamBold,
        Text = window.Name,
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = topbar,
    })
    bindTheme(title, "TextColor3", "Text")
    local subtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(68, 33),
        Size = UDim2.fromOffset(170, 18),
        Font = Enum.Font.Gotham,
        Text = tostring(settings.Subtitle or "Vaeron Interface"),
        TextColor3 = theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = topbar,
    })
    bindTheme(subtitle, "TextColor3", "TextMuted")

    createSearchBox(window, topbar)
    local controls = create("Frame", {
        Name = "Controls",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(112, 34),
        BackgroundTransparency = 1,
        Parent = topbar,
    })
    addList(controls, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 64),
        Size = UDim2.new(0, 210, 1, -64),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    bindTheme(sidebar, "BackgroundColor3", "Surface")
    local sideLine = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    bindTheme(sideLine, "BackgroundColor3", "StrokeSoft")
    local tabsLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(17, 13),
        Size = UDim2.new(1, -34, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "NAVIGATION",
        TextColor3 = theme.TextMuted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })
    bindTheme(tabsLabel, "TextColor3", "TextMuted")
    local tabHolder = create("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(10, 38),
        Size = UDim2.new(1, -20, 1, -120),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    })
    addList(tabHolder, 5)
    bindTheme(tabHolder, "ScrollBarImageColor3", "Accent")

    local profile = create("Frame", {
        Name = "Profile",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.new(1, -20, 0, 62),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    addCorner(profile, 11)
    bindTheme(profile, "BackgroundColor3", "SurfaceAlt")
    local avatar = create("ImageLabel", {
        Position = UDim2.fromOffset(10, 11),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = theme.AccentSoft,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
        Parent = profile,
    })
    addCorner(avatar, 99)
    bindTheme(avatar, "BackgroundColor3", "AccentSoft")
    local profileName = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(60, 11),
        Size = UDim2.new(1, -70, 0, 20),
        Font = Enum.Font.GothamSemibold,
        Text = tostring(settings.ProfileName or LocalPlayer.DisplayName),
        TextColor3 = theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = profile,
    })
    bindTheme(profileName, "TextColor3", "Text")
    local profileRole = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(60, 31),
        Size = UDim2.new(1, -70, 0, 17),
        Font = Enum.Font.Gotham,
        Text = tostring(settings.ProfileRole or "Executor user"),
        TextColor3 = theme.TextMuted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = profile,
    })
    bindTheme(profileRole, "TextColor3", "TextMuted")

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(210, 64),
        Size = UDim2.new(1, -210, 1, -92),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = root,
    })
    local pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.new(1, -28, 1, -20),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = content,
    })
    local statusBar = create("Frame", {
        Name = "StatusBar",
        Position = UDim2.new(0, 210, 1, -28),
        Size = UDim2.new(1, -210, 0, 28),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = root,
    })
    bindTheme(statusBar, "BackgroundColor3", "Surface")
    local statusLine = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Parent = statusBar,
    })
    bindTheme(statusLine, "BackgroundColor3", "StrokeSoft")
    local statusDot = create("Frame", {
        Position = UDim2.fromOffset(15, 11),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = theme.Success,
        BorderSizePixel = 0,
        Parent = statusBar,
    })
    addCorner(statusDot, 99)
    local statusText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(29, 0),
        Size = UDim2.new(1, -130, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(settings.StatusText or "Ready"),
        TextColor3 = theme.TextMuted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusBar,
    })
    bindTheme(statusText, "TextColor3", "TextMuted")
    local versionText = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(100, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "Vaeron " .. VaeronLib.Version,
        TextColor3 = theme.TextMuted,
        TextSize = 9,
        Parent = statusBar,
    })
    bindTheme(versionText, "TextColor3", "TextMuted")

    window.Root = root
    window.Topbar = topbar
    window.Sidebar = sidebar
    window.TabHolder = tabHolder
    window.Content = content
    window.Pages = pages
    window.StatusBar = statusBar
    window.StatusText = statusText
    window.StatusDot = statusDot
    window.Profile = profile
    window.ProfileLabels = {profileName, profileRole}
    window.TabsLabel = tabsLabel
    window.TitleLabel = title
    window.SubtitleLabel = subtitle
    window.Shadow = shadow

    connect(root:GetPropertyChangedSignal("Position"), function()
        shadow.Position = root.Position
    end, window._connections)
    connect(root:GetPropertyChangedSignal("Size"), function()
        shadow.Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset + 48, root.Size.Y.Scale, root.Size.Y.Offset + 48)
    end, window._connections)

    makeWindowButton(controls, "minus", 1, function()
        window:Minimize()
    end, "Minimize")
    makeWindowButton(controls, "maximize-2", 2, function()
        window:Maximize()
    end, "Maximize / restore")
    makeWindowButton(controls, "x", 3, function()
        window:Hide()
    end, "Hide interface")

    makeDraggable(topbar, root, window._connections)

    local resizeGrip = create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Text = "◢",
        TextColor3 = theme.TextMuted,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 20,
        Parent = root,
    })
    bindTheme(resizeGrip, "TextColor3", "TextMuted")
    window.ResizeGrip = resizeGrip
    local resizing = false
    local resizeStart
    local sizeStart
    connect(resizeGrip.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = inputPosition(input)
            sizeStart = root.AbsoluteSize
        end
    end, window._connections)
    connect(UserInputService.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inputPosition(input) - resizeStart
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            local maxWidth = math.max(300, viewport.X - 18)
            local maxHeight = math.max(340, viewport.Y - 18)
            local minWidth = math.min(620, maxWidth)
            local minHeight = math.min(420, maxHeight)
            root.Size = UDim2.fromOffset(
                clamp(sizeStart.X + delta.X, minWidth, maxWidth),
                clamp(sizeStart.Y + delta.Y, minHeight, maxHeight)
            )
            window._customSize = root.Size
        end
    end, window._connections)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end, window._connections)

    tween(root, 0.5, {BackgroundTransparency = 0}, Enum.EasingStyle.Exponential)
    tween(rootStroke, 0.45, {Transparency = 0.08})
    tween(shadow, 0.55, {ImageTransparency = 0.55}, Enum.EasingStyle.Exponential)
    return root
end

local WindowMethods = {}
WindowMethods.__index = WindowMethods

function WindowMethods:_updateResponsive()
    if self.Destroyed or not self.Root then
        return
    end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local compact = viewport.X < 720
    self.Compact = compact

    if not self._customSize and not self.Maximized then
        local minimumWidth = math.min(320, math.max(240, viewport.X - 8))
        local minimumHeight = math.min(360, math.max(300, viewport.Y - 8))
        local width = clamp(viewport.X - 24, minimumWidth, 860)
        local height = clamp(viewport.Y - 24, minimumHeight, 560)
        self.Root.Size = UDim2.fromOffset(width, height)
    end
    local sidebarWidth = compact and 76 or 210
    self.Sidebar.Size = UDim2.new(0, sidebarWidth, 1, -64)
    self.Content.Position = UDim2.fromOffset(sidebarWidth, 64)
    self.Content.Size = UDim2.new(1, -sidebarWidth, 1, -92)
    self.StatusBar.Position = UDim2.new(0, sidebarWidth, 1, -28)
    self.StatusBar.Size = UDim2.new(1, -sidebarWidth, 0, 28)
    self.TabsLabel.Visible = not compact
    self.Profile.Visible = not compact
    self.TabHolder.Position = compact and UDim2.fromOffset(10, 10) or UDim2.fromOffset(10, 38)
    self.TabHolder.Size = compact and UDim2.new(1, -20, 1, -20) or UDim2.new(1, -20, 1, -120)
    self.SearchFrame.Visible = viewport.X >= 650
    self.TitleLabel.Size = compact and UDim2.fromOffset(90, 21) or UDim2.fromOffset(170, 21)
    self.SubtitleLabel.Visible = not compact
    self.ResizeGrip.Visible = not UserInputService.TouchEnabled or UserInputService.MouseEnabled

    for _, tab in ipairs(self.Tabs) do
        tab.ButtonText.Visible = not compact
        tab.Button.Size = UDim2.new(1, 0, 0, 42)
        tab.ButtonIcon.Position = compact and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(13, 12)
        tab.ButtonIcon.AnchorPoint = compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0)
    end
end

function WindowMethods:SetStatus(text, status)
    self.StatusText.Text = tostring(text or "Ready")
    local key = "Success"
    if status == "warning" then
        key = "Warning"
    elseif status == "danger" or status == "error" then
        key = "Danger"
    elseif status == "accent" then
        key = "Accent"
    end
    self._statusKind = status or "success"
    self.StatusDot.BackgroundColor3 = self.Theme[key]
    return self
end

function WindowMethods:SetProfile(name, role)
    if name ~= nil then
        self.ProfileLabels[1].Text = tostring(name)
    end
    if role ~= nil then
        self.ProfileLabels[2].Text = tostring(role)
    end
    return self
end

function WindowMethods:SelectTab(tabOrName)
    local target = tabOrName
    if type(tabOrName) == "string" then
        target = nil
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == tabOrName then
                target = tab
                break
            end
        end
    end
    if not target or target == self.SelectedTab then
        return target
    end
    if self.SelectedTab then
        local previous = self.SelectedTab
        previous.Page.Visible = false
        tween(previous.Button, 0.2, {BackgroundTransparency = 1})
        tween(previous.ButtonText, 0.2, {TextColor3 = self.Theme.TextMuted})
        tween(previous.ButtonIcon, 0.2, {ImageColor3 = self.Theme.TextMuted})
        tween(previous.Indicator, 0.2, {Size = UDim2.fromOffset(3, 0), BackgroundTransparency = 1})
    end
    self.SelectedTab = target
    self.SearchBox.Text = ""
    target.Page.Visible = true
    target.Page.Position = UDim2.fromOffset(10, 0)
    target.Page.ScrollBarImageTransparency = 1
    tween(target.Page, 0.28, {Position = UDim2.fromOffset(0, 0), ScrollBarImageTransparency = 0.25}, Enum.EasingStyle.Exponential)
    tween(target.Button, 0.24, {BackgroundTransparency = 0, BackgroundColor3 = self.Theme.AccentSoft})
    tween(target.ButtonText, 0.2, {TextColor3 = self.Theme.Text})
    tween(target.ButtonIcon, 0.2, {ImageColor3 = self.Theme.Accent})
    tween(target.Indicator, 0.26, {Size = UDim2.fromOffset(3, 20), BackgroundTransparency = 0}, Enum.EasingStyle.Back)
    self:SetStatus(target.Name .. " selected", "accent")
    return target
end

function WindowMethods:ModifyTheme(theme)
    local resolved
    if type(theme) == "string" then
        resolved = VaeronLib.Themes[theme]
    elseif type(theme) == "table" then
        resolved = {}
        for key, value in pairs(VaeronLib.Themes.Vaeron) do
            resolved[key] = value
        end
        for key, value in pairs(theme) do
            if typeof(value) == "Color3" then
                resolved[key] = value
            end
        end
    end
    if not resolved then
        return false, "Unknown theme"
    end
    self.Theme = resolved
    applyTheme(resolved)
    for _, tab in ipairs(self.Tabs) do
        local selected = tab == self.SelectedTab
        tab.Button.BackgroundColor3 = selected and resolved.AccentSoft or resolved.Surface
        tab.ButtonText.TextColor3 = selected and resolved.Text or resolved.TextMuted
        tab.ButtonIcon.ImageColor3 = selected and resolved.Accent or resolved.TextMuted
        tab.Indicator.BackgroundColor3 = resolved.Accent
    end
    for _, control in pairs(self._controls) do
        if type(control.RefreshTheme) == "function" then
            control:RefreshTheme()
        end
    end
    self:SetStatus("Theme updated", "accent")
    return true
end

function WindowMethods:Hide()
    if self.Destroyed or not self.Visible then
        return
    end
    self.Visible = false
    local scale = self.Root:FindFirstChild("OpenScale")
    if not scale then
        scale = create("UIScale", {Name = "OpenScale", Scale = 1, Parent = self.Root})
    end
    tween(scale, 0.25, {Scale = 0.94}, Enum.EasingStyle.Exponential)
    tween(self.Root, 0.22, {BackgroundTransparency = 1}, Enum.EasingStyle.Exponential)
    tween(self.Shadow, 0.2, {ImageTransparency = 1}, Enum.EasingStyle.Exponential)
    task.delay(0.24, function()
        if not self.Visible and self.Root then
            self.Root.Visible = false
            self.Shadow.Visible = false
            self.MobileToggle.Visible = true
            self.MobileToggle.Size = UDim2.fromOffset(0, 46)
            tween(self.MobileToggle, 0.32, {Size = UDim2.fromOffset(126, 46)}, Enum.EasingStyle.Back)
        end
    end)
end

function WindowMethods:Show()
    if self.Destroyed or self.Visible then
        return
    end
    self.Visible = true
    self.MobileToggle.Visible = false
    self.Shadow.Visible = true
    local scale = self.Root:FindFirstChild("OpenScale")
    if not scale then
        scale = create("UIScale", {Name = "OpenScale", Scale = 0.94, Parent = self.Root})
    end
    self.Root.Visible = true
    self.Root.BackgroundTransparency = 1
    tween(scale, 0.34, {Scale = 1}, Enum.EasingStyle.Back)
    tween(self.Root, 0.28, {BackgroundTransparency = 0}, Enum.EasingStyle.Exponential)
    tween(self.Shadow, 0.35, {ImageTransparency = 0.55}, Enum.EasingStyle.Exponential)
end

function WindowMethods:Toggle()
    if self.Visible then
        self:Hide()
    else
        self:Show()
    end
end

function WindowMethods:Minimize()
    if self.Destroyed then
        return
    end
    if self.Minimized then
        self.Minimized = false
        local restore = self._beforeMinimize or UDim2.fromOffset(860, 560)
        self.Sidebar.Visible = true
        self.Content.Visible = true
        self.StatusBar.Visible = true
        tween(self.Root, 0.4, {Size = restore}, Enum.EasingStyle.Exponential)
    else
        self.Minimized = true
        self._beforeMinimize = self.Root.Size
        tween(self.Root, 0.38, {Size = UDim2.new(0, math.max(280, self.Root.AbsoluteSize.X), 0, 64)}, Enum.EasingStyle.Exponential)
        task.delay(0.2, function()
            if self.Minimized then
                self.Sidebar.Visible = false
                self.Content.Visible = false
                self.StatusBar.Visible = false
            end
        end)
    end
end

function WindowMethods:Maximize()
    if self.Destroyed then
        return
    end
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    if self.Maximized then
        self.Maximized = false
        tween(self.Root, 0.42, {
            Size = self._beforeMaximizeSize or UDim2.fromOffset(860, 560),
            Position = self._beforeMaximizePosition or UDim2.fromScale(0.5, 0.5),
        }, Enum.EasingStyle.Exponential)
    else
        self.Maximized = true
        self._beforeMaximizeSize = self.Root.Size
        self._beforeMaximizePosition = self.Root.Position
        tween(self.Root, 0.42, {
            Size = UDim2.fromOffset(math.max(320, viewport.X - 18), math.max(360, viewport.Y - 18)),
            Position = UDim2.fromScale(0.5, 0.5),
        }, Enum.EasingStyle.Exponential)
    end
end

function WindowMethods:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    disconnectBucket(self._connections)
    disconnectBucket(globalConnections)
    if self.Screen then
        self.Screen:Destroy()
    end
    if activeWindow == self then
        activeWindow = nil
        activeScreen = nil
        VaeronLib.Flags = {}
        themeBindings = {}
    end
    safeCall(self.OnDestroy)
end

function WindowMethods:CreateTab(nameOrSettings, icon)
    local settings
    if type(nameOrSettings) == "table" then
        settings = nameOrSettings
    else
        settings = {Name = nameOrSettings, Icon = icon}
    end
    settings = settings or {}
    local name = tostring(settings.Name or "Tab")
    local theme = self.Theme
    local button = create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = theme.AccentSoft,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.TabHolder,
    })
    addCorner(button, 9)
    local indicator = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 0),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = button,
    })
    addCorner(indicator, 99)
    local buttonIcon = makeIcon(button, settings.Icon or "layout-dashboard", 18, "TextMuted")
    buttonIcon.Position = UDim2.fromOffset(13, 12)
    local buttonText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(42, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = button,
    })
    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarImageTransparency = 0.25,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = self.Pages,
    })
    addPadding(page, 1, 5, 1, 10)
    addList(page, 8)
    bindTheme(page, "ScrollBarImageColor3", "Accent")

    local tab = setmetatable({
        Name = name,
        Icon = settings.Icon,
        Button = button,
        ButtonIcon = buttonIcon,
        ButtonText = buttonText,
        Indicator = indicator,
        Page = page,
        _container = page,
        _window = self,
        _tab = nil,
        _elements = {},
    }, WidgetHost)
    tab._tab = tab
    table.insert(self.Tabs, tab)
    connect(button.MouseEnter, function()
        tween(button, 0.16, {BackgroundColor3 = self.SelectedTab == tab and self.Theme.AccentSoft or self.Theme.SurfaceHover})
    end, self._connections)
    connect(button.MouseLeave, function()
        tween(button, 0.2, {BackgroundColor3 = self.SelectedTab == tab and self.Theme.AccentSoft or self.Theme.Surface})
    end, self._connections)
    connect(button.Activated, function()
        self:SelectTab(tab)
    end, self._connections)
    if not self.SelectedTab then
        self:SelectTab(tab)
    end
    self:_updateResponsive()
    return tab
end

local function promptDiscord(window, discord)
    if type(discord) ~= "table" or discord.Enabled ~= true then
        return
    end
    local invite = tostring(discord.Invite or ""):gsub("https?://", ""):gsub("discord%.gg/", ""):gsub("/", "")
    if invite == "" then
        return
    end
    local rememberPath = "VaeronLib/discord_" .. sanitizeFileName(invite) .. ".joined"
    if discord.RememberJoins and fileExists(rememberPath) then
        return
    end
    VaeronLib:Notify({
        Title = tostring(discord.Title or "Join our community"),
        Content = tostring(discord.Content or ("Open the Discord invite: discord.gg/" .. invite)),
        Image = "user",
        Duration = tonumber(discord.Duration) or 12,
        Actions = {
            {
                Name = "Join",
                Primary = true,
                Callback = function()
                    local requestFunction = (syn and syn.request)
                        or (http and http.request) or http_request or request
                    local rpcSuccess = false
                    if type(requestFunction) == "function" then
                        local requestOk, response = pcall(requestFunction, {
                            Url = "http://127.0.0.1:6463/rpc?v=1",
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                Origin = "https://discord.com",
                            },
                            Body = HttpService:JSONEncode({
                                cmd = "INVITE_BROWSER",
                                nonce = HttpService:GenerateGUID(false),
                                args = {code = invite},
                            }),
                        })
                        rpcSuccess = requestOk and type(response) == "table"
                            and (response.Success == true or response.StatusCode == 200 or response.StatusCode == 204)
                    end
                    if not rpcSuccess and type(setclipboard) == "function" then
                        pcall(setclipboard, "https://discord.gg/" .. invite)
                    end
                    if discord.RememberJoins and filesystemReady() then
                        ensureFolder("VaeronLib")
                        pcall(writefile, rememberPath, tostring(os.time()))
                    end
                    VaeronLib:Notify({
                        Title = rpcSuccess and "Discord opened" or "Invite copied",
                        Content = rpcSuccess and "Complete the join inside Discord."
                            or ("Open discord.gg/" .. invite),
                        Image = rpcSuccess and "circle-check" or "copy",
                        Duration = 4,
                    })
                end,
            },
            {Name = "Later", Callback = function() end},
        },
    })
end

function VaeronLib:CreateWindow(settings)
    settings = settings or {}
    if activeWindow and not activeWindow.Destroyed then
        activeWindow:Destroy()
    end
    disconnectBucket(globalConnections)
    globalConnections = {}
    themeBindings = {}
    VaeronLib.Flags = {}

    local selectedTheme = settings.Theme
    if type(selectedTheme) == "string" then
        selectedTheme = VaeronLib.Themes[selectedTheme]
    end
    if type(selectedTheme) == "table" and selectedTheme ~= VaeronLib.Themes.Vaeron
        and selectedTheme ~= VaeronLib.Themes.Midnight and selectedTheme ~= VaeronLib.Themes.Ocean
        and selectedTheme ~= VaeronLib.Themes.Light then
        local mergedTheme = {}
        for key, value in pairs(VaeronLib.Themes.Vaeron) do
            mergedTheme[key] = value
        end
        for key, value in pairs(selectedTheme) do
            if typeof(value) == "Color3" then
                mergedTheme[key] = value
            end
        end
        selectedTheme = mergedTheme
    elseif type(selectedTheme) ~= "table" then
        selectedTheme = VaeronLib.Themes.Vaeron
    end

    local window = setmetatable({
        Name = tostring(settings.Name or "VaeronLib"),
        Theme = selectedTheme,
        Tabs = {},
        SelectedTab = nil,
        Visible = true,
        Destroyed = false,
        Minimized = false,
        Maximized = false,
        ReducedMotion = settings.ReducedMotion == true,
        AnimationSpeed = tonumber(settings.AnimationSpeed) or 1,
        ConfigurationSaving = settings.ConfigurationSaving or {Enabled = false},
        ToggleKey = enumKey(settings.ToggleUIKeybind or settings.ToggleKey, Enum.KeyCode.RightControl),
        _controls = {},
        _searchItems = {},
        _connections = {},
        _saveSerial = 0,
        OnDestroy = settings.OnDestroy,
    }, WindowMethods)
    activeWindow = window

    local screen = create("ScreenGui", {
        Name = "VaeronLib_" .. sanitizeFileName(window.Name),
        DisplayOrder = tonumber(settings.DisplayOrder) or 999999,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    })
    protectGui(screen)
    local parent = getGuiParent()
    pcall(function()
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == screen.Name then
                child:Destroy()
            end
        end
    end)
    local parented = pcall(function()
        screen.Parent = parent
    end)
    if not parented then
        screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    activeScreen = screen
    window.Screen = screen

    if settings.LoadingEnabled ~= false then
        showLoading(screen, settings)
    end
    if settings.KeySystem == true then
        runKeyGate(screen, settings.KeySettings or {})
    end

    createWindowShell(window, screen, settings)
    window.MobileToggle = createMobileToggle(window, screen, settings.ShowText or "Open Vaeron")
    window:_updateResponsive()

    local camera = workspace.CurrentCamera
    if camera then
        connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
            window:_updateResponsive()
        end, window._connections)
    end
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        window:_updateResponsive()
    end, window._connections)
    connect(UserInputService.InputBegan, function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == window.ToggleKey then
            window:Toggle()
        elseif input.KeyCode == Enum.KeyCode.Slash and window.Visible and window.SearchFrame.Visible then
            window.SearchBox:CaptureFocus()
        elseif input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            and window.Visible and window.SearchFrame.Visible then
            window.SearchBox:CaptureFocus()
        end
    end, window._connections)
    table.insert(VaeronLib.Windows, window)
    window:SetStatus("Ready", "success")
    if settings.DisablePrompts ~= true then
        task.defer(promptDiscord, window, settings.Discord)
    end
    return window
end

function VaeronLib:SetVisibility(visible)
    if not activeWindow then
        return false
    end
    if visible then
        activeWindow:Show()
    else
        activeWindow:Hide()
    end
    return true
end

function VaeronLib:IsVisible()
    return activeWindow ~= nil and activeWindow.Visible == true
end

function VaeronLib:Destroy()
    if activeWindow then
        activeWindow:Destroy()
    end
end

local function attachControlBase(control, host, frame, settings)
    control.Frame = frame
    control.Name = tostring(settings.Name or "Element")
    control.Disabled = settings.Disabled == true
    control._window = host._window
    control._callback = settings.Callback

    function control:SetVisible(visible)
        self.Frame:SetAttribute("VaeronVisible", visible == true)
        self.Frame.Visible = visible == true
        return self
    end

    function control:SetDisabled(disabled)
        self.Disabled = disabled == true
        self.Frame.BackgroundTransparency = self.Disabled and 0.45 or 0
        return self
    end

    function control:Destroy()
        if self.Flag then
            self._window._controls[self.Flag] = nil
            VaeronLib.Flags[self.Flag] = nil
        end
        if self.Frame then
            self.Frame:Destroy()
        end
    end

    return control
end

local function commitValue(control, value, silent)
    if control.Flag then
        VaeronLib.Flags[control.Flag] = value
    end
    if not silent then
        safeCall(control._callback, value)
    end
    if not silent and not control._window._loadingConfiguration then
        scheduleSave(control._window)
    end
end

function WidgetHost:CreateSection(nameOrSettings)
    local settings = type(nameOrSettings) == "table" and nameOrSettings or {Name = nameOrSettings}
    settings = settings or {}
    local theme = currentTheme()
    local frame = create("Frame", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = self._container,
    })
    local line = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Parent = frame,
    })
    bindTheme(line, "BackgroundColor3", "StrokeSoft")
    local label = create("TextLabel", {
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        Text = string.upper(tostring(settings.Name or "SECTION")),
        TextColor3 = theme.TextMuted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    addPadding(label, 8, 8, 0, 0)
    bindTheme(label, "BackgroundColor3", "Background")
    bindTheme(label, "TextColor3", "TextMuted")
    local section = {Frame = frame, Name = settings.Name}
    function section:Set(newName)
        self.Name = tostring(newName or "SECTION")
        label.Text = string.upper(self.Name)
        return self
    end
    function section:SetVisible(visible)
        frame.Visible = visible == true
        return self
    end
    return section
end

function WidgetHost:CreateDivider()
    local theme = currentTheme()
    local frame = create("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        Parent = self._container,
    })
    local line = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Parent = frame,
    })
    bindTheme(line, "BackgroundColor3", "StrokeSoft")
    local divider = {Frame = frame}
    function divider:Set(visible)
        frame.Visible = visible == true
        return self
    end
    return divider
end

function WidgetHost:CreateSpacer(height)
    local frame = create("Frame", {
        Name = "Spacer",
        Size = UDim2.new(1, 0, 0, tonumber(height) or 8),
        BackgroundTransparency = 1,
        Parent = self._container,
    })
    return frame
end

function WidgetHost:CreateLabel(textOrSettings, icon, color, ignoreTheme)
    local settings
    if type(textOrSettings) == "table" then
        settings = textOrSettings
    else
        settings = {Name = textOrSettings, Icon = icon, Color = color, IgnoreTheme = ignoreTheme}
    end
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or settings.Text or "Label", 48, settings.Tooltip)
    label.Size = UDim2.new(1, settings.Icon and -58 or -32, 1, 0)
    if settings.Color then
        label.TextColor3 = settings.Color
    elseif not settings.IgnoreTheme then
        bindTheme(label, "TextColor3", "Text")
    end
    label:SetAttribute("VaeronIgnoreThemeTextColor3", settings.IgnoreTheme == true)
    local image
    if settings.Icon then
        image = makeIcon(frame, settings.Icon, 18, "Accent")
        image.AnchorPoint = Vector2.new(1, 0.5)
        image.Position = UDim2.new(1, -16, 0.5, 0)
    end
    local value = {Frame = frame, CurrentValue = label.Text}
    function value:Set(newText, newIcon, newColor, newIgnoreTheme)
        label.Text = tostring(newText or "")
        self.CurrentValue = label.Text
        if newColor then
            label.TextColor3 = newColor
        end
        if newIgnoreTheme ~= nil then
            label:SetAttribute("VaeronIgnoreThemeTextColor3", newIgnoreTheme == true)
        end
        if not label:GetAttribute("VaeronIgnoreThemeTextColor3") and not newColor then
            label.TextColor3 = currentTheme().Text
        end
        if newIcon ~= nil then
            if not image then
                image = makeIcon(frame, newIcon, 18, "Accent")
                image.AnchorPoint = Vector2.new(1, 0.5)
                image.Position = UDim2.new(1, -16, 0.5, 0)
            else
                applyIcon(image, newIcon)
            end
        end
        return self
    end
    return value
end

function WidgetHost:CreateParagraph(settings)
    settings = settings or {}
    if type(settings) == "string" then
        settings = {Title = "Information", Content = settings}
    end
    local theme = currentTheme()
    local frame = create("Frame", {
        Name = "Paragraph",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = self._container,
    })
    addCorner(frame, 11)
    local border = addStroke(frame, theme.StrokeSoft, 1, 0.18)
    addPadding(frame, 16, 16, 14, 14)
    bindTheme(frame, "BackgroundColor3", "SurfaceAlt")
    bindTheme(border, "Color", "StrokeSoft")
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    addList(holder, 6)
    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(settings.Title or "Information"),
        TextColor3 = theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    bindTheme(title, "TextColor3", "Text")
    local content = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(settings.Content or ""),
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = holder,
    })
    bindTheme(content, "TextColor3", "TextMuted")
    self:_registerSearch((settings.Title or "") .. " " .. (settings.Content or ""), frame)
    local paragraph = {Frame = frame}
    function paragraph:Set(newSettings)
        if type(newSettings) == "string" then
            content.Text = newSettings
        elseif type(newSettings) == "table" then
            if newSettings.Title ~= nil then
                title.Text = tostring(newSettings.Title)
            end
            if newSettings.Content ~= nil then
                content.Text = tostring(newSettings.Content)
            end
        end
        return self
    end
    return paragraph
end

function WidgetHost:CreateButton(settings)
    settings = type(settings) == "table" and settings or {Name = settings}
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Button", 54, settings.Tooltip)
    local iconBack = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = currentTheme().AccentSoft,
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(iconBack, 8)
    bindTheme(iconBack, "BackgroundColor3", "AccentSoft")
    local icon = makeIcon(iconBack, settings.Icon or "mouse-pointer-click", 16, "Accent")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    local control = attachControlBase({}, self, frame, settings)
    function control:Set(newName)
        self.Name = tostring(newName or self.Name)
        label.Text = self.Name
        return self
    end
    function control:Get()
        return self.Name
    end
    makeClickArea(frame, function()
        if not control.Disabled then
            safeCall(settings.Callback)
        end
    end)
    return control
end

function WidgetHost:CreateToggle(settings)
    settings = settings or {}
    local frame = baseElement(self, settings.Name or "Toggle", 54, settings.Tooltip)
    local theme = currentTheme()
    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(42, 24),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(track, 99)
    local trackStroke = addStroke(track, theme.Stroke, 1, 0.15)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = theme.TextMuted,
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(knob, 99)
    local control = attachControlBase({}, self, frame, settings)
    function control:Set(value, silent)
        value = value == true
        self.CurrentValue = value
        tween(track, 0.22, {BackgroundColor3 = value and currentTheme().Accent or currentTheme().Surface}, Enum.EasingStyle.Exponential)
        tween(trackStroke, 0.22, {Color = value and currentTheme().Accent or currentTheme().Stroke})
        tween(knob, 0.28, {
            Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = value and currentTheme().TextDark or currentTheme().TextMuted,
        }, Enum.EasingStyle.Back)
        commitValue(self, value, silent)
        return self
    end
    function control:Get()
        return self.CurrentValue
    end
    function control:RefreshTheme()
        local value = self.CurrentValue == true
        track.BackgroundColor3 = value and currentTheme().Accent or currentTheme().Surface
        trackStroke.Color = value and currentTheme().Accent or currentTheme().Stroke
        knob.BackgroundColor3 = value and currentTheme().TextDark or currentTheme().TextMuted
        return self
    end
    registerFlag(self._window, control, settings.Flag, "Toggle", settings.CurrentValue == true)
    control:Set(settings.CurrentValue == true, true)
    makeClickArea(frame, function()
        if not control.Disabled then
            control:Set(not control.CurrentValue)
        end
    end)
    return control
end

function WidgetHost:CreateSlider(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Slider", 76, settings.Tooltip)
    label.Size = UDim2.new(1, -110, 0, 40)
    local theme = currentTheme()
    local minimum = tonumber(settings.Range and settings.Range[1]) or tonumber(settings.Min) or 0
    local maximum = tonumber(settings.Range and settings.Range[2]) or tonumber(settings.Max) or 100
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    local increment = math.abs(tonumber(settings.Increment) or 1)
    local suffix = tostring(settings.Suffix or "")
    local valueLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(92, 26),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold,
        Text = "",
        TextColor3 = theme.Accent,
        TextSize = 11,
        Parent = frame,
    })
    addCorner(valueLabel, 7)
    bindTheme(valueLabel, "BackgroundColor3", "Surface")
    bindTheme(valueLabel, "TextColor3", "Accent")
    local bar = create("Frame", {
        Position = UDim2.new(0, 16, 1, -22),
        Size = UDim2.new(1, -32, 0, 5),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(bar, 99)
    bindTheme(bar, "BackgroundColor3", "Surface")
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    })
    addCorner(fill, 99)
    bindTheme(fill, "BackgroundColor3", "Accent")
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(13, 13),
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        Parent = bar,
    })
    addCorner(knob, 99)
    bindTheme(knob, "BackgroundColor3", "Text")
    local hitbox = create("TextButton", {
        Position = UDim2.new(0, 10, 1, -35),
        Size = UDim2.new(1, -20, 0, 30),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = frame,
    })
    local control = attachControlBase({}, self, frame, settings)
    control.Range = {minimum, maximum}
    control.Increment = increment
    control.Suffix = suffix
    function control:Set(value, silent)
        value = clamp(tonumber(value) or minimum, minimum, maximum)
        value = round(value, increment)
        value = clamp(value, minimum, maximum)
        self.CurrentValue = value
        local alpha = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        tween(fill, 0.12, {Size = UDim2.fromScale(alpha, 1)}, Enum.EasingStyle.Exponential)
        tween(knob, 0.14, {Position = UDim2.fromScale(alpha, 0.5)}, Enum.EasingStyle.Exponential)
        valueLabel.Text = formatNumber(value) .. suffix
        commitValue(self, value, silent)
        return self
    end
    function control:Get()
        return self.CurrentValue
    end
    registerFlag(self._window, control, settings.Flag, "Slider", settings.CurrentValue or minimum)
    control:Set(settings.CurrentValue or minimum, true)
    local dragging = false
    local function setFromPoint(point)
        local alpha = clamp((point.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        control:Set(minimum + (maximum - minimum) * alpha)
    end
    connect(hitbox.InputBegan, function(input)
        if control.Disabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromPoint(inputPosition(input))
            tween(knob, 0.15, {Size = UDim2.fromOffset(17, 17)}, Enum.EasingStyle.Back)
        end
    end, self._window._connections)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromPoint(inputPosition(input))
        end
    end, self._window._connections)
    connect(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(knob, 0.18, {Size = UDim2.fromOffset(13, 13)}, Enum.EasingStyle.Back)
        end
    end, self._window._connections)
    return control
end

function WidgetHost:CreateInput(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Input", 62, settings.Tooltip)
    label.Size = UDim2.new(0.42, -18, 1, 0)
    local theme = currentTheme()
    local inputBack = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0.56, 0, 0, 38),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(inputBack, 9)
    local inputStroke = addStroke(inputBack, theme.Stroke, 1, 0.2)
    bindTheme(inputBack, "BackgroundColor3", "Surface")
    bindTheme(inputStroke, "Color", "Stroke")
    local box = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = tostring(settings.PlaceholderText or settings.Placeholder or "Type here..."),
        PlaceholderColor3 = theme.TextMuted,
        Text = tostring(settings.CurrentValue or ""),
        TextColor3 = theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = inputBack,
    })
    bindTheme(box, "TextColor3", "Text")
    bindTheme(box, "PlaceholderColor3", "TextMuted")
    local control = attachControlBase({}, self, frame, settings)
    function control:Set(value, silent)
        value = tostring(value or "")
        self.CurrentValue = value
        self._settingText = true
        box.Text = value
        self._settingText = false
        commitValue(self, value, silent)
        return self
    end
    function control:Get()
        return self.CurrentValue
    end
    registerFlag(self._window, control, settings.Flag, "Input", tostring(settings.CurrentValue or ""))
    control:Set(settings.CurrentValue or "", true)
    connect(box.Focused, function()
        tween(inputStroke, 0.18, {Color = currentTheme().Accent, Transparency = 0})
    end, self._window._connections)
    connect(box.FocusLost, function(enterPressed)
        tween(inputStroke, 0.2, {Color = currentTheme().Stroke, Transparency = 0.2})
        if settings.Finished and not enterPressed then
            return
        end
        control:Set(box.Text)
        if settings.RemoveTextAfterFocusLost then
            box.Text = ""
        end
    end, self._window._connections)
    if settings.LiveUpdate then
        connect(box:GetPropertyChangedSignal("Text"), function()
            if control._settingText then
                return
            end
            control.CurrentValue = box.Text
            if control.Flag then
                VaeronLib.Flags[control.Flag] = box.Text
            end
            safeCall(control._callback, box.Text)
            scheduleSave(control._window)
        end, self._window._connections)
    end
    control.Input = box
    return control
end

WidgetHost.CreateTextbox = WidgetHost.CreateInput
WidgetHost.CreateTextBox = WidgetHost.CreateInput

function WidgetHost:CreateDropdown(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Dropdown", 54, settings.Tooltip)
    label.Size = UDim2.new(0.42, -18, 0, 54)
    local theme = currentTheme()
    local selector = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 9),
        Size = UDim2.new(0.56, 0, 0, 36),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 5,
        Parent = frame,
    })
    addCorner(selector, 9)
    local selectorStroke = addStroke(selector, theme.Stroke, 1, 0.2)
    bindTheme(selector, "BackgroundColor3", "Surface")
    bindTheme(selectorStroke, "Color", "Stroke")
    local selectedLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -42, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "Select...",
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 6,
        Parent = selector,
    })
    bindTheme(selectedLabel, "TextColor3", "TextMuted")
    local arrow = makeIcon(selector, "chevron-down", 15, "TextMuted")
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -11, 0.5, 0)
    arrow.ZIndex = 6
    local optionsHolder = create("ScrollingFrame", {
        Name = "Options",
        Position = UDim2.fromOffset(12, 54),
        Size = UDim2.new(1, -24, 0, 0),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        Visible = false,
        ZIndex = 6,
        Parent = frame,
    })
    addCorner(optionsHolder, 9)
    addPadding(optionsHolder, 6, 6, 6, 6)
    addList(optionsHolder, 4)
    bindTheme(optionsHolder, "BackgroundColor3", "Surface")
    bindTheme(optionsHolder, "ScrollBarImageColor3", "Accent")

    local control = attachControlBase({}, self, frame, settings)
    control.Options = {}
    control.CurrentOption = {}
    control.MultipleOptions = settings.MultipleOptions == true
    control.Open = false
    control._optionButtons = {}

    local function contains(list, value)
        for index, item in ipairs(list) do
            if item == value then
                return true, index
            end
        end
        return false, nil
    end

    local function updateDisplay()
        if #control.CurrentOption == 0 then
            selectedLabel.Text = tostring(settings.Placeholder or "Select...")
            selectedLabel.TextColor3 = currentTheme().TextMuted
        else
            selectedLabel.Text = table.concat(control.CurrentOption, ", ")
            selectedLabel.TextColor3 = currentTheme().Text
        end
        for option, buttonData in pairs(control._optionButtons) do
            local selected = contains(control.CurrentOption, option)
            tween(buttonData.Button, 0.16, {
                BackgroundColor3 = selected and currentTheme().AccentSoft or currentTheme().SurfaceAlt,
            })
            tween(buttonData.Label, 0.16, {
                TextColor3 = selected and currentTheme().Accent or currentTheme().TextMuted,
            })
            buttonData.Check.Visible = selected
        end
    end

    function control:Close()
        if not self.Open then
            return self
        end
        self.Open = false
        tween(arrow, 0.22, {Rotation = 0}, Enum.EasingStyle.Exponential)
        tween(frame, 0.3, {Size = UDim2.new(1, 0, 0, 54)}, Enum.EasingStyle.Exponential)
        tween(optionsHolder, 0.25, {Size = UDim2.new(1, -24, 0, 0)}, Enum.EasingStyle.Exponential)
        task.delay(0.26, function()
            if not control.Open then
                optionsHolder.Visible = false
            end
        end)
        if self._window._openDropdown == self then
            self._window._openDropdown = nil
        end
        return self
    end

    function control:OpenMenu()
        if self.Open or self.Disabled then
            return self
        end
        if self._window._openDropdown and self._window._openDropdown ~= self then
            self._window._openDropdown:Close()
        end
        self._window._openDropdown = self
        self.Open = true
        local visibleRows = math.min(#self.Options, tonumber(settings.MaxVisibleOptions) or 5)
        local optionsHeight = visibleRows > 0 and (visibleRows * 36 + 12) or 48
        optionsHolder.Visible = true
        tween(arrow, 0.22, {Rotation = 180}, Enum.EasingStyle.Exponential)
        tween(optionsHolder, 0.28, {Size = UDim2.new(1, -24, 0, optionsHeight)}, Enum.EasingStyle.Exponential)
        tween(frame, 0.32, {Size = UDim2.new(1, 0, 0, 60 + optionsHeight)}, Enum.EasingStyle.Exponential)
        return self
    end

    function control:ToggleMenu()
        if self.Open then
            return self:Close()
        end
        return self:OpenMenu()
    end

    function control:Set(value, silent)
        local values = type(value) == "table" and value or {value}
        local normalized = {}
        for _, item in ipairs(values) do
            item = tostring(item)
            local valid = contains(self.Options, item)
            if valid and not contains(normalized, item) then
                table.insert(normalized, item)
                if not self.MultipleOptions then
                    break
                end
            end
        end
        self.CurrentOption = normalized
        updateDisplay()
        local output = {}
        for index, item in ipairs(normalized) do
            output[index] = item
        end
        commitValue(self, output, silent)
        return self
    end

    function control:Get()
        local output = {}
        for index, item in ipairs(self.CurrentOption) do
            output[index] = item
        end
        return output
    end

    function control:RefreshTheme()
        selector.BackgroundColor3 = currentTheme().Surface
        selectorStroke.Color = currentTheme().Stroke
        optionsHolder.BackgroundColor3 = currentTheme().Surface
        updateDisplay()
        for option, buttonData in pairs(self._optionButtons) do
            local selected = contains(self.CurrentOption, option)
            buttonData.Button.BackgroundColor3 = selected and currentTheme().AccentSoft or currentTheme().SurfaceAlt
            buttonData.Label.TextColor3 = selected and currentTheme().Accent or currentTheme().TextMuted
            buttonData.Check.TextColor3 = currentTheme().Accent
        end
        return self
    end

    function control:Refresh(options, preserveSelection)
        self.Options = {}
        for _, option in ipairs(options or {}) do
            table.insert(self.Options, tostring(option))
        end
        for _, child in ipairs(optionsHolder:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end
        self._optionButtons = {}
        for _, option in ipairs(self.Options) do
            local optionButton = create("TextButton", {
                Name = option,
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = currentTheme().SurfaceAlt,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 7,
                Parent = optionsHolder,
            })
            addCorner(optionButton, 7)
            local optionLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -38, 1, 0),
                Font = Enum.Font.Gotham,
                Text = option,
                TextColor3 = currentTheme().TextMuted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 8,
                Parent = optionButton,
            })
            local check = create("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromOffset(30, 32),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "✓",
                TextColor3 = currentTheme().Accent,
                TextSize = 12,
                Visible = false,
                ZIndex = 8,
                Parent = optionButton,
            })
            self._optionButtons[option] = {Button = optionButton, Label = optionLabel, Check = check}
            connect(optionButton.Activated, function()
                local selected, index = contains(control.CurrentOption, option)
                local nextSelection = {}
                for i, current in ipairs(control.CurrentOption) do
                    nextSelection[i] = current
                end
                if control.MultipleOptions then
                    if selected then
                        table.remove(nextSelection, index)
                    else
                        table.insert(nextSelection, option)
                    end
                else
                    nextSelection = {option}
                end
                control:Set(nextSelection)
                if not control.MultipleOptions then
                    control:Close()
                end
            end, self._window._connections)
        end
        if preserveSelection then
            self:Set(self.CurrentOption, true)
        else
            self:Set({}, true)
        end
        return self
    end

    registerFlag(self._window, control, settings.Flag, "Dropdown", settings.CurrentOption or {})
    control:Refresh(settings.Options or {}, false)
    control:Set(settings.CurrentOption or {}, true)
    connect(selector.Activated, function()
        control:ToggleMenu()
    end, self._window._connections)
    return control
end

local function colorToHex(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function hexToColor(value)
    local hex = tostring(value or ""):gsub("#", ""):gsub("%s+", "")
    if #hex == 3 then
        hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
    end
    if #hex ~= 6 or not hex:match("^[%da-fA-F]+$") then
        return nil
    end
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end

function WidgetHost:CreateColorPicker(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Color Picker", 54, settings.Tooltip)
    label.Size = UDim2.new(1, -92, 0, 54)
    local theme = currentTheme()
    local previewButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 9),
        Size = UDim2.fromOffset(62, 36),
        BackgroundColor3 = settings.Color or Color3.fromRGB(102, 204, 255),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 5,
        Parent = frame,
    })
    addCorner(previewButton, 9)
    addStroke(previewButton, theme.Stroke, 1, 0.05)
    local checker = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "•••",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        TextTransparency = 0.35,
        ZIndex = 6,
        Parent = previewButton,
    })

    local panel = create("Frame", {
        Name = "Picker",
        Position = UDim2.fromOffset(12, 56),
        Size = UDim2.new(1, -24, 0, 166),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 6,
        Parent = frame,
    })
    addCorner(panel, 10)
    local panelStroke = addStroke(panel, theme.Stroke, 1, 0.16)
    bindTheme(panel, "BackgroundColor3", "Surface")
    bindTheme(panelStroke, "Color", "Stroke")

    local svArea = create("Frame", {
        Name = "SaturationValue",
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -64, 0, 104),
        BackgroundColor3 = Color3.fromHSV(0.55, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 7,
        Parent = panel,
    })
    addCorner(svArea, 8)
    local whiteLayer = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 8,
        Parent = svArea,
    })
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = whiteLayer,
    })
    local blackLayer = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 9,
        Parent = svArea,
    })
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = blackLayer,
    })
    local svInput = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 11,
        Parent = svArea,
    })
    local svMarker = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = svArea,
    })
    addCorner(svMarker, 99)
    addStroke(svMarker, Color3.new(1, 1, 1), 2, 0)

    local hueArea = create("Frame", {
        Name = "Hue",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.fromOffset(36, 104),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 7,
        Parent = panel,
    })
    addCorner(hueArea, 8)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hueArea,
    })
    local hueInput = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = hueArea,
    })
    local hueMarker = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.new(1, 4, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = hueArea,
    })
    addCorner(hueMarker, 99)
    addStroke(hueMarker, Color3.new(0, 0, 0), 1, 0.45)

    local hexBack = create("Frame", {
        Position = UDim2.fromOffset(10, 124),
        Size = UDim2.fromOffset(116, 32),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        ZIndex = 7,
        Parent = panel,
    })
    addCorner(hexBack, 8)
    bindTheme(hexBack, "BackgroundColor3", "SurfaceAlt")
    local hexInput = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        ClearTextOnFocus = false,
        Font = Enum.Font.Code,
        Text = "#66CCFF",
        TextColor3 = theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8,
        Parent = hexBack,
    })
    bindTheme(hexInput, "TextColor3", "Text")
    local rgbLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(136, 124),
        Size = UDim2.new(1, -146, 0, 32),
        Font = Enum.Font.GothamMedium,
        Text = "RGB 102, 204, 255",
        TextColor3 = theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 7,
        Parent = panel,
    })
    bindTheme(rgbLabel, "TextColor3", "TextMuted")

    local control = attachControlBase({}, self, frame, settings)
    control.Open = false
    control.Hue = 0.55
    control.Saturation = 1
    control.Value = 1

    local function updateMarkers()
        svArea.BackgroundColor3 = Color3.fromHSV(control.Hue, 1, 1)
        svMarker.Position = UDim2.fromScale(control.Saturation, 1 - control.Value)
        hueMarker.Position = UDim2.fromScale(0.5, control.Hue)
    end

    function control:Set(color, silent)
        if typeof(color) ~= "Color3" then
            return self
        end
        self.Color = color
        self.CurrentValue = color
        self.Hue, self.Saturation, self.Value = color:ToHSV()
        previewButton.BackgroundColor3 = color
        checker.TextColor3 = color.R + color.G + color.B > 1.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
        hexInput.Text = colorToHex(color)
        rgbLabel.Text = string.format(
            "RGB %d, %d, %d",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5)
        )
        updateMarkers()
        commitValue(self, color, silent)
        return self
    end

    function control:Get()
        return self.Color
    end

    function control:Close()
        if not self.Open then
            return self
        end
        self.Open = false
        tween(frame, 0.3, {Size = UDim2.new(1, 0, 0, 54)}, Enum.EasingStyle.Exponential)
        tween(panel, 0.24, {BackgroundTransparency = 1}, Enum.EasingStyle.Exponential)
        task.delay(0.25, function()
            if not control.Open then
                panel.Visible = false
            end
        end)
        return self
    end

    function control:OpenPicker()
        if self.Open or self.Disabled then
            return self
        end
        self.Open = true
        panel.Visible = true
        panel.BackgroundTransparency = 1
        tween(frame, 0.32, {Size = UDim2.new(1, 0, 0, 232)}, Enum.EasingStyle.Exponential)
        tween(panel, 0.24, {BackgroundTransparency = 0}, Enum.EasingStyle.Exponential)
        task.defer(updateMarkers)
        return self
    end

    function control:TogglePicker()
        if self.Open then
            return self:Close()
        end
        return self:OpenPicker()
    end

    registerFlag(self._window, control, settings.Flag, "ColorPicker", settings.Color or Color3.fromRGB(102, 204, 255))
    control:Set(settings.Color or Color3.fromRGB(102, 204, 255), true)
    connect(previewButton.Activated, function()
        control:TogglePicker()
    end, self._window._connections)

    local draggingSV = false
    local draggingHue = false
    local function updateSV(point)
        local x = clamp((point.X - svArea.AbsolutePosition.X) / math.max(svArea.AbsoluteSize.X, 1), 0, 1)
        local y = clamp((point.Y - svArea.AbsolutePosition.Y) / math.max(svArea.AbsoluteSize.Y, 1), 0, 1)
        control:Set(Color3.fromHSV(control.Hue, x, 1 - y))
    end
    local function updateHue(point)
        local y = clamp((point.Y - hueArea.AbsolutePosition.Y) / math.max(hueArea.AbsoluteSize.Y, 1), 0, 1)
        control:Set(Color3.fromHSV(y, control.Saturation, control.Value))
    end
    connect(svInput.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
            updateSV(inputPosition(input))
        end
    end, self._window._connections)
    connect(hueInput.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            updateHue(inputPosition(input))
        end
    end, self._window._connections)
    connect(UserInputService.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            if draggingSV then
                updateSV(inputPosition(input))
            elseif draggingHue then
                updateHue(inputPosition(input))
            end
        end
    end, self._window._connections)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = false
            draggingHue = false
        end
    end, self._window._connections)
    connect(hexInput.FocusLost, function()
        local color = hexToColor(hexInput.Text)
        if color then
            control:Set(color)
        else
            hexInput.Text = colorToHex(control.Color)
        end
    end, self._window._connections)
    return control
end

local function keyDisplay(key)
    if typeof(key) ~= "EnumItem" then
        return "NONE"
    end
    local name = key.Name
    local replacements = {
        LeftControl = "LCTRL", RightControl = "RCTRL",
        LeftShift = "LSHIFT", RightShift = "RSHIFT",
        LeftAlt = "LALT", RightAlt = "RALT",
        MouseButton1 = "M1", MouseButton2 = "M2",
    }
    return replacements[name] or string.upper(name)
end

function WidgetHost:CreateKeybind(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Keybind", 54, settings.Tooltip)
    label.Size = UDim2.new(1, -128, 1, 0)
    local theme = currentTheme()
    local keyButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(102, 34),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "RCTRL",
        TextColor3 = theme.Accent,
        TextSize = 10,
        Parent = frame,
    })
    addCorner(keyButton, 8)
    local keyStroke = addStroke(keyButton, theme.Stroke, 1, 0.2)
    bindTheme(keyButton, "BackgroundColor3", "Surface")
    bindTheme(keyButton, "TextColor3", "Accent")
    bindTheme(keyStroke, "Color", "Stroke")
    local control = attachControlBase({}, self, frame, settings)
    control.HoldToInteract = settings.HoldToInteract == true
    control.Capturing = false
    function control:Set(value, silent)
        local key = enumKey(value, self.CurrentKeybind or Enum.KeyCode.RightControl)
        self.CurrentKeybind = key
        keyButton.Text = keyDisplay(key)
        if self.Flag then
            VaeronLib.Flags[self.Flag] = key
        end
        if not silent and not self._window._loadingConfiguration then
            scheduleSave(self._window)
        end
        if not silent and type(settings.ChangedCallback) == "function" then
            safeCall(settings.ChangedCallback, key)
        end
        return self
    end
    function control:Get()
        return self.CurrentKeybind
    end
    function control:BeginCapture()
        if self.Disabled or self.Capturing then
            return self
        end
        self.Capturing = true
        keyButton.Text = "PRESS A KEY"
        tween(keyStroke, 0.18, {Color = currentTheme().Accent, Transparency = 0})
        return self
    end
    registerFlag(self._window, control, settings.Flag, "Keybind", enumKey(settings.CurrentKeybind or settings.Key, Enum.KeyCode.RightControl))
    control:Set(settings.CurrentKeybind or settings.Key or Enum.KeyCode.RightControl, true)
    connect(keyButton.Activated, function()
        control:BeginCapture()
    end, self._window._connections)
    connect(UserInputService.InputBegan, function(input, processed)
        if control.Capturing then
            if input.KeyCode == Enum.KeyCode.Unknown then
                return
            end
            control.Capturing = false
            tween(keyStroke, 0.18, {Color = currentTheme().Stroke, Transparency = 0.2})
            if input.KeyCode == Enum.KeyCode.Escape then
                keyButton.Text = keyDisplay(control.CurrentKeybind)
                return
            end
            control:Set(input.KeyCode, false)
            return
        end
        if processed or control.Disabled or input.KeyCode ~= control.CurrentKeybind then
            return
        end
        if control.HoldToInteract then
            safeCall(control._callback, true)
        else
            safeCall(control._callback, true)
        end
    end, self._window._connections)
    connect(UserInputService.InputEnded, function(input)
        if control.HoldToInteract and not control.Disabled and input.KeyCode == control.CurrentKeybind then
            safeCall(control._callback, false)
        end
    end, self._window._connections)
    return control
end

WidgetHost.CreateKeyBind = WidgetHost.CreateKeybind

function WidgetHost:CreateProgressBar(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Progress", 72, settings.Tooltip)
    label.Size = UDim2.new(1, -90, 0, 40)
    local theme = currentTheme()
    local minimum = tonumber(settings.Range and settings.Range[1]) or 0
    local maximum = tonumber(settings.Range and settings.Range[2]) or 100
    local valueText = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 11),
        Size = UDim2.fromOffset(72, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "0%",
        TextColor3 = theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame,
    })
    bindTheme(valueText, "TextColor3", "Accent")
    local bar = create("Frame", {
        Position = UDim2.new(0, 16, 1, -21),
        Size = UDim2.new(1, -32, 0, 7),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(bar, 99)
    bindTheme(bar, "BackgroundColor3", "Surface")
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = settings.Color or theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    })
    addCorner(fill, 99)
    if not settings.Color then
        bindTheme(fill, "BackgroundColor3", "Accent")
    end
    local control = attachControlBase({}, self, frame, settings)
    function control:Set(value, silent)
        value = clamp(tonumber(value) or minimum, minimum, maximum)
        self.CurrentValue = value
        local alpha = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        tween(fill, 0.35, {Size = UDim2.fromScale(alpha, 1)}, Enum.EasingStyle.Exponential)
        valueText.Text = settings.Suffix and (formatNumber(value) .. tostring(settings.Suffix))
            or (tostring(math.floor(alpha * 100 + 0.5)) .. "%")
        commitValue(self, value, silent)
        return self
    end
    function control:Get()
        return self.CurrentValue
    end
    registerFlag(self._window, control, settings.Flag, "ProgressBar", settings.CurrentValue or minimum)
    control:Set(settings.CurrentValue or minimum, true)
    return control
end

function WidgetHost:CreateStatus(settings)
    settings = settings or {}
    local frame, label = baseElement(self, settings.Name or "Status", 54, settings.Tooltip)
    label.Size = UDim2.new(1, -150, 1, 0)
    local theme = currentTheme()
    local badge = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(120, 30),
        BackgroundColor3 = theme.AccentSoft,
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(badge, 99)
    local dot = create("Frame", {
        Position = UDim2.fromOffset(11, 12),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = theme.Success,
        BorderSizePixel = 0,
        Parent = badge,
    })
    addCorner(dot, 99)
    local text = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(25, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = tostring(settings.Text or "Online"),
        TextColor3 = theme.Text,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = badge,
    })
    bindTheme(text, "TextColor3", "Text")
    local status = {Frame = frame, CurrentValue = settings.Text or "Online"}
    local function statusColor(kind)
        if typeof(kind) == "Color3" then
            return kind
        elseif kind == "warning" then
            return currentTheme().Warning
        elseif kind == "danger" or kind == "error" or kind == "offline" then
            return currentTheme().Danger
        elseif kind == "accent" then
            return currentTheme().Accent
        end
        return currentTheme().Success
    end
    function status:Set(value, kind)
        self.CurrentValue = tostring(value or "")
        text.Text = self.CurrentValue
        local color = statusColor(kind)
        dot.BackgroundColor3 = color
        badge.BackgroundColor3 = color:Lerp(currentTheme().Surface, 0.78)
        return self
    end
    function status:Get()
        return self.CurrentValue
    end
    status:Set(settings.Text or "Online", settings.Status or "success")
    return status
end

function WidgetHost:CreateGroup(settings)
    settings = type(settings) == "table" and settings or {Name = settings}
    settings = settings or {}
    local theme = currentTheme()
    local groupFrame = create("Frame", {
        Name = "Group",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self._container,
    })
    addCorner(groupFrame, 12)
    local groupStroke = addStroke(groupFrame, theme.StrokeSoft, 1, 0.1)
    bindTheme(groupFrame, "BackgroundColor3", "Surface")
    bindTheme(groupStroke, "Color", "StrokeSoft")
    addPadding(groupFrame, 8, 8, 8, 8)
    addList(groupFrame, 7)
    local header = create("TextButton", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = groupFrame,
    })
    addCorner(header, 9)
    bindTheme(header, "BackgroundColor3", "SurfaceAlt")
    local headerIcon = makeIcon(header, settings.Icon or "chevron-right", 16, "Accent")
    headerIcon.Position = UDim2.fromOffset(11, 11)
    local headerLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = tostring(settings.Name or "Group"),
        TextColor3 = theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    bindTheme(headerLabel, "TextColor3", "Text")
    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = groupFrame,
    })
    addList(content, 7)
    local group = setmetatable({
        Name = settings.Name or "Group",
        Frame = groupFrame,
        Header = header,
        Content = content,
        Collapsed = settings.Collapsed == true,
        _container = content,
        _window = self._window,
        _tab = self._tab,
        _elements = {},
    }, WidgetHost)
    function group:SetCollapsed(collapsed)
        self.Collapsed = collapsed == true
        tween(headerIcon, 0.22, {Rotation = self.Collapsed and 0 or 90}, Enum.EasingStyle.Exponential)
        content.Visible = not self.Collapsed
        return self
    end
    function group:Set(name)
        self.Name = tostring(name or "Group")
        headerLabel.Text = self.Name
        return self
    end
    function group:SetVisible(visible)
        groupFrame.Visible = visible == true
        return self
    end
    connect(header.Activated, function()
        group:SetCollapsed(not group.Collapsed)
    end, self._window._connections)
    self:_registerSearch(settings.Name or "Group", groupFrame)
    group:SetCollapsed(group.Collapsed)
    return group
end

function WidgetHost:CreateCodeBlock(settings)
    settings = type(settings) == "table" and settings or {Code = settings}
    settings = settings or {}
    local theme = currentTheme()
    local code = tostring(settings.Code or "-- code")
    local lines = 1
    for _ in code:gmatch("\n") do
        lines = lines + 1
    end
    local height = clamp(lines * 17 + 58, 94, tonumber(settings.MaxHeight) or 260)
    local frame = create("Frame", {
        Name = "CodeBlock",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = self._container,
    })
    addCorner(frame, 11)
    local border = addStroke(frame, theme.StrokeSoft, 1, 0.15)
    bindTheme(frame, "BackgroundColor3", "SurfaceAlt")
    bindTheme(border, "Color", "StrokeSoft")
    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 7),
        Size = UDim2.new(1, -80, 0, 28),
        Font = Enum.Font.GothamSemibold,
        Text = tostring(settings.Name or settings.Title or "Code"),
        TextColor3 = theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    bindTheme(title, "TextColor3", "Text")
    local copyButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 7),
        Size = UDim2.fromOffset(58, 28),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        Text = "COPY",
        TextColor3 = theme.Accent,
        TextSize = 9,
        Parent = frame,
    })
    addCorner(copyButton, 7)
    bindTheme(copyButton, "BackgroundColor3", "Surface")
    bindTheme(copyButton, "TextColor3", "Accent")
    local scroller = create("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 40),
        Size = UDim2.new(1, -20, 1, -50),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.XY,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        Parent = frame,
    })
    addCorner(scroller, 8)
    bindTheme(scroller, "BackgroundColor3", "Background")
    bindTheme(scroller, "ScrollBarImageColor3", "Accent")
    local codeLabel = create("TextLabel", {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = code,
        TextColor3 = theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = scroller,
    })
    bindTheme(codeLabel, "TextColor3", "TextMuted")
    connect(copyButton.Activated, function()
        if type(setclipboard) == "function" then
            local ok = pcall(setclipboard, codeLabel.Text)
            copyButton.Text = ok and "COPIED" or "FAILED"
            task.delay(1, function()
                if copyButton then
                    copyButton.Text = "COPY"
                end
            end)
        end
    end, self._window._connections)
    self:_registerSearch((settings.Name or "Code") .. " " .. code, frame)
    local block = {Frame = frame, CurrentValue = code}
    function block:Set(newCode)
        self.CurrentValue = tostring(newCode or "")
        codeLabel.Text = self.CurrentValue
        return self
    end
    function block:Get()
        return self.CurrentValue
    end
    return block
end

function WidgetHost:CreateImage(settings)
    settings = settings or {}
    local theme = currentTheme()
    local height = tonumber(settings.Height) or 180
    local frame = create("Frame", {
        Name = "ImageCard",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = theme.SurfaceAlt,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self._container,
    })
    addCorner(frame, 11)
    local image = create("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = type(settings.Image) == "number" and ("rbxassetid://" .. settings.Image) or tostring(settings.Image or ""),
        ScaleType = settings.ScaleType or Enum.ScaleType.Crop,
        Parent = frame,
    })
    local caption
    if settings.Caption then
        caption = create("TextLabel", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = theme.Background,
            BackgroundTransparency = 0.25,
            Font = Enum.Font.GothamSemibold,
            Text = tostring(settings.Caption),
            TextColor3 = theme.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
        addPadding(caption, 13, 13, 0, 0)
        bindTheme(caption, "BackgroundColor3", "Background")
        bindTheme(caption, "TextColor3", "Text")
    end
    self:_registerSearch(settings.Caption or "Image", frame)
    local imageControl = {Frame = frame, Image = image}
    function imageControl:Set(newImage, newCaption)
        image.Image = type(newImage) == "number" and ("rbxassetid://" .. newImage) or tostring(newImage or "")
        if newCaption ~= nil and caption then
            caption.Text = tostring(newCaption)
        end
        return self
    end
    return imageControl
end

WidgetHost.CreateCheckbox = WidgetHost.CreateToggle

return VaeronLib
