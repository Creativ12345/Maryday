-- Maryday V1.7 - ТП меню и скорость ходьбы (инжектор-совместимая версия)
-- Автор: @AiChatBot
-- Особенности: Всё в одном ScreenGui, только PlayerGui, простое перетаскивание, никаких Draggable=true/CoreGui

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Noclip = nil
local Clip = nil
local NoClipEnabled = false
local FlyEnabled = false
local FlyConnection = nil
local FlySpeed = 50
local WalkSpeed = 16
local WindowStartPos
local MainWindow
local ScreenGui
local Notification
local isWindowVisible = true
local TpMenuFrame = nil

-- === КОНФИГ ===
local MARYDAY_LAUNCH_CODE = "maryday" -- ваш код для запуска
local ESP_MAX_DISTANCE = 600 -- максимальная дистанция для ESP
local LANG = "ru" -- ru или en

-- === ЛОКАЛИЗАЦИЯ ===
local L = {
    ru = {
        enter_code = "Введите код для запуска Maryday",
        code_invalid = "Код неверный!",
        loading = "Загрузка Maryday...",
        loaded = "Maryday V1.7 успешно загружен!",
        tp_title = "Телепортация к игроку",
        tp_success = "Телепортировано к ",
        tp_fail = "Игрок не найден или не загружен",
        esp_hotkey = "Горячая клавиша ESP: ",
        press_key = "Нажмите любую клавишу...",
        esp_on = "ESP+Skeleton: ВКЛ",
        esp_off = "ESP+Skeleton: ВЫКЛ",
        window_hidden = "Окно Maryday скрыто. Нажмите Alt для показа/скрытия"
    },
    en = {
        enter_code = "Enter code to launch Maryday",
        code_invalid = "Invalid code!",
        loading = "Loading Maryday...",
        loaded = "Maryday V1.7 loaded!",
        tp_title = "Teleport to player",
        tp_success = "Teleported to ",
        tp_fail = "Player not found or not loaded",
        esp_hotkey = "ESP Hotkey: ",
        press_key = "Press any key...",
        esp_on = "ESP+Skeleton: ON",
        esp_off = "ESP+Skeleton: OFF",
        window_hidden = "Window hidden. Press Alt to show/hide"
    }
}
local function t(key)
    return L[LANG][key] or key
end

local function noclip()
    Clip = false
    local function Nocl()
        if Clip == false and Player.Character ~= nil then
            for _,v in pairs(Player.Character:GetDescendants()) do
                if v:IsA('BasePart') and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        wait(0.21)
    end
    Noclip = RunService.Stepped:Connect(Nocl)
end

local function clip()
    if Noclip then Noclip:Disconnect() end
    Clip = true
    if Player.Character then
        for _,v in pairs(Player.Character:GetDescendants()) do
            if v:IsA('BasePart') then
                v.CanCollide = true
            end
        end
    end
end

local function startFly()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = true end
    local moveDir = Vector3.new()
    FlyConnection = RunService.RenderStepped:Connect(function()
        moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then
            hrp.Velocity = moveDir.Unit * FlySpeed
        else
            hrp.Velocity = Vector3.new(0,0,0)
        end
    end)
end

local function stopFly()
    if FlyConnection then FlyConnection:Disconnect() end
    local char = Player.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    end
end

local function CreateSafeGUI()
    local success, gui = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "Maryday_"..math.random(1,9999)
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local locations = {Player.PlayerGui, game.CoreGui}
        for _, location in ipairs(locations) do
            pcall(function() screenGui.Parent = location end)
            if screenGui:IsDescendantOf(game) then
                return screenGui
            end
        end
        return nil
    end)
    return success and gui or nil
end

ScreenGui = CreateSafeGUI()
if not ScreenGui then
    warn("Maryday: Не удалось создать GUI!")
    return
end

-- ScreenGui всегда поверх
ScreenGui.DisplayOrder = 9999

-- Главное окно
MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 700, 0, 500)
MainWindow.Position = UDim2.new(0.5, -350, 0.5, -250)
MainWindow.BackgroundColor3 = Color3.fromRGB(24, 10, 32)
MainWindow.BackgroundTransparency = 0.08
MainWindow.BorderSizePixel = 0
MainWindow.ZIndex = 10
MainWindow.Parent = ScreenGui
MainWindow.Active = true

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 22)
WindowCorner.Parent = MainWindow

local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217"
Shadow.Size = UDim2.new(1, 60, 1, 60)
Shadow.Position = UDim2.new(0, -30, 0, -30)
Shadow.ZIndex = 9
Shadow.ImageTransparency = 0.3
Shadow.Parent = MainWindow

-- Верхняя панель для перетаскивания
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(14, 6, 22)
TitleBar.BackgroundTransparency = 0.08
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 30
TitleBar.Parent = MainWindow

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 18)
TitleCorner.Parent = TitleBar

-- Гамбургер-меню из трёх линий
local Hamburger = Instance.new("Frame")
Hamburger.Name = "Hamburger"
Hamburger.Size = UDim2.new(0, 32, 0, 32)
Hamburger.Position = UDim2.new(0, 4, 0, 4)
Hamburger.BackgroundTransparency = 1
Hamburger.ZIndex = 13
Hamburger.Parent = TitleBar
for i=0,2 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -8, 0, 4)
    line.Position = UDim2.new(0, 4, 0, 6 + i*8)
    line.BackgroundColor3 = Color3.fromRGB(220,220,220)
    line.BorderSizePixel = 0
    line.ZIndex = 14
    line.Parent = Hamburger
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5,0)
    corner.Parent = line
end

