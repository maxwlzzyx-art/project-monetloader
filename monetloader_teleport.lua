--[[
     _              _
    / \   __  _____| |
   / _ \  \ \/ / _ \ |
  / ___ \  >  <  __/ |
 /_/   \_\/_/\_\___|_|

       AXEL SECURITY - MONETLOADER
       TELEPORT INTERIOR SYSTEM
]]

local imgui = require("mimgui")
local ffi = require("ffi")
local sampEvents = require("lib.samp.events")

local interiorConfig = require("interior_config")
local interiorUtils = require("interior_utils")

local state = {
    visible = imgui.new.bool(false),
    selectedInterior = 1,
    searchText = imgui.new.char[128](),
    favorites = {},
    history = {},
    currentTab = 1, -- 1: All, 2: Favorites, 3: History
}

local filteredInteriors = {}

-- Load favorites & history dari memory
local function loadUserData()
    if fileExists("monetloader_favorites.lua") then
        local data = loadstring(readFile("monetloader_favorites.lua"))()
        if data then
            state.favorites = data.favorites or {}
            state.history = data.history or {}
        end
    end
end

-- Save favorites & history
local function saveUserData()
    local data = {
        favorites = state.favorites,
        history = state.history
    }
    local content = "return " .. serpent.serialize(data)
    saveFile("monetloader_favorites.lua", content)
end

-- Update filtered interiors berdasarkan search
local function updateFilteredInteriors()
    local searchQuery = ffi.string(state.searchText):lower()
    filteredInteriors = {}
    
    local sourceList = interiorConfig.interiors
    
    if state.currentTab == 2 then
        sourceList = state.favorites
    elseif state.currentTab == 3 then
        sourceList = state.history
    end
    
    for _, interior in ipairs(sourceList) do
        if searchQuery == "" or interior.name:lower():find(searchQuery, 1, true) then
            table.insert(filteredInteriors, interior)
        end
    end
end

-- Tambah ke favorites
local function addFavorite(interior)
    for _, fav in ipairs(state.favorites) do
        if fav.id == interior.id then
            return -- Sudah ada di favorites
        end
    end
    table.insert(state.favorites, interior)
    saveUserData()
end

-- Hapus dari favorites
local function removeFavorite(interiorId)
    for i, fav in ipairs(state.favorites) do
        if fav.id == interiorId then
            table.remove(state.favorites, i)
            break
        end
    end
    saveUserData()
end

-- Cek apakah interior ada di favorites
local function isFavorite(interiorId)
    for _, fav in ipairs(state.favorites) do
        if fav.id == interiorId then
            return true
        end
    end
    return false
end

-- Tambah ke history
local function addToHistory(interior)
    -- Hapus jika sudah ada (untuk update posisi)
    for i, hist in ipairs(state.history) do
        if hist.id == interior.id then
            table.remove(state.history, i)
            break
        end
    end
    
    table.insert(state.history, 1, interior)
    
    -- Limit history ke 20 item
    if #state.history > 20 then
        table.remove(state.history)
    end
    
    saveUserData()
end

-- Teleport ke interior
local function teleportToInterior(interior)
    local x, y, z = interior.x, interior.y, interior.z
    local interiorId = interior.interior_id or 0
    
    -- Gunakan SAMP API untuk teleport
    sampAddChatMessage(string.format(
        "{00FF40}[MONETLOADER]{FFFFFF} Teleporting to %s...",
        interior.name
    ), -1)
    
    -- Set interior
    setCharInterior(playerPed, interiorId)
    
    -- Teleport
    setCharCoordinates(playerPed, x, y, z)
    
    addToHistory(interior)
end

-- Command handler
sampRegisterChatCommand("tpx", function()
    state.visible[0] = not state.visible[0]
    updateFilteredInteriors()
end)

loadUserData()
updateFilteredInteriors()

