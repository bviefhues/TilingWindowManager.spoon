--- === TilingWindowManager.spoon ===
---
--- Tiling Window Manager.

local spaces =     require("hs._asm.undocumented.spaces")
local inspect =    require("hs.inspect")
local window =     require("hs.window")
local fnutils =    require("hs.fnutils")
local spoons =     require("hs.spoons")
local image =      require("hs.image")
local settings =   require("hs.settings")
local menubar =    require("hs.menubar")

local obj={}
obj.__index = obj

-- Metadata
obj.name = "TilingWindowManager"
obj.version = "0.0"
obj.author = "B Viefhues"
obj.homepage = "https://github.com/bviefhues/TilingWindowManager.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"


-- Variables --------------------------------------------------------

--- TilingWindowManager.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set 
--- the default log level for the messages coming from the Spoon.
obj.log = hs.logger.new("TilingWindowManager")

-- Internal: TiningWindowManager.spaces
-- Variable
-- Contains spaces-sepcific state.
obj.spaces = {}

-- Internal: TilingWindowManager.menubar
-- Variable
-- Contains the Spoons hs.menubar.
obj.menubar = nil

-- Internal: TilingWindowManager.spacesWatcher
-- Variable
-- Contains a hs.spaces.watcher for the Spoon to get notified on
-- macOS space changes.
obj.spacesWatcher = nil

-- Internal: TilingWindowManager.windowFilter
-- Variable
-- Contains a hs.window.filter subscription for the Spoon to get 
-- notified on macOS window changes.
obj.windowFilter = nil

--- TilingWindowManager.tilingMode
--- Variable
--- A table holding all known tiling modes. Maps keys to descriptive 
--- strings. The strings show up in the user interface.
---
--- The following tiling modes are defined as Keys:
---  * TilingWindowManager.tilingMode.floating
---  * TilingWindowManager.tilingMode.fullscreen
---  * TilingWindowManager.tilingMode.tall
---  * TilingWindowManager.tilingMode.wide
obj.tilingMode = {
    floating = "Floating",
    fullscreen = "Fullscreen",
    tall = "Tall",
    wide = "Wide",
}

--- TilingWindowManager.enabledTilingModes
--- Variable
--- A table holding all enabled tiling modes.
---
--- Notes:
--- Can be set as a config option in the spoons `start()` method.
obj.enabledTilingModes = {obj.tilingMode.floating} 

--- TilingWindowManager.fullscreenRightApps
--- Variable
--- A table holding names of applications which shall be positioned
--- on right half of screen only for fullscreen mode.
---
--- Notes:
--- Can be set as a config option in the spoons `start()` method.
obj.fullscreenRightApps = {}

--- TilingWindowManager.floatApps
--- Variable
--- A table holding names of applications which shall not be tiled.
--- These application's windows are never midified by the spoon.
---
--- Notes:
--- Can be set as a config option in the spoons `start()` method.
obj.floatApps = {}

--- TilingWindowManager.displayMode
--- Variable
--- If true: show `hs.alert()` with mode name when changing mode.
---
--- Notes:
--- Can be set as a config option in the spoons `start()` method.
obj.displayMode = false


-- Tiling strategy --------------------------------------------------

--- TilingWindowManager.tilingStrategy
--- Variable
--- A table holding everything necessary for each tiling mode.
--- 
--- The table key is a tiling mode, as per 
--- `TilingWindowManager.tilingMode`.
--- 
--- The table value for each tiling mode is a table with these keys:
---  * tile(windows) - a function to move windows in place.
---  * symbol - a string formatted as ASCII image, the tiling modes icon.
obj.tilingStrategy = {}

