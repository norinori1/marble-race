-- レースマネージャースクリプト
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local maps = ServerStorage:WaitForChild("ServerAssets"):WaitForChild("Maps")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local raceStartEvent = remoteEvents:WaitForChild("RaceStart")
local raceEndEvent = remoteEvents:WaitForChild("RaceEnd")
local checkpointReachedEvent = remoteEvents:WaitForChild("CheckpointReached")
local updateRaceUIEvent = remoteEvents:WaitForChild("UpdateRaceUI")

-- レース開始リクエスト用RemoteEvent
local startRaceRequestEvent = Instance.new("RemoteEvent")
startRaceRequestEvent.Name = "StartRaceRequest"
startRaceRequestEvent.Parent = remoteEvents

-- レース設定
local MIN_PLAYERS = 2
local MAX_PLAYERS = 12
local RACE_DURATION = 180 -- 秒
local COUNTDOWN_TIME = 5 -- 秒

-- レース状態（グローバル変数として公開）
_G.raceState = {
    isRacing = false,
    currentMap = nil,
    players = {},
    playerProgress = {},
    raceStartTime = 0,
    countdown = 0
}

-- ローカル変数としても参照
local raceState = _G.raceState

-- プレイヤー進捗情報の初期化
local function initializePlayerProgress(player)
    raceState.playerProgress[player.UserId] = {
        checkpointsPassed = 0,
        lastCheckpoint = 0,
        distanceTraveled = 0,
        finished = false,
        finishTime = 0,
        position = player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position or Vector3.new(0, 0, 0)
    }
end

-- レース開始の準備
local function prepareRace()
    if raceState.isRacing then
        return false, "レース中です"
    end
    
    local playerCount = #Players:GetPlayers()
    if playerCount < MIN_PLAYERS then
        return false, "プレイヤーが足りません（最低" .. MIN_PLAYERS .. "人必要）"
    end
    
    if playerCount > MAX_PLAYERS then
        return false, "プレイヤーが多すぎます（最大" .. MAX_PLAYERS .. "人まで）"
    end
    
    -- マップの選択（初期はBeginner Slopeのみ）
    local selectedMap = maps:FindFirstChild("BeginnerSlope")
    if not selectedMap then
        return false, "マップが見つかりません"
    end
    
    raceState.currentMap = selectedMap
    raceState.players = Players:GetPlayers()
    
    -- プレイヤー進捗の初期化
    for _, player in raceState.players do
        initializePlayerProgress(player)
    end
    
    return true, "レース準備完了"
end

