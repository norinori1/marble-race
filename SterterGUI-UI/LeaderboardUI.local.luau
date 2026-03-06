-- リーダーボードUIスクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteFunctions
local getLeaderboard = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetLeaderboard")
local getPlayerRank = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerRank")

-- UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LeaderboardUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- 最初は非表示
screenGui.Parent = playerGui

-- メインフレーム
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.75, 0, 0.8, 0)
mainFrame.Position = UDim2.new(0.125, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- タイトル
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🏆 リーダーボード 🏆"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- ソートオプションフレーム
local sortFrame = Instance.new("Frame")
sortFrame.Name = "SortFrame"
sortFrame.Size = UDim2.new(0.9, 0, 0.08, 0)
sortFrame.Position = UDim2.new(0.05, 0, 0.14, 0)
sortFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
sortFrame.BorderSizePixel = 0
sortFrame.Parent = mainFrame

-- ソートボタンの作成
local sortOptions = {"勝利数", "ベストタイム", "コイン", "レベル"}
local sortButtons = {}
local currentSort = "勝利数"

for i, option in ipairs(sortOptions) do
    local button = Instance.new("TextButton")
    button.Name = "SortButton" .. i
    button.Size = UDim2.new(0.23, 0, 0.8, 0)
    button.Position = UDim2.new(0.01 + (i - 1) * 0.24, 0, 0.1, 0)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    button.BorderSizePixel = 0
    button.Text = option
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.Gotham
    button.Parent = sortFrame
    
    sortButtons[option] = button
    
    -- ボタンホバーエフェクト
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(90, 90, 110)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        if currentSort == option then
            button.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
        else
            button.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
        end
    end)
    
    -- クリックイベント
    button.MouseButton1Click:Connect(function()
        currentSort = option
        refreshLeaderboard()
    end)
end

-- リーダーボードリスト用スクロールフレーム
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(0.9, 0, 0.65, 0)
scrollFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = mainFrame

-- UIレイアウト
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = scrollFrame

-- 自分のランク表示
local myRankFrame = Instance.new("Frame")
myRankFrame.Name = "MyRankFrame"
myRankFrame.Size = UDim2.new(0.9, 0, 0.1, 0)
myRankFrame.Position = UDim2.new(0.05, 0, 0.92, 0)
myRankFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
myRankFrame.BorderSizePixel = 0
myRankFrame.Parent = mainFrame

local myRankLabel = Instance.new("TextLabel")
myRankLabel.Name = "MyRankLabel"
myRankLabel.Size = UDim2.new(1, 0, 1, 0)
myRankLabel.BackgroundTransparency = 1
myRankLabel.Text = "🏆 自分のランク: 読み込み中..."
myRankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
myRankLabel.TextScaled = true
myRankLabel.Font = Enum.Font.GothamBold
myRankLabel.Parent = myRankFrame

-- 閉じるボタン
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0.15, 0, 0.06, 0)
closeButton.Position = UDim2.new(0.82, 0, 0.03, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

-- ボタンホバーエフェクト
closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    }):Play()
end)

-- 閉じるボタンのクリック
closeButton.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- ソートオプションをサーバー用に変換
local function getSortKey(sortOption)
    if sortOption == "勝利数" then
        return "totalWins"
    elseif sortOption == "ベストタイム" then
        return "bestTime"
    elseif sortOption == "コイン" then
        return "totalCoins"
    elseif sortOption == "レベル" then
        return "level"
    end
    return "totalWins"
end

-- リーダーボードのリフレッシュ
local function refreshLeaderboard()
    -- 既存のエントリをクリア
    for _, child in scrollFrame:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- ソートボタンの色を更新
    for option, button in pairs(sortButtons) do
        if option == currentSort then
            button.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
        else
            button.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
        end
    end
    
    -- リーダーボードデータを取得
    local success, leaderboard = pcall(function()
        return getLeaderboard:InvokeServer(getSortKey(currentSort), 20)
    end)
    
    if not success or not leaderboard then
        return
    end
    
    -- リーダーボードエントリの作成
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #leaderboard * 40)
    
    for i, entry in ipairs(leaderboard) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "Entry" .. i
        entryFrame.Size = UDim2.new(1, 0, 0, 35)
        entryFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = scrollFrame
        
        -- 上位3位の色を変更
        if i == 1 then
            entryFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        elseif i == 2 then
            entryFrame.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
        elseif i == 3 then
            entryFrame.BackgroundColor3 = Color3.fromRGB(205, 127, 50)
        end
        
        -- 順位
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0.1, 0, 1, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = tostring(i)
        rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.Parent = entryFrame
        
        -- プレイヤー名
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.1, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.playerName or "Unknown"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entryFrame
        
        -- スコア表示
        local scoreLabel = Instance.new("TextLabel")
        scoreLabel.Size = UDim2.new(0.5, 0, 1, 0)
        scoreLabel.Position = UDim2.new(0.5, 0, 0, 0)
        scoreLabel.BackgroundTransparency = 1
        
        if currentSort == "勝利数" then
            scoreLabel.Text = "🏆 " .. (entry.totalWins or 0)
        elseif currentSort == "ベストタイム" then
            if entry.bestTime and entry.bestTime < math.huge then
                scoreLabel.Text = "⏱️ " .. string.format("%.2f", entry.bestTime) .. "s"
            else
                scoreLabel.Text = "⏱️ -"
            end
        elseif currentSort == "コイン" then
            scoreLabel.Text = "💰 " .. (entry.totalCoins or 0)
        elseif currentSort == "レベル" then
            scoreLabel.Text = "⭐ Lv." .. (entry.level or 1)
        end
        
        scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        scoreLabel.TextScaled = true
        scoreLabel.Font = Enum.Font.Gotham
        scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
        scoreLabel.Parent = entryFrame
    end
    
    -- 自分のランクを更新
    local rankSuccess, myRank = pcall(function()
        return getPlayerRank:InvokeServer(getSortKey(currentSort))
    end)
    
    if rankSuccess and myRank then
        myRankLabel.Text = "🏆 自分のランク: " .. myRank .. "位"
    else
        myRankLabel.Text = "🏆 自分のランク: -"
    end
end

-- リーダーボードを開く関数
_G.openLeaderboard = function()
    screenGui.Enabled = true
    refreshLeaderboard()
end

return "リーダーボードUIを作成しました"