obj.tilingStrategy[obj.tilingMode.floating] = {
    tile = function(windows)
        obj.log.d("> tileLayout", obj.tilingMode.floating)
        -- do nothing 
        obj.log.d("< tileLayout", obj.tilingMode.floating)
    end,

    symbol = [[ASCII:
. . . . . . . . . . . . . . . . . . . . .
. . D E # # # # # # # # # E F . . . . . .
. D H # # # # # # # # # # # H F . . . . .
. C . . . . . . . . . . . . . G . . . . .
. # . . . . h a # # # # # # # # # a b . .
. # . . . h i # # # # # # # # # # # i b .
. # . . . g . . . . . . . . . . . . . c .
. # . . . # . . . . . . . . . . . . . # .
. C . . . # . . . . . . . . . . . . . # .
. B . . . # . . . . . . . . . . . . . # .
. . B A A # . . . . . . . . . . . . . # .
. . . . . g . . . . . . . . . . . . . c .
. . . . . f . . . . . . . . . . . . . d .
. . . . . . f e # # # # # # # # # e d . .
. . . . . . . . . . . . . . . . . . . . .
]],
}

obj.tilingStrategy[obj.tilingMode.fullscreen] = {
    tile = function(windows)
        obj.log.d("> tileLayout", obj.tilingMode.fullscreen)
        for i, window in ipairs(windows) do
            local frame = window:screen():frame()
            appTitle = window:application():title()
            -- Keep some apps on right side only
            -- Old habit...
            if fnutils.contains(obj.fullscreenRightApps, appTitle) then
                frame.x = frame.x + (frame.w / 2)
                frame.w = frame.w / 2
            end
            window:setFrame(frame)
        end
        obj.log.d("< tileLayout", obj.tilingMode.fullscreen)
    end,

    symbol = [[ASCII:
. . . . . . . . . . . . . . . . . . . . .
. . h a # # # # # # # # # # # # # a b . .
. h A # # # # # # # # # # # # # # # B b .
. g . . . . . . . . . . . . . . . . . c .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. g . . . . . . . . . . . . . . . . . c .
. f . . . . . . . . . . . . . . . . . d .
. . f e # # # # # # # # # # # # # e d . .
. . . . . . . . . . . . . . . . . . . . .
]],
}

