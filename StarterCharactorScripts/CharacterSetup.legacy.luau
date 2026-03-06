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
    -- 明示的に透過度を0にして見えるようにする
    hrp.Transparency = 0
    
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
    
    -- 設定が反映されたか確認
    if character.PrimaryPart ~= hrp then
        warn("[CharacterSetup] PrimaryPartの設定に失敗しました")
    end
    
    -- HumanoidRootPartをアンチャー解除（移動可能にする）
    hrp.Anchored = false
    
    print("[CharacterSetup] マブルキャラクターを設定しました: " .. (player and player.Name or "Unknown") .. " (色: " .. colorIndex .. ")")
    print("[CharacterSetup] PrimaryPartを設定しました: " .. hrp.Name .. " (確認: " .. tostring(character.PrimaryPart == hrp) .. ")")
    print("[CharacterSetup] HumanoidRootPartをアンチャー解除しました")

    local highlight = character:FindFirstChild("MarbleHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "MarbleHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = marbleColor
        highlight.FillTransparency = 0.6
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Adornee = character
        highlight.Parent = character
    end
end

-- Humanoidの設定（パーツを削除する前に首の必要性を無効化する！）
local humanoid = character:WaitForChild("Humanoid")
if humanoid then
    humanoid.RequiresNeck = false -- Headを消しても死なないようにする
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = 0 -- マブルなのでWalkSpeedは使用しない
    humanoid.JumpPower = 0 -- マブルなのでJumpPowerは使用しない
    humanoid.PlatformStand = true -- マブルなので立たせない
    print("[CharacterSetup] Humanoidを設定しました: MaxHealth=" .. humanoid.MaxHealth)
end

-- 不要なパーツを透明・無効化する（Destroyすると死亡判定になるリスクがあるため）
for _, child in ipairs(character:GetDescendants()) do
    -- MarbleModel内のパーツは除外
    local marbleModel = character:FindFirstChild("MarbleModel")
    local isMarblePart = false
    if marbleModel then
        isMarblePart = child:IsDescendantOf(marbleModel) or child == marbleModel
    end
    
    if not isMarblePart then
        if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
            -- ルートパーツ以外のすべてのパーツを透明にして当たり判定オフ
            child.Transparency = 1
            child.CanCollide = false
            child.Massless = true
        elseif child:IsA("Decal") then
            -- 顔などのデカールを透明にする
            child.Transparency = 1
        end
    end
end

print("[CharacterSetup] マブルキャラクターの初期化が完了しました: " .. (player and player.Name or "Unknown"))
