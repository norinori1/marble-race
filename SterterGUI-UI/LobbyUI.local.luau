-- ロビーUIスクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local raceStartEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RaceStart")
local raceEndEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RaceEnd")
local updateRaceUIEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateRaceUI")
local checkpointReachedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CheckpointReached")
local startRaceRequestEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StartRaceRequest")

-- UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- メインフレーム
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.8, 0, 0.9, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.05, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- タイトル
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🏁 マーブルレース 🏁"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- プレイヤー情報フレーム
local playerInfoFrame = Instance.new("Frame")
playerInfoFrame.Name = "PlayerInfoFrame"
playerInfoFrame.Size = UDim2.new(0.4, 0, 0.2, 0)
playerInfoFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
playerInfoFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
playerInfoFrame.BorderSizePixel = 0
playerInfoFrame.Parent = mainFrame

-- コイン表示
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
coinsLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "💰 コイン: 0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.Gotham
coinsLabel.Parent = playerInfoFrame

-- レベル表示
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
levelLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "⭐ レベル: 1"
levelLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.Gotham
levelLabel.Parent = playerInfoFrame

-- 勝利数表示
local winsLabel = Instance.new("TextLabel")
winsLabel.Name = "WinsLabel"
winsLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
winsLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
winsLabel.BackgroundTransparency = 1
winsLabel.Text = "🏆 勝利数: 0"
winsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
winsLabel.TextScaled = true
winsLabel.Font = Enum.Font.Gotham
winsLabel.Parent = playerInfoFrame

-- レース情報フレーム
local raceInfoFrame = Instance.new("Frame")
raceInfoFrame.Name = "RaceInfoFrame"
raceInfoFrame.Size = UDim2.new(0.5, 0, 0.25, 0)
raceInfoFrame.Position = UDim2.new(0.5, 0, 0.2, 0)
raceInfoFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
raceInfoFrame.BorderSizePixel = 0
raceInfoFrame.Parent = mainFrame

-- 待機プレイヤー数
local waitingLabel = Instance.new("TextLabel")
waitingLabel.Name = "WaitingLabel"
waitingLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
waitingLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
waitingLabel.BackgroundTransparency = 1
waitingLabel.Text = "待機中: 1/12 人"
waitingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waitingLabel.TextScaled = true
waitingLabel.Font = Enum.Font.Gotham
waitingLabel.Parent = raceInfoFrame

-- ステータス
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
statusLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "プレイヤーを待っています..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = raceInfoFrame

-- 次のマップ表示
local nextMapLabel = Instance.new("TextLabel")
nextMapLabel.Name = "NextMapLabel"
nextMapLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
nextMapLabel.Position = UDim2.new(0.05, 0, 0.75, 0)
nextMapLabel.BackgroundTransparency = 1
nextMapLabel.Text = "🗺️ 次のマップ: ランダム"
nextMapLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
nextMapLabel.TextScaled = true
nextMapLabel.Font = Enum.Font.Gotham
nextMapLabel.Parent = raceInfoFrame

-- レース開始ボタン
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0.3, 0, 0.1, 0)
startButton.Position = UDim2.new(0.35, 0, 0.75, 0)
startButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
startButton.BorderSizePixel = 0
startButton.Text = "レース開始"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextScaled = true
startButton.Font = Enum.Font.GothamBold
startButton.Parent = mainFrame

-- ショップボタン
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0.3, 0, 0.08, 0)
shopButton.Position = UDim2.new(0.35, 0, 0.87, 0)
shopButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
shopButton.BorderSizePixel = 0
shopButton.Text = "🛒 ショップ"
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextScaled = true
shopButton.Font = Enum.Font.GothamBold
shopButton.Parent = mainFrame

-- ボタンホバーエフェクト
shopButton.MouseEnter:Connect(function()
    TweenService:Create(shopButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 220, 120)
    }):Play()
    if _G.playSFX then
        _G.playSFX("ButtonClickSound")
    end
end)

shopButton.MouseLeave:Connect(function()
    TweenService:Create(shopButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    }):Play()
end)

-- ショップボタンのクリック
shopButton.MouseButton1Click:Connect(function()
    -- ショップUIを開く
    if _G.openShop then
        _G.openShop()
    end
end)

