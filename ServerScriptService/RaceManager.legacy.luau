-- レースマネージャースクリプト
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local maps = workspace:WaitForChild("RaceMaps")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local raceStartEvent = remoteEvents:WaitForChild("RaceStart")
local raceEndEvent = remoteEvents:WaitForChild("RaceEnd")
local checkpointReachedEvent = remoteEvents:WaitForChild("CheckpointReached")
local updateRaceUIEvent = remoteEvents:WaitForChild("UpdateRaceUI")
local startRaceRequestEvent = remoteEvents:WaitForChild("StartRaceRequest")

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
local function prepareRace(forceStart)
    forceStart = forceStart or false
    
    if raceState.isRacing then
        return false, "レース中です"
    end
    
    local playerCount = #Players:GetPlayers()
    
    -- 強制開始の場合はプレイヤー数チェックをスキップ
    if not forceStart then
        if playerCount < MIN_PLAYERS then
            return false, "プレイヤーが足りません（最低" .. MIN_PLAYERS .. "人必要）"
        end
    end
    
    if playerCount < 1 then
        return false, "プレイヤーがいません"
    end
    
    if playerCount > MAX_PLAYERS then
        return false, "プレイヤーが多すぎます（最大" .. MAX_PLAYERS .. "人まで）"
    end
    
    -- 利用可能なマップを取得
    local availableMaps = {}
    for _, map in maps:GetChildren() do
        if map:IsA("Folder") then
            table.insert(availableMaps, map)
        end
    end
    
    if #availableMaps == 0 then
        return false, "マップが見つかりません"
    end
    
    -- ランダムにマップを選択
    local selectedMap = availableMaps[math.random(1, #availableMaps)]
    
    raceState.currentMap = selectedMap
    raceState.players = Players:GetPlayers()
    
    -- プレイヤー進捗の初期化
    for _, player in raceState.players do
        initializePlayerProgress(player)
    end
    
    return true, "レース準備完了: " .. selectedMap:GetAttribute("CourseName")
end

-- レース開始
local function startRace(forceStart)
    forceStart = forceStart or false
    
    local success, message = prepareRace(forceStart)
    if not success then
        return false, message
    end
    
    raceState.isRacing = true
    raceState.countdown = COUNTDOWN_TIME
    
    print("[RaceManager] レース開始処理開始")
    print("[RaceManager] 選択されたマップ: " .. raceState.currentMap.Name)
    
    -- マップを表示（非表示から表示に変更）
    local currentMap = raceState.currentMap
    local partCount = 0
    for _, child in ipairs(currentMap:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Transparency = 0
            child.CanCollide = true
            partCount = partCount + 1
        end
    end
    print("[RaceManager] マップを表示しました: " .. partCount .. "個のパーツ")
    
    -- プレイヤーをスタート位置にテレポート
    local startArea = currentMap:FindFirstChild("StartArea")
    if startArea then
        print("[RaceManager] StartArea位置: " .. tostring(startArea.Position))
        for i, player in raceState.players do
            -- キャラクターがロードされるのを待つ（タイムアウト付き）
            local character = player.Character
            if not character then
                character = player.CharacterAdded:Wait(5)
            end
            
            if not character then
                warn("[RaceManager] プレイヤー " .. player.Name .. " のキャラクターが見つかりません")
                continue
            end
            
            -- PrimaryPartが設定されるのを待つ（タイムアウト付き）
            if not character.PrimaryPart then
                local timeout = 0
                while not character.PrimaryPart and timeout < 50 do
                    task.wait(0.1)
                    timeout = timeout + 1
                end
            end
            
            if character and character.PrimaryPart then
                local offset = Vector3.new((i - 1 - (#raceState.players - 1) / 2) * 5, 5, 0)
                character:SetPrimaryPartCFrame(startArea.CFrame + offset)
                print("[RaceManager] プレイヤー " .. player.Name .. " をスタート位置にテレポート: " .. tostring(startArea.CFrame + offset))
            else
                warn("[RaceManager] プレイヤー " .. player.Name .. " のPrimaryPartが見つかりません")
            end
        end
    else
        warn("[RaceManager] StartAreaが見つかりません！")
    end
    
    -- 全プレイヤーにレース開始準備を通知
    for _, player in raceState.players do
        raceStartEvent:FireClient(player, {
            mapName = raceState.currentMap:GetAttribute("CourseName"),
            duration = RACE_DURATION,
            checkpointCount = raceState.currentMap:GetAttribute("CheckpointCount"),
            bgmName = "RaceBGM" .. math.random(1, 2) -- ランダムにBGMを選択
        })
    end
    
    -- カウントダウン開始
    for countdown = COUNTDOWN_TIME, 1, -1 do
        raceState.countdown = countdown
        print("[RaceManager] カウントダウン: " .. countdown)
        
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
    print("[RaceManager] レース開始！")
    
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
        
        -- 報酬を配布
        if _G.updatePlayerData then
            _G.updatePlayerData(player, {
                coins = (_G.getPlayerData(player).coins or 0) + playerReward.coins,
                totalRaces = (_G.getPlayerData(player).totalRaces or 0) + 1
            })
            
            -- XPを追加
            if _G.addXP then
                _G.addXP(player, playerReward.xp)
            end
            
            -- 勝利数を更新
            if playerReward.rank == 1 then
                _G.updatePlayerData(player, {
                    totalWins = (_G.getPlayerData(player).totalWins or 0) + 1
                })
            end
        end
        
        -- リーダーボードに記録
        if _G.recordRaceResult then
            local playerProgress = raceState.playerProgress[player.UserId]
            local finishTime = playerProgress and playerProgress.finishTime or 0
            _G.recordRaceResult(player, playerReward.rank, finishTime, playerReward.coins)
        end
        
        raceEndEvent:FireClient(player, {
            rank = playerReward.rank,
            coins = playerReward.coins,
            xp = playerReward.xp,
            rankings = rankings
        })
    end
    
    -- マップを非表示にする
    if raceState.currentMap then
        for _, child in ipairs(raceState.currentMap:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = 1
                child.CanCollide = false
            end
        end
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
            local progress = raceState.playerProgress[player.UserId]
            
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

-- 全マップのチェックポイントとゴールにイベントを設定
local function setupAllMapEvents()
    for _, map in ipairs(maps:GetChildren()) do
        if map:IsA("Folder") then
            -- チェックポイントの設定
            local checkpointsFolder = map:FindFirstChild("Checkpoints")
            if checkpointsFolder then
                for _, checkpoint in ipairs(checkpointsFolder:GetChildren()) do
                    if checkpoint:IsA("BasePart") then
                        checkpoint.Touched:Connect(function(hit)
                            -- レース中で、このマップが使用されている場合のみ処理
                            if not raceState.isRacing or raceState.currentMap ~= map then
                                return
                            end
                            
                            local character = hit.Parent
                            if not character then return end
                            
                            local humanoid = character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                local player = Players:GetPlayerFromCharacter(character)
                                if player then
                                    checkCheckpoint(player, checkpoint)
                                end
                            end
                        end)
                    end
                end
            end
            
            -- ゴールエリアの設定
            local goalArea = map:FindFirstChild("GoalArea")
            if goalArea and goalArea:IsA("BasePart") then
                goalArea.Touched:Connect(function(hit)
                    -- レース中で、このマップが使用されている場合のみ処理
                    if not raceState.isRacing or raceState.currentMap ~= map then
                        return
                    end
                    
                    local character = hit.Parent
                    if not character then return end
                    
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local player = Players:GetPlayerFromCharacter(character)
                        if player then
                            checkGoal(player, goalArea)
                        end
                    end
                end)
            end
        end
    end
end

-- 初期化時に全マップのイベントを設定
setupAllMapEvents()

-- レース開始リクエストの処理
startRaceRequestEvent.OnServerEvent:Connect(function(player)
    print("[RaceManager] レース開始リクエストを受信: " .. player.Name)
    
    -- 最初のリクエストのみを受け付ける（スパム防止）
    if raceState.isRacing then
        print("[RaceManager] 既にレース中です")
        updateRaceUIEvent:FireClient(player, {
            type = "error",
            message = "既にレース中です"
        })
        return
    end
    
    -- プレイヤー数が足りない場合は強制開始フラグを設定
    local playerCount = #Players:GetPlayers()
    print("[RaceManager] プレイヤー数: " .. playerCount)
    local forceStart = playerCount < MIN_PLAYERS
    
    local success, message = startRace(forceStart)
    if success then
        print("[RaceManager] レース開始成功: " .. message)
    else
        print("[RaceManager] レース開始失敗: " .. message)
        -- エラーメッセージをプレイヤーに通知
        updateRaceUIEvent:FireClient(player, {
            type = "error",
            message = message
        })
    end
end)

-- テスト用：レース開始コマンド
_G.startRace = startRace
_G.endRace = endRace

return "レースマネージャーを初期化しました"