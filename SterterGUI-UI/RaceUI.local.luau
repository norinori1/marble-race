-- レースUIスクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- カメラ追従設定
local cameraOffset = Vector3.new(0, 12, 18) -- 少し低く、近くに調整
local cameraSmoothness = 0.12 -- 少しレスポンスを上げる
local isRacing = false
local marble = nil
local cameraInitialized = false

-- マブルを取得する関数
local function getMarble()
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        return hrp
    end
    return nil
end

-- カメラ追従ループ
local frameCount = 0
RunService.RenderStepped:Connect(function(deltaTime)
    if isRacing then
        marble = getMarble()
        frameCount = frameCount + 1
        
        if not marble and frameCount % 60 == 0 then
            -- 1秒ごと（60フレーム）にmarbleが見つからない場合のログを出力
            warn("[RaceUI] マーブルが見つかりません！ character:", player.Character)
            if player.Character then
                local children = {}
                for _, child in player.Character:GetChildren() do
                    table.insert(children, child.Name)
                end
                warn("[RaceUI] Character children: " .. table.concat(children, ", "))
            end
        end
        
        if marble then
            local camera = workspace.CurrentCamera
            local targetCFrame = CFrame.new(marble.Position + cameraOffset, marble.Position)
            
            if not cameraInitialized then
                -- 初回はLerpせずにスナップ
                camera.CFrame = targetCFrame
                cameraInitialized = true
                print("[RaceUI] カメラをマブルにスナップしました")
                print("[RaceUI] マーブル位置: " .. tostring(marble.Position))
                print("[RaceUI] マーブル名前: " .. marble.Name)
                print("[RaceUI] マーブル親: " .. tostring(marble.Parent))
            else
                -- 2回目以降はスムーズに追従
                camera.CFrame = camera.CFrame:Lerp(targetCFrame, cameraSmoothness)
            end
        end
    end
end)

-- RemoteEvents
local raceStartEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RaceStart")
local raceEndEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RaceEnd")
local updateRaceUIEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateRaceUI")
local checkpointReachedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CheckpointReached")

-- UIの作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RaceUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- 最初は非表示
screenGui.Parent = playerGui

-- 上部情報バー
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0.08, 0)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