-- リーダーボードボタン
local leaderboardButton = Instance.new("TextButton")
leaderboardButton.Name = "LeaderboardButton"
leaderboardButton.Size = UDim2.new(0.3, 0, 0.08, 0)
leaderboardButton.Position = UDim2.new(0.35, 0, 0.96, 0)
leaderboardButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
leaderboardButton.BorderSizePixel = 0
leaderboardButton.Text = "🏆 リーダーボード"
leaderboardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
leaderboardButton.TextScaled = true
leaderboardButton.Font = Enum.Font.GothamBold
leaderboardButton.Parent = mainFrame

-- ボタンホバーエフェクト
leaderboardButton.MouseEnter:Connect(function()
    TweenService:Create(leaderboardButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(120, 170, 255)
    }):Play()
    if _G.playSFX then
        _G.playSFX("ButtonClickSound")
    end
end)

leaderboardButton.MouseLeave:Connect(function()
    TweenService:Create(leaderboardButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    }):Play()
end)

-- リーダーボードボタンのクリック
leaderboardButton.MouseButton1Click:Connect(function()
    -- リーダーボードUIを開く
    if _G.openLeaderboard then
        _G.openLeaderboard()
    end
end)

-- ボタンホバーエフェクト
startButton.MouseEnter:Connect(function()
    TweenService:Create(startButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(120, 220, 120)
    }):Play()
    if _G.playSFX then
        _G.playSFX("ButtonClickSound")
    end
end)

startButton.MouseLeave:Connect(function()
    TweenService:Create(startButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    }):Play()
end)

-- レース開始ボタンのクリック
startButton.MouseButton1Click:Connect(function()
    -- サーバーにレース開始をリクエスト
    startButton.Text = "準備中..."
    startButton.Active = false
    
    local success, errorMessage = pcall(function()
        startRaceRequestEvent:FireServer()
    end)
    
    if not success then
        print("[LobbyUI] レース開始リクエストエラー: " .. tostring(errorMessage))
        startButton.Text = "レース開始"
        startButton.Active = true
        statusLabel.Text = "エラーが発生しました"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- プレイヤー情報の更新
local function updatePlayerInfo()
    local getPlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerData")
    local success, data = pcall(function()
        return getPlayerData:InvokeServer()
    end)
    
    if success and data then
        coinsLabel.Text = "💰 コイン: " .. (data.coins or 0)
        levelLabel.Text = "⭐ レベル: " .. (data.level or 1)
        winsLabel.Text = "🏆 勝利数: " .. (data.totalWins or 0)
    end
end

-- 待機プレイヤー数の更新
local function updateWaitingPlayers()
    local playerCount = #Players:GetPlayers()
    waitingLabel.Text = "待機中: " .. playerCount .. "/12 人"
    
    if playerCount >= 2 then
        statusLabel.Text = "レース開始可能！"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        startButton.Active = true
        startButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    elseif playerCount == 1 then
        statusLabel.Text = "単独プレイで開始できます"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        startButton.Active = true
        startButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    else
        statusLabel.Text = "プレイヤーを待っています..."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        startButton.Active = false
        startButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end

-- 定期的に情報を更新
task.spawn(function()
    while true do
        updatePlayerInfo()
        updateWaitingPlayers()
        task.wait(1)
    end
end)

-- レース開始イベントの受信
raceStartEvent.OnClientEvent:Connect(function(data)
    -- ロビーUIを非表示
    screenGui.Enabled = false
end)

-- レース終了イベントの受信
raceEndEvent.OnClientEvent:Connect(function(data)
    -- ロビーUIを表示
    screenGui.Enabled = true
    startButton.Text = "レース開始"
    startButton.Active = true
end)

-- エラーメッセージの表示
updateRaceUIEvent.OnClientEvent:Connect(function(data)
    if data.type == "error" then
        print("[LobbyUI] エラーメッセージを受信: " .. data.message)
        statusLabel.Text = data.message
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        startButton.Text = "レース開始"
        startButton.Active = true
    end
end)

return "ロビーUIを作成しました"