local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -130, 1, 0)
TitleText.Position = UDim2.new(0, 40, 0, 0)
TitleText.Text = "Maryday V1.7 — Premium Cheats"
TitleText.TextColor3 = Color3.fromRGB(180, 100, 255)
TitleText.TextSize = 28
TitleText.Font = Enum.Font.GothamBlack
TitleText.BackgroundTransparency = 1
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 12
TitleText.Parent = TitleBar

-- Кнопка сворачивания
local MinButton = Instance.new("TextButton")
MinButton.Name = "MinButton"
MinButton.Size = UDim2.new(0, 40, 0, 40)
MinButton.Position = UDim2.new(1, -80, 0, 0)
MinButton.Text = "–"
MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinButton.TextSize = 32
MinButton.Font = Enum.Font.GothamBold
MinButton.BackgroundTransparency = 1
MinButton.ZIndex = 31
MinButton.Parent = TitleBar

-- Перетаскивание окна (теперь за любое место окна)
local dragging = false
local dragStart, startPos
MainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Сворачивание окна и уведомление
local function showNotification(text)
    if Notification then Notification:Destroy() end
    Notification = Instance.new("Frame")
    Notification.Name = "MarydayNotification"
    Notification.Size = UDim2.new(0, 320, 0, 48)
    Notification.Position = UDim2.new(1, -340, 1, -68)
    Notification.AnchorPoint = Vector2.new(0, 0)
    Notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Notification.BackgroundTransparency = 0.15
    Notification.ZIndex = 100
    Notification.Parent = ScreenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = Notification
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 101
    label.Parent = Notification
    TweenService:Create(Notification, TweenInfo.new(0.3), {BackgroundTransparency = 0.15}):Play()
end