-- レース開始
local function startRace()
    local success, message = prepareRace()
    if not success then
        return false, message
    end
    
    raceState.isRacing = true
    raceState.countdown = COUNTDOWN_TIME
    
    -- カウントダウン開始
    for countdown = COUNTDOWN_TIME, 1, -1 do
        raceState.countdown = countdown
        
        -- 全プレイヤーにカウントダウンを通知
        for _, player in raceState.players do
            updateRaceUIEvent:FireClient(player, {
                type = "countdown",
                value = countdown
            })
        end
        
        task.wait(1)
    end
    
    -- レース開始
    raceState.raceStartTime = tick()
    raceState.countdown = 0
    
    -- マップをワークスペースに配置
    local mapClone = raceState.currentMap:Clone()
    mapClone.Name = "RaceMap"
    mapClone.Parent = workspace
    
    -- プレイヤーをスタート位置にテレポート
    local startArea = mapClone:FindFirstChild("StartArea")
    if startArea then
        for i, player in raceState.players do
            if player.Character and player.Character.PrimaryPart then
                local offset = Vector3.new((i - 1 - (#raceState.players - 1) / 2) * 5, 5, 0)
                player.Character:SetPrimaryPartCFrame(startArea.CFrame + offset)
            end
        end
    end
    
    -- 全プレイヤーにレース開始を通知
    for _, player in raceState.players do
        raceStartEvent:FireClient(player, {
            mapName = raceState.currentMap:GetAttribute("CourseName"),
            duration = RACE_DURATION,
            checkpointCount = raceState.currentMap:GetAttribute("CheckpointCount")
        })
    end
    
    -- タイマー開始
    task.spawn(function()
        while raceState.isRacing and (tick() - raceState.raceStartTime) < RACE_DURATION do
            local remainingTime = math.ceil(RACE_DURATION - (tick() - raceState.raceStartTime))
            
            -- 全プレイヤーに残り時間を通知
            for _, player in raceState.players do
                updateRaceUIEvent:FireClient(player, {
                    type = "time",
                    value = remainingTime
                })
            end
            
            task.wait(1)
        end
        
        -- タイムアップ
        if raceState.isRacing then
            endRace()
        end
    end)
    
    return true, "レース開始"
end

-- レース終了
local function endRace()
    if not raceState.isRacing then
        return
    end
    
    raceState.isRacing = false
    
    -- 順位の計算
    local rankings = {}
    for userId, progress in pairs(raceState.playerProgress) do
        table.insert(rankings, {
            userId = userId,
            checkpointsPassed = progress.checkpointsPassed,
            distanceTraveled = progress.distanceTraveled,
            finished = progress.finished,
            finishTime = progress.finishTime
        })
    end
    
    -- 順位でソート
    table.sort(rankings, function(a, b)
        if a.finished and b.finished then
            return a.finishTime < b.finishTime
        elseif a.finished then
            return true
        elseif b.finished then
            return false
        else
            if a.checkpointsPassed ~= b.checkpointsPassed then
                return a.checkpointsPassed > b.checkpointsPassed
            else
                return a.distanceTraveled > b.distanceTraveled
            end
        end
    end)
    
    -- 報酬の計算
    local rewards = {}
    for rank, data in ipairs(rankings) do
        local coinReward = 0
        if rank == 1 then
            coinReward = 100
        elseif rank == 2 then
            coinReward = 70
        elseif rank == 3 then
            coinReward = 50
        else
            coinReward = 20
        end
        
        rewards[data.userId] = {
            rank = rank,
            coins = coinReward,
            xp = 10 + (MAX_PLAYERS - rank + 1) * 5
        }
    end
    
    -- 全プレイヤーに結果を通知
    for _, player in raceState.players do
        local playerReward = rewards[player.UserId]
        raceEndEvent:FireClient(player, {
            rank = playerReward.rank,
            coins = playerReward.coins,
            xp = playerReward.xp,
            rankings = rankings
        })
    end
    
    -- マップを削除
    local raceMap = workspace:FindFirstChild("RaceMap")
    if raceMap then
        raceMap:Destroy()
    end
    
    -- プレイヤーをロビーに戻す
    local lobbyFolder = workspace:FindFirstChild("Lobby")
    if lobbyFolder then
        local spawnLocations = lobbyFolder:FindFirstChild("SpawnLocations")
        if spawnLocations then
            for i, player in raceState.players do
                if player.Character and player.Character.PrimaryPart then
                    local spawnIndex = (player.UserId % 12) + 1
                    local spawnLocation = spawnLocations:FindFirstChild("Spawn" .. spawnIndex)
                    if spawnLocation then
                        player.Character:SetPrimaryPartCFrame(spawnLocation.CFrame + Vector3.new(0, 5, 0))
                    end
                end
            end
        end
    end
    
    -- レース状態をリセット
    raceState.currentMap = nil
    raceState.players = {}
    raceState.playerProgress = {}
end

-- チェックポイント通過判定
local function checkCheckpoint(player, checkpointPart)
    if not raceState.isRacing then
        return
    end
    
    local progress = raceState.playerProgress[player.UserId]
    if not progress then
        return
    end
    
    local checkpointNumber = checkpointPart:GetAttribute("CheckpointNumber")
    if not checkpointNumber then
        return
    end
    
    -- 順番通りに通過したか確認
    if checkpointNumber == progress.lastCheckpoint + 1 then
        progress.lastCheckpoint = checkpointNumber
        progress.checkpointsPassed = checkpointNumber
        
        -- プレイヤーに通知
        checkpointReachedEvent:FireClient(player, {
            checkpointNumber = checkpointNumber,
            totalCheckpoints = raceState.currentMap:GetAttribute("CheckpointCount")
        })
    end
end

-- ゴール判定
local function checkGoal(player, goalPart)
    if not raceState.isRacing then
        return
    end
    
    local progress = raceState.playerProgress[player.UserId]
    if not progress or progress.finished then
        return
    end
    
    -- 全チェックポイントを通過したか確認
    local totalCheckpoints = raceState.currentMap:GetAttribute("CheckpointCount")
    if progress.checkpointsPassed >= totalCheckpoints then
        progress.finished = true
        progress.finishTime = tick() - raceState.raceStartTime
        
        -- プレイヤーにゴール通知
        updateRaceUIEvent:FireClient(player, {
            type = "finished",
            time = progress.finishTime
        })
    end
end

-- プレイヤーが落ちたときのリスポーン
local function respawnPlayer(player)
    if not raceState.isRacing then
        return
    end
    
    local progress = raceState.playerProgress[player.UserId]
    if not progress then
        return
    end
    
    -- 最後のチェックポイントにリスポーン
    local lastCheckpoint = progress.lastCheckpoint
    if lastCheckpoint > 0 then
        local checkpoints = raceState.currentMap:FindFirstChild("Checkpoints")
        if checkpoints then
            local checkpointPart = checkpoints:FindFirstChild("Checkpoint" .. lastCheckpoint)
            if checkpointPart and player.Character and player.Character.PrimaryPart then
                player.Character:SetPrimaryPartCFrame(checkpointPart.CFrame + Vector3.new(0, 10, 0))
            end
        end
    else
        -- スタート地点にリスポーン
        local startArea = raceState.currentMap:FindFirstChild("StartArea")
        if startArea and player.Character and player.Character.PrimaryPart then
            player.Character:SetPrimaryPartCFrame(startArea.CFrame + Vector3.new(0, 5, 0))
        end
    end
end

-- プレイヤー落下検出
RunService.Heartbeat:Connect(function()
    if not raceState.isRacing then
        return
    end
    
    for _, player in raceState.players do
        if player.Character and player.Character.PrimaryPart then
            local position = player.Character.PrimaryPart.Position
            progress = raceState.playerProgress[player.UserId]
            
            if progress then
                -- 進行距離の更新
                local distance = position.Z - (-raceState.currentMap:GetAttribute("CourseLength") / 2)
                progress.distanceTraveled = math.max(0, distance)
                progress.position = position
                
                -- 落下判定
                if position.Y < -50 then
                    respawnPlayer(player)
                end
            end
        end
    end
end)

-- テスト用：レース開始コマンド
-- 実際にはUIボタンなどから呼び出す
_G.startRace = startRace
_G.endRace = endRace

return "レースマネージャーを初期化しました"