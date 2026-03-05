-- サウンドマネージャースクリプト
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local soundsFolder = ReplicatedStorage:WaitForChild("SharedAssets"):WaitForChild("Sounds")

-- サウンドのキャッシュ
local soundCache = {}
local currentBGM = nil

-- サウンドを取得または作成
local function getSound(soundName)
    if soundCache[soundName] then
        return soundCache[soundName]
    end
    
    local template = soundsFolder:FindFirstChild(soundName)
    if not template then
        warn("サウンドが見つかりません: " .. soundName)
        return nil
    end
    
    local sound = template:Clone()
    sound.Parent = SoundService
    soundCache[soundName] = sound
    
    return sound
end

-- BGMを再生
local function playBGM(bgmName, fadeInTime)
    -- 現在のBGMを停止
    if currentBGM then
        if fadeInTime then
            currentBGM:FadeOut(fadeInTime)
            task.wait(fadeInTime)
        else
            currentBGM:Stop()
        end
    end
    
    -- 新しいBGMを再生
    local bgm = getSound(bgmName)
    if bgm then
        currentBGM = bgm
        if fadeInTime then
            bgm:FadeIn(fadeInTime)
        end
        bgm:Play()
    end
end

-- BGMを停止
local function stopBGM(fadeOutTime)
    if currentBGM then
        if fadeOutTime then
            currentBGM:FadeOut(fadeOutTime)
            task.wait(fadeOutTime)
        else
            currentBGM:Stop()
        end
        currentBGM = nil
    end
end

-- SFXを再生
local function playSFX(soundName, volume)
    local sfx = getSound(soundName)
    if sfx then
        if volume then
            sfx.Volume = volume
        end
        sfx:Play()
    end
end

-- グローバル関数として公開
_G.playBGM = playBGM
_G.stopBGM = stopBGM
_G.playSFX = playSFX

-- ロビーBGMを自動再生
playBGM("LobbyBGM", 2)

return "サウンドマネージャーを初期化しました"