local function hideNotification()
    if Notification then
        TweenService:Create(Notification, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        Notification:Destroy()
        Notification = nil
    end
end

-- Размытие заднего фона при открытом меню
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = game:GetService("Lighting")

local function setMenuBlur(state)
    if state then
        blur.Size = 18
    else
        blur.Size = 0
    end
end

local oldSetWindowVisible = setWindowVisible
function setWindowVisible(state)
    isWindowVisible = state
    MainWindow.Visible = state
    if TpMenuFrame then TpMenuFrame.Visible = state end
    setMenuBlur(state)
    if not state then
        showNotification(t("window_hidden"))
    else
        hideNotification()
    end
end

MinButton.MouseButton1Click:Connect(function()
    setWindowVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        setWindowVisible(not isWindowVisible)
    end
end)

-- === ОКНО ВВОДА КОДА ===

-- Контент (основные функции)
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -60, 1, -40)
ContentFrame.Position = UDim2.new(0, 30, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ZIndex = 10
ContentFrame.Parent = MainWindow

-- Добавляем вертикальный Layout для пунктов меню
local MenuLayout = Instance.new("UIListLayout")
MenuLayout.Parent = ContentFrame
MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
MenuLayout.Padding = UDim.new(0, 10)

-- Заголовок
local MainLabel = Instance.new("TextLabel")
MainLabel.Size = UDim2.new(1, 0, 0, 40)
MainLabel.Position = UDim2.new(0, 0, 0, 0)
MainLabel.Text = "Добро пожаловать в Maryday!"
MainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MainLabel.TextSize = 20
MainLabel.Font = Enum.Font.GothamBold
MainLabel.BackgroundTransparency = 1
MainLabel.ZIndex = 14
MainLabel.TextXAlignment = Enum.TextXAlignment.Left
MainLabel.Parent = ContentFrame

-- NoClip toggle (современный ползунок, ниже WalkSpeed)
local NoClipFrame = Instance.new("Frame")
NoClipFrame.Name = "NoClipFrame"
NoClipFrame.Size = UDim2.new(1, 0, 0, 50)
NoClipFrame.BackgroundColor3 = Color3.fromRGB(14, 6, 22)
NoClipFrame.BackgroundTransparency = 0.5
NoClipFrame.ZIndex = 13
NoClipFrame.Parent = ContentFrame
local NoClipCorner = Instance.new("UICorner")
NoClipCorner.CornerRadius = UDim.new(0, 12)
NoClipCorner.Parent = NoClipFrame

local NoClipLabel = Instance.new("TextLabel")
NoClipLabel.Name = "NoClipLabel"
NoClipLabel.Size = UDim2.new(0.7, -10, 1, 0)
NoClipLabel.Position = UDim2.new(0, 10, 0, 0)
NoClipLabel.Text = "NoClip"
NoClipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NoClipLabel.TextSize = 16
NoClipLabel.Font = Enum.Font.GothamBold
NoClipLabel.BackgroundTransparency = 1
NoClipLabel.TextXAlignment = Enum.TextXAlignment.Left
NoClipLabel.ZIndex = 14
NoClipLabel.Parent = NoClipFrame

local NoClipToggleBG = Instance.new("Frame")
NoClipToggleBG.Name = "NoClipToggleBG"
NoClipToggleBG.Size = UDim2.new(0, 48, 0, 24)
NoClipToggleBG.Position = UDim2.new(1, -58, 0.5, -12)
NoClipToggleBG.AnchorPoint = Vector2.new(0, 0.5)
NoClipToggleBG.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
NoClipToggleBG.BackgroundTransparency = 0.1
NoClipToggleBG.ZIndex = 15
NoClipToggleBG.Parent = NoClipFrame
local NoClipToggleBGCorner = Instance.new("UICorner")
NoClipToggleBGCorner.CornerRadius = UDim.new(0.5, 0)
NoClipToggleBGCorner.Parent = NoClipToggleBG
local NoClipToggleDot = Instance.new("Frame")
NoClipToggleDot.Name = "NoClipToggleDot"
NoClipToggleDot.Size = UDim2.new(0, 20, 0, 20)
NoClipToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
NoClipToggleDot.AnchorPoint = Vector2.new(0, 0.5)
NoClipToggleDot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
NoClipToggleDot.ZIndex = 16
NoClipToggleDot.Parent = NoClipToggleBG
local NoClipToggleDotCorner = Instance.new("UICorner")
NoClipToggleDotCorner.CornerRadius = UDim.new(0.5, 0)
NoClipToggleDotCorner.Parent = NoClipToggleDot
local NoClipToggleButton = Instance.new("TextButton")
NoClipToggleButton.Name = "NoClipToggleButton"
NoClipToggleButton.Size = UDim2.new(1, 0, 1, 0)
NoClipToggleButton.Position = UDim2.new(0, 0, 0, 0)
NoClipToggleButton.BackgroundTransparency = 1
NoClipToggleButton.Text = ""
NoClipToggleButton.ZIndex = 17
NoClipToggleButton.Parent = NoClipToggleBG

local function ToggleNoClip()
    NoClipEnabled = not NoClipEnabled
    if NoClipEnabled then
        TweenService:Create(NoClipToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 255, 100)}):Play()
        TweenService:Create(NoClipToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 26, 0.5, -10), BackgroundColor3 = Color3.fromRGB(60, 200, 60)}):Play()
        noclip()
    else
        TweenService:Create(NoClipToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        TweenService:Create(NoClipToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10), BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
        clip()
    end
end
NoClipToggleButton.MouseButton1Click:Connect(ToggleNoClip)

-- Fly toggle (современный ползунок, ниже NoClip)
local FlyFrame = Instance.new("Frame")
FlyFrame.Name = "FlyFrame"
FlyFrame.Size = UDim2.new(1, 0, 0, 50)
FlyFrame.Position = UDim2.new(0, 0, 0, 160)
FlyFrame.BackgroundColor3 = Color3.fromRGB(14, 6, 22)
FlyFrame.BackgroundTransparency = 0.5
FlyFrame.ZIndex = 13
FlyFrame.Parent = ContentFrame
local FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(0, 12)
FlyCorner.Parent = FlyFrame

local FlyLabel = Instance.new("TextLabel")
FlyLabel.Name = "FlyLabel"
FlyLabel.Size = UDim2.new(0.7, -10, 1, 0)
FlyLabel.Position = UDim2.new(0, 10, 0, 0)
FlyLabel.Text = "Fly"
FlyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyLabel.TextSize = 16
FlyLabel.Font = Enum.Font.GothamBold
FlyLabel.BackgroundTransparency = 1
FlyLabel.TextXAlignment = Enum.TextXAlignment.Left
FlyLabel.ZIndex = 14
FlyLabel.Parent = FlyFrame

local FlyToggleBG = Instance.new("Frame")
FlyToggleBG.Name = "FlyToggleBG"
FlyToggleBG.Size = UDim2.new(0, 48, 0, 24)
FlyToggleBG.Position = UDim2.new(1, -58, 0.5, -12)
FlyToggleBG.AnchorPoint = Vector2.new(0, 0.5)
FlyToggleBG.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
FlyToggleBG.BackgroundTransparency = 0.1
FlyToggleBG.ZIndex = 15
FlyToggleBG.Parent = FlyFrame
local FlyToggleBGCorner = Instance.new("UICorner")
FlyToggleBGCorner.CornerRadius = UDim.new(0.5, 0)
FlyToggleBGCorner.Parent = FlyToggleBG

local FlyToggleDot = Instance.new("Frame")
FlyToggleDot.Name = "FlyToggleDot"
FlyToggleDot.Size = UDim2.new(0, 20, 0, 20)
FlyToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
FlyToggleDot.AnchorPoint = Vector2.new(0, 0.5)
FlyToggleDot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
FlyToggleDot.ZIndex = 16
FlyToggleDot.Parent = FlyToggleBG
local FlyToggleDotCorner = Instance.new("UICorner")
FlyToggleDotCorner.CornerRadius = UDim.new(0.5, 0)
FlyToggleDotCorner.Parent = FlyToggleDot

local FlyToggleButton = Instance.new("TextButton")
FlyToggleButton.Name = "FlyToggleButton"
FlyToggleButton.Size = UDim2.new(1, 0, 1, 0)
FlyToggleButton.Position = UDim2.new(0, 0, 0, 0)
FlyToggleButton.BackgroundTransparency = 1
FlyToggleButton.Text = ""
FlyToggleButton.ZIndex = 17
FlyToggleButton.Parent = FlyToggleBG

local function ToggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        TweenService:Create(FlyToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 200, 255)}):Play()
        TweenService:Create(FlyToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 26, 0.5, -10), BackgroundColor3 = Color3.fromRGB(60, 180, 255)}):Play()
        startFly()
    else
        TweenService:Create(FlyToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        TweenService:Create(FlyToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10), BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
        stopFly()
    end
end
FlyToggleButton.MouseButton1Click:Connect(ToggleFly)

-- ESP и скелет
local ESPEnabled = false
local SkeletonEnabled = false
local ESPDrawings = {}
local SkeletonDrawings = {}

local function clearDrawings(tbl)
    for _,d in pairs(tbl) do if d.Remove then d:Remove() elseif d.Destroy then d:Destroy() end end
    for k in pairs(tbl) do tbl[k] = nil end
end

-- Загрузка: красивое меню
local function showLoading()
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "MarydayLoading"..math.random(1,9999)
    loadingGui.ResetOnSpawn = false
    loadingGui.IgnoreGuiInset = true
    loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loadingGui.Parent = game:GetService("CoreGui")
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(10,10,20)
    bg.BackgroundTransparency = 0.2
    bg.Parent = loadingGui
    local shadow = Instance.new("ImageLabel")
    shadow.Image = "rbxassetid://1316045217"
    shadow.Size = UDim2.new(0, 500, 0, 200)
    shadow.Position = UDim2.new(0.5, -250, 0.5, -100)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.7
    shadow.Parent = bg
    local title = Instance.new("TextLabel")
    title.Text = "Maryday cheats"
    title.Size = UDim2.new(0, 400, 0, 60)
    title.Position = UDim2.new(0.5, -200, 0.5, -30)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(100,200,255)
    title.TextStrokeTransparency = 0.7
    title.TextSize = 48
    title.Font = Enum.Font.GothamBlack
    title.Parent = bg
    title.ZIndex = 10
    TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=0}):Play()
    wait(1.5)
    TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency=1}):Play()
    wait(0.5)
    loadingGui:Destroy()
