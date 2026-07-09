local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kenscript 🍫 Mundo 3",
   LoadingTitle = "Cargando Mundo 3...",
   LoadingSubtitle = "by xxkenxr",
   ConfigurationSaving = { Enabled = false },
})

-- ==================== AUTO FARM, LIMPIAR OBSTÁCULOS Y GRABADOR DE RUTA ====================
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local autoFarming = false
local farmConnection = nil
local obstaclesCleaned = false

-- Waypoints / recorder
local waypoints = {}            -- array of Vector3
local recording = false
local recordConnection = nil
local recordInterval = 0.5      -- segundos
local recordMinDistance = 2     -- studs mínimo para añadir nuevo punto automáticamente

-- helper notify
local function notify(title, content, duration)
   if Rayfield and Rayfield.Notify then
      Rayfield:Notify({Title = title, Content = content, Duration = duration or 3})
   end
end

-- ==================== LIMPIEZA DE OBSTÁCULOS (MEJORADA) ====================
local function isObstacleName(s)
   if not s then return false end
   s = s:lower()
   return s:find("kill") or s:find("death") or s:find("spike") or s:find("lava") or s:find("obstacle") or s:find("trap")
end

local function toggleCleanObstacles(state)
   obstaclesCleaned = state
   if state then
      notify("Limpiar Obstáculos ON", "Eliminando obstáculos mortales...", 4)
      spawn(function()
         while obstaclesCleaned do
            for _, v in pairs(workspace:GetDescendants()) do
               if v:IsA("BasePart") then
                  local ok = pcall(function()
                     local name = v.Name or ""
                     local parentName = (v.Parent and v.Parent.Name) or ""
                     if isObstacleName(name) or isObstacleName(parentName) then
                        v.CanCollide = false
                        v.Transparency = math.max(0.6, v.Transparency or 0)
                     end
                  end)
                  -- ignorar fallos (part protegido por el servidor)
               end
            end
            wait(1)
         end
      end)
   else
      notify("Limpiar Obstáculos OFF", "Reactivado (no se restaura servidor-side)", 3)
   end
end

-- ==================== PATHFINDING Y SEGUIMIENTO DE RUTA ====================
local function getCharacter()
   local char = player and player.Character
   if char and char.Parent then return char end
   -- esperar character
   for i = 1, 50 do
      char = player and player.Character
      if char and char.Parent then return char end
      wait(0.1)
   end
   return nil
end

local function followPosition(targetPos, humanoid, hrp)
   if not humanoid or not hrp then return false end
   local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 45})
   path:Compute(hrp.Position, targetPos)
   if path.Status ~= Enum.PathStatus.Success then
      return false
   end
   local waypointsPath = path:GetWaypoints()
   for _, wp in ipairs(waypointsPath) do
      if wp.Action == Enum.PathWaypointAction.Jump then
         humanoid.Jump = true
      end
      humanoid:MoveTo(wp.Position)
      local ok = humanoid.MoveToFinished:Wait()
      if not ok then
         -- si no llega al waypoint, intenta pequeño teletransporte seguro (fallback)
         pcall(function()
            hrp.CFrame = CFrame.new(wp.Position + Vector3.new(0, 3, 0))
         end)
      end
      wait(0.05)
   end
   return true
end

local function followRoute(humanoid, hrp, points)
   for i, pos in ipairs(points) do
      local success = followPosition(pos, humanoid, hrp)
      if not success then
         -- fallback directo por Tween
         pcall(function()
            local dist = (hrp.Position - pos).Magnitude
            local t = math.clamp(dist / 10, 0.2, 5)
            local tweenInfo = TweenInfo.new(t, Enum.EasingStyle.Linear)
            TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))}):Play()
         end)
         wait(0.5)
      end
   end
end

-- ==================== AUTO FARM HANDLER ====================
local function startAutoFarm()
   local character = getCharacter()
   if not character then return end
   local humanoid = character:FindFirstChildOfClass("Humanoid")
   local hrp = character:FindFirstChild("HumanoidRootPart")
   if not humanoid or not hrp then return end

   farmConnection = RunService.Heartbeat:Connect(function(dt)
      if not autoFarming then return end
      if #waypoints > 0 then
         -- desconectar loop para reproducir la ruta de forma síncrona
         if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
         followRoute(humanoid, hrp, waypoints)
         -- reactivar si autoFarming sigue activo
         if autoFarming then startAutoFarm() end
         return
      else
         -- movimiento simple hacia adelante (fallback)
         local speed = 16
         pcall(function()
            hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * (speed * 0.016)
         end)
         if math.random(1, 12) == 1 then humanoid.Jump = true end
      end
   end)
end

