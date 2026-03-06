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
        -- 不要な装飾品やデフォルトの部位をクリア
        for _, child in character:GetChildren() do
            if child:IsA("Accessory") or child:IsA("Clothing") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
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
            marble.Name = "MarbleModel"
            print("[MarbleSpawner] クローンしたマーブルテンプレート: " .. tostring(marbleTemplate.Name) .. " -> MarbleModel")
            
            -- まずCFrameを合わせる
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                character.PrimaryPart = hrp
                marble:PivotTo(hrp.CFrame)
                marble.Parent = character
                print("[MarbleSpawner] MarbleModel をキャラクターに親付けしました: " .. tostring(player.Name))
                
                -- HRPとMarbleをWeldConstraintで結合
                local marbleHrp = marble:FindFirstChild("HumanoidRootPart") or marble.PrimaryPart or marble:FindFirstChildWhichIsA("BasePart")
                if marbleHrp then
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = hrp
                    weld.Part1 = marbleHrp
                    weld.Parent = marbleHrp
                    print("[MarbleSpawner] HRP と Marble の WeldConstraint を作成しました: " .. tostring(hrp) .. " <-> " .. tostring(marbleHrp))
                    
                    -- モデル側の剛体設定（重さなどをHRPに任せる）
                    for _, part in ipairs(marble:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Anchored = false
                            part.Massless = true
                            part.CanCollide = false
                            if part.Name == "Marble" or part.Name == "HumanoidRootPart" then
                                part.Transparency = 0
                            end
                        end
                    end
                end
                
                -- HRP自体もボール化して見えるようにする
                hrp.Transparency = 0
                print("[MarbleSpawner] HRP の Transparency を0に設定しました")
                hrp.CanCollide = true
                hrp.Anchored = false
                hrp.Size = Vector3.new(4, 4, 4) -- サイズ統一
                hrp.Shape = Enum.PartType.Ball

                local highlight = character:FindFirstChild("MarbleHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "MarbleHighlight"
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillColor = hrp.Color
                    highlight.FillTransparency = 0.65
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = character
                    highlight.Parent = character
                end
            else
                marble.Parent = character
            end
            
            -- マブルモデル内のパーツも表示
            local marblePart = marble:FindFirstChild("Marble")
            if marblePart then
                marblePart.Transparency = 0
                marblePart.CanCollide = true
            end
            
            local marbleHrp = marble:FindFirstChild("HumanoidRootPart")
            if marbleHrp then
                marbleHrp.Transparency = 0
                marbleHrp.CanCollide = true
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