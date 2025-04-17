local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Конфигурация
local SETTINGS = {
    Menu = {
        Title = "DARK_HUB",
        Width = 500,
        Height = 400,
        Color = Color3.fromRGB(20, 20, 25),
        AccentColor = Color3.fromRGB(0, 180, 0),
        DragAreaWidth = 15
    },
    Hitbox = {
        MinSize = 5,
        MaxSize = 100,
        DefaultSize = 50,
        DefaultColor = Color3.fromRGB(255, 50, 50),
        DefaultTransparency = 0.5
    },
    Spinbot = {
        MinSpeed = 1,
        MaxSpeed = 100,
        DefaultSpeed = 30
    },
    TouchFling = {
        Force = 500
    },
    Highlight = {
        MurderColor = Color3.fromRGB(255, 0, 0),
        SheriffColor = Color3.fromRGB(0, 0, 255),
        InnocentColor = Color3.fromRGB(0, 255, 0),
        OutlineTransparency = 0,
        FillTransparency = 0.5
    }
}

-- Состояние
local state = {
    MenuVisible = false,
    Hitbox = {
        Enabled = false,
        Size = SETTINGS.Hitbox.DefaultSize,
        Color = SETTINGS.Hitbox.DefaultColor,
        Transparency = SETTINGS.Hitbox.DefaultTransparency
    },
    DoubleJump = {
        Enabled = false,
        HasDoubleJumped = false
    },
    Spinbot = {
        Enabled = false,
        Speed = SETTINGS.Spinbot.DefaultSpeed,
        Angle = 0,
        LastUpdate = os.clock()
    },
    TouchFling = {
        Enabled = false
    },
    Highlight = {
        Enabled = false
    }
}

-- Инициализация игрока
local player = Players.LocalPlayer
local character = player.Character or player:WaitForChild("CharacterAdded"):Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local normalJumpPower = humanoid.JumpPower

-- Глобальные переменные
local menuGUI = nil
local loadingScreen = nil

-- Функция для определения роли игрока
local function GetPlayerRole(player)
    if player:FindFirstChild("Role") then
        return player.Role.Value
    end
    if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Role") then
        return player.leaderstats.Role.Value
    end
    return "Innocent"
end

-- Функция для создания Highlight с учетом роли
local function CreateHighlight(character)
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerHighlight"
    highlight.OutlineTransparency = SETTINGS.Highlight.OutlineTransparency
    highlight.FillTransparency = SETTINGS.Highlight.FillTransparency
    
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local role = GetPlayerRole(player)
        if role == "Murderer" or role == "Murder" then
            highlight.FillColor = SETTINGS.Highlight.MurderColor
            highlight.OutlineColor = SETTINGS.Highlight.MurderColor
        elseif role == "Sheriff" then
            highlight.FillColor = SETTINGS.Highlight.SheriffColor
            highlight.OutlineColor = SETTINGS.Highlight.SheriffColor
        else
            highlight.FillColor = SETTINGS.Highlight.InnocentColor
            highlight.OutlineColor = SETTINGS.Highlight.InnocentColor
        end
    else
        highlight.FillColor = SETTINGS.Highlight.InnocentColor
        highlight.OutlineColor = SETTINGS.Highlight.InnocentColor
    end
    
    highlight.Parent = character
    return highlight
end

-- Функция для обновления Highlight
local function UpdateHighlights()
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local highlight = otherPlayer.Character:FindFirstChild("PlayerHighlight")
            
            if state.Highlight.Enabled then
                if not highlight then
                    highlight = CreateHighlight(otherPlayer.Character)
                else
                    local player = Players:GetPlayerFromCharacter(otherPlayer.Character)
                    if player then
                        local role = GetPlayerRole(player)
                        if role == "Murderer" or role == "Murder" then
                            highlight.FillColor = SETTINGS.Highlight.MurderColor
                            highlight.OutlineColor = SETTINGS.Highlight.MurderColor
                        elseif role == "Sheriff" then
                            highlight.FillColor = SETTINGS.Highlight.SheriffColor
                            highlight.OutlineColor = SETTINGS.Highlight.SheriffColor
                        else
                            highlight.FillColor = SETTINGS.Highlight.InnocentColor
                            highlight.OutlineColor = SETTINGS.Highlight.InnocentColor
                        end
                    end
                end
                highlight.Enabled = true
            else
                if highlight then
                    highlight.Enabled = false
                end
            end
        end
    end
