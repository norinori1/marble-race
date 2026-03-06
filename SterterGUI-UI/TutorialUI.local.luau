-- チュートリアルUIスクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local tutorialCompletedEvent = remoteEvents:WaitForChild("TutorialCompleted")

-- UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TutorialUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- チュートリアルフレーム
local tutorialFrame = Instance.new("Frame")
tutorialFrame.Name = "TutorialFrame"
tutorialFrame.Size = UDim2.new(0.7, 0, 0.6, 0)
tutorialFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
tutorialFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tutorialFrame.BorderSizePixel = 0
tutorialFrame.Visible = false
tutorialFrame.Parent = screenGui

-- タイトル
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎮 マーブルレースへようこそ！"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = tutorialFrame

-- チュートリアル内容
local contentLabel = Instance.new("TextLabel")
contentLabel.Name = "ContentLabel"
contentLabel.Size = UDim2.new(0.9, 0, 0.6, 0)
contentLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
contentLabel.BackgroundTransparency = 1
contentLabel.Text = [[
🎯 目的: マーブルを操作してコースを走り抜けよう！

🕹️ 操作方法:
• W/A/S/D または矢印キーで移動
• スペースキーでジャンプ
• モバイル: 画面左側の仮想スティック

🏁 ルール:
• チェックポイントを順番に通過
• 落下したら最後のチェックポイントから再開
• 1位を目指してゴールしよう！

💡 ヒント:
• スピードを出しすぎると落ちやすいよ
• ショップで新しいマブルを購入できる
]]
contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
contentLabel.TextScaled = true
contentLabel.Font = Enum.Font.Gotham
contentLabel.TextXAlignment = Enum.TextXAlignment.Left
contentLabel.TextYAlignment = Enum.TextYAlignment.Top
contentLabel.Parent = tutorialFrame

-- 閉じるボタン
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0.3, 0, 0.1, 0)
closeButton.Position = UDim2.new(0.35, 0, 0.85, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
closeButton.BorderSizePixel = 0
closeButton.Text = "わかった！"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = tutorialFrame

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
    tutorialFrame.Visible = false
    
    -- チュートリアル完了をサーバーに通知
    tutorialCompletedEvent:FireServer()
end)

-- チュートリアルを表示する関数
local function showTutorial()
    tutorialFrame.Visible = true
end

-- チュートリアル完了チェック
local function checkTutorialCompletion()
    -- サーバーからチュートリアル完了状態を確認
    local getTutorialCompleted = remoteEvents:FindFirstChild("GetTutorialCompleted")
    
    if getTutorialCompleted then
        local completed = getTutorialCompleted:InvokeServer()
        if completed then
            -- チュートリアル完了済み
            return
        end
    end
    
    -- チュートリアル未完了の場合、少し遅れて表示
    task.delay(2, showTutorial)
end

-- プレイヤーが参加したときにチェック
checkTutorialCompletion()

return "チュートリアルUIを作成しました"