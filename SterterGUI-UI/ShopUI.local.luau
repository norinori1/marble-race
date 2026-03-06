-- ショップUIスクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents/Functions
local getPlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerData")
local savePlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SavePlayerData")

-- スキン情報
local SKINS = {
    {name = "RedMarble", displayName = "レッドマーブル", price = 0, color = Color3.fromRGB(255, 100, 100)},
    {name = "BlueMarble", displayName = "ブルーマーブル", price = 100, color = Color3.fromRGB(100, 150, 255)},
    {name = "GreenMarble", displayName = "グリーンマーブル", price = 150, color = Color3.fromRGB(100, 255, 100)},
    {name = "YellowMarble", displayName = "イエローマーブル", price = 200, color = Color3.fromRGB(255, 255, 100)}
}

-- UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- 最初は非表示
screenGui.Parent = playerGui

-- メインフレーム
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.8, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.075, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- タイトル
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🛒 マーブルショップ 🛒"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- コイン表示
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(0.3, 0, 0.08, 0)
coinsLabel.Position = UDim2.new(0.05, 0, 0.14, 0)
coinsLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
coinsLabel.BorderSizePixel = 0
coinsLabel.Text = "💰 0 コイン"
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = mainFrame

-- 閉じるボタン
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0.15, 0, 0.08, 0)
closeButton.Position = UDim2.new(0.8, 0, 0.14, 0)
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
    if _G.playSFX then
        _G.playSFX("ButtonClickSound")
    end
    screenGui.Enabled = false
end)

-- スキンリスト用スクロールフレーム
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
scrollFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = mainFrame

-- UIレイアウト
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 10)
uiListLayout.Parent = scrollFrame

-- スキンアイテムの作成
local function createSkinItem(skinData, owned, equipped)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = skinData.name
    itemFrame.Size = UDim2.new(1, 0, 0, 80)
    itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = scrollFrame
    
    -- 装備中の場合のハイライト
    if equipped then
        itemFrame.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
    end
    
    -- マブルプレビュー
    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "PreviewFrame"
    previewFrame.Size = UDim2.new(0.15, 0, 0.8, 0)
    previewFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    previewFrame.BackgroundColor3 = skinData.color
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = itemFrame
    
    local previewCircle = Instance.new("UICorner")
    previewCircle.CornerRadius = UDim.new(0.5, 0)
    previewCircle.Parent = previewFrame
    
    -- スキン名
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0.2, 0, 0.1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = skinData.displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemFrame
    
    -- 価格/状態
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.4, 0, 0.3, 0)
    statusLabel.Position = UDim2.new(0.2, 0, 0.5, 0)
    statusLabel.BackgroundTransparency = 1
    
    if equipped then
        statusLabel.Text = "✓ 装備中"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif owned then
        statusLabel.Text = "所持済み"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        statusLabel.Text = "💰 " .. skinData.price .. " コイン"
        statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    end
    
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = itemFrame
    
    -- アクションボタン
    local actionButton = Instance.new("TextButton")
    actionButton.Name = "ActionButton"
    actionButton.Size = UDim2.new(0.2, 0, 0.5, 0)
    actionButton.Position = UDim2.new(0.75, 0, 0.25, 0)
    actionButton.BorderSizePixel = 0
    actionButton.TextScaled = true
    actionButton.Font = Enum.Font.GothamBold
    actionButton.Parent = itemFrame
    
    if equipped then
        actionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        actionButton.Text = "装備中"
        actionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        actionButton.Active = false
    elseif owned then
        actionButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        actionButton.Text = "装備"
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        actionButton.MouseButton1Click:Connect(function()
            -- 装備処理
            local success, data = pcall(function()
                return getPlayerData:InvokeServer()
            end)
            
            if success and data then
                data.equippedSkin = skinData.name
                savePlayerData:InvokeServer(data)
                refreshShop()
            end
        end)
    else
        actionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
        actionButton.Text = "購入"
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        actionButton.MouseButton1Click:Connect(function()
            -- 購入処理
            local success, data = pcall(function()
                return getPlayerData:InvokeServer()
            end)
            
            if success and data then
                if data.coins >= skinData.price then
                    data.coins = data.coins - skinData.price
                    table.insert(data.ownedSkins, skinData.name)
                    savePlayerData:InvokeServer(data)
                    
                    -- 購入成功音を再生
                    if _G.playSFX then
                        _G.playSFX("PurchaseSound")
                    end
                    
                    refreshShop()
                else
                    -- コイン不足
                    actionButton.Text = "コイン不足"
                    actionButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                    task.wait(1)
                    refreshShop()
                end
            end
        end)
    end
    
    -- ボタンホバーエフェクト
    if actionButton.Active then
        actionButton.MouseEnter:Connect(function()
            local targetColor = owned and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(255, 220, 120)
            TweenService:Create(actionButton, TweenInfo.new(0.2), {
                BackgroundColor3 = targetColor
            }):Play()
        end)
        
        actionButton.MouseLeave:Connect(function()
            local targetColor = owned and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 200, 100)
            TweenService:Create(actionButton, TweenInfo.new(0.2), {
                BackgroundColor3 = targetColor
            }):Play()
        end)
    end
end

-- ショップのリフレッシュ
local function refreshShop()
    -- 既存のアイテムをクリア
    for _, child in scrollFrame:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- プレイヤーデータの取得
    local success, data = pcall(function()
        return getPlayerData:InvokeServer()
    end)
    
    if not success or not data then
        return
    end
    
    -- コイン表示の更新
    coinsLabel.Text = "💰 " .. (data.coins or 0) .. " コイン"
    
    -- スキンアイテムの作成
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #SKINS * 90)
    
    for _, skinData in ipairs(SKINS) do
        local owned = false
        local equipped = false
        
        -- 所持チェック
        for _, ownedSkin in ipairs(data.ownedSkins or {}) do
            if ownedSkin == skinData.name then
                owned = true
                break
            end
        end
        
        -- 装備チェック
        if data.equippedSkin == skinData.name then
            equipped = true
        end
        
        createSkinItem(skinData, owned, equipped)
    end
end

-- ショップを開く関数
_G.openShop = function()
    screenGui.Enabled = true
    refreshShop()
end

return "ショップUIを作成しました"