end

-- Создание экрана загрузки
local function CreateLoadingScreen()
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "LoadingScreen"
    loadingGui.IgnoreGuiInset = true
    loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BorderSizePixel = 0
    background.Parent = loadingGui
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.4, 0, 0, 150)
    container.Position = UDim2.new(0.3, 0, 0.5, -75)
    container.BackgroundTransparency = 1
    container.Parent = background
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 40)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.Text = "DARK_HUB Activated"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 24
    textLabel.Font = Enum.Font.GothamBold
    textLabel.BackgroundTransparency = 1
    textLabel.Parent = container
    
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 10)
    progressBg.Position = UDim2.new(0, 0, 0.7, 0)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = container
    Instance.new("UICorner", progressBg).CornerRadius = UDim.new(1, 0)

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = SETTINGS.Menu.AccentColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(1, 0)

    local tween = TweenService:Create(
        progressBar,
        TweenInfo.new(3, Enum.EasingStyle.Linear),
        {Size = UDim2.new(1, 0, 1, 0)}
    )

    loadingGui.Parent = player:WaitForChild("PlayerGui")
    tween:Play()
    
    return loadingGui
end

-- Создание элементов UI
local function CreateToggle(name, position, parent, initialState)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 180, 0, 30)
    toggleFrame.Position = position
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Parent = toggleFrame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 50, 0, 25)
    button.Position = UDim2.new(1, -50, 0.5, -12)
    button.Text = initialState and "ON" or "OFF"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = initialState and SETTINGS.Menu.AccentColor or Color3.fromRGB(80, 80, 80)
    button.TextSize = 14
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
    button.Parent = toggleFrame

    return button
end

local function CreateSlider(name, min, max, value, position, parent)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, 180, 0, 50)
    sliderFrame.Position = position
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Parent = sliderFrame

    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "Background"
    sliderBg.Size = UDim2.new(1, 0, 0, 10)
    sliderBg.Position = UDim2.new(0, 0, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    sliderBg.Parent = sliderFrame

    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((value-min)/(max-min), 0, 1, 0)
    sliderFill.BackgroundColor3 = SETTINGS.Menu.AccentColor
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    sliderFill.Parent = sliderBg

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -50, 0, 5)
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Color3.new(1, 1, 1)
    valueLabel.TextSize = 14
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.Parent = sliderFrame

    return {
        Frame = sliderFrame,
        Background = sliderBg,
        Fill = sliderFill,
        ValueLabel = valueLabel
    }
end

local function CreateColorPicker(name, defaultValue, position, parent)
    local pickerFrame = Instance.new("Frame")
    pickerFrame.Size = UDim2.new(0, 180, 0, 40)
    pickerFrame.Position = position
    pickerFrame.BackgroundTransparency = 1
    pickerFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Parent = pickerFrame

    local colorBox = Instance.new("TextBox")
    colorBox.Size = UDim2.new(0, 100, 0, 25)
    colorBox.Position = UDim2.new(1, -100, 0.5, -12)
    colorBox.Text = defaultValue
    colorBox.PlaceholderText = "R,G,B"
    colorBox.TextColor3 = Color3.new(1, 1, 1)
    colorBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    colorBox.TextSize = 14
    Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0, 4)
    colorBox.Parent = pickerFrame

    colorBox.FocusLost:Connect(function()
        local success, err = pcall(function()
            local parts = {}
            for part in string.gmatch(colorBox.Text, "[^,]+") do
                table.insert(parts, tonumber(part))
            end
            if #parts == 3 then
                state.Hitbox.Color = Color3.fromRGB(parts[1], parts[2], parts[3])
            end
        end)
        if not success then
            colorBox.Text = "255,50,50"
            state.Hitbox.Color = SETTINGS.Hitbox.DefaultColor
        end
    end)

    return colorBox
