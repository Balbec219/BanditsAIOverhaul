---------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_DebugUI.lua
-- V1.9
--
-- BAO Developer Debug UI
--
-- F10:
-- Open / Close
--
-- AI TESTS:
-- Decision System scenario testing.
---------------------------------------------------------

require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISComboBox"

---------------------------------------------------------
-- SAFE REFERENCES
---------------------------------------------------------

local ISCollapsableWindowClass =
    _G["ISCollapsableWindow"]

local ISButtonClass =
    _G["ISButton"]

local UIFontClass =
    _G["UIFont"]

local KeyboardClass =
    _G["Keyboard"]

local getCoreFunction =
    _G["getCore"]

---------------------------------------------------------
-- BAO
---------------------------------------------------------

BAO = BAO or {}

BAO.DebugUI = BAO.DebugUI or {}

---------------------------------------------------------
-- WINDOW CLASS
---------------------------------------------------------

local BAODebugWindow =
    ISCollapsableWindowClass:derive(
        "BAO_DebugUI"
    )

BAODebugWindow.instance = nil

---------------------------------------------------------
-- TEST STATE
---------------------------------------------------------

BAODebugWindow.lastScenario = "NONE"

BAODebugWindow.lastDecision = "NONE"

BAODebugWindow.lastScore = 0

BAODebugWindow.lastPriority = 0

BAODebugWindow.lastTestStatus = "READY"

---------------------------------------------------------
-- CONSTRUCTOR
---------------------------------------------------------

function BAODebugWindow:new(
    x,
    y,
    width,
    height
)

    local o =
        ISCollapsableWindowClass:new(
            x,
            y,
            width,
            height
        )

    setmetatable(o, self)

    self.__index = self

    o.x = x
    o.y = y

    o.width = width
    o.height = height

    o.title = "BAO Debug UI"

    o.resizable = false

    o.drawFrame = true

    o.backgroundColor = {

        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.97
    }

    o.borderColor = {

        r = 0.4,
        g = 0.4,
        b = 0.4,
        a = 1
    }

    return o

end

---------------------------------------------------------
-- CREATE CHILDREN
---------------------------------------------------------

