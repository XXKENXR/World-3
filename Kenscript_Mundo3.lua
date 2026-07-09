-- Kenscript_Mundo3.lua (mobile-friendly: botones, espera Character, play en spawn)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kenscript 🍫 Mundo 3",
   LoadingTitle = "Cargando Mundo 3...",
   LoadingSubtitle = "by xxkenxr",
   ConfigurationSaving = { Enabled = false },
})

-- Key System
local KeyTab = Window:CreateTab("Key System", 4483362458)

local function onKeyEntered(Value)
   if (Value or ""):upper() == "XKR" then
      Rayfield:Notify({Title = "✅ Key Correcta", Content = "Acceso concedido", Duration = 4})
      loadMainMenu()
   else
      Rayfield:Notify({Title = "❌ Key Incorrecta", Content = "Key Invalid", Duration = 3})
   end
end

KeyTab:CreateInput({
   Name = "Key",
   PlaceholderText = "Ingresa la clave...",
   Callback = onKeyEntered,
})

KeyTab:CreateParagraph({Title = "Nota", Content = "El mejor script"})

-- SERVICES
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- STATE
local autoFarming = false
local farmConnection = nil
local obstaclesCleaned = false

-- WAYPOINTS / RECORDER
local waypoints = {}
local recording = false
local recordThread = nil
local recordInterval = 0.5
local recordMinDistance = 2

-- HELPERS
local function notify(title, content, duration)
   if Rayfield and Rayfield.Notify then
      Rayfield:Notify({Title = title, Content = content, Duration = duration or 3})
   end
end

local function getCharacter(waitFor)
   local char = player and player.Character
   if char and char.Parent then return char end
   if not waitFor then return nil end
   for i = 1, 50 do
      char = player and player.Character
      if char and char.Parent then return char end
      wait(0.1)
   end
   return nil
end

-- OBSTACLE CLEANER (cliente; puede no afectar partes protegidas por servidor)
local function isObstacleName(s)
   if not s then return false end
   s = s:lower()
   return s:find("kill") or s:find("death") or s:find("spike") or s:find("lava") or s:find("obstacle") or s:find("trap")
end

local function toggleCleanObstacles(state)
   obstaclesCleaned = state
   if state then
      notify("Limpiar Obstáculos ON", "Intentando atenuar obstáculos...", 4)
      spawn(function()
         while obstaclesCleaned do
            for _, v in pairs(workspace:GetDescendants()) do
               if v:IsA("BasePart") then
                  pcall(function()
                     local name = v.Name or ""
                     local parentName = (v.Parent and v.Parent.Name) or ""
                     if isObstacleName(name) or isObstacleName(parentName) then
                        v.CanCollide = false
                        v.Transparency = math.max(0.7, v.Transparency or 0)
                     end
                  end)
               end
            end
            wait(1)
         end
      end)
   else
      notify("Limpiar Obstáculos OFF", "Desactivado (no restaura estado servidor-side)", 3)
   end
end

-- PATHFINDING / FOLLOW
local function followPosition(targetPos, humanoid, hrp)
   if not humanoid or not hrp then return false end
   local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 45})
   path:Compute(hrp.Position, targetPos)
   if path.Status ~= Enum.PathStatus.Success then
      return false
   end
   for _, wp in ipairs(path:GetWaypoints()) do
      if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
      humanoid:MoveTo(wp.Position)
      local ok = humanoid.MoveToFinished:Wait()
      if not ok then
         pcall(function() hrp.CFrame = CFrame.new(wp.Position + Vector3.new(0,3,0)) end)
      end
      wait(0.03)
   end
   return true
end

local function followRoute(humanoid, hrp, points)
   for _, pos in ipairs(points) do
      local ok = followPosition(pos, humanoid, hrp)
      if not ok then
         pcall(function()
            local dist = (hrp.Position - pos).Magnitude
            local t = math.clamp(dist / 10, 0.2, 5)
            local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0,3,0))})
            tw:Play(); tw.Completed:Wait()
         end)
         wait(0.2)
      end
   end
end

