-- キャラクター設定スクリプト
local character = script.Parent
local Players = game:GetService("Players")
local player = Players:GetPlayerFromCharacter(character)

-- マブルの色をランダムに選択
local marbleColors = {
    Color3.fromRGB(255, 100, 100), -- 赤
    Color3.fromRGB(100, 255, 100), -- 緑
    Color3.fromRGB(100, 100, 255), -- 青
    Color3.fromRGB(255, 255, 100), -- 黄
    Color3.fromRGB(255, 100, 255), -- 紫
    Color3.fromRGB(100, 255, 255), -- シアン
    Color3.fromRGB(255, 150, 50),  -- オレンジ
    Color3.fromRGB(150, 50, 255),  -- ラベンダー
}

-- プレイヤーIDに基づいて色を決定（同じプレイヤーは同じ色）
local colorIndex = (player and (player.UserId % #marbleColors) + 1) or math.random(1, #marbleColors)
local marbleColor = marbleColors[colorIndex]

-- HumanoidRootPartを球体に変更
local hrp = character:WaitForChild("HumanoidRootPart")
if hrp then
    -- Meshを削除して球体にする
    local mesh = hrp:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        mesh:Destroy()
    end
    
    -- 新しい球体Meshを作成
    local sphereMesh = Instance.new("SpecialMesh")
    sphereMesh.MeshType = Enum.MeshType.Sphere
    sphereMesh.Parent = hrp
    
    -- サイズを調整（マブルサイズ）
    hrp.Size = Vector3.new(4, 4, 4)
    
    -- マテリアルを設定
    hrp.Material = Enum.Material.SmoothPlastic
    hrp.Color = marbleColor
    
    -- 物理設定
    hrp.CustomPhysicalProperties = PhysicalProperties.new(
        5, -- 密度
        0.3, -- 摩擦
        0.2, -- 弾性
        1, -- 摩擦重量
        1 -- 弾性重量
    )
    
    -- PrimaryPartを設定（重要！）
    character.PrimaryPart = hrp
    
    -- HumanoidRootPartをアンチャー解除（移動可能にする）
    hrp.Anchored = false
    
    print("[CharacterSetup] マブルキャラクターを設定しました: " .. (player and player.Name or "Unknown") .. " (色: " .. colorIndex .. ")")
    print("[CharacterSetup] PrimaryPartを設定しました: " .. hrp.Name)
    print("[CharacterSetup] HumanoidRootPartをアンチャー解除しました")
end

-- 不要なパーツを削除（Head, LeftLeg, RightLegなど）
local partsToRemove = {"Head", "LeftLeg", "RightLeg", "LeftArm", "RightArm"}
for _, partName in ipairs(partsToRemove) do
    local part = character:FindFirstChild(partName)
    if part then
        part:Destroy()
    end
end

-- Humanoidの設定
local humanoid = character:WaitForChild("Humanoid")
if humanoid then
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = 0 -- マブルなのでWalkSpeedは使用しない
    humanoid.JumpPower = 0 -- マブルなのでJumpPowerは使用しない
    humanoid.PlatformStand = true -- マブルなので立たせない
end

print("[CharacterSetup] マブルキャラクターを設定しました")
