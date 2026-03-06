-- マブル操作制御スクリプト
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local hrp = nil
local humanoid = nil

local function resolveCharacterParts(targetCharacter)
    local activeCharacter = targetCharacter or character
    if not activeCharacter then
        return nil, nil
    end

    local rootPart = activeCharacter:FindFirstChild("HumanoidRootPart")
    local activeHumanoid = activeCharacter:FindFirstChildOfClass("Humanoid")
    return rootPart, activeHumanoid
end

-- キャラクターが完全にロードされるまで待機
task.wait(0.5)

-- レース状態の追跡
local isRacing = false

-- レース開始イベントを監視
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local updateRaceUIEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateRaceUI")

updateRaceUIEvent.OnClientEvent:Connect(function(data)
    -- カウントダウン0またはrace_startedで操作を有効化
    if (data.type == "countdown" and data.value == 0) or data.type == "race_started" then
        hrp, humanoid = resolveCharacterParts(character)
        if not isRacing then
            isRacing = true
            print("[MarbleControl] レース開始！操作を有効にします")
            
            -- 位置とHP確認用ログ
            if hrp then
                print("[MarbleControl] マーブル位置: " .. tostring(hrp.Position))
                print("[MarbleControl] マーブルアンカー状態: " .. tostring(hrp.Anchored))
                print("[MarbleControl] マーブルサイズ: " .. tostring(hrp.Size))
                print("[MarbleControl] マーブル透過度: " .. tostring(hrp.Transparency))
                -- キャラクター構成の詳細ログ
                if character then
                    local childNames = {}
                    for _, c in ipairs(character:GetChildren()) do
                        table.insert(childNames, c.Name)
                    end
                    print("[MarbleControl] character children: " .. table.concat(childNames, ", "))
                    local marbleModel = character:FindFirstChild("MarbleModel")
                    if marbleModel then
                        print("[MarbleControl] MarbleModel found. Parts:")
                        for _, d in ipairs(marbleModel:GetDescendants()) do
                            if d:IsA("BasePart") then
                                print("  - " .. d:GetFullName() .. " (Transparency=" .. tostring(d.Transparency) .. ", Parent=" .. tostring(d.Parent) .. ")")
                            end
                        end
                    else
                        print("[MarbleControl] MarbleModel not found under character yet")
                    end
                end
            end
            if humanoid then
                print("[MarbleControl] マーブルHP: " .. tostring(humanoid.Health))
            end
                -- ローカル表示の確保: サーバ側で透明になっている場合、クライアント側で一時的に表示する
                if hrp then
                    -- 強制的に表示（クライアント側で即時復元）
                    if hrp.Transparency >= 1 then
                        hrp.LocalTransparencyModifier = 0
                        hrp.Transparency = 0
                        print("[MarbleControl] HRP が透明だったため、LocalTransparencyModifier と Transparency をリセットしました")
                    else
                        hrp.LocalTransparencyModifier = 0
                    end
                    -- 既存の子パーツもローカルで強制表示（クライアント側で強制的に0にする）
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 0
                            if part.Transparency >= 1 then
                                part.Transparency = 0
                            end
                        end
                    end
                    -- MarbleModel が後から追加された場合に備えて監視を行う
                    character.ChildAdded:Connect(function(child)
                        if child and child.Name == "MarbleModel" then
                            print("[MarbleControl] MarbleModel が追加されました: " .. tostring(child))
                            for _, d in ipairs(child:GetDescendants()) do
                                if d:IsA("BasePart") then
                                    d.LocalTransparencyModifier = 0
                                    if d.Transparency >= 1 then
                                        d.Transparency = 0
                                    end
                                end
                            end
                        end
                    end)
                end
        end
    end
end)

-- レース終了イベントを監視
local raceEndEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RaceEnd")
raceEndEvent.OnClientEvent:Connect(function(data)
    isRacing = false
    print("[MarbleControl] レース終了！操作を無効にします")
end)

-- キャラクター初期化の待機（複数回試行）
local initAttempts = 0
local maxInitAttempts = 30

while (not hrp or not humanoid) and initAttempts < maxInitAttempts do
    initAttempts = initAttempts + 1
    hrp, humanoid = resolveCharacterParts(character)
    if not hrp then
        hrp = character:WaitForChild("HumanoidRootPart", 2)
    end
    if not humanoid then
        humanoid = character:WaitForChildOfClass("Humanoid", 2)
    end
    
    -- まだ初期化されていない場合は待機
    if not hrp or not humanoid then
        task.wait(0.5)
    end
end

if not hrp or not humanoid then
    warn("[MarbleControl] キャラクターの初期化に失敗しました（試行: " .. initAttempts .. "回）")
    print("[MarbleControl] hrp:", hrp, "humanoid:", humanoid)
    print("[MarbleControl] character:", character)
    if character then
        local childNames = {}
        for _, child in character:GetChildren() do
            table.insert(childNames, child.Name)
        end
        print("[MarbleControl] character children:", table.concat(childNames, ", "))
    end
    return
