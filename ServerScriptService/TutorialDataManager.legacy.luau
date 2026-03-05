-- チュートリアルデータ管理スクリプト
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tutorialDataStore = DataStoreService:GetDataStore("MarbleRaceTutorialData")

-- チュートリアル完了状態のキャッシュ
local tutorialCache = {}

-- プレイヤーのチュートリアル完了状態をロード
local function loadTutorialData(player)
    local success, completed = pcall(function()
        return tutorialDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    if success then
        tutorialCache[player.UserId] = completed or false
    else
        tutorialCache[player.UserId] = false
    end
    
    return tutorialCache[player.UserId]
end

-- プレイヤーのチュートリアル完了状態を保存
local function saveTutorialData(player, completed)
    local success, err = pcall(function()
        tutorialDataStore:SetAsync("Player_" .. player.UserId, completed)
    end)
    
    if success then
        tutorialCache[player.UserId] = completed
        return true
    else
        warn("チュートリアルデータ保存失敗: " .. tostring(err))
        return false
    end
end

-- RemoteEventsの設定
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- TutorialCompleted RemoteEventの作成
local tutorialCompletedEvent = remoteEvents:FindFirstChild("TutorialCompleted")
if not tutorialCompletedEvent then
    tutorialCompletedEvent = Instance.new("RemoteEvent")
    tutorialCompletedEvent.Name = "TutorialCompleted"
    tutorialCompletedEvent.Parent = remoteEvents
end

-- GetTutorialCompleted RemoteFunctionの作成
local getTutorialCompleted = remoteEvents:FindFirstChild("GetTutorialCompleted")
if not getTutorialCompleted then
    getTutorialCompleted = Instance.new("RemoteFunction")
    getTutorialCompleted.Name = "GetTutorialCompleted"
    getTutorialCompleted.Parent = remoteEvents
end

-- TutorialCompletedイベントの処理
tutorialCompletedEvent.OnServerEvent:Connect(function(player)
    saveTutorialData(player, true)
end)

-- GetTutorialCompleted RemoteFunctionの処理
getTutorialCompleted.OnServerInvoke = function(player)
    return tutorialCache[player.UserId] or false
end

-- プレイヤー参加時にデータをロード
Players.PlayerAdded:Connect(function(player)
    loadTutorialData(player)
end)

-- 既存のプレイヤーに対してもデータをロード
for _, player in Players:GetPlayers() do
    loadTutorialData(player)
end

return "チュートリアルデータマネージャーを初期化しました"