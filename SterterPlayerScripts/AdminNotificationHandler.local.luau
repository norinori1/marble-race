-- 管理者通知ハンドラー
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local adminNotificationEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AdminNotification")

-- 通知UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminNotificationGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 通知フレーム
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0.4, 0, 0.08, 0)
notificationFrame.Position = UDim2.new(0.3, 0, 0.05, 0)
notificationFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
notificationFrame.BorderSizePixel = 0
notificationFrame.BackgroundTransparency = 1
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

-- 通知テキスト
local notificationText = Instance.new("TextLabel")
notificationText.Name = "NotificationText"
notificationText.Size = UDim2.new(1, 0, 1, 0)
notificationText.BackgroundTransparency = 1
notificationText.Text = ""
notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationText.TextScaled = true
notificationText.Font = Enum.Font.GothamBold
notificationText.Parent = notificationFrame

-- 通知を表示する関数
local function showNotification(text, color)
    -- 通知の設定
    notificationFrame.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    notificationFrame.BackgroundTransparency = 0.2
    notificationText.Text = text
    notificationFrame.Visible = true
    
    -- フェードイン
    local fadeIn = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {
        BackgroundTransparency = 0
    })
    fadeIn:Play()
    
    -- 3秒後にフェードアウト
    task.delay(3, function()
        local fadeOut = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notificationFrame.Visible = false
        end)
    end)
end

-- 通知イベントの受信
adminNotificationEvent.OnClientEvent:Connect(function(data)
    showNotification(data.text, data.color)
end)

return "管理者通知ハンドラーを初期化しました"