function BAODebugWindow:createChildren()

    ISCollapsableWindowClass.createChildren(
        self
    )

    local titleBar =
        self:titleBarHeight()

    -----------------------------------------------------
    -- BASIC TEST
    -----------------------------------------------------

    self.testButton =
        ISButtonClass:new(
            20,
            titleBar + 65,
            180,
            30,
            "PIPELINE TESTS",
            self,
            BAODebugWindow.onTestButton
        )

    self.testButton:initialise()

    self:addChild(
        self.testButton
    )

    -----------------------------------------------------
    -- AI TEST BUTTONS
    -----------------------------------------------------

    self.spawnNPCButton = ISButtonClass:new(20, titleBar + 270, 175, 26,
        "SPAWN TEST NPC", self, BAODebugWindow.onSpawnNPC)
    self.spawnNPCButton:initialise()
    self:addChild(self.spawnNPCButton)
    self.removeNPCButton = ISButtonClass:new(215, titleBar + 270, 175, 26,
        "REMOVE ALL TEST NPC", self, BAODebugWindow.onRemoveNPC)
    self.removeNPCButton:initialise()
    self:addChild(self.removeNPCButton)
    self.npcSelector = _G["ISComboBox"]:new(20, titleBar + 305, 245, 24, self, nil)
    self.npcSelector:initialise()
    self:addChild(self.npcSelector)
    local buttons = {
        {275,305,115,"REFRESH NPC",BAODebugWindow.onRefreshNPC},
        {20,338,175,"TARGET: MY TILE",BAODebugWindow.onNPCTarget},
        {215,338,175,"START PATROL",BAODebugWindow.onNPCPatrol},
        {20,370,175,"STOP NPC",BAODebugWindow.onNPCStop},
        {215,370,175,"NPC STATUS",BAODebugWindow.onNPCStatus}
    }
    for _, item in ipairs(buttons) do
        local button = ISButtonClass:new(item[1], titleBar+item[2], item[3], 26, item[4], self, item[5])
        button:initialise()
        self:addChild(button)
    end
    self:refreshNPCList()

    local startY =
        titleBar + 105

    local buttonWidth = 175
    local buttonHeight = 26

    local gap = 6

    -----------------------------------------------------
    -- LEFT COLUMN
    -----------------------------------------------------

    self.normalButton =
        self:createTestButton(
            20,
            startY,
            buttonWidth,
            buttonHeight,
            "NORMAL",
            "NORMAL"
        )

    self.lowHealthButton =
        self:createTestButton(
            20,
            startY + (buttonHeight + gap),
            buttonWidth,
            buttonHeight,
            "LOW HEALTH",
            "LOW_HEALTH"
        )

    self.highFatigueButton =
        self:createTestButton(
            20,
            startY + (buttonHeight + gap) * 2,
            buttonWidth,
            buttonHeight,
            "HIGH FATIGUE",
            "HIGH_FATIGUE"
        )

    self.manyZombiesButton =
        self:createTestButton(
            20,
            startY + (buttonHeight + gap) * 3,
            buttonWidth,
            buttonHeight,
            "MANY ZOMBIES",
            "MANY_ZOMBIES"
        )

    self.nightButton =
        self:createTestButton(
            20,
            startY + (buttonHeight + gap) * 4,
            buttonWidth,
            buttonHeight,
            "NIGHT",
            "NIGHT"
        )

    -----------------------------------------------------
    -- RIGHT COLUMN
    -----------------------------------------------------

    local rightX =
        215

    self.noWeaponButton =
        self:createTestButton(
            rightX,
            startY,
            buttonWidth,
            buttonHeight,
            "NO WEAPON",
            "NO_WEAPON"
        )

    self.hungryButton =
        self:createTestButton(
            rightX,
            startY + (buttonHeight + gap),
            buttonWidth,
            buttonHeight,
            "HUNGRY",
            "HUNGRY"
        )

    self.thirstyButton =
        self:createTestButton(
            rightX,
            startY + (buttonHeight + gap) * 2,
            buttonWidth,
            buttonHeight,
            "THIRSTY",
            "THIRSTY"
        )

    self.panicButton =
        self:createTestButton(
            rightX,
            startY + (buttonHeight + gap) * 3,
            buttonWidth,
            buttonHeight,
            "PANIC",
            "PANIC"
        )

    self.runAllButton =
        self:createTestButton(
            rightX,
            startY + (buttonHeight + gap) * 4,
            buttonWidth,
            buttonHeight,
            "RUN ALL TESTS",
            "RUN_ALL"
        )

end

---------------------------------------------------------
-- CREATE TEST BUTTON
---------------------------------------------------------

function BAODebugWindow:createTestButton(
    x,
    y,
    width,
    height,
    title,
    scenario
)

    local button =
        ISButtonClass:new(
            x,
            y,
            width,
            height,
            title,
            self,
            BAODebugWindow.onScenarioButton
        )

    button.scenario =
        scenario

    button:initialise()

    self:addChild(button)

    return button

end

---------------------------------------------------------
-- RENDER
---------------------------------------------------------