-- ImGui Frame
imgui.OnFrame(
    function()
        return state.visible[0]
    end,
    function()
        local io = imgui.GetIO()
        
        imgui.SetNextWindowPos(
            imgui.ImVec2(io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5),
            imgui.Cond.FirstUseEver,
            imgui.ImVec2(0.5, 0.5)
        )
        
        imgui.SetNextWindowSize(
            imgui.ImVec2(700, 550),
            imgui.Cond.FirstUseEver
        )
        
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 10)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
        imgui.PushStyleVarFloat(imgui.StyleVar.ItemSpacing.x, 8)
        imgui.PushStyleVarFloat(imgui.StyleVar.ItemSpacing.y, 6)
        
        -- Theme (Green Neon)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.10, 0.98))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.00, 0.85, 0.35, 1.00))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.85, 1.00, 0.85, 1.00))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.12, 0.12, 0.14, 1.00))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.00, 0.55, 0.25, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.00, 0.70, 0.30, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.00, 0.85, 0.40, 1.00))
        imgui.PushStyleColor(imgui.Col.Header, imgui.ImVec4(0.00, 0.55, 0.25, 1.00))
        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(0.00, 0.70, 0.30, 1.00))
        
        local pulse = (math.sin(os.clock() * 2.5) + 1) / 2
        local dots = string.rep(".", math.floor(os.clock() % 4))
        
        imgui.Begin(
            "MONETLOADER - TELEPORT INTERIOR",
            state.visible,
            imgui.WindowFlags.NoSavedSettings
        )
        
        -- Header
        imgui.TextColored(
            imgui.ImVec4(0.0, 0.75 + pulse * 0.25, 0.30 + pulse * 0.60, 1.0),
            ">> MONETLOADER TELEPORT SYSTEM <<"
        )
        imgui.TextDisabled("Interior Teleporter v1.0")
        imgui.Separator()
        
        -- Tabs
        if imgui.Button("All Interiors", imgui.ImVec2(120, 0)) then
            state.currentTab = 1
            updateFilteredInteriors()
        end
        imgui.SameLine()
        if imgui.Button("Favorites", imgui.ImVec2(120, 0)) then
            state.currentTab = 2
            updateFilteredInteriors()
        end
        imgui.SameLine()
        if imgui.Button("History", imgui.ImVec2(120, 0)) then
            state.currentTab = 3
            updateFilteredInteriors()
        end
        
        imgui.Separator()
        
        -- Search
        imgui.PushItemWidth(-1)
        if imgui.InputTextWithHint(
            "##search",
            "Search interior...",
            state.searchText,
            ffi.sizeof(state.searchText)
        ) then
            updateFilteredInteriors()
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Interior List
        if imgui.BeginChild("##interior_list", imgui.ImVec2(0, 350), true) then
            for idx, interior in ipairs(filteredInteriors) do
                local isFav = isFavorite(interior.id)
                local favIcon = isFav and "★" or "☆"
                local buttonText = string.format(
                    "[%d] %s - X:%.1f Y:%.1f Z:%.1f %s",
                    interior.id, interior.name, interior.x, interior.y, interior.z, favIcon
                )
                
                if imgui.Button(buttonText, imgui.ImVec2(-1, 30)) then
                    teleportToInterior(interior)
                    state.visible[0] = false
                end
                
                -- Tooltip
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(
                        string.format("Interior: %d\nCoords: %.1f, %.1f, %.1f",
                            interior.interior_id or 0, interior.x, interior.y, interior.z)
                    )
                end
                
                -- Favorite button on same line
                imgui.SameLine()
                if imgui.SmallButton(favIcon .. "##" .. idx) then
                    if isFav then
                        removeFavorite(interior.id)
                    else
                        addFavorite(interior)
                    end
                    updateFilteredInteriors()
                end
            end
            imgui.EndChild()
        end
        
        imgui.Spacing()
        
        -- Statistics
        imgui.TextColored(
            imgui.ImVec4(0.0, 1.0, 0.4, 1.0),
            string.format("Total Interiors: %d | Favorites: %d | History: %d",
                #interiorConfig.interiors, #state.favorites, #state.history)
        )
        
        -- Footer
        if imgui.Button("Close", imgui.ImVec2(-1, 30)) then
            state.visible[0] = false
        end
        
        imgui.End()
        
        imgui.PopStyleColor(9)
        imgui.PopStyleVar(4)
    end
)

return true