end
showLoading()

-- ESP и Skeleton только для прогруженных игроков и в радиусе ESP_MAX_DISTANCE
local function isLoadedPlayer(plr)
    if plr == Player or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = plr.Character.HumanoidRootPart
    local myhrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not myhrp then return false end
    if (hrp.Position - myhrp.Position).Magnitude > ESP_MAX_DISTANCE then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function drawESP()
    clearDrawings(ESPDrawings)
    if not ESPEnabled then return end
    local cam = workspace.CurrentCamera
    for _,plr in ipairs(Players:GetPlayers()) do
        if isLoadedPlayer(plr) then
            local pos, onScreen = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                -- Рамка
                local box = Drawing and Drawing.new and Drawing.new("Square") or nil
                if box then
                    box.Visible = true
                    box.Color = Color3.fromRGB(180, 100, 255)
                    box.Thickness = 2
                    box.Filled = false
                    box.Size = Vector2.new(32, 64)
                    box.Position = Vector2.new(pos.X-16, pos.Y-32)
                    box.Transparency = 0.8
                    table.insert(ESPDrawings, box)
                end
                -- Полоса HP (без процентов)
                local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local hpBar = Drawing and Drawing.new and Drawing.new("Line") or nil
                    if hpBar then
                        hpBar.Visible = true
                        hpBar.Color = Color3.fromRGB(200, 80, 255)
                        hpBar.Thickness = 4
                        hpBar.From = Vector2.new(pos.X-22, pos.Y+32)
                        hpBar.To = Vector2.new(pos.X-22, pos.Y+32 - 60*hp)
                        hpBar.Transparency = 0.9
                        table.insert(ESPDrawings, hpBar)
                    end
                end
                -- Трейсер (линия от центра экрана до игрока)
                local tracer = Drawing and Drawing.new and Drawing.new("Line") or nil
                if tracer then
                    tracer.Visible = true
                    tracer.Color = Color3.fromRGB(120, 60, 200)
                    tracer.Thickness = 2
                    tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y)
                    tracer.Transparency = 0.7
                    table.insert(ESPDrawings, tracer)
                end
            end
        end
    end
end

local function drawSkeleton()
    clearDrawings(SkeletonDrawings)
    if not SkeletonEnabled then return end
    local cam = workspace.CurrentCamera
    for _,plr in ipairs(Players:GetPlayers()) do
        if isLoadedPlayer(plr) then
            local char = plr.Character
            local function getPos(part)
                if char:FindFirstChild(part) then
                    local pos, onScreen = cam:WorldToViewportPoint(char[part].Position)
                    if onScreen then return Vector2.new(pos.X, pos.Y) end
                end
                return nil
            end
            local head = getPos("Head")
            local torso = getPos("UpperTorso") or getPos("Torso")
            local larm = getPos("LeftUpperArm") or getPos("Left Arm")
            local rarm = getPos("RightUpperArm") or getPos("Right Arm")
            local lleg = getPos("LeftUpperLeg") or getPos("Left Leg")
            local rleg = getPos("RightUpperLeg") or getPos("Right Leg")
            if head and torso then
                local line = Drawing and Drawing.new and Drawing.new("Line") or nil
                if line then
                    line.Visible = true
                    line.Color = Color3.fromRGB(0,255,255)
                    line.Thickness = 2
                    line.From = head
                    line.To = torso
                    line.Transparency = 0.8
                    table.insert(SkeletonDrawings, line)
                end
            end
            if torso and larm then
                local line = Drawing and Drawing.new and Drawing.new("Line") or nil
                if line then
                    line.Visible = true
                    line.Color = Color3.fromRGB(0,255,255)
                    line.Thickness = 2
                    line.From = torso
                    line.To = larm
                    line.Transparency = 0.8
                    table.insert(SkeletonDrawings, line)
                end
            end
            if torso and rarm then
                local line = Drawing and Drawing.new and Drawing.new("Line") or nil
                if line then
                    line.Visible = true
                    line.Color = Color3.fromRGB(0,255,255)
                    line.Thickness = 2
                    line.From = torso
                    line.To = rarm
                    line.Transparency = 0.8
                    table.insert(SkeletonDrawings, line)
                end
            end
            if torso and lleg then
                local line = Drawing and Drawing.new and Drawing.new("Line") or nil
                if line then
                    line.Visible = true
                    line.Color = Color3.fromRGB(0,255,255)
                    line.Thickness = 2
                    line.From = torso
                    line.To = lleg
                    line.Transparency = 0.8
                    table.insert(SkeletonDrawings, line)
                end
            end
            if torso and rleg then
                local line = Drawing and Drawing.new and Drawing.new("Line") or nil
                if line then
                    line.Visible = true
                    line.Color = Color3.fromRGB(0,255,255)
                    line.Thickness = 2
                    line.From = torso
                    line.To = rleg
                    line.Transparency = 0.8
                    table.insert(SkeletonDrawings, line)
                end
            end
        end
    end