function BAODebugWindow:render()

    ISCollapsableWindowClass.render(
        self
    )

    local titleBar =
        self:titleBarHeight()
    self:drawText(self.npcTargetText or "Target: stand on destination, click TARGET: MY TILE",
        20, titleBar+405, 1,1,1,1, UIFontClass.Small)
    self:drawText(self.npcStatusText or "NPC: select an ID, then choose a command",
        20, titleBar+425, 0.6,1,0.6,1, UIFontClass.Small)

    -----------------------------------------------------
    -- HEADER
    -----------------------------------------------------

    self:drawText(
        "Bandits AI Overhaul",
        20,
        titleBar + 15,
        1,
        1,
        1,
        1,
        UIFontClass.Small
    )

    -----------------------------------------------------
    -- STATUS
    -----------------------------------------------------

    self:drawText(
        "DEBUG STATUS: ACTIVE",
        20,
        titleBar + 42,
        0.5,
        1,
        0.5,
        1,
        UIFontClass.Small
    )

    -----------------------------------------------------
    -- LAST TEST
    -----------------------------------------------------

    self:drawText(
        "Scenario: "
        .. tostring(
            self.lastScenario
        ),
        20,
        self.height - 75,
        0.8,
        0.8,
        0.8,
        1,
        UIFontClass.Small
    )

    self:drawText(
        "Decision: "
        .. tostring(
            self.lastDecision
        ),
        20,
        self.height - 55,
        1,
        1,
        1,
        1,
        UIFontClass.Small
    )

    self:drawText(
        "Score: "
        .. tostring(
            self.lastScore
        )
        .. "  Priority: "
        .. tostring(
            self.lastPriority
        ),
        20,
        self.height - 35,
        0.8,
        0.8,
        0.8,
        1,
        UIFontClass.Small
    )

    self:drawText(
        "Status: "
        .. tostring(
            self.lastTestStatus
        ),
        220,
        self.height - 35,
        0.6,
        1,
        0.6,
        1,
        UIFontClass.Small
    )

end

---------------------------------------------------------
-- BASIC TEST
---------------------------------------------------------

function BAODebugWindow:runNPCCommand(spawn)
    self.lastScenario = spawn and "NPC SPAWN" or "NPC REMOVE"
    self.lastScore, self.lastPriority = 0, 0
    local adapter = BAO.NPCWorldAdapter
    if not adapter then self.lastTestStatus = "UNAVAILABLE"; return end
    local ok, success, reason = pcall(function()
        if BAO.NPCWorldClient then return BAO.NPCWorldClient.Request(spawn, _G["getPlayer"] and getPlayer()) end
        return false, "client_module_unavailable"
    end)
    self.lastDecision = tostring(ok and reason or success)
    self.lastTestStatus = ok and (success and "OK" or "REFUSED") or "ERROR"
    print("[BAO][DebugUI] " .. self.lastScenario .. " " .. self.lastTestStatus
        .. " reason=" .. self.lastDecision)
end
function BAODebugWindow:refreshNPCList()
    if not self.npcSelector then return end
    local previous = self.npcIds and self.npcIds[self.npcSelector.selected]
    self.npcSelector:clear()
    self.npcSelector.selected = 1
    self.npcIds = {}
    local client = BAO.NPCWorldClient
    for index, identity in ipairs(client and client.GetNPCList() or {}) do
        self.npcIds[index] = identity.id
        self.npcSelector:addOption(identity.id)
        if identity.id == previous then self.npcSelector.selected = index end
    end
    if #self.npcIds == 0 then self.npcSelector:addOption("No active NPC") end
end
function BAODebugWindow:onRefreshNPC()
    self:refreshNPCList()
    if _G["isClient"] and isClient() then
        sendClientCommand(getPlayer(), "BAO_Debug", "world_state", {})
    end
end
function BAODebugWindow:onNPCTarget()
    local player = getPlayer()
    if not player then return end
    self.npcTarget = {x=math.floor(player:getX()), y=math.floor(player:getY()), z=math.floor(player:getZ())}
    local t = self.npcTarget
    self.npcTargetText = "Target: " .. t.x .. ", " .. t.y .. ", " .. t.z
end
function BAODebugWindow:sendNPCOrder(command)
    local id = self.npcIds and self.npcIds[self.npcSelector.selected]
    if not id then self.npcStatusText = "NPC: refresh and select an active NPC"; return end
    if command == "npc_patrol" and not self.npcTarget then
        self.npcStatusText = "NPC: set TARGET: MY TILE first"; return
    end
    local t = self.npcTarget or {}
    self.npcStatusText = "NPC: sending " .. command
    local ok, reason = BAO.NPCWorldClient.CommandNPC(getPlayer(), command, {id=id,x=t.x,y=t.y,z=t.z})
    if not ok then self.npcStatusText = "NPC: " .. tostring(reason) end
