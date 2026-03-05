-- マブル操作制御スクリプト
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- HumanoidRootPartをマブルとして使用（タイムアウト付き）
local marble = character:FindFirstChild("HumanoidRootPart")
if not marble then
    marble = character:WaitForChild("HumanoidRootPart", 10)
end

local hrp = marble
local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then
    humanoid = character:WaitForChildOfClass("Humanoid", 10)
end

if not marble or not humanoid then
    warn("[MarbleControl] キャラクターの初期化に失敗しました")
    return
end

-- マブルの設定（調整済み）
local MARBLE_SPEED = 100
local JUMP_POWER = 80
local MAX_SPEED = 120
local FRICTION = 0.98
local GRAVITY = Vector3.new(0, -150, 0)
local ACCELERATION = 250

-- 入力状態
local moveInput = Vector3.new(0, 0, 0)
local isJumping = false

-- カメラ追従設定（マブルサイズに合わせて調整）
local cameraOffset = Vector3.new(0, 20, 25)
local cameraSmoothness = 0.08

-- 入力の取得
local function getMoveInput()
    local inputVector = Vector3.new(0, 0, 0)
    
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
    
    -- モバイル用の仮想スティック入力
    local gamepad = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    if #gamepad > 0 then
        for _, button in gamepad do
            if button.KeyCode == Enum.KeyCode.Thumbstick1 then
                inputVector = Vector3.new(button.Position.X, 0, -button.Position.Y)
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
    if not marble or not hrp then return end
    
    -- 入力の取得
    moveInput = getMoveInput()
    
    -- カメラの向きを考慮した移動方向
    local camera = workspace.CurrentCamera
    local cameraCF = camera.CFrame
    local moveDirection = Vector3.new(
        cameraCF.LookVector.X,
        0,
        cameraCF.LookVector.Z
    ).Unit
    
    local rightDirection = Vector3.new(
        cameraCF.RightVector.X,
        0,
        cameraCF.RightVector.Z
    ).Unit
    
    -- 入力ベクトルをカメラ基準に変換
    local worldMoveInput = (rightDirection * moveInput.X + moveDirection * moveInput.Z)
    
    -- 現在の速度を取得
    local currentVelocity = hrp.AssemblyLinearVelocity
    
    -- 移動力の適用
    local moveForce = worldMoveInput * ACCELERATION
    
    -- ジャンプ処理
    if isJumping then
        local rayOrigin = marble.Position
        local rayDirection = Vector3.new(0, -1, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        -- マブルの半径を考慮してレイキャストの距離を調整
        local marbleRadius = marble.Size.Y / 2
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
    
    -- カメラの追従
    local targetCFrame = CFrame.new(hrp.Position + cameraOffset, hrp.Position)
    camera.CFrame = camera.CFrame:Lerp(targetCFrame, cameraSmoothness)
end)

-- キャラクターがリスポーンしたときの処理
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    
    -- HumanoidRootPartをマブルとして使用（タイムアウト付き）
    marble = character:FindFirstChild("HumanoidRootPart")
    if not marble then
        marble = character:WaitForChild("HumanoidRootPart", 10)
    end
    
    hrp = marble
    
    humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChildOfClass("Humanoid", 10)
    end
    
    if not marble or not humanoid then
        warn("[MarbleControl] キャラクターのリスポーンに失敗しました")
        return
    end
    
    print("[MarbleControl] キャラクターをリスポーンしました")
end)