end

print("[MarbleControl] キャラクターの初期化に成功しました（試行: " .. initAttempts .. "回）")
if hrp then
    print("[MarbleControl] HumanoidRootPart size:", hrp.Size)
end
if humanoid then
    print("[MarbleControl] Humanoid health:", humanoid.Health)
end

-- マブルの設定（調整済み）
local MARBLE_SPEED = 100
local JUMP_POWER = 80
local MAX_SPEED = 120
local FRICTION = 0.98
local GRAVITY = Vector3.new(0, -150, 0)
local ACCELERATION = 250
local GAMEPAD_DEADZONE = 0.15

-- 入力状態
local moveInput = Vector3.new(0, 0, 0)
local isJumping = false
local lastMoveInputDebugTime = 0

-- キー状態トラッキング（InputBegan/InputEndedで確実に検知する）
local keyState = {}
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        keyState[input.KeyCode] = true
        -- デバッグ出力
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
            print("[MarbleControl] KeyDown: " .. tostring(input.KeyCode))
        end
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        keyState[input.KeyCode] = nil
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
            print("[MarbleControl] KeyUp: " .. tostring(input.KeyCode))
        end
    end
end)

-- カメラ追従設定（マブルサイズに合わせて調整）
local cameraOffset = Vector3.new(0, 20, 25)
local cameraSmoothness = 0.08