end
function BAODebugWindow:onNPCPatrol() self:sendNPCOrder("npc_patrol") end
function BAODebugWindow:onNPCStop() self:sendNPCOrder("npc_stop") end
function BAODebugWindow:onNPCStatus() self:sendNPCOrder("npc_status") end
function BAO.DebugUI.ReceiveNPCStatus(args)
    local window = BAODebugWindow.instance
    if not window then return end
    if args.snapshot then window:refreshNPCList() end
    if args.npcId then
        local detail = args.detail or {}
        window.npcStatusText = tostring(args.npcId) .. ": " .. tostring(detail.state or args.reason)
        if detail.reason and detail.reason ~= "none" then
            window.npcStatusText = window.npcStatusText .. " / " .. tostring(detail.reason)
        end
    end
end
function BAODebugWindow:onSpawnNPC() self:runNPCCommand(true); self:refreshNPCList() end
function BAODebugWindow:onRemoveNPC() self:runNPCCommand(false); self:refreshNPCList() end

function BAODebugWindow:onTestButton()
    self.lastScenario = "PIPELINE"
    self.lastDecision = "NONE"
    self.lastScore = 0
    self.lastPriority = 0
    local harness = BAO.AIControllerTestHarness
    if not harness or not harness.Run or not harness.GetSummary then
        self.lastTestStatus = "HARNESS UNAVAILABLE"
        return
    end
    local ok, success = pcall(harness.Run)
    if not ok then
        print("[BAO][DebugUI] Pipeline error: " .. tostring(success))
        self.lastTestStatus = "ERROR"
        return
    end
    local summary = harness.GetSummary()
    self.lastDecision = tostring(summary.Passed) .. "/" .. tostring(summary.Total) .. " PASSED"
    self.lastTestStatus = success and "PASS" or "FAIL"
end

---------------------------------------------------------
-- RUN SCENARIO
---------------------------------------------------------

function BAODebugWindow:runScenario(
    scenarioName
)

    if not BAO.AITestHarness then

        print(
            "[BAO][DebugUI] ERROR: "
            .. "AITestHarness unavailable"
        )

        self.lastTestStatus =
            "HARNESS UNAVAILABLE"

        return

    end

    if not BAO.AITestHarness.RunScenario then

        print(
            "[BAO][DebugUI] ERROR: "
            .. "RunScenario unavailable"
        )

        self.lastTestStatus =
            "RUNNER UNAVAILABLE"

        return

    end

    print(
        "[BAO][DebugUI] Running scenario: "
        .. tostring(
            scenarioName
        )
    )

    local result =
        BAO.AITestHarness.RunScenario(
            scenarioName
        )

    if not result then

        self.lastScenario =
            tostring(
                scenarioName
            )

        self.lastDecision =
            "FAILED"

        self.lastScore = 0

        self.lastPriority = 0

        self.lastTestStatus =
            "FAILED"

        return

    end

    self.lastScenario =
        tostring(
            result.Scenario
        )

    self.lastDecision =
        tostring(
            result.Decision
        )

    self.lastScore =
        result.Score or 0

    self.lastPriority =
        result.Priority or 0

    self.lastTestStatus =
        "PASS"

end

---------------------------------------------------------
-- SCENARIO BUTTON
---------------------------------------------------------

function BAODebugWindow:onScenarioButton(
    button
)

    if not button then
        return
    end

    local scenario =
        button.scenario

    if not scenario then
        return
    end

    if scenario == "RUN_ALL" then

        self:runAllTests()

        return
    end

    self:runScenario(
        scenario
    )

end

---------------------------------------------------------
-- RUN ALL
---------------------------------------------------------