end

-- ESP+Skeleton кнопка
local ESPComboToggle = Instance.new("TextButton")
ESPComboToggle.Size = UDim2.new(0, 200, 0, 48)
ESPComboToggle.Position = UDim2.new(0, 200, 0, 430)
ESPComboToggle.Text = "ESP+Skeleton: OFF"
ESPComboToggle.TextColor3 = Color3.fromRGB(255,255,255)
ESPComboToggle.TextSize = 18
ESPComboToggle.Font = Enum.Font.GothamBold
ESPComboToggle.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
ESPComboToggle.BackgroundTransparency = 0.08
ESPComboToggle.ZIndex = 14
ESPComboToggle.Parent = ContentFrame
local ESPComboToggleCorner = Instance.new("UICorner")
ESPComboToggleCorner.CornerRadius = UDim.new(0.5,0)
ESPComboToggleCorner.Parent = ESPComboToggle

ESPComboToggle.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    SkeletonEnabled = ESPEnabled
    ESPComboToggle.Text = ESPEnabled and "ESP+Skeleton: ON" or "ESP+Skeleton: OFF"
    drawESP()
    drawSkeleton()
end)

-- Горячая клавиша для ESP
local ESPHotkey = Enum.KeyCode.H
local ESPHotkeyBtn = Instance.new("TextButton")
ESPHotkeyBtn.Size = UDim2.new(0, 180, 0, 40)
ESPHotkeyBtn.Position = UDim2.new(0, 420, 0, 430)
ESPHotkeyBtn.Text = "ESP Hotkey: H"
ESPHotkeyBtn.TextColor3 = Color3.fromRGB(255,255,255)
ESPHotkeyBtn.TextSize = 16
ESPHotkeyBtn.Font = Enum.Font.GothamBold
ESPHotkeyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
ESPHotkeyBtn.BackgroundTransparency = 0.1
ESPHotkeyBtn.ZIndex = 14
ESPHotkeyBtn.Parent = ContentFrame
local ESPHotkeyBtnCorner = Instance.new("UICorner")
ESPHotkeyBtnCorner.CornerRadius = UDim.new(0.5,0)
ESPHotkeyBtnCorner.Parent = ESPHotkeyBtn

local waitingHotkey = false
ESPHotkeyBtn.MouseButton1Click:Connect(function()
    ESPHotkeyBtn.Text = "Press any key..."
    waitingHotkey = true
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if waitingHotkey and input.UserInputType == Enum.UserInputType.Keyboard then
        ESPHotkey = input.KeyCode
        ESPHotkeyBtn.Text = "ESP Hotkey: "..input.KeyCode.Name
        waitingHotkey = false
    elseif not processed and input.KeyCode == ESPHotkey then
        ESPEnabled = not ESPEnabled
        SkeletonEnabled = ESPEnabled
        ESPComboToggle.Text = ESPEnabled and "ESP+Skeleton: ON" or "ESP+Skeleton: OFF"
        drawESP()
        drawSkeleton()
    end
end)

RunService.RenderStepped:Connect(function()
    if ESPEnabled then drawESP() end
    if SkeletonEnabled then drawSkeleton() end
end)

-- Анимация появления окна
MainWindow.Size = UDim2.new(0, 0, 0, 0)
MainWindow.Visible = true
TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 700, 0, 500)}):Play()

-- Анимации наведения на кнопки
local function addButtonHoverAnim(btn, colorOn, colorOff, scale)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = colorOn, TextSize = btn.TextSize * scale}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = colorOff, TextSize = btn.TextSize / scale}):Play()
    end)
end
addButtonHoverAnim(ESPToggle, Color3.fromRGB(255,255,100), Color3.fromRGB(60,120,255), 1.1)
addButtonHoverAnim(SkeletonToggle, Color3.fromRGB(0,255,255), Color3.fromRGB(60,120,255), 1.1)
addButtonHoverAnim(MinusButton, Color3.fromRGB(100,100,255), Color3.fromRGB(60,60,60), 1.1)
addButtonHoverAnim(PlusButton, Color3.fromRGB(100,255,100), Color3.fromRGB(60,60,60), 1.1)
addButtonHoverAnim(TpButton, Color3.fromRGB(100,200,255), Color3.fromRGB(40,40,40), 1.1)
addButtonHoverAnim(ESPComboToggle, Color3.fromRGB(100,200,255), Color3.fromRGB(40,40,40), 1.1)
addButtonHoverAnim(ESPHotkeyBtn, Color3.fromRGB(255,255,255), Color3.fromRGB(60,120,255), 1.1)

-- Кнопка смены языка (теперь смайлики-флаги)
local LangBtn = Instance.new("TextButton")
LangBtn.Size = UDim2.new(0, 40, 0, 40)
LangBtn.Position = UDim2.new(1, -50, 0, 10)
LangBtn.BackgroundTransparency = 1
LangBtn.ZIndex = 100
LangBtn.Parent = MainWindow
LangBtn.Text = LANG == "ru" and "🇷🇺" or "🇬🇧"
LangBtn.TextSize = 32
LangBtn.Font = Enum.Font.GothamBlack
LangBtn.MouseButton1Click:Connect(function()
    LANG = LANG == "ru" and "en" or "ru"
    LangBtn.Text = LANG == "ru" and "🇷🇺" or "🇬🇧"
    -- обновить подписи, если нужно
    ESPHotkeyBtn.Text = t("esp_hotkey")..(ESPhotkey and ESPHotkey.Name or "H")
    ESPComboToggle.Text = ESPEnabled and t("esp_on") or t("esp_off")
end)