-- 残り時間
local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "TimeLabel"
timeLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
timeLabel.Position = UDim2.new(0.4, 0, 0.1, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "⏱️ 180秒"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.GothamBold
timeLabel.Parent = topBar

-- チェックポイント進行
local checkpointLabel = Instance.new("TextLabel")
checkpointLabel.Name = "CheckpointLabel"
checkpointLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
checkpointLabel.Position = UDim2.new(0.7, 0, 0.1, 0)
checkpointLabel.BackgroundTransparency = 1
checkpointLabel.Text = "🚩 0/5"
checkpointLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
checkpointLabel.TextScaled = true
checkpointLabel.Font = Enum.Font.GothamBold
checkpointLabel.Parent = topBar

-- 順位
local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "RankLabel"
rankLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
rankLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.Text = "🏆 ?位"
rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Parent = topBar

-- カウントダウン表示
local countdownFrame = Instance.new("Frame")
countdownFrame.Name = "CountdownFrame"
countdownFrame.Size = UDim2.new(0.3, 0, 0.2, 0)
countdownFrame.Position = UDim2.new(0.35, 0, 0.4, 0)
countdownFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
countdownFrame.BorderSizePixel = 0
countdownFrame.Visible = false
countdownFrame.Parent = screenGui

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(1, 0, 1, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "5"
countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
countdownLabel.TextScaled = true
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.Parent = countdownFrame

-- チェックポイント通過通知
local checkpointNotification = Instance.new("Frame")
checkpointNotification.Name = "CheckpointNotification"
checkpointNotification.Size = UDim2.new(0.4, 0, 0.1, 0)
checkpointNotification.Position = UDim2.new(0.3, 0, 0.15, 0)
checkpointNotification.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
checkpointNotification.BorderSizePixel = 0
checkpointNotification.Visible = false
checkpointNotification.Parent = screenGui

local checkpointNotificationLabel = Instance.new("TextLabel")
checkpointNotificationLabel.Name = "Label"
checkpointNotificationLabel.Size = UDim2.new(1, 0, 1, 0)
checkpointNotificationLabel.BackgroundTransparency = 1
checkpointNotificationLabel.Text = "🚩 チェックポイント通過！"
checkpointNotificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
checkpointNotificationLabel.TextScaled = true
checkpointNotificationLabel.Font = Enum.Font.GothamBold
checkpointNotificationLabel.Parent = checkpointNotification

-- ゴール通知
local goalNotification = Instance.new("Frame")
goalNotification.Name = "GoalNotification"
goalNotification.Size = UDim2.new(0.5, 0, 0.2, 0)
goalNotification.Position = UDim2.new(0.25, 0, 0.4, 0)
goalNotification.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
goalNotification.BorderSizePixel = 0
goalNotification.Visible = false
goalNotification.Parent = screenGui

local goalNotificationLabel = Instance.new("TextLabel")
goalNotificationLabel.Name = "Label"
goalNotificationLabel.Size = UDim2.new(1, 0, 0.6, 0)
goalNotificationLabel.Position = UDim2.new(0, 0, 0.1, 0)
goalNotificationLabel.BackgroundTransparency = 1
goalNotificationLabel.Text = "🏁 ゴール！"
goalNotificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
goalNotificationLabel.TextScaled = true
goalNotificationLabel.Font = Enum.Font.GothamBold
goalNotificationLabel.Parent = goalNotification

local goalTimeLabel = Instance.new("TextLabel")
goalTimeLabel.Name = "TimeLabel"
goalTimeLabel.Size = UDim2.new(1, 0, 0.3, 0)
goalTimeLabel.Position = UDim2.new(0, 0, 0.7, 0)
goalTimeLabel.BackgroundTransparency = 1
goalTimeLabel.Text = "タイム: 0.00秒"
goalTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
goalTimeLabel.TextScaled = true
goalTimeLabel.Font = Enum.Font.Gotham
goalTimeLabel.Parent = goalNotification

-- レース開始イベントの受信
raceStartEvent.OnClientEvent:Connect(function(data)
    screenGui.Enabled = true
    checkpointLabel.Text = "🚩 0/" .. data.checkpointCount
    rankLabel.Text = "🏆 ?位"
    
    -- レースBGMを再生
    if _G.playBGM and data.bgmName then
        _G.playBGM(data.bgmName, 1)
    end
end)

-- レース終了イベントの受信
raceEndEvent.OnClientEvent:Connect(function(data)
    screenGui.Enabled = false
    isRacing = false
    
    -- ロビーBGMに戻す
    if _G.playBGM then
        _G.playBGM("LobbyBGM", 2)
    end
    
    print("[RaceUI] レース終了！カメラ追従を停止しました")
end)

-- UI更新イベントの受信
updateRaceUIEvent.OnClientEvent:Connect(function(data)
    if data.type == "countdown" then
        countdownFrame.Visible = true
        countdownLabel.Text = tostring(data.value)
        
        -- カウントダウン音を再生
        if _G.playSFX then
            _G.playSFX("CountdownSound")
        end
        
        -- カウントダウンの色を変更
        if data.value <= 3 then
            countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        
        if data.value == 0 then
            countdownFrame.Visible = false
            if _G.playSFX then _G.playSFX("GoSound") end
            
            -- レース開始：カメラ追従を開始
            if not isRacing then
                isRacing = true
                cameraInitialized = false -- 次のフレームでスナップさせる
                
                print("[RaceUI] レース開始！カメラ追従を開始しました（countdown値0）")
            end
        end
    elseif data.type == "race_started" then
        -- race_startedイベントでもレース開始フラグを確認
        if not isRacing then
            isRacing = true
            cameraInitialized = false
            print("[RaceUI] レース開始！カメラ追従を開始しました（race_started）")
        else
            print("[RaceUI] レース既に開始済み（race_started）")
        end
    elseif data.type == "time" then
        timeLabel.Text = "⏱️ " .. data.value .. "秒"
        
        -- 残り時間が少なくなったら警告色
        if data.value <= 30 then
            timeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    elseif data.type == "finished" then
        goalNotification.Visible = true
        goalTimeLabel.Text = "タイム: " .. string.format("%.2f", data.time) .. "秒"
        -- ゴール音を再生
        if _G.playSFX then
            _G.playSFX("GoalSound")
        end
        -- ゴールエフェクトを再生
        if _G.attachEffectToMarble then
            _G.attachEffectToMarble("GoalEffect", 3)
        end
    end
end)

-- チェックポイント通過イベントの受信
checkpointReachedEvent.OnClientEvent:Connect(function(data)
    checkpointLabel.Text = "🚩 " .. data.checkpointNumber .. "/" .. data.totalCheckpoints
    
    -- チェックポイント音を再生
    if _G.playSFX then
        _G.playSFX("CheckpointSound")
    end
    
    -- チェックポイントエフェクトを再生
    if _G.attachEffectToMarble then
        _G.attachEffectToMarble("CheckpointEffect", 1)
    end
    
    -- 通知を表示
    checkpointNotification.Visible = true
    checkpointNotificationLabel.Text = "🚩 チェックポイント " .. data.checkpointNumber .. " 通過！"
    
    -- 2秒後に非表示
    task.delay(2, function()
        checkpointNotification.Visible = false
    end)
end)

return "レースUIを作成しました"