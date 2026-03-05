-- Hazard Bridgeのハンマーを制御するスクリプト
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ハンマーの回転制御
local function rotateHammers()
    local raceMap = Workspace:FindFirstChild("RaceMap")
    if not raceMap or raceMap.Name ~= "HazardBridge" then
        return
    end
    
    -- 全てのハンマーを取得
    for _, part in raceMap:GetDescendants() do
        if part.Name:sub(1, 6) == "Hammer" and part:IsA("BasePart") then
            local motor = part:FindFirstChild("HammerMotor")
            if motor then
                local rotationSpeed = part:GetAttribute("RotationSpeed") or 2
                motor.C1 = motor.C1 * CFrame.Angles(0, 0, math.rad(rotationSpeed))
            end
        end
    end
end

-- 定期的にハンマーを回転
RunService.Heartbeat:Connect(function(deltaTime)
    if _G.raceState and _G.raceState.isRacing then
        rotateHammers()
    end
end)

return "Hazard Bridgeマネージャーを初期化しました"