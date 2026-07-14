local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local targetPlayer = nil
local isSyncing = false
local syncConnection = nil
local activeAnimations = {}

---------------------------------------------------------
-- 1. CREACIÓN DE LA INTERFAZ (GUI AVANZADA)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimCopierPro"
ScreenGui.ResetOnSpawn = false

local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 180) -- Ventana un poco más alta para el perfil
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Barra superior
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Zero-Delay Anim Copier"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -55, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TopBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -27, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Zona de Información del Objetivo (Avatar y Nombre)
local TargetInfo = Instance.new("Frame")
TargetInfo.Size = UDim2.new(1, -20, 0, 40)
TargetInfo.Position = UDim2.new(0, 10, 0, 5)
TargetInfo.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
TargetInfo.Parent = ContentFrame
Instance.new("UICorner", TargetInfo).CornerRadius = UDim.new(0, 6)

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 30, 0, 30)
AvatarImage.Position = UDim2.new(0, 5, 0, 5)
AvatarImage.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
AvatarImage.Image = "" -- Se llenará dinámicamente
AvatarImage.Parent = TargetInfo
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0) -- Círculo perfecto

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -45, 1, 0)
StatusLabel.Position = UDim2.new(0, 40, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Esperando objetivo..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped = true
StatusLabel.Parent = TargetInfo

-- Inputs
local TargetBox = Instance.new("TextBox")
TargetBox.Size = UDim2.new(1, -20, 0, 30)
TargetBox.Position = UDim2.new(0, 10, 0, 55)
TargetBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TargetBox.Text = ""
TargetBox.PlaceholderText = "Escribe el nombre aquí..."
TargetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetBox.Font = Enum.Font.Gotham
TargetBox.TextSize = 13
TargetBox.Parent = ContentFrame
Instance.new("UICorner", TargetBox).CornerRadius = UDim.new(0, 4)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 95)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ToggleBtn.Text = "ACTIVAR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ContentFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

---------------------------------------------------------
-- 2. LÓGICA DE CERO DELAY (RENDER STEPPED)
---------------------------------------------------------
local function stopMyAnimations()
	local char = LocalPlayer.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		local animator = char.Humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				track:Stop(0) -- El 0 fuerza detención instantánea sin difuminado
			end
		end
	end
	activeAnimations = {}
end

-- Esta función corre cada frame para garantizar consistencia absoluta
local function processAnimations()
	if not isSyncing or not targetPlayer then return end
	
	local targetChar = targetPlayer.Character
	local myChar = LocalPlayer.Character
	
	if not targetChar or not myChar then return end
	
	local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
	local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
	
	if not targetHumanoid or not myHumanoid then return end
	
	local targetAnimator = targetHumanoid:FindFirstChildOfClass("Animator")
	local myAnimator = myHumanoid:FindFirstChildOfClass("Animator") or myHumanoid:WaitForChild("Animator")
	
	if not targetAnimator then return end

	local targetTracks = targetAnimator:GetPlayingAnimationTracks()
	local currentlyPlaying = {}

	for _, tTrack in ipairs(targetTracks) do
		local animId = tTrack.Animation.AnimationId
		-- Ignorar animaciones base que causen conflicto
		if string.find(animId, "507768375") then continue end 
		
		currentlyPlaying[animId] = true

		if not activeAnimations[animId] then
			-- Si el objetivo reproduce una nueva animación, la forzamos AL INSTANTE (fadeTime = 0)
			local newAnim = Instance.new("Animation")
			newAnim.AnimationId = animId
			local mTrack = myAnimator:LoadAnimation(newAnim)
			
			mTrack:Play(0, tTrack.WeightTarget, tTrack.Speed)
			mTrack.TimePosition = tTrack.TimePosition
			
			activeAnimations[animId] = mTrack
		else
			-- CORRECCIÓN CONSTANTE DE DESINCRONIZACIÓN (0 Ping Feature)
			local mTrack = activeAnimations[animId]
			
			-- Copia peso y velocidad al instante
			mTrack:AdjustWeight(tTrack.WeightTarget, 0)
			mTrack:AdjustSpeed(tTrack.Speed)
			
			-- Si el server lagea y hay una diferencia de tiempo notable, forzamos la posición
			if math.abs(mTrack.TimePosition - tTrack.TimePosition) > 0.05 then
				mTrack.TimePosition = tTrack.TimePosition
			end
		end
	end

	-- Limpiar animaciones que el objetivo ya dejó de reproducir
	for animId, mTrack in pairs(activeAnimations) do
		if not currentlyPlaying[animId] then
			mTrack:Stop(0) -- Detener instantáneamente
			activeAnimations[animId] = nil
		end
	end
end

local function getPlayerFromString(str)
	if not str or str == "" then return nil end
	str = string.lower(str)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(p.Name), 1, #str) == str or string.sub(string.lower(p.DisplayName), 1, #str) == str then
			return p
		end
	end
	return nil
end

local function updateUIForTarget(player)
	if player then
		StatusLabel.Text = "Copiando a:\n" .. player.DisplayName .. " (@" .. player.Name .. ")"
		StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		-- Cargar foto de perfil
		local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		AvatarImage.Image = isReady and content or ""
	else
		StatusLabel.Text = "Esperando objetivo..."
		StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		AvatarImage.Image = ""
	end
end

---------------------------------------------------------
-- 3. INTERACCIONES DE INTERFAZ
---------------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
	isSyncing = not isSyncing
	if isSyncing then
		targetPlayer = getPlayerFromString(TargetBox.Text)
		if targetPlayer and targetPlayer ~= LocalPlayer then
			ToggleBtn.Text = "DESACTIVAR"
			ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			
			updateUIForTarget(targetPlayer)
			stopMyAnimations()
			
			-- Iniciar el bucle de renderizado ultra-rápido
			if syncConnection then syncConnection:Disconnect() end
			syncConnection = RunService.RenderStepped:Connect(processAnimations)
		else
			isSyncing = false
			StatusLabel.Text = "¡Jugador no encontrado!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			task.wait(1.5)
			if not isSyncing then updateUIForTarget(nil) end
		end
	else
		ToggleBtn.Text = "ACTIVAR"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		targetPlayer = nil
		updateUIForTarget(nil)
		
		if syncConnection then
			syncConnection:Disconnect()
			syncConnection = nil
		end
		stopMyAnimations()
	end
end)

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	ContentFrame.Visible = not minimized
	if minimized then
		MainFrame.Size = UDim2.new(0, 260, 0, 30)
		MinimizeBtn.Text = "+"
	else
		MainFrame.Size = UDim2.new(0, 260, 0, 180)
		MinimizeBtn.Text = "-"
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	if syncConnection then syncConnection:Disconnect() end
	stopMyAnimations()
	ScreenGui:Destroy()
end)
