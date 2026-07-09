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