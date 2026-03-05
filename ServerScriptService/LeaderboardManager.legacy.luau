-- リーダーボードマネージャースクリプト
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local leaderboardDataStore = DataStoreService:GetDataStore("MarbleRaceLeaderboard")

-- リーダーボードデータのキャッシュ
local leaderboardCache = {}
local MAX_LEADERBOARD_ENTRIES = 100

-- リーダーボードエントリの構造
-- {
--   userId = number,
--   playerName = string,
--   totalWins = number,
--   totalRaces = number,
--   bestTime = number,
--   totalCoins = number,
--   level = number
-- }

-- リーダーボードをロード
local function loadLeaderboard()
    local success, data = pcall(function()
        return leaderboardDataStore:GetAsync("GlobalLeaderboard")
    end)
    
    if success and data then
        leaderboardCache = data
    else
        leaderboardCache = {}
    end
    
    return leaderboardCache
end

-- リーダーボードを保存
local function saveLeaderboard()
    local success, err = pcall(function()
        leaderboardDataStore:SetAsync("GlobalLeaderboard", leaderboardCache)
    end)
    
    if not success then
        warn("リーダーボード保存失敗: " .. tostring(err))
        return false
    end
    
    return true
end

-- プレイヤーのリーダーボードエントリを取得または作成
local function getPlayerEntry(userId)
    for i, entry in ipairs(leaderboardCache) do
        if entry.userId == userId then
            return entry, i
        end
    end
    
    -- 新しいエントリを作成
    local newEntry = {
        userId = userId,
        playerName = "Unknown",
        totalWins = 0,
        totalRaces = 0,
        bestTime = math.huge,
        totalCoins = 0,
        level = 1
    }
    
    table.insert(leaderboardCache, newEntry)
    return newEntry, #leaderboardCache
end

-- プレイヤーのリーダーボードデータを更新
local function updatePlayerEntry(player, updates)
    local entry, index = getPlayerEntry(player.UserId)
    
    if not entry then
        return false, "エントリの作成に失敗しました"
    end
    
    -- データを更新
    for key, value in pairs(updates) do
        entry[key] = value
    end
    
    -- プレイヤー名を更新
    entry.playerName = player.Name
    
    return true
end

-- レース結果をリーダーボードに記録
local function recordRaceResult(player, rank, time, coinsEarned)
    local entry, index = getPlayerEntry(player.UserId)
    
    if not entry then
        return false, "エントリの作成に失敗しました"
    end
    
    -- レース結果を更新
    entry.totalRaces = (entry.totalRaces or 0) + 1
    entry.totalCoins = (entry.totalCoins or 0) + coinsEarned
    
    if rank == 1 then
        entry.totalWins = (entry.totalWins or 0) + 1
    end
    
    -- ベストタイムを更新
    if time < (entry.bestTime or math.huge) then
        entry.bestTime = time
    end
    
    -- プレイヤーデータからレベルを取得
    if _G.getPlayerData then
        local playerData = _G.getPlayerData(player)
        if playerData then
            entry.level = playerData.level or 1
        end
    end
    
    -- プレイヤー名を更新
    entry.playerName = player.Name
    
    -- 定期的に保存
    if entry.totalRaces % 5 == 0 then
        saveLeaderboard()
    end
    
    return true
end

-- リーダーボードを取得（ソート済み）
local function getLeaderboard(sortBy, limit)
    sortBy = sortBy or "totalWins" -- デフォルトは勝利数でソート
    limit = limit or 10
    
    local sortedLeaderboard = table.clone(leaderboardCache)
    
    -- ソート
    table.sort(sortedLeaderboard, function(a, b)
        if sortBy == "totalWins" then
            return (a.totalWins or 0) > (b.totalWins or 0)
        elseif sortBy == "bestTime" then
            return (a.bestTime or math.huge) < (b.bestTime or math.huge)
        elseif sortBy == "totalCoins" then
            return (a.totalCoins or 0) > (b.totalCoins or 0)
        elseif sortBy == "level" then
            return (a.level or 1) > (b.level or 1)
        else
            return (a.totalRaces or 0) > (b.totalRaces or 0)
        end
    end)
    
    -- 上位N件を返す
    local result = {}
    for i = 1, math.min(limit, #sortedLeaderboard) do
        table.insert(result, sortedLeaderboard[i])
    end
    
    return result
end

-- プレイヤーのランキングを取得
local function getPlayerRank(player, sortBy)
    sortBy = sortBy or "totalWins"
    
    local sortedLeaderboard = table.clone(leaderboardCache)
    
    table.sort(sortedLeaderboard, function(a, b)
        if sortBy == "totalWins" then
            return (a.totalWins or 0) > (b.totalWins or 0)
        elseif sortBy == "bestTime" then
            return (a.bestTime or math.huge) < (b.bestTime or math.huge)
        elseif sortBy == "totalCoins" then
            return (a.totalCoins or 0) > (b.totalCoins or 0)
        elseif sortBy == "level" then
            return (a.level or 1) > (b.level or 1)
        else
            return (a.totalRaces or 0) > (b.totalRaces or 0)
        end
    end)
    
    for i, entry in ipairs(sortedLeaderboard) do
        if entry.userId == player.UserId then
            return i
        end
    end
    
    return nil
end

-- 初期化
loadLeaderboard()

-- 定期的な自動保存（5分ごと）
task.spawn(function()
    while true do
        task.wait(300) -- 5分
        saveLeaderboard()
    end
end)

-- RemoteFunctionsの設定
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getLeaderboardRF = remoteFunctions:WaitForChild("GetLeaderboard")
local getPlayerRankRF = remoteFunctions:WaitForChild("GetPlayerRank")

-- GetLeaderboard RemoteFunctionの処理
getLeaderboardRF.OnServerInvoke = function(player, sortBy, limit)
    return getLeaderboard(sortBy, limit)
end

-- GetPlayerRank RemoteFunctionの処理
getPlayerRankRF.OnServerInvoke = function(player, sortBy)
    return getPlayerRank(player, sortBy)
end

-- グローバル関数として公開
_G.recordRaceResult = recordRaceResult
_G.getLeaderboard = getLeaderboard
_G.getPlayerRank = getPlayerRank
_G.updatePlayerEntry = updatePlayerEntry

return "リーダーボードマネージャーを初期化しました"