-- ゲーム管理ツールスクリプト
-- テストとデバッグ用のコマンドを提供

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 管理者コマンド
local AdminCommands = {}

-- コマンドマッピング（コマンド名 → 関数名）
local CommandMapping = {
    ["/forcerace"] = "ForceStartRace",
    ["/endrace"] = "ForceEndRace",
    ["/addcoins"] = "AddCoins",
    ["/resetdata"] = "ResetPlayerData",
    ["/gameinfo"] = "ShowGameInfo"
}

-- レースを強制開始
function AdminCommands.ForceStartRace(player)
    if _G.startRace then
        local success, message = _G.startRace(true) -- 強制開始フラグをtrueに設定
        if success then
            return "✅ レースを開始しました: " .. message
        else
            return "❌ レース開始失敗: " .. message
        end
    else
        return "❌ レースマネージャーが見つかりません"
    end
end

-- レースを強制終了
function AdminCommands.ForceEndRace(player)
    if _G.endRace then
        _G.endRace()
        return "✅ レースを終了しました"
    else
        return "❌ レースマネージャーが見つかりません"
    end
end

-- 全プレイヤーにコインを追加
function AdminCommands.AddCoins(player, amount)
    amount = tonumber(amount) or 100
    
    for _, targetPlayer in Players:GetPlayers() do
        if _G.updatePlayerData then
            local data = _G.getPlayerData(targetPlayer)
            if data then
                _G.updatePlayerData(targetPlayer, {
                    coins = (data.coins or 0) + amount
                })
            end
        end
    end
    
    return "✅ 全プレイヤーに " .. amount .. " コインを追加しました"
end

-- プレイヤーデータをリセット
function AdminCommands.ResetPlayerData(player, targetPlayerName)
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then
        return "❌ プレイヤーが見つかりません: " .. targetPlayerName
    end
    
    if _G.updatePlayerData then
        _G.updatePlayerData(targetPlayer, {
            coins = 0,
            level = 1,
            xp = 0,
            ownedSkins = {"RedMarble"},
            equippedSkin = "RedMarble",
            totalWins = 0,
            totalRaces = 0
        })
        return "✅ " .. targetPlayerName .. " のデータをリセットしました"
    else
        return "❌ データマネージャーが見つかりません"
    end
end

-- ゲーム情報を表示
function AdminCommands.ShowGameInfo(player)
    local info = "📊 ゲーム情報:\n"
    info = info .. "プレイヤー数: " .. #Players:GetPlayers() .. "\n"
    
    if _G.raceState then
        info = info .. "レース中: " .. tostring(_G.raceState.isRacing) .. "\n"
        if _G.raceState.currentMap then
            info = info .. "現在のマップ: " .. (_G.raceState.currentMap:GetAttribute("CourseName") or "Unknown") .. "\n"
        end
    end
    
    return info
end

-- RemoteEventの取得
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local adminNotificationEvent = remoteEvents:WaitForChild("AdminNotification")

-- プレイヤーに通知を送信
local function notifyPlayer(player, message, color)
    color = color or Color3.fromRGB(100, 255, 100)
    
    local success, err = pcall(function()
        adminNotificationEvent:FireClient(player, {
            text = message,
            color = color
        })
    end)
    
    if not success then
        warn("通知送信失敗: " .. tostring(err))
    end
end

-- チャットコマンドの処理
local function setupPlayerCommands(player)
    print("[GameAdmin] プレイヤー " .. player.Name .. " にコマンドを設定しました")
    
    player.Chatted:Connect(function(message)
        print("[GameAdmin] メッセージ受信: " .. message)
        
        -- コマンドかどうかをチェック
        if string.sub(message, 1, 1) ~= "/" then
            return
        end
        
        print("[GameAdmin] コマンド検出: " .. message)
        
        -- コマンドをパース
        local commandParts = string.split(message, " ")
        local command = commandParts[1]
        local args = {}
        for i = 2, #commandParts do
            table.insert(args, commandParts[i])
        end
        
        print("[GameAdmin] コマンド: " .. tostring(command) .. ", 引数: " .. table.concat(args, ", "))
        
        -- コマンドの実行
        local commandName = CommandMapping[command]
        print("[GameAdmin] マッピングされた関数名: " .. tostring(commandName))
        
        if commandName then
            local commandFunc = AdminCommands[commandName]
            if commandFunc then
                print("[GameAdmin] コマンド実行開始: " .. commandName)
                local success, result = pcall(function()
                    return commandFunc(player, unpack(args))
                end)
                
                print("[GameAdmin] 実行結果: " .. tostring(success) .. ", " .. tostring(result))
                
                if success then
                    notifyPlayer(player, result, Color3.fromRGB(100, 255, 100))
                else
                    notifyPlayer(player, "❌ コマンド実行エラー: " .. tostring(result), Color3.fromRGB(255, 100, 100))
                end
            else
                print("[GameAdmin] エラー: コマンド関数が見つかりません: " .. commandName)
                notifyPlayer(player, "❌ コマンド関数が見つかりません: " .. commandName, Color3.fromRGB(255, 100, 100))
            end
        else
            print("[GameAdmin] エラー: 不明なコマンド: " .. command)
            notifyPlayer(player, "❌ 不明なコマンド: " .. command .. "\n使用可能なコマンド: /forcerace, /endrace, /addcoins, /resetdata, /gameinfo", Color3.fromRGB(255, 150, 50))
        end
    end)
end

-- 既存のプレイヤーにコマンドを設定
for _, player in Players:GetPlayers() do
    setupPlayerCommands(player)
end

-- 新しいプレイヤーにコマンドを設定
Players.PlayerAdded:Connect(setupPlayerCommands)

-- グローバル関数として公開
_G.AdminCommands = AdminCommands

return "ゲーム管理ツールを初期化しました\n使用可能なコマンド:\n/forcerace - レース強制開始\n/endrace - レース強制終了\n/addcoins [金額] - 全プレイヤーにコイン追加\n/resetdata [プレイヤー名] - プレイヤーデータリセット\n/gameinfo - ゲーム情報表示"