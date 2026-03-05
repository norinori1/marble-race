-- プレイヤーにマブルをスポーンさせるスクリプト
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local marbleTemplates = ServerStorage:WaitForChild("ServerAssets"):WaitForChild("MarbleTemplates")
local lobbyFolder = workspace:WaitForChild("Lobby")
local spawnLocations = lobbyFolder:WaitForChild("SpawnLocations")

-- デフォルトスキン
local DEFAULT_SKIN = "RedMarble"

-- プレイヤーが参加したときの処理
local function onPlayerAdded(player)
    -- キャラクターがロードされたときの処理
    player.CharacterAdded:Connect(function(character)
        -- 既存のキャラクターをクリア
        for _, child in character:GetChildren() do
            if child.Name ~= "Humanoid" then
                child:Destroy()
            end
        end
        
        -- プレイヤーデータの取得（DataManagerから）
        local data = _G.getPlayerData and _G.getPlayerData(player)
        local skinName = DEFAULT_SKIN
        
        if data and data.equippedSkin then
            skinName = data.equippedSkin
        end
        
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
                -- PrimaryPartが設定されるまで待機
                if not character.PrimaryPart then
                    local timeout = 0
                    while not character.PrimaryPart and timeout < 50 do
                        task.wait(0.1)
                        timeout = timeout + 1
                    end
                end
                
                if character.PrimaryPart then
                    character:SetPrimaryPartCFrame(spawnLocation.CFrame + Vector3.new(0, 5, 0))
                    print("[MarbleSpawner] プレイヤー " .. player.Name .. " をロビースポーン位置に設定しました")
                else
                    warn("[MarbleSpawner] プレイヤー " .. player.Name .. " のPrimaryPartが設定されていません")
                end
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

-- RemoteFunction: プレイヤーデータの取得
local getPlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetPlayerData")
getPlayerData.OnServerInvoke = function(player)
    return _G.getPlayerData and _G.getPlayerData(player) or nil
end

-- RemoteFunction: プレイヤーデータの保存
local savePlayerData = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SavePlayerData")
savePlayerData.OnServerInvoke = function(player, data)
    return _G.updatePlayerData and _G.updatePlayerData(player, data)
end