-- 入力の取得
local function getMoveInput()
    local inputVector = Vector3.new(0, 0, 0)
    -- まず InputBegan/InputEnded で記録した keyState を優先して使う
    if keyState[Enum.KeyCode.W] then
        inputVector = inputVector + Vector3.new(0, 0, -1)
    end
    if keyState[Enum.KeyCode.S] then
        inputVector = inputVector + Vector3.new(0, 0, 1)
    end
    if keyState[Enum.KeyCode.A] then
        inputVector = inputVector + Vector3.new(-1, 0, 0)
    end
    if keyState[Enum.KeyCode.D] then
        inputVector = inputVector + Vector3.new(1, 0, 0)
    end

    -- フォールバック: keyState が空の場合は IsKeyDown を参照
    if inputVector.Magnitude == 0 then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            inputVector = inputVector + Vector3.new(0, 0, -1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            inputVector = inputVector + Vector3.new(0, 0, 1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            inputVector = inputVector + Vector3.new(-1, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            inputVector = inputVector + Vector3.new(1, 0, 0)
        end
    end

    -- デバッグ: keyState と IsKeyDown の差分を出す（問題切り分け用）
    local ks = tostring(keyState[Enum.KeyCode.W]) .. "," .. tostring(keyState[Enum.KeyCode.A]) .. "," .. tostring(keyState[Enum.KeyCode.S]) .. "," .. tostring(keyState[Enum.KeyCode.D])
    local iskd = tostring(UserInputService:IsKeyDown(Enum.KeyCode.W)) .. "," .. tostring(UserInputService:IsKeyDown(Enum.KeyCode.A)) .. "," .. tostring(UserInputService:IsKeyDown(Enum.KeyCode.S)) .. "," .. tostring(UserInputService:IsKeyDown(Enum.KeyCode.D))
    if tick() - lastMoveInputDebugTime > 0.5 then
        print("[MarbleControl] getMoveInput debug: keyState=" .. ks .. " IsKeyDown=" .. iskd .. " vectorBeforeNorm=" .. tostring(inputVector))
        lastMoveInputDebugTime = tick()
    end
    
    -- ゲームパッド入力は有効なスティック操作がある時だけ使う
    local gamepad = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    if #gamepad > 0 then
        for _, button in gamepad do
            if button.KeyCode == Enum.KeyCode.Thumbstick1 then
                local thumbstickVector = Vector3.new(button.Position.X, 0, -button.Position.Y)
                if thumbstickVector.Magnitude > GAMEPAD_DEADZONE then
                    inputVector = thumbstickVector
                    if tick() - lastMoveInputDebugTime > 0.5 then
                        print("[MarbleControl] gamepad input detected: " .. tostring(thumbstickVector))
                    end
                end
            end
        end
    end
    
    -- 入力を正規化
    if inputVector.Magnitude > 0 then
        inputVector = inputVector.Unit
    end
    
    return inputVector
end

-- ジャンプ入力の処理
UserInputService.JumpRequest:Connect(function()
    if not isJumping then
        isJumping = true
    end
end)

-- メイン更新ループ
RunService.Heartbeat:Connect(function(deltaTime)
    if not character or character.Parent == nil then
        character = player.Character
    end

    if not hrp or not hrp.Parent then
        hrp, humanoid = resolveCharacterParts(character)
    end

    if not hrp then return end
    
    -- レース中のみ操作を有効にする
    if not isRacing then
        -- レース中でない場合は速度をゼロにする
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        return
    end
    
    -- 入力の取得
    moveInput = getMoveInput()

    -- デバッグ: キー状態と入力ベクトルをログ（早めに実行して、moveInput==0でもキー押下の矛盾を検出）
    if moveInput.Magnitude > 0 then
        print("[MarbleControl] moveInput magnitude: " .. tostring(moveInput.Magnitude) .. " moveInput: " .. tostring(moveInput))
    else
        -- キーが押されているが moveInput が0になっているケースの検出
        local anyKey = keyState[Enum.KeyCode.W] or keyState[Enum.KeyCode.A] or keyState[Enum.KeyCode.S] or keyState[Enum.KeyCode.D]
        if anyKey then
            print("[MarbleControl] キーは押されていますが moveInput がゼロです（カメラ参照の問題かもしれません）")
        end
    end

    if moveInput.Magnitude == 0 and not isJumping then
        local currentVelocity = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(
            currentVelocity.X * FRICTION,
            currentVelocity.Y,
            currentVelocity.Z * FRICTION
        )
        return
    end
    
    -- カメラの向きを考慮した移動方向
    local camera = workspace.CurrentCamera
    local cameraCF = camera.CFrame
    local forward = Vector3.new(
        cameraCF.LookVector.X,
        0,
        cameraCF.LookVector.Z
    )
    local right = Vector3.new(
        cameraCF.RightVector.X,
        0,
        cameraCF.RightVector.Z
    )

    local moveDirection = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
    
    local rightDirection = right.Magnitude > 0 and right.Unit or Vector3.new(1, 0, 0)
    
    -- 入力ベクトルをカメラ基準に変換
    local worldMoveInput = (rightDirection * moveInput.X - moveDirection * moveInput.Z)
    if worldMoveInput.Magnitude > 0 then
        worldMoveInput = worldMoveInput.Unit
    end
    
    -- 現在の速度を取得
    local currentVelocity = hrp.AssemblyLinearVelocity
    
    -- 移動力の適用
    local moveForce = worldMoveInput * ACCELERATION
    
    -- ジャンプ処理
    if isJumping then
        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -1, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        -- マブルの半径を考慮してレイキャストの距離を調整
        local marbleRadius = hrp.Size.Y / 2
        local rayResult = workspace:Raycast(rayOrigin, rayDirection * (marbleRadius + 0.5), raycastParams)
        
        if rayResult then
            currentVelocity = Vector3.new(
                currentVelocity.X,
                JUMP_POWER,
                currentVelocity.Z
            )
            -- ジャンプ音を再生
            if _G.playSFX then
                _G.playSFX("JumpSound")
            end
            -- ジャンプエフェクトを再生
            if _G.attachEffectToMarble then
                _G.attachEffectToMarble("JumpEffect", 0.5)
            end
        end
        isJumping = false
    end
    
    -- 重力の適用
    currentVelocity = currentVelocity + GRAVITY * deltaTime
    
    -- 移動力の適用（水平方向のみ）
    currentVelocity = Vector3.new(
        currentVelocity.X + moveForce.X * deltaTime,
        currentVelocity.Y,
        currentVelocity.Z + moveForce.Z * deltaTime
    )
    
    -- 摩擦の適用
    currentVelocity = Vector3.new(
        currentVelocity.X * FRICTION,
        currentVelocity.Y,
        currentVelocity.Z * FRICTION
    )
    
    -- 最大速度制限
    local horizontalSpeed = Vector3.new(currentVelocity.X, 0, currentVelocity.Z).Magnitude
    if horizontalSpeed > MAX_SPEED then
        local horizontalDirection = Vector3.new(currentVelocity.X, 0, currentVelocity.Z).Unit
        currentVelocity = Vector3.new(
            horizontalDirection.X * MAX_SPEED,
            currentVelocity.Y,
            horizontalDirection.Z * MAX_SPEED
        )
    end
    
    -- 速度を適用
    hrp.AssemblyLinearVelocity = currentVelocity
    -- 適用後の速度をログ（デバッグ）
    task.spawn(function()
        task.wait(0.03)
        if hrp and hrp.Parent then
            print("[MarbleControl] Applied velocity: " .. tostring(hrp.AssemblyLinearVelocity))
        end
    end)
end)

-- キャラクターがリスポーンしたときの処理
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    isRacing = false
    
    -- HumanoidRootPartをマブルとして使用（タイムアウト付き）
    hrp, humanoid = resolveCharacterParts(character)
    if not hrp then
        hrp = character:WaitForChild("HumanoidRootPart", 10)
    end
    if not humanoid then
        humanoid = character:WaitForChildOfClass("Humanoid", 10)
    end
    
    if not hrp or not humanoid then
        warn("[MarbleControl] キャラクターのリスポーンに失敗しました")
        return
    end
    
    print("[MarbleControl] キャラクターをリスポーンしました")
end)