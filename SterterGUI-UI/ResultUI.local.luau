-- 結果UIスクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local raceEndEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RaceEnd")

-- UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ResultUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- 最初は非表示
screenGui.Parent = playerGui

-- メインフレーム
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
mainFrame.Position = UDim2.new(0.15, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- タイトル
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🏁 レース結果 🏁"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- 自分の結果フレーム
local myResultFrame = Instance.new("Frame")
myResultFrame.Name = "MyResultFrame"
myResultFrame.Size = UDim2.new(0.9, 0, 0.25, 0)
myResultFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
myResultFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
myResultFrame.BorderSizePixel = 0
myResultFrame.Parent = mainFrame

-- 順位表示
local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "RankLabel"
rankLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
rankLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.Text = "🏆 1位"
rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Parent = myResultFrame

-- コイン報酬
local coinsRewardLabel = Instance.new("TextLabel")
coinsRewardLabel.Name = "CoinsRewardLabel"
coinsRewardLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
coinsRewardLabel.Position = UDim2.new(0.35, 0, 0.1, 0)
coinsRewardLabel.BackgroundTransparency = 1
coinsRewardLabel.Text = "+100 💰"
coinsRewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsRewardLabel.TextScaled = true
coinsRewardLabel.Font = Enum.Font.GothamBold
coinsRewardLabel.Parent = myResultFrame

-- XP報酬
local xpRewardLabel = Instance.new("TextLabel")
xpRewardLabel.Name = "XPRewardLabel"
xpRewardLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
xpRewardLabel.Position = UDim2.new(0.65, 0, 0.1, 0)
xpRewardLabel.BackgroundTransparency = 1
xpRewardLabel.Text = "+50 ⭐"
xpRewardLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
xpRewardLabel.TextScaled = true
xpRewardLabel.Font = Enum.Font.GothamBold
xpRewardLabel.Parent = myResultFrame

-- メッセージ
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
messageLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = "素晴らしいレースでした！"
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextScaled = true
messageLabel.Font = Enum.Font.Gotham
messageLabel.Parent = myResultFrame

-- 全順位リストフレーム
local rankingsFrame = Instance.new("Frame")
rankingsFrame.Name = "RankingsFrame"
rankingsFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
rankingsFrame.Position = UDim2.new(0.05, 0, 0.5, 0)
rankingsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
rankingsFrame.BorderSizePixel = 0
rankingsFrame.Parent = mainFrame

-- 順位リストタイトル
local rankingsTitle = Instance.new("TextLabel")
rankingsTitle.Name = "Title"
rankingsTitle.Size = UDim2.new(1, 0, 0.15, 0)
rankingsTitle.Position = UDim2.new(0, 0, 0, 0)
rankingsTitle.BackgroundTransparency = 1
rankingsTitle.Text = "📊 全順位"
rankingsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
rankingsTitle.TextScaled = true
rankingsTitle.Font = Enum.Font.GothamBold
rankingsTitle.Parent = rankingsFrame

-- 順位リスト用スクロールフレーム
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, 0, 0.85, 0)
scrollFrame.Position = UDim2.new(0, 0, 0.15, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = rankingsFrame

-- UIレイアウト
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = scrollFrame

-- 閉じるボタン
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0.3, 0, 0.08, 0)
closeButton.Position = UDim2.new(0.35, 0, 0.92, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
closeButton.BorderSizePixel = 0
closeButton.Text = "ロビーに戻る"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

-- ボタンホバーエフェクト
closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(120, 220, 120)
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    }):Play()
end)

-- 閉じるボタンのクリック
closeButton.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- 順位に応じたメッセージ
local function getRankMessage(rank)
    if rank == 1 then
        return "🎉 優勝！おめでとうございます！"
    elseif rank == 2 then
        return "🥈 準優勝！素晴らしい！"
    elseif rank == 3 then
        return "🥉 3位！よく頑張りました！"
    else
        return "次はもっと頑張ろう！"
    end
end

-- 順位に応じた色
local function getRankColor(rank)
    if rank == 1 then
        return Color3.fromRGB(255, 215, 0)
    elseif rank == 2 then
        return Color3.fromRGB(192, 192, 192)
    elseif rank == 3 then
        return Color3.fromRGB(205, 127, 50)
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

-- 順位リストの作成
local function createRankingsList(rankings)
    -- 既存のリストをクリア
    for _, child in scrollFrame:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #rankings * 35)
    
    for i, data in ipairs(rankings) do
        local rankFrame = Instance.new("Frame")
        rankFrame.Name = "Rank" .. i
        rankFrame.Size = UDim2.new(1, 0, 0, 30)
        rankFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        rankFrame.BorderSizePixel = 0
        rankFrame.Parent = scrollFrame
        
        -- 順位
        local rankTextLabel = Instance.new("TextLabel")
        rankTextLabel.Size = UDim2.new(0.15, 0, 1, 0)
        rankTextLabel.BackgroundTransparency = 1
        rankTextLabel.Text = tostring(i) .. "位"
        rankTextLabel.TextColor3 = getRankColor(i)
        rankTextLabel.TextScaled = true
        rankTextLabel.Font = Enum.Font.GothamBold
        rankTextLabel.Parent = rankFrame
        
        -- プレイヤー名
        local targetPlayer = Players:GetPlayerByUserId(data.userId)
        local playerName = targetPlayer and targetPlayer.Name or "Unknown"
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerName
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.Parent = rankFrame
        
        -- チェックポイント数
        local checkpointLabel = Instance.new("TextLabel")
        checkpointLabel.Size = UDim2.new(0.2, 0, 1, 0)
        checkpointLabel.Position = UDim2.new(0.65, 0, 0, 0)
        checkpointLabel.BackgroundTransparency = 1
        checkpointLabel.Text = "CP: " .. data.checkpointsPassed
        checkpointLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        checkpointLabel.TextScaled = true
        checkpointLabel.Font = Enum.Font.Gotham
        checkpointLabel.Parent = rankFrame
        
        -- タイム
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0.2, 0, 1, 0)
        timeLabel.Position = UDim2.new(0.85, 0, 0, 0)
        timeLabel.BackgroundTransparency = 1
        if data.finished then
            timeLabel.Text = string.format("%.1fs", data.finishTime)
            timeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            timeLabel.Text = "DNF"
            timeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        timeLabel.TextScaled = true
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.Parent = rankFrame
    end
end

-- レース終了イベントの受信
raceEndEvent.OnClientEvent:Connect(function(data)
    -- 結果UIを表示
    screenGui.Enabled = true
    
    -- 自分の結果を表示
    rankLabel.Text = "🏆 " .. data.rank .. "位"
    rankLabel.TextColor3 = getRankColor(data.rank)
    coinsRewardLabel.Text = "+" .. data.coins .. " 💰"
    xpRewardLabel.Text = "+" .. data.xp .. " ⭐"
    messageLabel.Text = getRankMessage(data.rank)
    
    -- 全順位リストを作成
    createRankingsList(data.rankings)
end)

return "結果UIを作成しました"