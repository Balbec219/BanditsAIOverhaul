----------------------------------------------------------------
-- BanditsAIOverhaul
-- BAO Debug UI
-- Version: 1.2
--
-- Client-side developer debug interface.
--
-- F10
--   ↓
-- BAO Debug UI
--   ↓
-- sendClientCommand
--   ↓
-- BAO Debug Server
----------------------------------------------------------------

if not BAO then
    BAO = {}
end

local DebugUI = {}

DebugUI.VERSION = "1.2"
DebugUI.MODULE = "BAO_Debug"

----------------------------------------------------------------
-- UI configuration
----------------------------------------------------------------

DebugUI.WIDTH = 480
DebugUI.HEIGHT = 420

DebugUI.visible = false
DebugUI.initialized = false

DebugUI.panel = nil
DebugUI.statusLabel = nil

----------------------------------------------------------------
-- PZ UI classes
----------------------------------------------------------------

---@type any
local ISPanelClass = nil

---@type any
local ISButtonClass = nil

---@type any
local ISLabelClass = nil

---@type any
local UIFontClass = nil

---@type any
local UIManagerObject = nil

---@type any
local getCoreFunction = nil

---@type any
local sendClientCommandFunction = nil

----------------------------------------------------------------
-- Load dependencies
----------------------------------------------------------------

local function LoadDependencies()

    pcall(
        require,
        "ISUI/ISPanel"
    )

    pcall(
        require,
        "ISUI/ISButton"
    )

    pcall(
        require,
        "ISUI/ISLabel"
    )

    ISPanelClass = _G["ISPanel"]
    ISButtonClass = _G["ISButton"]
    ISLabelClass = _G["ISLabel"]
    UIFontClass = _G["UIFont"]

    UIManagerObject = _G["UIManager"]

    getCoreFunction = _G["getCore"]

    sendClientCommandFunction =
        _G["sendClientCommand"]

    if not ISPanelClass then
        print(
            "[BAO][DebugUI] Missing ISPanel"
        )
    end

    if not ISButtonClass then
        print(
            "[BAO][DebugUI] Missing ISButton"
        )
    end

    if not ISLabelClass then
        print(
            "[BAO][DebugUI] Missing ISLabel"
        )
    end

    if not UIFontClass then
        print(
            "[BAO][DebugUI] Missing UIFont"
        )
    end

    if not UIManagerObject then
        print(
            "[BAO][DebugUI] Missing UIManager"
        )
    end

    if not getCoreFunction then
        print(
            "[BAO][DebugUI] Missing getCore"
        )
    end

    return
        ISPanelClass ~= nil and
        ISButtonClass ~= nil and
        ISLabelClass ~= nil and
        UIFontClass ~= nil and
        UIManagerObject ~= nil and
        getCoreFunction ~= nil
end

----------------------------------------------------------------
-- Send command to server
----------------------------------------------------------------

function DebugUI.SendCommand(
    command,
    args
)

    if not sendClientCommandFunction then

        sendClientCommandFunction =
            _G["sendClientCommand"]

    end

    if not sendClientCommandFunction then

        print(
            "[BAO][DebugUI] " ..
            "sendClientCommand unavailable"
        )

        return false
    end

    args = args or {}

    local success =
        pcall(
            sendClientCommandFunction,
            DebugUI.MODULE,
            command,
            args
        )

    if not success then

        print(
            "[BAO][DebugUI] " ..
            "Failed to send command: " ..
            tostring(command)
        )

        return false
    end

    return true
end

----------------------------------------------------------------
-- Update status text
----------------------------------------------------------------

function DebugUI.SetStatus(data)

    if not data then
        return
    end

    if not DebugUI.statusLabel then
        return
    end

    local text =
        "Status: " ..
        tostring(
            data.status or "UNKNOWN"
        )

    if data.result then

        text =
            text ..
            "\nResult: " ..
            tostring(data.result)

    end

    if data.detail then

        text =
            text ..
            "\nDetail: " ..
            tostring(data.detail)

    end

    if data.npcExists ~= nil then

        text =
            text ..
            "\nNPC: " ..
            tostring(data.npcExists)

    end

    if data.navigationState then

        text =
            text ..
            "\nNavigation: " ..
            tostring(data.navigationState)

    end

    if data.distance ~= nil then

        local distanceText =
            tostring(data.distance)

        if type(data.distance) == "number" then

            distanceText =
                string.format(
                    "%.2f",
                    data.distance
                )

        end

        text =
            text ..
            "\nDistance: " ..
            distanceText

    end

    if data.pathResult then

        text =
            text ..
            "\nPath: " ..
            tostring(data.pathResult)

    end

    ----------------------------------------------------------------
    -- Important:
    -- Do NOT call setName().
    -- setText() is sufficient for ISLabel.
    ----------------------------------------------------------------

    local success =
        pcall(
            function()

                DebugUI.statusLabel:setText(
                    text
                )

            end
        )

    if not success then

        print(
            "[BAO][DebugUI] " ..
            "Failed to update status label"
        )

    end