-- AUTO FARM
local function startAutoFarm()
   local char = getCharacter(true)
   if not char then notify("AutoFarm fallo", "No hay character cargado", 3); return end
   local humanoid = char:FindFirstChildOfClass("Humanoid")
   local hrp = char:FindFirstChild("HumanoidRootPart")
   if not humanoid or not hrp then notify("AutoFarm fallo", "Humanoid/HRP no encontrados", 3); return end

   farmConnection = RunService.Heartbeat:Connect(function(dt)
      if not autoFarming then return end
      if #waypoints > 0 then
         if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
         -- seguir ruta en spawn para no bloquear
         spawn(function()
            followRoute(humanoid, hrp, waypoints)
            -- una vez terminada, volver a iniciar loop si sigue activo
            if autoFarming then startAutoFarm() end
         end)
         return
      else
         pcall(function() hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * (16 * (dt or 0.016)) end)
         if math.random(1,12) == 1 then humanoid.Jump = true end
      end
   end)
end

local function stopAutoFarm()
   if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
end

local function toggleAutoFarm(state)
   autoFarming = state
   if state then notify("Auto Farm ON", "Recorriendo Mundo 3...", 4); startAutoFarm()
   else stopAutoFarm(); notify("Auto Farm OFF", "Detenido", 3) end
end

-- RECORDER
local function addCurrentWaypoint()
   local char = getCharacter(true)
   if not char then notify("No character", "Espera a que tu personaje cargue", 3); return end
   local hrp = char:FindFirstChild("HumanoidRootPart")
   if not hrp then notify("No HRP", "", 2); return end
   table.insert(waypoints, hrp.Position)
   notify("Waypoint añadido", "Total: "..tostring(#waypoints), 2)
end

local function clearWaypoints()
   waypoints = {}
   notify("Waypoints borrados", "", 2)
end

local function recorderLoop()
   local lastPos = nil
   while recording do
      local char = getCharacter(false)
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      if hrp then
         local pos = hrp.Position
         if (not lastPos) or (pos - lastPos).Magnitude >= recordMinDistance then
            table.insert(waypoints, pos)
            lastPos = pos
            notify("Waypoint auto añadido", "Total: "..tostring(#waypoints), 1.2)
         end
      end
      wait(recordInterval)
   end
end

local function startRecording()
   if recording then return end
   recording = true
   notify("Grabación iniciada", "Muevete para grabar la ruta (móvil)", 3)
   recordThread = spawn(recorderLoop)
end

local function stopRecording()
   if not recording then return end
   recording = false
   recordThread = nil
   notify("Grabación detenida", "Waypoints: "..tostring(#waypoints), 3)
end

-- MENÚ
function loadMainMenu()
   local MainTab = Window:CreateTab("Mundo 3", 4483362458)

   MainTab:CreateToggle({
      Name = "Limpiar Obstáculos (Mortales)",
      CurrentValue = false,
      Callback = function(Value) toggleCleanObstacles(Value) end,
   })

   MainTab:CreateToggle({
      Name = "Auto Farm (Recorrido Mundo 3)",
      CurrentValue = false,
      Callback = function(Value) toggleAutoFarm(Value) end,
   })

   MainTab:CreateToggle({
      Name = "Recording Route (auto)",
      CurrentValue = false,
      Callback = function(Value)
         if Value then startRecording() else stopRecording() end
      end,
   })

   MainTab:CreateButton({ Name = "Add Current Position", Callback = function() addCurrentWaypoint() end })
   MainTab:CreateButton({ Name = "Play Route", Callback = function()
      -- esperar character; ejecutar followRoute en spawn (móvil)
      spawn(function()
         local char = getCharacter(true)
         if not char then notify("Play fallo", "No se cargó tu personaje", 3); return end
         local humanoid = char:FindFirstChildOfClass("Humanoid")
         local hrp = char:FindFirstChild("HumanoidRootPart")
         if humanoid and hrp and #waypoints > 0 then
            followRoute(humanoid, hrp, waypoints)
         else
            notify("No hay waypoints", "Usa Add Current Position o Recording", 3)
         end
      end)
   end })
   MainTab:CreateButton({ Name = "Clear Waypoints", Callback = function() clearWaypoints() end })
   MainTab:CreateParagraph({Title = "Instrucciones (móvil)", Content = "Usa Recording para grabar automáticamente mientras caminas. Usa Add para puntos puntuales y Play para reproducir la ruta. Clear borra los puntos."})
end

print("🔒 Script Mundo 3 cargado - Usa la clave XKR")