end

local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DARK_HUB"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, SETTINGS.Menu.Width, 0, SETTINGS.Menu.Height)
    mainFrame.Position = UDim2.new(0.5, -SETTINGS.Menu.Width/2, 0.5, -SETTINGS.Menu.Height/2)
    mainFrame.BackgroundColor3 = SETTINGS.Menu.Color
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 5)
    mainFrame.Parent = screenGui

    -- Области для перетаскивания
    local leftDragArea = Instance.new("Frame")
    leftDragArea.Size = UDim2.new(0, SETTINGS.Menu.DragAreaWidth, 1, 0)
    leftDragArea.Position = UDim2.new(0, 0, 0, 0)
    leftDragArea.BackgroundTransparency = 1
    leftDragArea.Parent = mainFrame

    local rightDragArea = Instance.new("Frame")
    rightDragArea.Size = UDim2.new(0, SETTINGS.Menu.DragAreaWidth, 1, 0)
    rightDragArea.Position = UDim2.new(1, -SETTINGS.Menu.DragAreaWidth, 0, 0)
    rightDragArea.BackgroundTransparency = 1
    rightDragArea.Parent = mainFrame

    -- Заголовок и кнопка закрытия
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 5)
    titleBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Text = SETTINGS.Menu.Title
    titleLabel.TextColor3 = SETTINGS.Menu.AccentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 18
    closeButton.BackgroundTransparency = 1
    closeButton.Parent = titleBar

    -- Вкладки
    local tabs = {"Main", "Trolling"}
    local tabButtons = {}
    local tabFrames = {}

    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, -20, 0, 30)
    tabsContainer.Position = UDim2.new(0, 10, 0, 40)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = mainFrame

    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1/#tabs, -5, 1, 0)
        tabButton.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
        tabButton.Text = tabName
        tabButton.TextColor3 = i == 1 and SETTINGS.Menu.AccentColor or Color3.new(0.7, 0.7, 0.7)
        tabButton.TextSize = 16
        tabButton.BackgroundTransparency = 1
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.Parent = tabsContainer
        table.insert(tabButtons, tabButton)

        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, -20, 1, -80)
        tabFrame.Position = UDim2.new(0, 10, 0, 80)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = mainFrame
        tabFrames[i] = tabFrame
    end

    -- Вкладка Main
    local mainTab = tabFrames[1]
    local hitboxToggle = CreateToggle("Hitbox Expander", UDim2.new(0, 0, 0, 0), mainTab, state.Hitbox.Enabled)
    local hitboxSizeSlider = CreateSlider("Hitbox Size", SETTINGS.Hitbox.MinSize, SETTINGS.Hitbox.MaxSize, state.Hitbox.Size, UDim2.new(0, 0, 0, 40), mainTab)
    local hitboxColorPicker = CreateColorPicker("Hitbox Color", "255,50,50", UDim2.new(0, 0, 0, 90), mainTab)
    local hitboxTransparencySlider = CreateSlider("Transparency", 0, 1, state.Hitbox.Transparency, UDim2.new(0, 0, 0, 140), mainTab)
    local doubleJumpToggle = CreateToggle("Double Jump", UDim2.new(0, 250, 0, 0), mainTab, state.DoubleJump.Enabled)
    local spinbotToggle = CreateToggle("Spinbot", UDim2.new(0, 250, 0, 40), mainTab, state.Spinbot.Enabled)
    local spinbotSpeedSlider = CreateSlider("Spin Speed", SETTINGS.Spinbot.MinSpeed, SETTINGS.Spinbot.MaxSpeed, state.Spinbot.Speed, UDim2.new(0, 250, 0, 90), mainTab)
    local highlightToggle = CreateToggle("Role Highlight", UDim2.new(0, 250, 0, 180), mainTab, state.Highlight.Enabled)

    -- Вкладка Trolling
    local trollingTab = tabFrames[2]
    local touchFlingToggle = CreateToggle("Touch Fling", UDim2.new(0, 0, 0, 0), trollingTab, state.TouchFling.Enabled)

    -- Функция для перетаскивания
    local function SetupDrag(dragArea)
        local dragging = false
        local dragStart = Vector2.new(0, 0)
        local startPos = Vector2.new(0, 0)

        dragArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = Vector2.new(input.Position.X, input.Position.Y)
                startPos = Vector2.new(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
            end
        end)

        dragArea.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    0, startPos.X + delta.X,
                    0, startPos.Y + delta.Y
                )
            end
        end)
    end

    -- Настройка перетаскивания
    SetupDrag(leftDragArea)
    SetupDrag(rightDragArea)

    -- Функции для слайдеров
    local function SetupSlider(slider, min, max, onChange)
        local dragging = false
        
        slider.Background.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local percent = (input.Position.X - slider.Background.AbsolutePosition.X) / slider.Background.AbsoluteSize.X
                local value = math.floor(min + (max - min) * math.clamp(percent, 0, 1))
                onChange(value)
            end
        end)
        
        slider.Background.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local percent = (input.Position.X - slider.Background.AbsolutePosition.X) / slider.Background.AbsoluteSize.X
                local value = math.floor(min + (max - min) * math.clamp(percent, 0, 1))
                slider.Fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
                slider.ValueLabel.Text = tostring(value)
                onChange(value)
            end
        end)
    end

    -- Настройка слайдеров
    SetupSlider(hitboxSizeSlider, SETTINGS.Hitbox.MinSize, SETTINGS.Hitbox.MaxSize, function(value)
        state.Hitbox.Size = value
    end)
    
    SetupSlider(hitboxTransparencySlider, 0, 100, function(value)
        state.Hitbox.Transparency = value/100
        hitboxTransparencySlider.ValueLabel.Text = string.format("%.2f", state.Hitbox.Transparency)
    end)
    
    SetupSlider(spinbotSpeedSlider, SETTINGS.Spinbot.MinSpeed, SETTINGS.Spinbot.MaxSpeed, function(value)
        state.Spinbot.Speed = value
    end)

    -- Обработчики кнопок
    closeButton.MouseButton1Click:Connect(function()
        state.MenuVisible = not state.MenuVisible
        mainFrame.Visible = state.MenuVisible
    end)

    hitboxToggle.MouseButton1Click:Connect(function()
        state.Hitbox.Enabled = not state.Hitbox.Enabled
        hitboxToggle.Text = state.Hitbox.Enabled and "ON" or "OFF"
        hitboxToggle.BackgroundColor3 = state.Hitbox.Enabled and SETTINGS.Menu.AccentColor or Color3.fromRGB(80, 80, 80)
    end)

    doubleJumpToggle.MouseButton1Click:Connect(function()
        state.DoubleJump.Enabled = not state.DoubleJump.Enabled
        doubleJumpToggle.Text = state.DoubleJump.Enabled and "ON" or "OFF"
        doubleJumpToggle.BackgroundColor3 = state.DoubleJump.Enabled and SETTINGS.Menu.AccentColor or Color3.fromRGB(80, 80, 80)
    end)

    spinbotToggle.MouseButton1Click:Connect(function()
        state.Spinbot.Enabled = not state.Spinbot.Enabled
        spinbotToggle.Text = state.Spinbot.Enabled and "ON" or "OFF"
        spinbotToggle.BackgroundColor3 = state.Spinbot.Enabled and SETTINGS.Menu.AccentColor or Color3.fromRGB(80, 80, 80)
    end)

    highlightToggle.MouseButton1Click:Connect(function()
        state.Highlight.Enabled = not state.Highlight.Enabled
        highlightToggle.Text = state.Highlight.Enabled and "ON" or "OFF"
        highlightToggle.BackgroundColor3 = state.Highlight.Enabled and SETTINGS.Menu.AccentColor or Color3.fromRGB(80, 80, 80)
        UpdateHighlights()
    end)

    touchFlingToggle.MouseButton1Click:Connect(function()
        state.TouchFling.Enabled = not state.TouchFling.Enabled
        touchFlingToggle.Text = state.TouchFling.Enabled and "ON" or "OFF"
        touchFlingToggle.BackgroundColor3 = state.TouchFling.Enabled and SETTINGS.Menu.AccentColor or Color3.fromRGB(80, 80, 80)
    end)

    -- Переключение вкладок
    for i, tabButton in ipairs(tabButtons) do
        tabButton.MouseButton1Click:Connect(function()
            for j, btn in ipairs(tabButtons) do
                btn.TextColor3 = (i == j) and SETTINGS.Menu.AccentColor or Color3.new(0.7, 0.7, 0.7)
                tabFrames[j].Visible = (i == j)
            end
        end)
    end

    return {
        GUI = screenGui,
        MainFrame = mainFrame
    }
