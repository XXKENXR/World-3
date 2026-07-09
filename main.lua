local s = [[
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kenscript 🍫 Mundo 3",
   LoadingTitle = "Cargando Mundo 3...",
   LoadingSubtitle = "by xxkenxr",
   ConfigurationSaving = { Enabled = false },
})

-- Key System
local KeyTab = Window:CreateTab("Key System", 4483362458)

KeyTab:CreateInput({
   Name = "Key",
   PlaceholderText = "Ingresa la clave...",
   Callback = function(Value)
      if Value == "XKR" then
         Rayfield:Notify({Title = "✅ Key Correcta", Content = "Acceso concedido", Duration = 4})
         loadMainMenu()
      else
         Rayfield:Notify({Title = "❌ Key Incorrecta", Content = "Key Invalid", Duration = 3})
      end
   end,
})

KeyTab:CreateParagraph({Title = "Nota", Content = "El mejor script"})

-- ==================== AUTO FARM Y LIMPIAR OBSTÁCULOS ====================
local RunService = game:GetService("RunService")
local autoFarming = false
local farmConnection = nil
local obstaclesCleaned = false

local function toggleAutoFarm(state)
   autoFarming = state
   local character = game.Players.LocalPlayer.Character
   if not character then return end
   local humanoid = character:FindFirstChild("Humanoid")
   if not humanoid then return end

   if state then
      Rayfield:Notify({Title = "Auto Farm ON", Content = "Recorriendo Mundo 3...", Duration = 5})
      farmConnection = RunService.Heartbeat:Connect(function()
         if humanoid and autoFarming then
            humanoid:Move(Vector3.new(1, 0, 0), true)
            if math.random(1, 12) == 1 then
               humanoid.Jump = true
            end
         end
      end)
   else
      if farmConnection then farmConnection:Disconnect() end
      Rayfield:Notify({Title = "Auto Farm OFF", Content = "Detenido", Duration = 3})
   end
end

local function toggleCleanObstacles(state)
   obstaclesCleaned = state
   if state then
      Rayfield:Notify({Title = "Limpiar Obstáculos ON", Content = "Eliminando obstáculos mortales...", Duration = 4})
      spawn(function()
         while obstaclesCleaned do
            for _, v in pairs(workspace:GetDescendants()) do
               if v:IsA("BasePart") and v.CanCollide then
                  local name = v.Name:lower()
                  if name:find("kill") or name:find("death") or name:find("spike") or name:find("lava") or name:find("obstacle") then
                     v.CanCollide = false
                     v.Transparency = 0.8
                  end
               end
            end
            wait(1)
         end
      end)
   else
      Rayfield:Notify({Title = "Limpiar Obstáculos OFF", Content = "Reactivado", Duration = 3})
   end
end

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
end

print("🔒 Script Mundo 3 cargado - Usa la clave XKR")
]]

local ok, err = pcall(function()
    loadstring(s)()
end)
if not ok then
    warn("Error cargando el loadstring:", err)
end