obj.tilingStrategy[obj.tilingMode.tall] = {
    tile = function(windows)
        obj.log.d("> tile", obj.tilingMode.tall)
        if #windows == 1 then
            obj.tilingStrategy[obj.tilingMode.fullscreen].tile(windows)
        else
            for i, window in ipairs(windows) do
                local frame = window:screen():frame()
                if i == 1 then 
                    -- vertical main
                    frame.w = frame.w / 2
                else
                    -- vertical stack
                    frame.x = frame.x + (frame.w / 2)
                    frame.h = frame.h / (#windows - 1)
                    frame.y = frame.y + frame.h * (i - 2)
                    frame.w = frame.w / 2
                end
                window:setFrame(frame)
            end
        end
        obj.log.d("< tile", obj.tilingMode.tall)
    end,

    symbol = [[ASCII:
. . . . . . . . . . . . . . . . . . . . .
. . h a # # # # # # # # # # # # # a b . .
. h 2 # # # # # # 2 1 3 # # # # # # 3 b .
. g . . . . . . . . # . . . . . . . . c .
. # . . . . . . . . # . . . . . . . . # .
. # . . . . . . . . # 4 # # # # # # 4 # .
. # . . . . . . . . # 5 # # # # # # 5 # .
. # . . . . . . . . # . . . . . . . . # .
. # . . . . . . . . # . . . . . . . . # .
. # . . . . . . . . # 6 # # # # # # 6 # .
. # . . . . . . . . # 7 # # # # # # 7 # .
. g . . . . . . . . # . . . . . . . . c .
. f . . . . . . . . 1 . . . . . . . . d .
. . f e # # # # # # # # # # # # # e d . .
. . . . . . . . . . . . . . . . . . . . .
]],
}

obj.tilingStrategy[obj.tilingMode.wide] = {
    tile = function(windows)
        obj.log.d("> tile", obj.tilingMode.wide)
        if #windows == 1 then
            obj.tilingStrategy[obj.tilingMode.fullscreen].tile(windows)
        else
            for i, window in ipairs(windows) do
                local frame = window:screen():frame()
                if i == 1 then 
                    -- horizontal main
                    frame.h = frame.h / 2
                else
                    -- horizontal stack
                    frame.y = frame.y + (frame.h / 2)
                    frame.w = frame.w / (#windows - 1)
                    frame.x = frame.x + frame.w * (i - 2)
                    frame.h = frame.h / 2
                end
                window:setFrame(frame)
            end
        end
        obj.log.d("< tile", obj.tilingMode.wide)
    end,

    symbol = [[ASCII:
. . . . . . . . . . . . . . . . . . . . .
. . h a # # # # # # # # # # # # # a b . .
. h 1 # # # # # # # # # # # # # # # 1 b .
. g . . . . . . . . . . . . . . . . . c .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # . . . . . . . . . . . . . . . . . # .
. # 2 # # # # # # # # # # # # # # # 2 # .
. # 3 # # # # # # # # # # # # # # # 3 # .
. # . . . . . 4 . . . . . 5 . . . . . # .
. # . . . . . # . . . . . # . . . . . # .
. g . . . . . # . . . . . # . . . . . c .
. f . . . . . 4 . . . . . 5 . . . . . d .
. . f e # # # # # # # # # # # # # e d . .
. . . . . . . . . . . . . . . . . . . . .
]],
}


-- Load and save settings, initiaize data structures ----------------

-- Internal: Save spaces config to keep them across hammerspoon reloads
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function obj.saveSettings()
    obj.log.d("> saveSettings")
    tileSettings = {}
    for spaceID, spaceData in pairs(obj.spaces) do
        tileSettings[tostring(spaceID)] = spaceData.tilingMode
    end
    obj.log.d(inspect(tileSettings))
    settings.set("TilingWindowManager", tileSettings)
    obj.log.d("< saveSettings")
end

-- Internal: Load spaces config
--
-- Parameters:
--  * None
--
-- Returns:
--  * Settings table
function obj.loadSettings()
    obj.log.d("> loadSettings")
    local settings = settings.get("TilingWindowManager")
    local settingsInt = {}
    for spaceID, setting in pairs(settings) do
        settingsInt[tonumber(spaceID)] = setting
    end
    obj.log.d("< loadSettings ->", inspect.inspect(settingsInt))
    return settingsInt
end

-- Internal: generate default data structure for a space.
--
-- Parameters:
--  * None
--
-- Returns
--  * Table with default data structure
function obj.initSpace()
    local space = {}
    space.tilingMode = obj.enabledTilingModes[1]
    space.tilingWindows = {}
    return space
end


-- Internal: Initialize the obj.spaces table.
-- Maps loadSettings() data to current spaces.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function obj.initSpaces()
    obj.log.d("> initSpaces")
    local settings = obj.loadSettings()

    obj.spaces = {} -- we will re-build this now

    local screen = spaces.mainScreenUUID()
    for space_number, space_id in ipairs(spaces.layout()[screen]) do
        local space = obj.initSpace()
        if settings and settings[space_id] then
            tilingMode = settings[space_id]
            if fnutils.contains(obj.enabledTilingModes, tilingMode) then
                space.tilingMode = tilingMode
            end
        end
        obj.spaces[space_id] = space
    end
    obj.log.d("< initSpaces")
end


-- Tiling management ------------------------------------------------

-- Internal: Helper function to log a table of window objects to the
-- console, including some relevant window attributes. Useful for
-- debugging.
--
-- Parameters:
--  * text - written to console to identify output
--  * windows - a table of `hs.windows` objects.
--
--  Returns:
--   * None
function obj.logWindows(text, windows)
    obj.log.d(text)
    if windows then
        for i, w in ipairs(windows) do
            obj.log.d("  ", i, 
                "ID:"..w:id(), 
                "V:"..tostring(w:isVisible()):sub(1,1), 
                "S:"..tostring(w:isStandard()):sub(1,1), 
                "M:"..tostring(w:isMinimized()):sub(1,1),
                "("..w:title():sub(1,25)..")")
        end
    else 
        obj.log.d("  no windows")
    end
end

-- Internal: Gets the tiling mode of the current macOS space
--
-- Parameters:
--  * None
--
-- Returns:
--  * the tiling mode string
function obj.tilingModeCurrentSpace()
    obj.log.d("> tilingModeCurrentSpace")
    local currentSpaceID = spaces.activeSpace()
    local tilingMode = obj.spaces[currentSpaceID].tilingMode
    obj.log.d("< tilingModeCurrentSpace", tilingMode)
    return tilingMode
end

-- Internal: Sets the tiling mode of the current space.
-- 
-- Parameters:
--  * tilingMode - String as per `obj.enabledTilingModes`
--
-- Returns:
--  * None
function obj.setTilingModeCurrentSpace(tilingMode)
    obj.log.d("> setTilingModeCurrentSpace", tilingMode)
    -- TODO check if tilingMode is allowed
    local currentSpaceID = spaces.activeSpace()
    obj.spaces[currentSpaceID].tilingMode = tilingMode

    if obj.displayMode then obj.displayTilingMode() end
    
    obj.log.d("> setTilingModeCurrentSpace")
end

-- Internal: Returns an ordered table of all tileable windows for the
-- current space. Preserves the order of known windows and combines with 
-- any newly visible windows in the space, e.g. through un-minimizing.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of `hs.window` objects ordered for layouting
function obj.tileableWindowsCurrentSpace()
    obj.log.d("> tileableWindowsCurrentSpace")
    local currentSpaceID = spaces.activeSpace()
    if not obj.spaces[currentSpaceID] then
        -- current space unknown, initialize
        obj.spaces[currentSpaceID] = obj.initSpaces()
    end
    
    -- TODO variable naming is a mess
    -- all visible and "good" windows in current space
    local windows = spaces.allWindowsForSpace(currentSpaceID)
    local visibleWindows = fnutils.filter(windows, function(w) 
        return (
            w:isVisible() 
            and w:isStandard() 
            and (not w:isMinimized())
            --and #w:title()>0
        )
    end)
    -- recorded state of window order
    local orderedWindows = obj.spaces[currentSpaceID].tilingWindows
    -- filter ordered windows for visible windows only
    local orderedVisibleWindows = fnutils.filter(orderedWindows, 
        function(w)
            return fnutils.contains(visibleWindows, w)
        end)
    -- Windows which are new, we don't know the order of
    local newVisibleWindows = fnutils.filter(visibleWindows, function(w)
        return (not fnutils.contains(orderedWindows, w))
    end)
    -- sort by window position to maintain order across Hammerspoon
    -- restarts. 
    table.sort(newVisibleWindows, function(w1, w2) 
        f1 = w1:frame()
        f2 = w2:frame()
        return (f1.x + f1.y) < (f2.x + f2.y)
    end)
    -- Add new windows to ordered windows, at top of stack
    local mainWindows = {orderedVisibleWindows[1]} -- TODO multi-windows
    local stackWindows = {table.unpack(orderedVisibleWindows, 2)}
    local tileableWindows = fnutils.concat(fnutils.concat(
        mainWindows, 
        newVisibleWindows),
        stackWindows)
    -- filter out configured "always float" app windows
    local tilingWindows = fnutils.filter(tileableWindows, function(w)
        return (not fnutils.contains(
            obj.floatApps, 
            w:application():name()))
    end)

    obj.spaces[currentSpaceID].tilingWindows = tilingWindows

    logWindows("Tileable Windows: ", tilingWindows)
    obj.log.d("< tileableWindowsCurrentSpace", "(...)")
    return tilingWindows
end

-- Internal: tiles the current macOS space, i.e. re-arranges windows
-- according to the selected tiling mode for that space.
--
-- Parameters:
--  * windows - a table of windows to tile, this is optional to help
--    avoiding calculating the window table several times. The calling
--    code can pass this if it knows that table already. Will be 
--    calculated in the method if `nil`.
--
-- Returns:
--  * None
--
-- Notes:
-- This calls the `tile()` function of `tilingStrategy`. 
function obj.tileCurrentSpace(windows)
    obj.log.d("> tileCurrentSpace", hs.inspect(windows))
    --obj.logWindows("Windows:", windows)
    windows = windows or obj.tileableWindowsCurrentSpace()
    obj.tilingStrategy[obj.tilingModeCurrentSpace()].tile(windows)
    obj.log.d("< tileCurrentSpace")
end

-- Internal: Callback for hs.spaces.watcher, is triggered when
-- user switches to another space, tiles space and updates menu.
--
-- Parameters:
--  * None
--
--  Returns:
--   * None
function obj.switchedToSpace(number)
    obj.log.d("> switchedToSpace", number)
    obj.tileCurrentSpace() -- in case window configuration has changed
    obj.updateMenu()
    obj.log.d("< switchedToSpace")
end


-- Move focus and swap windows --------------------------------------

--- TilingWindowManager.focusNext()
--- Function
--- Change window focus to next window in tileable windows.
--- Wraps around if current window is last window.
---
--- Parameters:
---  * None
---
---  Returns:
---   * None
function obj.focusNext()
    obj.log.d("> focusNext")
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            local j = i + 1
            if i == #windows then j = 1 end
            windows[j]:focus():raise()
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< focusNext")
end

--- TilingWindowManager.focusPrev()
--- Function
--- Change window focus to previous window in tileable windows.
--- Wraps around if current window is first window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.focusPrev()
    obj.log.d("> focusPrev")
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            local j = i - 1
            if i == 1 then j = #windows end
            windows[j]:focus():raise()
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< focusPrev")
end

--- TilingWindowManager.swapNext()
--- Function
--- Swaps window order and position with next window in tileable windows.
--- Wraps around if current window is last window, then current window 
--- becomes first window. Tiles the current space.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.swapNext()
    obj.log.d("> swapNext")
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            local j = i + 1
            if i == #windows then j = 1 end
            windows[i], windows[j] = windows[j], windows[i]
            obj.tileCurrentSpace(windows)
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< swapNext")
end

--- TilingWindowManager.swapPrev()
--- Function
--- Swaps window order and position with previous window in tileable 
--- windows. Wraps around if current window is first window, then 
--- current window  becomes last window. Tiles the current space.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.swapPrev()
    obj.log.d("> swapPrev")
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            local j = i - 1
            if i == 1 then j = #windows end
            windows[i], windows[j] = windows[j], windows[i]
            obj.tileCurrentSpace(windows)
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< swapPrev")
end

--- TilingWindowManager.swapFirst()
--- Function
--- 
--- If current window is first window:
--- Swaps window order and position with second window in tileable windows.
---
--- If current window is not first window:
--- Swaps window order and position with first window in tileable windows.
---
--- Tiles the current space.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.swapFirst()
    obj.log.d("> swapFirst")
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then 
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            if i == 1 then
                obj.swapNext()
            elseif i > 1 then
                windows[i], windows[1] = windows[1], windows[i]
                obj.tileCurrentSpace(windows)
            end
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< swapFirst")
end

--- TilingWindowManager.toggleFirst()
--- Function
--- 
--- If current window is first window:
--- Swaps window order and position with second window in tileable windows.
---
--- If current window is not first window:
--- Makes current window the first window. Previous first window becomes
--- the second window..
---
--- Tiles the current space.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.toggleFirst()
    obj.log.d("> toggleFirst")
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            if i == 1 then
                obj.swapNext()
            elseif i > 1 then
                table.insert(windows, 1, table.remove(windows, i))
                obj.tileCurrentSpace(windows)
            end
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< toggleFirst")
end


-- Menu bar ---------------------------------------------------------

-- Internal: Callback for hs.menubar, is triggered when
-- user selects a tiling mode in menu bar, tiles space and updates menu.
--
-- Parameters:
--  * modifiers - koyboard modifiers
--  * menuItem - table with selected menu item
--
-- Returns:
--  * None
function obj.switchTilingMode(modifiers, menuItem)
    obj.log.d("> switchTilingMode", 
        inspect(modifiers), inspect(menuItem))
    obj.setTilingModeCurrentSpace(menuItem.title)
    obj.tileCurrentSpace()
    obj.updateMenu()
    obj.saveSettings()
    obj.log.d("< switchTilingMode")
end

-- Internal: Helper function to convert an ASCII image to an icon.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Icon
local function iconFromASCII(ascii)
    -- Hacky workaround: make Hammerspoon render the icon by creating
    -- a menubar object, grabbing the icon and deleting the menubar
    -- object.
    local menubar = menubar:new(false):setIcon(ascii)
    local icon = menubar:icon() -- hs.image object
    menubar:delete()
    return icon
end

-- Internal: Generates the menu table for the menu bar.
--
-- Parameters:
--  * None
--
-- Returns:
--  * menu table
function obj.menuTable()
    obj.log.d("> menuTable")
    local tilingModeCurrentSpace = obj.tilingModeCurrentSpace() 
    local menuTable = {}
    for i, tilingMode in ipairs(obj.enabledTilingModes) do
        local mode = {}
        mode.title = tilingMode
        if not obj.tilingStrategy[tilingMode].icon then
            -- cache icons
            obj.tilingStrategy[tilingMode].icon = 
                iconFromASCII((obj.tilingStrategy[tilingMode].symbol))
        end
        mode.image = obj.tilingStrategy[tilingMode].icon 
        if tilingMode == tilingModeCurrentSpace then
            mode.checked = true
        end
        mode.fn = obj.switchTilingMode
        table.insert(menuTable, mode)
    end
    
    -- obj.log.d("< menuTable ->", inspect.inspect(menuTable))
    obj.log.d("< menuTable ->", "(...)")
    return menuTable
end

-- Internal: Draw the menubar menu.
--
-- Parameters:
--  * None
-- 
-- Returns:
--  * None
function obj.updateMenu()
    if not obj.menubar then return end
    obj.log.d("> updateMenu")
    obj.menubar:setIcon(
        obj.tilingStrategy[obj.tilingModeCurrentSpace()].symbol)
    obj.menubar:setMenu(obj.menuTable)
    obj.log.d("< updateMenu")
end

--- TilingWindowManager.displayTilingMode()
--- Function
--- Shows an alert displaying the current spaces current tiling mode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.displayTilingMode()
    hs.alert(obj.tilingModeCurrentSpace().." Mode", 1)
end


-- Spoon methods ----------------------------------------------------

--- TilingWindowManager:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for TilingWindowManager
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for 
---    the following items:
---   * tile - Manually tiles the current macOS space.
---   * focusNext - move focus to next window.
---   * focusPrev - move focus to previous window.
---   * swapNext - swap current window with next window.
---   * swapPrev - swap current window with previous window.
---   * swapFirst - swap current window with first window.
---   * toggleFirst - Toggle current window with first window.
---   * float - switch current space to float tiling mode
---   * fullscreen - switch current space to fullscreen tiling mode.
---   * tall - switch current space to tall tiling mode.
---   * wide - switch current space to wide tiling mode.
---   * display - display current space tiling mode.
---
--- Returns:
---  * The TilingWindowManager object
function obj:bindHotkeys(mapping)
    obj.log.d("> bindHotkeys", inspect(mapping))
    local def = {
        tile = obj.tileCurrentSpace,
        focusNext = obj.focusNext,
        focusPrev = obj.focusPrev,
        swapNext = obj.swapNext,
        swapPrev = obj.swapPrev,
        swapFirst = obj.swapFirst,
        toggleFirst = obj.toggleFirst,
        float = function()
            obj.setTilingModeCurrentSpace(obj.tilingMode.float)
        end,
        fullscreen = function()
            obj.setTilingModeCurrentSpace(obj.tilingMode.fullscreen)
            obj.tileCurrentSpace()
        end,
        tall = function()
            obj.setTilingModeCurrentSpace(obj.tilingMode.tall)
            obj.tileCurrentSpace()
        end,
        wide = function()
            obj.setTilingModeCurrentSpace(obj.tilingMode.wide)
            obj.tileCurrentSpace()
        end,
        display = obj.displayTilingMode,
    }
    spoons.bindHotkeysToSpec(def, mapping)
    obj.log.d("< bindHotkeys")
    return self
end

-- Internal: Stub only, not needed right now.
function obj:init()
    --obj.log.d("> init")
    --obj.log.d("< init")
    return self
end

--- TilingWindowManager:start()
--- Method
--- Starts TilingWindowManager spoon
---
--- Parameters:
---  * config
---    A table with configuration options for the spoon.
---    These keys are recognized:
---   * dynamic - if true: dynamically tile windows.
---   * tilingModes - a table with all tiling modes to be enabled.
---   * fullscreenRightApps - a table with app names to TODO
---   * floatApp - a table with app names to always float.
---   * displayMode - if true: show mode when switching tiling mode.
---   * menubar - if true: enable menubar item.
---
--- Returns:
---  * The TilingWindowManager object
function obj:start(config)
    obj.log.d("> start")

    if config.dynamic == true then
        obj.windowFilter = window.filter.new()
            :setDefaultFilter()
            :setOverrideFilter({
                fullscreen = false,
                currentSpace = true,
                allowRoles   = { 'AXStandardWindow' },
            })
            :subscribe({ 
                window.filter.windowMinimized,
                window.filter.windowVisible,
                window.filter.windowCreated,
                window.filter.windowDestroyed,
            }, function(_, _, _) obj.tileCurrentSpace() end)
    end

    if config.tilingModes then
        obj.enabledTilingModes = config.tilingModes
    end

    if config.fullscreenRightApps then
        obj.fullscreenRightApps = config.fullscreenRightApps
    end

    if config.floatApps then
        obj.floatApps = config.floatApps
    end

    if config.displayMode then obj.displayMode = true end

    obj.initSpaces() -- needs obj.enabledTilingModes

    if config.menubar == true then
        obj.menubar = menubar.new()
        obj.updateMenu()
        obj.spacesWatcher = hs.spaces.watcher.new(
            obj.switchedToSpace):start()
    end

    obj.log.d("< start")
    return self
end

--- TilingWindowManager:stop()
--- Method
--- Stops TilingWindowManager spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The TilingWindowManager object
function obj:stop()
    obj.log.d("> stop")
    
    if obj.menubar then obj.menubar:delete() end
    obj.menubar = nil

    if obj.spacesWatcher then obj.spacesWatcher:stop() end
    obj.spacesWatcher = nil

    if obj.windowFilter then obj.windowFilter:unsubscribe() end
    obj.windowFilter = nil    

    obj.log.d("< stop")
    return self
end

--- TilingWindowManager:setLogLevel()
--- Method
--- Set the log level of the spoon logger.
---
--- Parameters:
---  * Log level 
---
--- Returns:
---  * The TilingWindowManager object
function obj:setLogLevel(level)
    obj.log.d("> setLogLevel")
    obj.log.setLogLevel(level)
    obj.log.d("< setLogLevel")
    return self
end

return obj