-- Функция для полного удаления скрипта
local function unloadMaryday()
    if ScreenGui then ScreenGui:Destroy() end
    if Notification then Notification:Destroy() end
    clearDrawings(ESPDrawings)
    clearDrawings(SkeletonDrawings)
    -- Отключить все коннекты, если есть (например, RunService.RenderStepped)
    if ESPConn then ESPConn:Disconnect() end
    if SkeletonConn then SkeletonConn:Disconnect() end
    -- Можно добавить очистку глобальных переменных, если нужно
    print("Maryday полностью выгружен!")
end

-- Fly и NoClip: поддержка после смерти персонажа
local function onCharacterAdded(char)
    if NoClipEnabled then
        noclip()
    end
    if FlyEnabled then
        startFly()
    end
end
Player.CharacterAdded:Connect(onCharacterAdded)

print("Maryday V1.7 успешно загружен!")

MainWindow.Position = MainWindowPos
MainWindow.Visible = true

-- === ВСТРОЕННОЕ МЕНЮ ТЕЛЕПОРТАЦИИ (ВСЕГДА ВИДИМО) ===
TpMenuFrame = Instance.new("Frame")
TpMenuFrame.Name = "TpMenuFrame"
TpMenuFrame.Size = UDim2.new(1, 0, 0, 220)
TpMenuFrame.Position = UDim2.new(0, 0, 0, 220)
TpMenuFrame.BackgroundColor3 = Color3.fromRGB(24,10,32)
TpMenuFrame.BackgroundTransparency = 0.08
TpMenuFrame.ZIndex = 12
TpMenuFrame.Parent = ContentFrame
local TpMenuCorner = Instance.new("UICorner")
TpMenuCorner.CornerRadius = UDim.new(0, 14)
TpMenuCorner.Parent = TpMenuFrame
local TpMenuTitle = Instance.new("TextLabel")
TpMenuTitle.Size = UDim2.new(1, 0, 0, 32)
TpMenuTitle.Position = UDim2.new(0, 0, 0, 0)
TpMenuTitle.BackgroundTransparency = 1
TpMenuTitle.Text = t("tp_title")
TpMenuTitle.TextColor3 = Color3.fromRGB(180, 100, 255)
TpMenuTitle.TextSize = 18
TpMenuTitle.Font = Enum.Font.GothamBlack
TpMenuTitle.TextXAlignment = Enum.TextXAlignment.Center
TpMenuTitle.ZIndex = 13
TpMenuTitle.Parent = TpMenuFrame
local TpMenuScroll = Instance.new("ScrollingFrame")
TpMenuScroll.Size = UDim2.new(1, -12, 1, -36)
TpMenuScroll.Position = UDim2.new(0, 6, 0, 34)
TpMenuScroll.BackgroundTransparency = 1
TpMenuScroll.BorderSizePixel = 0
TpMenuScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TpMenuScroll.ScrollBarThickness = 6
TpMenuScroll.ZIndex = 14
TpMenuScroll.Parent = TpMenuFrame
local TpMenuLayout = Instance.new("UIListLayout")
TpMenuLayout.Padding = UDim.new(0, 4)
TpMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
TpMenuLayout.Parent = TpMenuScroll
local function updateTpMenuCanvas()
    TpMenuScroll.CanvasSize = UDim2.new(0, 0, 0, TpMenuLayout.AbsoluteContentSize.Y)
end
TpMenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTpMenuCanvas)
local function refreshTpMenu()
    for _,child in ipairs(TpMenuScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.TextSize = 15
            btn.Font = Enum.Font.Gotham
            btn.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
            btn.BackgroundTransparency = 0.12
            btn.ZIndex = 15
            btn.Parent = TpMenuScroll
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0.5,0)
            btnCorner.Parent = btn
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(180, 100, 255) end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(120, 60, 200) end)
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
                    showNotification(t("tp_success")..plr.Name)
                else
                    showNotification(t("tp_fail"))
                end
            end)
        end
    end
    updateTpMenuCanvas()
end
refreshTpMenu()
Players.PlayerAdded:Connect(refreshTpMenu)
Players.PlayerRemoving:Connect(refreshTpMenu)