end

----------------------------------------------------------------
-- Server command
----------------------------------------------------------------

function DebugUI.OnServerCommand(
    module,
    command,
    args
)

    if module ~= DebugUI.MODULE then
        return
    end

    if command == "status" then

        DebugUI.SetStatus(
            args
        )

    end
end

----------------------------------------------------------------
-- Button helper
----------------------------------------------------------------

function DebugUI.AddButton(
    panel,
    x,
    y,
    width,
    height,
    text,
    callback
)

    if not ISButtonClass then
        return nil
    end

    local button

    local success =
        pcall(
            function()

                button =
                    ISButtonClass:new(
                        x,
                        y,
                        width,
                        height,
                        text,
                        nil,
                        callback
                    )

                button:initialise()
                button:instantiate()

                panel:addChild(
                    button
                )

            end
        )

    if not success then

        print(
            "[BAO][DebugUI] " ..
            "Failed to create button: " ..
            tostring(text)
        )

        return nil
    end

    return button
end

----------------------------------------------------------------
-- Label helper
----------------------------------------------------------------

function DebugUI.AddLabel(
    panel,
    x,
    y,
    width,
    height,
    text,
    font
)

    if not ISLabelClass then
        return nil
    end

    local label

    local success =
        pcall(
            function()

                label =
                    ISLabelClass:new(
                        x,
                        y,
                        height,
                        text,
                        1,
                        1,
                        1,
                        1,
                        font,
                        true
                    )

                panel:addChild(
                    label
                )

            end
        )

    if not success then

        print(
            "[BAO][DebugUI] " ..
            "Failed to create label: " ..
            tostring(text)
        )

        return nil
    end

    return label
end

----------------------------------------------------------------
-- Create panel
----------------------------------------------------------------

function DebugUI.CreatePanel()

    if DebugUI.panel then
        return DebugUI.panel
    end

    if not LoadDependencies() then

        print(
            "[BAO][DebugUI] " ..
            "UI dependencies unavailable"
        )

        return nil
    end

    local core =
        getCoreFunction()

    if not core then

        print(
            "[BAO][DebugUI] " ..
            "getCore() returned nil"
        )

        return nil
    end

    local screenWidth =
        core:getScreenWidth()

    local screenHeight =
        core:getScreenHeight()

    local x =
        math.floor(
            (screenWidth - DebugUI.WIDTH) / 2
        )

    local y =
        math.floor(
            (screenHeight - DebugUI.HEIGHT) / 2
        )

    local panel

    local success =
        pcall(
            function()

                panel =
                    ISPanelClass:new(
                        x,
                        y,
                        DebugUI.WIDTH,
                        DebugUI.HEIGHT
                    )

                panel:initialise()
                panel:instantiate()

                panel.backgroundColor.a =
                    0.90

                panel.borderColor.a =
                    1.0

                panel:setVisible(
                    false
                )

            end
        )

    if not success or not panel then

        print(
            "[BAO][DebugUI] " ..
            "Failed to create main panel"
        )

        return nil
    end

    ----------------------------------------------------------------
    -- Header
    ----------------------------------------------------------------

    DebugUI.AddLabel(
        panel,
        20,
        15,
        440,
        30,
        "BAO DEBUG",
        UIFontClass.Large
    )

    DebugUI.AddLabel(
        panel,
        20,
        45,
        440,
        20,
        "BanditsAIOverhaul developer tools",
        UIFontClass.Small
    )

    ----------------------------------------------------------------
    -- Status section
    ----------------------------------------------------------------

    DebugUI.AddLabel(
        panel,
        20,
        80,
        440,
        20,
        "RUNTIME STATUS",
        UIFontClass.Small
    )

    local status =
        DebugUI.AddLabel(
            panel,
            20,
            105,
            440,
            65,
            "Status: READY",
            UIFontClass.Small
        )

    DebugUI.statusLabel =
        status

    ----------------------------------------------------------------
    -- NPC section
    ----------------------------------------------------------------

    DebugUI.AddLabel(
        panel,
        20,
        185,
        440,
        20,
        "NPC TEST",
        UIFontClass.Small
    )

    DebugUI.AddButton(
        panel,
        20,
        210,
        210,
        35,
        "Spawn Test NPC",
        function()

            DebugUI.SendCommand(
                "spawn_npc"
            )

        end
    )

    DebugUI.AddButton(
        panel,
        250,
        210,
        210,
        35,
        "Destroy Test NPC",
        function()

            DebugUI.SendCommand(
                "destroy_npc"
            )

        end
    )

    ----------------------------------------------------------------
    -- Navigation section
    ----------------------------------------------------------------

    DebugUI.AddLabel(
        panel,
        20,
        260,
        440,
        20,
        "NAVIGATION TEST",
        UIFontClass.Small
    )

    DebugUI.AddButton(
        panel,
        20,
        285,
        210,
        35,
        "Start Navigation",
        function()

            DebugUI.SendCommand(
                "start_navigation"
            )

        end
    )

    DebugUI.AddButton(
        panel,
        250,
        285,
        210,
        35,
        "Cancel Navigation",
        function()

            DebugUI.SendCommand(
                "cancel_navigation"
            )

        end
    )

    ----------------------------------------------------------------
    -- Diagnostics
    ----------------------------------------------------------------

    DebugUI.AddLabel(
        panel,
        20,
        335,
        440,
        20,
        "DIAGNOSTICS",
        UIFontClass.Small
    )

    DebugUI.AddButton(
        panel,
        20,
        360,
        210,
        35,
        "Get Status",
        function()

            DebugUI.SendCommand(
                "get_status"
            )

        end
    )

    DebugUI.AddButton(
        panel,
        250,
        360,
        210,
        35,
        "Close",
        function()

            DebugUI.Hide()

        end
    )

    ----------------------------------------------------------------
    -- Register panel with UIManager
    ----------------------------------------------------------------

    local addSuccess =
        pcall(
            function()

                UIManagerObject.Add(
                    panel
                )

            end
        )

    if not addSuccess then

        print(
            "[BAO][DebugUI] " ..
            "UIManager.Add failed"
        )

        return nil
    end

    DebugUI.panel =
        panel

    print(
        "[BAO][DebugUI] " ..
        "Panel created and registered"
    )

    return panel