local function stopAutoFarm()
   if farmConnection then
      farmConnection:Disconnect()
      farmConnection = nil
   end
end

local function toggleAutoFarm(state)
   autoFarming = state
   if state then
      notify("Auto Farm ON", "Recorriendo Mundo 3...", 4)
      startAutoFarm()
   else
      stopAutoFarm()
      notify("Auto Farm OFF", "Detenido", 3)
   end
end

-- ==================== GRABADOR DE RUTA ====================
local function addCurrentWaypoint()
   local char = getCharacter()
   if not char then return end
   local hrp = char:FindFirstChild("HumanoidRootPart")
   if not hrp then return end
   table.insert(waypoints, hrp.Position)
   notify("Waypoint añadido", "Total: "..tostring(#waypoints), 2)
end

local function clearWaypoints()
   waypoints = {}
   notify("Waypoints borrados", "", 2)
end

local function startRecording()
   if recording then return end
   recording = true
   notify("Grabación iniciada", "Movete por la ruta para grabarla", 3)
   local lastPos = nil
   recordConnection = spawn(function()
      while recording do
         local char = getCharacter()
         local hrp = char and char:FindFirstChild("HumanoidRootPart")
         if hrp then
            local pos = hrp.Position
            if not lastPos or (pos - lastPos).Magnitude >= recordMinDistance then
               table.insert(waypoints, pos)
               lastPos = pos
               notify("Waypoint añadido (auto)", "Total: "..tostring(#waypoints), 1.2)
            end
         end
         wait(recordInterval)
      end
   end)
end

local function stopRecording()
   if not recording then return end
   recording = false
   notify("Grabación parada", "Waypoints totales: "..tostring(#waypoints), 3)
   -- recordConnection es spawn, no hace falta disconnect pero lo dejamos nil
   recordConnection = nil
end

-- Atajos de teclado (R: add, P: play, C: clear)
local enableHotkeys = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   if not enableHotkeys then return end
   if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
   if input.KeyCode == Enum.KeyCode.R then
      addCurrentWaypoint()
   elseif input.KeyCode == Enum.KeyCode.P then
      local char = getCharacter()
      local humanoid = char and char:FindFirstChildOfClass("Humanoid")
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if humanoid and hrp and #waypoints > 0 then
         followRoute(humanoid, hrp, waypoints)
      else
         notify("No hay waypoints", "Presiona R o usa el toggle de grabación", 3)
      end
   elseif input.KeyCode == Enum.KeyCode.C then
      clearWaypoints()
   end
end)

-- ==================== MENÚ ====================
function loadMainMenu()
   local MainTab = Window:CreateTab("Mundo 3", 4483362458)

   MainTab:CreateToggle({
      Name = "Limpiar Obstáculos (Mortales)",
      CurrentValue = false,
      Callback = function(Value)
         toggleCleanObstacles(Value)
      end,
   })

   MainTab:CreateToggle({
      Name = "Auto Farm (Recorrido Mundo 3)",
      CurrentValue = false,
      Callback = function(Value)
         toggleAutoFarm(Value)
      end,
   })

   MainTab:CreateToggle({
      Name = "Recording Route (R = add, P = play, C = clear)",
      CurrentValue = false,
      Callback = function(Value)
         if Value then
            startRecording()
         else
            stopRecording()
         end
      end,
   })

   MainTab:CreateToggle({
      Name = "Enable Hotkeys (Ctrl+R/P/C)",
      CurrentValue = false,
      Callback = function(Value) enableHotkeys = Value; notify("Hotkeys "..(Value and "ON" or "OFF"), "", 2) end,
   })

   MainTab:CreateButton({
      Name = "Add Current Position (R)",
      Callback = function()
         addCurrentWaypoint()
      end
   })

   MainTab:CreateButton({
      Name = "Play Route (P)",
      Callback = function()
         local char = getCharacter()
         local humanoid = char and char:FindFirstChildOfClass("Humanoid")
         local hrp = char and char:FindFirstChild("HumanoidRootPart")
         if humanoid and hrp and #waypoints > 0 then
            followRoute(humanoid, hrp, waypoints)
         else
            notify("No hay waypoints", "Presiona R para añadir puntos o activa Recording", 3)
         end
      end
   })

   MainTab:CreateButton({
      Name = "Clear Waypoints (C)",
      Callback = function()
         clearWaypoints()
      end
   })

   MainTab:CreateParagraph({Title = "Instrucciones", Content = "Usa el toggle Recording para grabar la ruta automáticamente (cada 0.5s). O presiona R para añadir manualmente. Presiona Play para reproducir la ruta."})
end

-- Auto-open the menu so no key is required
pcall(function()
   loadMainMenu()
end)

print("🔓 Script Mundo 3 cargado - Menú disponible")