-- === ДОПОЛНИТЕЛЬНОЕ МИНИ TP-МЕНЮ (теперь среди основных функций) ===
local MiniTPMenuFrame = Instance.new("Frame")
MiniTPMenuFrame.Name = "MiniTPMenuFrame"
MiniTPMenuFrame.Size = UDim2.new(0, 200, 0, 300)
MiniTPMenuFrame.Position = UDim2.new(0, 480, 0, 100)
MiniTPMenuFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
MiniTPMenuFrame.BorderSizePixel = 0
MiniTPMenuFrame.Visible = false
MiniTPMenuFrame.ZIndex = 100
MiniTPMenuFrame.Parent = ContentFrame
MiniTPMenuFrame.Active = true
local MiniTPMenuTitle = Instance.new("TextLabel")
MiniTPMenuTitle.Parent = MiniTPMenuFrame
MiniTPMenuTitle.Size = UDim2.new(1,0,0,50)
MiniTPMenuTitle.BackgroundColor3=Color3.fromRGB(70,70,70)
MiniTPMenuTitle.Text="TP to Player"
MiniTPMenuTitle.TextColor3=Color3.new(1,1,1)
MiniTPMenuTitle.Font=Enum.Font.SourceSans
MiniTPMenuTitle.TextSize=20
local MiniTPMenuScroll = Instance.new("ScrollingFrame")
MiniTPMenuScroll.Parent = MiniTPMenuFrame
MiniTPMenuScroll.Size = UDim2.new(1,0,1,-50)
MiniTPMenuScroll.Position = UDim2.new(0,0,0,50)
MiniTPMenuScroll.CanvasSize = UDim2.new(0,0,0,0)
MiniTPMenuScroll.ScrollBarThickness=8
MiniTPMenuScroll.BackgroundColor3=Color3.fromRGB(40,40,40)
local function refreshMiniTPMenu()
    for _,child in ipairs(MiniTPMenuScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local h=0;for i,j in ipairs(Players:GetPlayers())do if j~=Player then local k=Instance.new("TextButton")k.Parent=MiniTPMenuScroll;k.Size=UDim2.new(1,-10,0,30)k.Position=UDim2.new(0,5,0,h)k.Text=j.Name;k.BackgroundColor3=Color3.fromRGB(60,60,60)k.TextColor3=Color3.new(1,1,1)k.Font=Enum.Font.SourceSans;k.TextSize=18;h=h+35;k.MouseButton1Click:Connect(function()local l=j.Character;if l and l:FindFirstChild("HumanoidRootPart")then local m=l.HumanoidRootPart;local n=m.CFrame.LookVector;Player.Character.HumanoidRootPart.CFrame=m.CFrame-n*2+Vector3.new(0,0.5,0)end end)end end;MiniTPMenuScroll.CanvasSize=UDim2.new(0,0,0,h)
end
Players.PlayerAdded:Connect(refreshMiniTPMenu)
Players.PlayerRemoving:Connect(refreshMiniTPMenu)
refreshMiniTPMenu()

-- Ползунок для мини-TPMenu
local MiniTPMenuToggleBG = Instance.new("Frame")
MiniTPMenuToggleBG.Name = "MiniTPMenuToggleBG"
MiniTPMenuToggleBG.Size = UDim2.new(1, 0, 0, 50)
MiniTPMenuToggleBG.BackgroundColor3 = Color3.fromRGB(14, 6, 22)
MiniTPMenuToggleBG.BackgroundTransparency = 0.5
MiniTPMenuToggleBG.ZIndex = 15
MiniTPMenuToggleBG.Parent = ContentFrame
local MiniTPMenuToggleDot = Instance.new("Frame")
MiniTPMenuToggleDot.Name = "MiniTPMenuToggleDot"
MiniTPMenuToggleDot.Size = UDim2.new(0, 20, 0, 20)
MiniTPMenuToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
MiniTPMenuToggleDot.AnchorPoint = Vector2.new(0, 0.5)
MiniTPMenuToggleDot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
MiniTPMenuToggleDot.ZIndex = 16
MiniTPMenuToggleDot.Parent = MiniTPMenuToggleBG
local MiniTPMenuToggleButton = Instance.new("TextButton")
MiniTPMenuToggleButton.Name = "MiniTPMenuToggleButton"
MiniTPMenuToggleButton.Size = UDim2.new(1, 0, 1, 0)
MiniTPMenuToggleButton.Position = UDim2.new(0, 0, 0, 0)
MiniTPMenuToggleButton.BackgroundTransparency = 1
MiniTPMenuToggleButton.Text = "TPMenu (мини)"
MiniTPMenuToggleButton.ZIndex = 17
MiniTPMenuToggleButton.Parent = MiniTPMenuToggleBG
local MiniTPMenuVisible = false
local function ToggleMiniTPMenu()
    MiniTPMenuVisible = not MiniTPMenuVisible
    MiniTPMenuFrame.Visible = MiniTPMenuVisible
    MiniTPMenuToggleDot.BackgroundColor3 = MiniTPMenuVisible and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(220, 220, 220)
    MiniTPMenuToggleDot.Position = MiniTPMenuVisible and UDim2.new(0, 26, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
end
MiniTPMenuToggleButton.MouseButton1Click:Connect(ToggleMiniTPMenu)

-- Maryday TP (отдельная функция в меню, сразу после NoClip)
local MarydayTPToggleFrame = Instance.new("Frame")
MarydayTPToggleFrame.Name = "MarydayTPToggleFrame"
MarydayTPToggleFrame.Size = UDim2.new(1, 0, 0, 50)
MarydayTPToggleFrame.BackgroundColor3 = Color3.fromRGB(14, 6, 22)
MarydayTPToggleFrame.BackgroundTransparency = 0.5
MarydayTPToggleFrame.ZIndex = 15
MarydayTPToggleFrame.Parent = ContentFrame
local MarydayTPToggleCorner = Instance.new("UICorner")
MarydayTPToggleCorner.CornerRadius = UDim.new(0, 12)
MarydayTPToggleCorner.Parent = MarydayTPToggleFrame
local MarydayTPToggleLabel = Instance.new("TextLabel")
MarydayTPToggleLabel.Name = "MarydayTPToggleLabel"
MarydayTPToggleLabel.Size = UDim2.new(0.7, -10, 1, 0)
MarydayTPToggleLabel.Position = UDim2.new(0, 10, 0, 0)
MarydayTPToggleLabel.Text = "Maryday TP"
MarydayTPToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MarydayTPToggleLabel.TextSize = 16
MarydayTPToggleLabel.Font = Enum.Font.GothamBold
MarydayTPToggleLabel.BackgroundTransparency = 1
MarydayTPToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
MarydayTPToggleLabel.ZIndex = 14
MarydayTPToggleLabel.Parent = MarydayTPToggleFrame
local MarydayTPToggleBG = Instance.new("Frame")
MarydayTPToggleBG.Name = "MarydayTPToggleBG"
MarydayTPToggleBG.Size = UDim2.new(0, 48, 0, 24)
MarydayTPToggleBG.Position = UDim2.new(1, -58, 0.5, -12)
MarydayTPToggleBG.AnchorPoint = Vector2.new(0, 0.5)
MarydayTPToggleBG.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MarydayTPToggleBG.BackgroundTransparency = 0.1
MarydayTPToggleBG.ZIndex = 15
MarydayTPToggleBG.Parent = MarydayTPToggleFrame
local MarydayTPToggleBGCorner = Instance.new("UICorner")
MarydayTPToggleBGCorner.CornerRadius = UDim.new(0.5, 0)
MarydayTPToggleBGCorner.Parent = MarydayTPToggleBG
local MarydayTPToggleDot = Instance.new("Frame")
MarydayTPToggleDot.Name = "MarydayTPToggleDot"
MarydayTPToggleDot.Size = UDim2.new(0, 20, 0, 20)
MarydayTPToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
MarydayTPToggleDot.AnchorPoint = Vector2.new(0, 0.5)
MarydayTPToggleDot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
MarydayTPToggleDot.ZIndex = 16
MarydayTPToggleDot.Parent = MarydayTPToggleBG
local MarydayTPToggleDotCorner = Instance.new("UICorner")
MarydayTPToggleDotCorner.CornerRadius = UDim.new(0.5, 0)
MarydayTPToggleDotCorner.Parent = MarydayTPToggleDot
local MarydayTPToggleButton = Instance.new("TextButton")
MarydayTPToggleButton.Name = "MarydayTPToggleButton"
MarydayTPToggleButton.Size = UDim2.new(1, 0, 1, 0)
MarydayTPToggleButton.Position = UDim2.new(0, 0, 0, 0)
MarydayTPToggleButton.BackgroundTransparency = 1
MarydayTPToggleButton.Text = ""
MarydayTPToggleButton.ZIndex = 17
MarydayTPToggleButton.Parent = MarydayTPToggleBG
local MarydayTPVisible = false
local function ToggleMarydayTP()
    MarydayTPVisible = not MarydayTPVisible
    MarydayTPFrame.Visible = MarydayTPVisible
    MarydayTPToggleDot.BackgroundColor3 = MarydayTPVisible and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(220, 220, 220)
    MarydayTPToggleDot.Position = MarydayTPVisible and UDim2.new(0, 26, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
end
MarydayTPToggleButton.MouseButton1Click:Connect(ToggleMarydayTP)

-- Само окно Maryday TP (Frame справа, как раньше)
local MarydayTPFrame = Instance.new("Frame")
MarydayTPFrame.Name = "MarydayTPFrame"
MarydayTPFrame.Size = UDim2.new(0, 200, 0, 300)
MarydayTPFrame.AnchorPoint = Vector2.new(0, 0)
MarydayTPFrame.Position = UDim2.new(1, 20, 0, 0)
MarydayTPFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
MarydayTPFrame.BorderSizePixel = 0
MarydayTPFrame.Visible = false
MarydayTPFrame.ZIndex = 100
MarydayTPFrame.Parent = ContentFrame
MarydayTPFrame.Active = true
local MarydayTPTitle = Instance.new("TextLabel")
MarydayTPTitle.Parent = MarydayTPFrame
MarydayTPTitle.Size = UDim2.new(1,0,0,50)
MarydayTPTitle.BackgroundColor3=Color3.fromRGB(70,70,70)
MarydayTPTitle.Text="Maryday TP"
MarydayTPTitle.TextColor3=Color3.new(1,1,1)
MarydayTPTitle.Font=Enum.Font.SourceSans
MarydayTPTitle.TextSize=20
local MarydayTPScroll = Instance.new("ScrollingFrame")
MarydayTPScroll.Parent = MarydayTPFrame
MarydayTPScroll.Size = UDim2.new(1,0,1,-50)
MarydayTPScroll.Position = UDim2.new(0,0,0,50)
MarydayTPScroll.CanvasSize = UDim2.new(0,0,0,0)
MarydayTPScroll.ScrollBarThickness=8
MarydayTPScroll.BackgroundColor3=Color3.fromRGB(40,40,40)
local function refreshMarydayTP()
    for _,child in ipairs(MarydayTPScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local h=0;for i,j in ipairs(Players:GetPlayers())do if j~=Player then local k=Instance.new("TextButton")k.Parent=MarydayTPScroll;k.Size=UDim2.new(1,-10,0,30)k.Position=UDim2.new(0,5,0,h)k.Text=j.Name;k.BackgroundColor3=Color3.fromRGB(60,60,60)k.TextColor3=Color3.new(1,1,1)k.Font=Enum.Font.SourceSans;k.TextSize=18;h=h+35;k.MouseButton1Click:Connect(function()local l=j.Character;if l and l:FindFirstChild("HumanoidRootPart")then local m=l.HumanoidRootPart;local n=m.CFrame.LookVector;Player.Character.HumanoidRootPart.CFrame=m.CFrame-n*2+Vector3.new(0,0.5,0)end end)end end;MarydayTPScroll.CanvasSize=UDim2.new(0,0,0,h)
end
Players.PlayerAdded:Connect(refreshMarydayTP)
Players.PlayerRemoving:Connect(refreshMarydayTP)
refreshMarydayTP()