end

-- Основные игровые функции
local function UpdateHitboxes()
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = otherPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                hrp.Size = state.Hitbox.Enabled and Vector3.new(state.Hitbox.Size, state.Hitbox.Size, state.Hitbox.Size) or Vector3.new(2, 2, 1)
                hrp.Transparency = state.Hitbox.Enabled and state.Hitbox.Transparency or 1
                hrp.Color = state.Hitbox.Color
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            end
        end
    end
end

local function HandleJump()
    if state.DoubleJump.Enabled and humanoid:GetState() == Enum.HumanoidStateType.Freefall and not state.DoubleJump.HasDoubleJumped then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        state.DoubleJump.HasDoubleJumped = true
    elseif humanoid.FloorMaterial ~= Enum.Material.Air then
        state.DoubleJump.HasDoubleJumped = false
    end
end

local function HandleSpinbot()
    if state.Spinbot.Enabled and rootPart then
        local now = os.clock()
        local deltaTime = now - (state.Spinbot.LastUpdate or now)
        state.Spinbot.LastUpdate = now
        
        local angleChange = (state.Spinbot.Speed * deltaTime * 6)
        state.Spinbot.Angle = (state.Spinbot.Angle + angleChange) % 360
        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(angleChange), 0)
    end
end

local function HandleTouchFling()
    if not state.TouchFling.Enabled or not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                    local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and hrp and humanoid.Health > 0 then
                        local distance = (part.Position - hrp.Position).Magnitude
                        if distance < 5 then
                            local direction = (hrp.Position - part.Position).Unit
                            hrp.Velocity = direction * SETTINGS.TouchFling.Force
                        end
                    end
                end
            end
        end
    end
end

-- Обработчик смерти персонажа
local function HandleCharacterDeath()
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        humanoid = character:WaitForChild("Humanoid")
        rootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Восстанавливаем меню, если оно было открыто
        if menuGUI and not menuGUI.Parent then
            menuGUI.Parent = player:WaitForChild("PlayerGui")
            if state.MenuVisible then
                menuGUI.MainFrame.Visible = true
            end
        end
    end)
end

-- Инициализация
loadingScreen = CreateLoadingScreen()
HandleCharacterDeath()

task.delay(3, function()
    loadingScreen:Destroy()
    menuGUI = CreateMenu()

    -- Обработка ввода
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            state.MenuVisible = not state.MenuVisible
            menuGUI.MainFrame.Visible = state.MenuVisible
        end
    end)

    -- Основной цикл
    RunService.RenderStepped:Connect(function()
        UpdateHitboxes()
        UpdateHighlights()
        HandleJump()
        HandleSpinbot()
        HandleTouchFling()
    end)

    print(string.format("%s успешно загружен! Нажмите Insert для открытия меню", SETTINGS.Menu.Title))
end)
