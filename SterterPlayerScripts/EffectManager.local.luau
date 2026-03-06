-- エフェクトマネージャースクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local effectsFolder = ReplicatedStorage:WaitForChild("SharedAssets"):WaitForChild("Effects")

-- エフェクトのキャッシュ
local effectCache = {}

-- エフェクトを取得または作成
local function getEffect(effectName)
    if effectCache[effectName] then
        return effectCache[effectName]
    end
    
    local template = effectsFolder:FindFirstChild(effectName)
    if not template then
        warn("エフェクトが見つかりません: " .. effectName)
        return nil
    end
    
    local effect = template:Clone()
    effectCache[effectName] = effect
    
    return effect
end

-- エフェクトを再生
local function playEffect(effectName, position, duration)
    local effect = getEffect(effectName)
    if not effect then
        return
    end
    
    -- エフェクト用のパートを作成
    local effectPart = Instance.new("Part")
    effectPart.Name = "EffectPart"
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = workspace
    
    -- エフェクトをパートにアタッチ
    local emitter = effect:Clone()
    emitter.Parent = effectPart
    
    -- エフェクトを一時的に有効化
    emitter.Enabled = true
    
    -- 指定時間後にクリーンアップ
    local cleanupTime = duration or 2
    task.delay(cleanupTime, function()
        emitter.Enabled = false
        task.wait(1)
        effectPart:Destroy()
    end)
end

-- マーブルにエフェクトをアタッチ
local function attachEffectToMarble(effectName, duration)
    local character = player.Character
    if not character then
        return
    end
    
    -- HumanoidRootPartをマブルとして使用
    local marble = character:FindFirstChild("HumanoidRootPart")
    if not marble then
        return
    end
    
    local effect = getEffect(effectName)
    if not effect then
        return
    end
    
    -- エフェクトをマブルにアタッチ
    local emitter = effect:Clone()
    emitter.Parent = marble
    emitter.Enabled = true
    
    -- 指定時間後にクリーンアップ
    local cleanupTime = duration or 2
    task.delay(cleanupTime, function()
        emitter.Enabled = false
        task.wait(1)
        emitter:Destroy()
    end)
end

-- グローバル関数として公開
_G.playEffect = playEffect
_G.attachEffectToMarble = attachEffectToMarble

return "エフェクトマネージャーを初期化しました"