end

----------------------------------------------------------------
-- Show
----------------------------------------------------------------

function DebugUI.Show()

    if not DebugUI.panel then

        DebugUI.CreatePanel()

    end

    if not DebugUI.panel then

        print(
            "[BAO][DebugUI] " ..
            "Show failed: panel unavailable"
        )

        return
    end

    local success =
        pcall(
            function()

                DebugUI.panel:setVisible(
                    true
                )

            end
        )

    if not success then

        print(
            "[BAO][DebugUI] " ..
            "Failed to show panel"
        )

        return
    end

    DebugUI.visible = true

    print(
        "[BAO][DebugUI] UI shown"
    )

    DebugUI.SendCommand(
        "get_status"
    )
end

----------------------------------------------------------------
-- Hide
----------------------------------------------------------------

function DebugUI.Hide()

    if not DebugUI.panel then
        return
    end

    local success =
        pcall(
            function()

                DebugUI.panel:setVisible(
                    false
                )

            end
        )

    if not success then

        print(
            "[BAO][DebugUI] " ..
            "Failed to hide panel"
        )

    end

    DebugUI.visible = false

    print(
        "[BAO][DebugUI] UI hidden"
    )
end

----------------------------------------------------------------
-- Toggle
----------------------------------------------------------------

function DebugUI.Toggle()

    if DebugUI.visible then

        DebugUI.Hide()

    else

        DebugUI.Show()

    end
end

----------------------------------------------------------------
-- Keyboard
--
-- Build 42.20 currently reports the tested F10
-- through OnKeyPressed as 10001.
----------------------------------------------------------------

function DebugUI.OnKeyPressed(key)

    if key ~= 10001 then
        return
    end

    DebugUI.Toggle()
end

----------------------------------------------------------------
-- Game start
----------------------------------------------------------------

function DebugUI.OnGameStart()

    DebugUI.initialized = true

    print(
        "[BAO][DebugUI] " ..
        "Version " ..
        DebugUI.VERSION ..
        " initialized"
    )
end

----------------------------------------------------------------
-- Events
----------------------------------------------------------------

local EventsTable =
    _G["Events"]

if EventsTable then

    if EventsTable.OnKeyPressed then

        EventsTable.OnKeyPressed.Add(
            DebugUI.OnKeyPressed
        )

    end

    if EventsTable.OnServerCommand then

        EventsTable.OnServerCommand.Add(
            DebugUI.OnServerCommand
        )

    end

    if EventsTable.OnGameStart then

        EventsTable.OnGameStart.Add(
            DebugUI.OnGameStart
        )

    end
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

BAO.DebugUI =
    DebugUI

print(
    "[BAO][DebugUI] V" ..
    DebugUI.VERSION ..
    " loaded"
)