function BAODebugWindow:runAllTests()

    if not BAO.AITestHarness then

        print(
            "[BAO][DebugUI] ERROR: "
            .. "AITestHarness unavailable"
        )

        self.lastTestStatus =
            "HARNESS UNAVAILABLE"

        return
    end

    print(
        "[BAO][DebugUI] RUNNING ALL AI TESTS"
    )

    local result =
        BAO.AITestHarness.RunAll()

    if not result then

        self.lastScenario =
            "ALL"

        self.lastDecision =
            "FAILED"

        self.lastScore = 0

        self.lastPriority = 0

        self.lastTestStatus =
            "FAILED"

        return
    end

    self.lastScenario =
        "ALL"

    self.lastDecision =
        tostring(
            result.Passed
        )
        .. "/"
        .. tostring(
            result.Total
        )
        .. " PASSED"

    self.lastScore = 0

    self.lastPriority = 0

    self.lastTestStatus =
        "COMPLETE"

end

---------------------------------------------------------
-- CLOSE
---------------------------------------------------------

function BAODebugWindow:close()

    print(
        "[BAO][DebugUI] Close()"
    )

    self:setVisible(false)

    self:removeFromUIManager()

    BAODebugWindow.instance =
        nil

end

---------------------------------------------------------
-- CREATE
---------------------------------------------------------

function BAO.DebugUI.Create()

    if BAODebugWindow.instance then

        if BAODebugWindow.instance:isVisible() then

            return BAODebugWindow.instance

        end

    end

    local screenWidth =
        getCoreFunction():getScreenWidth()

    local screenHeight =
        getCoreFunction():getScreenHeight()

    local width = 560

    local height = 570

    local x =
        math.floor(
            (screenWidth - width) / 2
        )

    local y =
        math.floor(
            (screenHeight - height) / 2
        )

    print(
        "[BAO][DebugUI] Creating V1.9 window at "
        .. tostring(x)
        .. ", "
        .. tostring(y)
    )

    local window =
        BAODebugWindow:new(
            x,
            y,
            width,
            height
        )

    window:initialise()

    window:addToUIManager()

    BAODebugWindow.instance =
        window

    print(
        "[BAO][DebugUI] Window created successfully"
    )

    return window

end

---------------------------------------------------------
-- OPEN
---------------------------------------------------------

function BAO.DebugUI.Open()

    print(
        "[BAO][DebugUI] Open()"
    )

    local window =
        BAO.DebugUI.Create()

    if window then

        window:setVisible(true)

        print(
            "[BAO][DebugUI] Window visible"
        )

    end

end

---------------------------------------------------------
-- CLOSE
---------------------------------------------------------

function BAO.DebugUI.Close()

    print(
        "[BAO][DebugUI] Close()"
    )

    if BAODebugWindow.instance then

        BAODebugWindow.instance:close()

    end

end

---------------------------------------------------------
-- TOGGLE
---------------------------------------------------------

function BAO.DebugUI.Toggle()

    if BAODebugWindow.instance
        and BAODebugWindow.instance:isVisible() then

        BAO.DebugUI.Close()

    else

        BAO.DebugUI.Open()

    end

end

---------------------------------------------------------
-- F10
---------------------------------------------------------

function BAO.DebugUI.OnKeyStartPressed(
    key
)

    if key ==
        KeyboardClass.KEY_F10 then

        print(
            "[BAO][DebugUI] F10 detected"
        )

        BAO.DebugUI.Toggle()

    end

end

---------------------------------------------------------
-- GAME START
---------------------------------------------------------

function BAO.DebugUI.OnGameStart()

    print(
        "[BAO][DebugUI] OnGameStart"
    )

end

---------------------------------------------------------
-- EVENTS
---------------------------------------------------------

if Events then

    if Events.OnKeyStartPressed then

        Events.OnKeyStartPressed.Add(
            BAO.DebugUI.OnKeyStartPressed
        )

        print(
            "[BAO][DebugUI] "
            .. "OnKeyStartPressed registered"
        )

    end

    if Events.OnGameStart then

        Events.OnGameStart.Add(
            BAO.DebugUI.OnGameStart
        )

        print(
            "[BAO][DebugUI] "
            .. "OnGameStart registered"
        )

    end

end

---------------------------------------------------------
-- LOADED
---------------------------------------------------------

print(
    "[BAO][DebugUI] V1.9 loaded"
)
