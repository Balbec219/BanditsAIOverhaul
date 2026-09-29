---------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_DebugUI.lua
-- V1.7 - Minimal stable Debug UI for B42.20
---------------------------------------------------------

require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"

---------------------------------------------------------
-- Safe references for Lua diagnostics
---------------------------------------------------------

local ISCollapsableWindowClass = _G["ISCollapsableWindow"]
local ISButtonClass = _G["ISButton"]
local UIFontClass = _G["UIFont"]
local KeyboardClass = _G["Keyboard"]
local getCoreFunction = _G["getCore"]

---------------------------------------------------------
-- Namespace
---------------------------------------------------------

BAO = BAO or {}
BAO.DebugUI = BAO.DebugUI or {}

---------------------------------------------------------
-- Window class
---------------------------------------------------------

local BAODebugWindow =
    ISCollapsableWindowClass:derive("BAO_DebugUI")

---------------------------------------------------------
-- State
---------------------------------------------------------

BAODebugWindow.instance = nil

---------------------------------------------------------
-- Constructor
---------------------------------------------------------

function BAODebugWindow:new(x, y, width, height)

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
        a = 0.95
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
-- Create children
---------------------------------------------------------

function BAODebugWindow:createChildren()

    ISCollapsableWindowClass.createChildren(self)

    local titleBar = self:titleBarHeight()

    -----------------------------------------------------
    -- Test button
    -----------------------------------------------------

    self.testButton =
        ISButtonClass:new(
            20,
            titleBar + 70,
            180,
            30,
            "TEST BUTTON",
            self,
            BAODebugWindow.onTestButton
        )

    self.testButton:initialise()

    self:addChild(self.testButton)

end

---------------------------------------------------------
-- Render
---------------------------------------------------------

function BAODebugWindow:render()

    ISCollapsableWindowClass.render(self)

    local titleBar = self:titleBarHeight()

    -----------------------------------------------------
    -- Header
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
    -- Status
    -----------------------------------------------------

    self:drawText(
        "STATUS: UI TEST MODE",
        20,
        titleBar + 45,
        0.7,
        1,
        0.7,
        1,
        UIFontClass.Small
    )

    -----------------------------------------------------
    -- Test information
    -----------------------------------------------------

    self:drawText(
        "F10 = Open / Close Debug UI",
        20,
        titleBar + 120,
        0.8,
        0.8,
        0.8,
        1,
        UIFontClass.Small
    )

    self:drawText(
        "BAO Debug UI V1.7",
        20,
        titleBar + 145,
        0.6,
        0.6,
        0.6,
        1,
        UIFontClass.Small
    )

end

---------------------------------------------------------
-- Test button
---------------------------------------------------------

function BAODebugWindow:onTestButton()

    print("[BAO][DebugUI] TEST BUTTON PRESSED")

end

---------------------------------------------------------
-- Close
---------------------------------------------------------

function BAODebugWindow:close()

    print("[BAO][DebugUI] Close()")

    self:setVisible(false)

    self:removeFromUIManager()

    BAODebugWindow.instance = nil

end

---------------------------------------------------------
-- Create window
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

    local width = 420
    local height = 260

    local x =
        math.floor(
            (screenWidth - width) / 2
        )

    local y =
        math.floor(
            (screenHeight - height) / 2
        )

    print(
        "[BAO][DebugUI] Creating V1.7 window at "
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

    BAODebugWindow.instance = window

    print("[BAO][DebugUI] Window created successfully")

    return window

end

---------------------------------------------------------
-- Open
---------------------------------------------------------

function BAO.DebugUI.Open()

    print("[BAO][DebugUI] Open()")

    local window =
        BAO.DebugUI.Create()

    if window then

        window:setVisible(true)

        print("[BAO][DebugUI] Window visible")

    end

end

---------------------------------------------------------
-- Close
---------------------------------------------------------

function BAO.DebugUI.Close()

    print("[BAO][DebugUI] Close()")

    if BAODebugWindow.instance then

        BAODebugWindow.instance:close()

    end

end

---------------------------------------------------------
-- Toggle
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

function BAO.DebugUI.OnKeyStartPressed(key)

    if key == KeyboardClass.KEY_F10 then

        print("[BAO][DebugUI] F10 detected")

        BAO.DebugUI.Toggle()

    end

end

---------------------------------------------------------
-- Game start
---------------------------------------------------------

function BAO.DebugUI.OnGameStart()

    print("[BAO][DebugUI] OnGameStart")

end

---------------------------------------------------------
-- Events
---------------------------------------------------------

if Events then

    if Events.OnKeyStartPressed then

        Events.OnKeyStartPressed.Add(
            BAO.DebugUI.OnKeyStartPressed
        )

        print(
            "[BAO][DebugUI] OnKeyStartPressed registered"
        )

    end

    if Events.OnGameStart then

        Events.OnGameStart.Add(
            BAO.DebugUI.OnGameStart
        )

        print(
            "[BAO][DebugUI] OnGameStart registered"
        )

    end

end

---------------------------------------------------------
-- Loaded
---------------------------------------------------------

print("[BAO][DebugUI] V1.7 loaded")