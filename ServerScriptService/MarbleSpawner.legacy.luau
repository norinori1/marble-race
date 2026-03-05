-- プレイヤーにマブルをスポーンさせるスクリプト
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local marbleTemplates = ServerStorage:WaitForChild("ServerAssets"):WaitForChild("MarbleTemplates")
local lobbyFolder = workspace:WaitForChild("Lobby")
local spawnLocations = lobbyFolder:WaitForChild("SpawnLocations")

-- デフォルトスキン
local DEFAULT_SKIN = "RedMarble"

-- プレイヤーデータの初期化
local playerData = {}

-- プレイヤーが参加したときの処理
local function onPlayerAdded(player)
    -- プレイヤーデータの初期化
    playerData[player.UserId] = {
        coins = 0,
        level = 1,
        xp = 0,
        ownedSkins = {DEFAULT_SKIN},
        equippedSkin = DEFAULT_SKIN,
        totalWins = 0,
        totalRaces = 0
    }
    
    -- キャラクターがロードされたときの処理
    player.CharacterAdded:Connect(function(character)
        -- 既存のキャラクターをクリア
        for _, child in character:GetChildren() do
            if child.Name ~= "Humanoid" then
                child:Destroy()
            end
        end
        
        -- プレイヤーデータの取得
        local data = playerData[player.UserId]
        local skinName = data.equippedSkin or DEFAULT_SKIN
        
        -- マブルテンプレートの取得
        local marbleTemplate = marbleTemplates:FindFirstChild(skinName)
        if not marbleTemplate then
            marbleTemplate = marbleTemplates:FindFirstChild(DEFAULT_SKIN)
        end
        
        if marbleTemplate then
            -- マブルをクローンしてキャラクターに追加
            local marble = marbleTemplate:Clone()
            marble.Name = "Marble"
            marble.Parent = character
            
            -- HumanoidRootPartの設定
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Transparency = 1
                hrp.CanCollide = false
            end
            
            -- マブルの位置をスポーン位置に設定
            local spawnIndex = (player.UserId % 12) + 1
            local spawnLocation = spawnLocations:FindFirstChild("Spawn" .. spawnIndex)
            if spawnLocation then
                character:SetPrimaryPartCFrame(spawnLocation.CFrame + Vector3.new(0, 5, 0))
            end
        end
    end)
end

-- 既存のプレイヤーを処理
for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

-- 新しいプレイヤーを監視
Players.PlayerAdded:Connect(onPlayerAdded)

-- プレイヤーが退出したときの処理
Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
end)

-- RemoteFunction: プレイヤーデータの取得
local getPlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerData")
getPlayerData.OnServerInvoke = function(player)
    return playerData[player.UserId]
end

-- RemoteFunction: プレイヤーデータの保存
local savePlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SavePlayerData")
savePlayerData.OnServerInvoke = function(player, data)
    if playerData[player.UserId] then
        playerData[player.UserId] = data
        return true
    end
    return false
end