-- データ管理スクリプト
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- DataStoreの取得
local playerDataStore = DataStoreService:GetDataStore("MarbleRacePlayerData")

-- データのデフォルト値
local DEFAULT_DATA = {
    coins = 0,
    level = 1,
    xp = 0,
    ownedSkins = {"RedMarble"},
    equippedSkin = "RedMarble",
    totalWins = 0,
    totalRaces = 0
}

-- プレイヤーデータのキャッシュ
local playerDataCache = {}

-- データの読み込み
local function loadPlayerData(player)
    local userId = player.UserId
    local key = "Player_" .. userId
    
    local success, data = pcall(function()
        return playerDataStore:GetAsync(key)
    end)
    
    if success and data then
        -- データが存在する場合、キャッシュに保存
        playerDataCache[userId] = data
        return data
    else
        -- データが存在しない場合、デフォルト値を使用
        playerDataCache[userId] = table.clone(DEFAULT_DATA)
        return table.clone(DEFAULT_DATA)
    end
end

-- データの保存
local function savePlayerData(player)
    local userId = player.UserId
    local key = "Player_" .. userId
    local data = playerDataCache[userId]
    
    if not data then
        return false, "データが見つかりません"
    end
    
    -- 指数バックオフでリトライ
    local maxRetries = 3
    local retryDelay = 1
    
    for attempt = 1, maxRetries do
        local success, err = pcall(function()
            playerDataStore:SetAsync(key, data)
        end)
        
        if success then
            return true
        else
            warn("データ保存失敗 (試行 " .. attempt .. "/" .. maxRetries .. "): " .. tostring(err))
            if attempt < maxRetries then
                task.wait(retryDelay)
                retryDelay = retryDelay * 2 -- 指数バックオフ
            end
        end
    end
    
    return false, "データ保存に失敗しました"
end

-- データの更新
local function updatePlayerData(player, updates)
    local userId = player.UserId
    local data = playerDataCache[userId]
    
    if not data then
        return false, "データが見つかりません"
    end
    
    -- データを更新
    for key, value in pairs(updates) do
        data[key] = value
    end
    
    return true
end

-- XPの追加とレベルアップチェック
local function addXP(player, xpAmount)
    local data = playerDataCache[player.UserId]
    if not data then
        return false, "データが見つかりません"
    end
    
    data.xp = data.xp + xpAmount
    
    -- レベルアップチェック
    local requiredXP = 100 + 20 * (data.level - 1)
    while data.xp >= requiredXP do
        data.xp = data.xp - requiredXP
        data.level = data.level + 1
        requiredXP = 100 + 20 * (data.level - 1)
        
        -- レベルアップ通知
        print(player.Name .. " がレベル " .. data.level .. " にアップしました！")
    end
    
    return true
end

-- プレイヤーが参加したときの処理
local function onPlayerAdded(player)
    -- データを読み込み
    local data = loadPlayerData(player)
    print(player.Name .. " のデータを読み込みました: レベル " .. data.level .. ", コイン " .. data.coins)
end

-- プレイヤーが退出したときの処理
local function onPlayerRemoving(player)
    -- データを保存
    local success, err = savePlayerData(player)
    if success then
        print(player.Name .. " のデータを保存しました")
    else
        warn(player.Name .. " のデータ保存に失敗しました: " .. tostring(err))
    end
    
    -- キャッシュから削除
    playerDataCache[player.UserId] = nil
end

-- 既存のプレイヤーを処理
for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

-- 新しいプレイヤーを監視
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- 定期的な自動保存（5分ごと）
task.spawn(function()
    while true do
        task.wait(300) -- 5分
        
        for _, player in Players:GetPlayers() do
            local success, err = savePlayerData(player)
            if not success then
                warn("自動保存失敗: " .. player.Name .. " - " .. tostring(err))
            end
        end
    end
end)

-- グローバル関数として公開
_G.getPlayerData = function(player)
    return playerDataCache[player.UserId]
end

_G.updatePlayerData = updatePlayerData
_G.addXP = addXP
_G.savePlayerData = savePlayerData

return "データマネージャーを初期化しました"