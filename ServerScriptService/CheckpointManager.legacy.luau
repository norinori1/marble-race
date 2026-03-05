-- チェックポイントとゴールの検出スクリプト
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- チェックポイントの検出
local function checkCheckpoints()
    local raceMap = Workspace:FindFirstChild("RaceMap")
    if not raceMap then
        return
    end
    
    local checkpointsFolder = raceMap:FindFirstChild("Checkpoints")
    if not checkpointsFolder then
        return
    end
    
    local goalLine = raceMap:FindFirstChild("GoalLine")
    
    for _, player in Players:GetPlayers() do
        if player.Character and player.Character.PrimaryPart then
            local character = player.Character
            local hrp = character.PrimaryPart
            
            -- チェックポイントの検出
            for _, checkpoint in checkpointsFolder:GetChildren() do
                if checkpoint:IsA("BasePart") then
                    local distance = (hrp.Position - checkpoint.Position).Magnitude
                    if distance < 10 then -- チェックポイントの半径
                        -- チェックポイント通過を通知（RaceManagerで処理）
                        local checkpointNumber = checkpoint:GetAttribute("CheckpointNumber")
                        if checkpointNumber then
                            -- プレイヤーの進捗を更新
                            local progress = _G.raceState and _G.raceState.playerProgress[player.UserId]
                            if progress and checkpointNumber == progress.lastCheckpoint + 1 then
                                progress.lastCheckpoint = checkpointNumber
                                progress.checkpointsPassed = checkpointNumber
                                
                                -- クライアントに通知
                                local checkpointReachedEvent = game.ReplicatedStorage.RemoteEvents:FindFirstChild("CheckpointReached")
                                if checkpointReachedEvent then
                                    checkpointReachedEvent:FireClient(player, {
                                        checkpointNumber = checkpointNumber,
                                        totalCheckpoints = raceMap:GetAttribute("CheckpointCount") or 5
                                    })
                                end
                            end
                        end
                    end
                end
            end
            
            -- ゴールの検出
            if goalLine then
                local distance = (hrp.Position - goalLine.Position).Magnitude
                if distance < 10 then
                    local progress = _G.raceState and _G.raceState.playerProgress[player.UserId]
                    if progress and not progress.finished then
                        local totalCheckpoints = raceMap:GetAttribute("CheckpointCount") or 5
                        if progress.checkpointsPassed >= totalCheckpoints then
                            progress.finished = true
                            progress.finishTime = tick() - (_G.raceState and _G.raceState.raceStartTime or 0)
                            
                            -- クライアントにゴール通知
                            local updateRaceUIEvent = game.ReplicatedStorage.RemoteEvents:FindFirstChild("UpdateRaceUI")
                            if updateRaceUIEvent then
                                updateRaceUIEvent:FireClient(player, {
                                    type = "finished",
                                    time = progress.finishTime
                                })
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 定期的にチェックポイントを検出
RunService.Heartbeat:Connect(function()
    if _G.raceState and _G.raceState.isRacing then
        checkCheckpoints()
    end
end)

return "チェックポイントマネージャーを初期化しました"