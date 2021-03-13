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

--- TilingWindowManager.layouts
--- Variable
--- A table holding all known tiling layouts. Maps keys to descriptive 
--- strings. The strings show up in the user interface.
---
--- The following tiling layouts are defined as Keys:
---  * TilingWindowManager.layouts.floating
---  * TilingWindowManager.layouts.fullscreen
---  * TilingWindowManager.layouts.tall
---  * TilingWindowManager.layouts.wide
obj.layouts = {
    floating = "Floating",
    fullscreen = "Fullscreen",
    tall = "Tall",
    wide = "Wide",
}

--- TilingWindowManager.enabledLayouts
--- Variable
--- A table holding all enabled tiling layouts.
---
--- Notes:
--- Can be set as a config option in the spoons `start()` method.
obj.enabledLayouts = {obj.layouts.floating} 

--- TilingWindowManager.fullscreenRightApps
--- Variable
--- A table holding names of applications which shall be positioned
--- on right half of screen only for fullscreen layout.
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

--- TilingWindowManager.displayLayoutOnLayoutChange
--- Variable
--- If true: show `hs.alert()` with layout name when changing layout.
---
--- Notes:
--- Can be set as a config option in the spoons `start()` method.
obj.displayLayoutOnLayoutChange = false


-- Tiling strategy --------------------------------------------------

--- TilingWindowManager.tilingStrategy
--- Variable
--- A table holding everything necessary for each layout.
--- 
--- The table key is a tiling layout, as per 
--- `TilingWindowManager.layouts`.
--- 
--- The table value for each layout is a table with these keys:
---  * tile(windows) - a function to move windows in place.
---  * symbol - a string formatted as ASCII image, the layouts icon.
obj.tilingStrategy = {}

obj.tilingStrategy[obj.layouts.floating] = {
    tile = function(windows, layoutConfig)
        obj.log.d("> tile", inspect(layoutConfig))
        -- do nothing 
        obj.log.d("< tile")
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

obj.tilingStrategy[obj.layouts.fullscreen] = {
    tile = function(windows, layoutConfig)
        obj.log.d("> tile", obj.layouts.fullscreen)
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
        obj.log.d("< tile", obj.layouts.fullscreen)
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

obj.tilingStrategy[obj.layouts.tall] = {
    tile = function(windows, layoutConfig)
        obj.log.d("> tile", inspect(layoutConfig))
        if #windows > 0 then
            local mainNumberWindows = math.min(
                layoutConfig.mainNumberWindows or 1,
                #windows)
            local stackNumberWindows = 0
            local mainRatio = 1
            if #windows > mainNumberWindows then -- check if stack
                mainRatio = layoutConfig.mainRatio or 0.5
                stackNumberWindows = #windows - mainNumberWindows
            end

            for i, window in ipairs(windows) do
                local frame = window:screen():frame()
                if i <= layoutConfig.mainNumberWindows then -- main
                    frame.w = frame.w * mainRatio
                    frame.h = frame.h / mainNumberWindows
                    frame.y = frame.y + frame.h * (i - 1)
                else -- stack
                    frame.x = frame.x + (frame.w * mainRatio)
                    frame.h = frame.h / stackNumberWindows
                    frame.y = frame.y + 
                        frame.h * (i - mainNumberWindows - 1)
                    frame.w = frame.w * (1 - mainRatio)
                end
                window:setFrame(frame)
            end
        end
        obj.log.d("< tile")
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

obj.tilingStrategy[obj.layouts.wide] = {
    tile = function(windows, layoutConfig)
        obj.log.d("> tile", inspect(layoutConfig))
        if #windows > 0 then
            local mainNumberWindows = math.min(
                layoutConfig.mainNumberWindows or 1,
                #windows)
            local stackNumberWindows = 0
            local mainRatio = 1
            if #windows > mainNumberWindows then -- check if stack
                mainRatio = layoutConfig.mainRatio or 0.5
                stackNumberWindows = #windows - mainNumberWindows
            end

            for i, window in ipairs(windows) do
                local frame = window:screen():frame()
                if i <= layoutConfig.mainNumberWindows then -- main
                    frame.h = frame.h * mainRatio
                    frame.w = frame.w / mainNumberWindows
                    frame.x = frame.x + frame.w * (i - 1)
                else -- stack
                    frame.y = frame.y + (frame.h * mainRatio)
                    frame.w = frame.w / stackNumberWindows
                    frame.x = frame.x + 
                        frame.w * (i - mainNumberWindows - 1)
                    frame.h = frame.h * (1 - mainRatio)
                end
                window:setFrame(frame)
            end
        end
        obj.log.d("< tile")
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
    settingsData = {}
    for spaceID, space in pairs(obj.spaces) do
        local sID = tostring(spaceID)
        obj.log.d(spaceID, sID, inspect(space))
        settingsData[sID] = {}
        settingsData[sID].layout = space.layout
        settingsData[sID].mainNumberWindows = space.mainNumberWindows
        settingsData[sID].mainRatio = space.mainRatio
    end
    -- obj.log.d(inspect(settingsData))
    settings.clear("TilingWindowManager")
    settings.set("TilingWindowManager", settingsData)
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
    local settingsInt = {}
    local settingsData = settings.get("TilingWindowManager")
    -- obj.log.d(inspect(settingsData))
    if settingsData then 
        for spaceID, setting in pairs(settingsData) do
            if setting.layout and
                    setting.mainNumberWindows and
                    setting.mainRatio then
                sID = tonumber(spaceID)
                settingsInt[sID] = {}
                settingsInt[sID].layout = setting.layout
                settingsInt[sID].mainNumberWindows = 
                    setting.mainNumberWindows
                settingsInt[sID].mainRatio = 
                    setting.mainRatio
            end
        end
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
    space.layout = obj.enabledLayouts[1]
    space.tilingWindows = {}
    space.mainNumberWindows = 1
    space.mainRatio = 0.5
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
    local settingsData = obj.loadSettings()

    obj.spaces = {} -- we will re-build this now

    local screen = spaces.mainScreenUUID() -- TODO multi-monitor
    for space_number, spaceID in pairs(spaces.layout()[screen]) do
        local space = obj.initSpace()
        if settingsData and settingsData[spaceID] then
            local layout = settingsData[spaceID].layout
            if fnutils.contains(obj.enabledLayouts, layout) then
                space.layout = layout
            end
            space.mainNumberWindows = 
                settingsData[spaceID].mainNumberWindows
            space.mainRatio = settingsData[spaceID].mainRatio
        end
        obj.spaces[spaceID] = space
    end
    -- obj.log.d(inspect(obj.spaces))
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
-- Returns:
--  * None
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

-- Internal: Gets the tiling layout of the current macOS space
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table with layout configuration, see `initSpace()`
function obj.layoutConfigCurrentSpace()
    obj.log.d("> layoutConfigurationCurrentSpace")
    local currentSpaceID = spaces.activeSpace()
    local layoutConfig = obj.spaces[currentSpaceID]
    obj.log.d("< layoutConfigurationCurrentSpace", inspect(layoutConfig))
    return layoutConfig
end

-- Internal: Sets the tiling layout of the current space.
-- 
-- Parameters:
--  * layout - String as per `obj.enabledLayouts`
--
-- Returns:
--  * None
function obj.setLayoutCurrentSpace(layout)
    obj.log.d("> setLayoutCurrentSpace", layout)
    if fnutils.contains(obj.enabledLayouts, layout) then
        local currentSpaceID = spaces.activeSpace()
        obj.spaces[currentSpaceID].layout = layout
    else
        obj.log.d("Tiling layout not enabled:", layout)
    end

    if obj.displayLayoutOnLayoutChange then obj.displayLayout() end
    
    obj.saveSettings()
    obj.log.d("> setLayoutCurrentSpace")
end

-- TODO
function obj.setMainRatioRelative(ratio)
    obj.log.d("> setMainRatioRelative", ratio)
    local currentSpaceID = spaces.activeSpace()
    obj.spaces[currentSpaceID].mainRatio = 
        obj.spaces[currentSpaceID].mainRatio + ratio
    if obj.spaces[currentSpaceID].mainRatio < 0.2 then 
        obj.spaces[currentSpaceID].mainRatio = 0.2
    end
    if obj.spaces[currentSpaceID].mainRatio > 0.8 then 
        obj.spaces[currentSpaceID].mainRatio = 0.8
    end
    obj.saveSettings()
    obj.log.d("> setMainRatioRelative")
end

-- TODO
function obj.setMainWindowsRelative(i)
    obj.log.d("> setMainWindowsRelative", i)
    local currentSpaceID = spaces.activeSpace()
    obj.spaces[currentSpaceID].mainNumberWindows = 
        obj.spaces[currentSpaceID].mainNumberWindows + i
    if obj.spaces[currentSpaceID].mainNumberWindows < 1 then 
        obj.spaces[currentSpaceID].mainNumberWindows = 1
    end
    if obj.spaces[currentSpaceID].mainNumberWindows > 10 then 
        obj.spaces[currentSpaceID].mainNumberWindows = 10
    end
    obj.saveSettings()
    obj.log.d("> setMainRatioRelative")
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
    -- Add new windows to ordered windows, at top 
    local tileableWindows = fnutils.concat(
        newVisibleWindows,
        orderedVisibleWindows) 
    -- filter out configured "always float" app windows
    local tilingWindows = fnutils.filter(tileableWindows, function(w)
        return (not fnutils.contains(
            obj.floatApps, 
            w:application():name()))
    end)

    obj.spaces[currentSpaceID].tilingWindows = tilingWindows

    obj.logWindows("Tileable Windows: ", tilingWindows)
    obj.log.d("< tileableWindowsCurrentSpace", "(...)")
    return tilingWindows
end

-- Internal: tiles the current macOS space, i.e. re-arranges windows
-- according to the selected layout for that space.
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
    local windows = windows or obj.tileableWindowsCurrentSpace()
    local layoutConfig = obj.layoutConfigCurrentSpace()
    obj.tilingStrategy[layoutConfig.layout].tile(windows, layoutConfig)
    obj.log.d("< tileCurrentSpace")
end

-- Internal: Callback for hs.spaces.watcher, is triggered when
-- user switches to another space, tiles space and updates menu.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function obj.switchedToSpace(number)
    obj.log.d("> switchedToSpace", number)
    obj.tileCurrentSpace() -- in case window configuration has changed
    obj.updateMenu()
    obj.log.d("< switchedToSpace")
end


-- Move focus and swap windows --------------------------------------

--- TilingWindowManager.focusRelative(relativeIndex) -> nil
--- Function
--- Change window focus. Newly focussed window is determined by relative 
--- distance `relativeIndex` from current window in orderedtileable 
--- windows table.  Wraps around if current window is first or last window.
---
--- Parameters:
---  * relativeIndex - positive moves focus next, negative moves
---    focus previous.
---
--- Returns:
---  * None
function obj.focusRelative(relativeIndex)
    obj.log.d("> focusRelative", relativeIndex)
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            -- offset the table starting with 1 index for modulo
            local j = (i - 1 + relativeIndex) % #windows + 1
            windows[j]:focus():raise()
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< focusRelative")
end

--- TilingWindowManager.moveRelative(relativeIndex) -> nil
--- Function
--- Moves window to different position in table of tileable windows.
--- Wraps around if current window is first or last window. 
---
--- Tiles the current space.
---
--- Parameters:
---  * relativeIndex - positive moves window next, negative moves
---    window previous.
---
--- Returns:
---  * None
function obj.moveRelative(relativeIndex)
    obj.log.d("> moveRelative", relativeIndex)
    local windows = obj.tileableWindowsCurrentSpace()
    if #windows > 1 then
        i = fnutils.indexOf(windows, window.focusedWindow()) 
        if i then
            -- offset the table starting with 1 index for modulo
            local j = (i - 1 + relativeIndex) % #windows + 1
            windows[i], windows[j] = windows[j], windows[i]
            obj.tileCurrentSpace(windows)
        else
            obj.log.d("Window is floating")
        end
    end
    obj.log.d("< swapNext")
end

--- TilingWindowManager.swapFirst() -> nil
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
                obj.moveRelative(1)
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

--- TilingWindowManager.toggleFirst() -> nil
--- Function
--- 
--- If current window is first window:
--- Swaps window order and position with second window in tileable windows.
---
--- If current window is not first window:
--- Makes current window the first window. Previous first window becomes
--- the second window.
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
                obj.moveRelative(1)
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
-- user selects a layout in menu bar, tiles space and updates menu.
--
-- Parameters:
--  * modifiers - koyboard modifiers
--  * menuItem - table with selected menu item
--
-- Returns:
--  * None
function obj.switchLayout(modifiers, menuItem)
    obj.log.d("> switchLayout", 
        inspect(modifiers), inspect(menuItem))
    obj.setLayoutCurrentSpace(menuItem.title)
    obj.tileCurrentSpace()
    obj.updateMenu()
    obj.log.d("< switchLayout")
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
    local layoutCurrentSpace = obj.layoutConfigCurrentSpace().layout
    local menuTable = {}
    for i, layout in ipairs(obj.enabledLayouts) do
        local layout = {}
        layout.title = layout
        if not obj.tilingStrategy[layout].icon then
            -- cache icons
            obj.tilingStrategy[layout].icon = 
                iconFromASCII((obj.tilingStrategy[layout].symbol))
        end
        layout.image = obj.tilingStrategy[layout].icon 
        if layout == layoutCurrentSpace then
            layout.checked = true
        end
        layout.fn = obj.switchLayout
        table.insert(menuTable, layout)
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
        obj.tilingStrategy[obj.layoutConfigCurrentSpace().layout].symbol)
    obj.menubar:setMenu(obj.menuTable)
    obj.log.d("< updateMenu")
end

--- TilingWindowManager.displayLayout() -> nil
--- Function
--- Shows an alert displaying the current spaces current layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj.displayLayout()
    obj.log.d("> displayLayout")
    local layoutConfig = obj.layoutConfigCurrentSpace()
    hs.alert(layoutConfig.layout.." Layout", 1)
    obj.log.d("Layout:", layoutConfig.layout)
    obj.log.d("#Main windows:", layoutConfig.mainNumberWindows)
    obj.log.d("Main ratio:", layoutConfig.mainRatio)
    obj.log.d("< displayLayout")
end

function obj.functionTimer(f)
    obj.log.d("> functionTimer")
    ttime = os.time()
    ctime = os.clock()
    f()
    obj.log.d("< functionTimer", 
        "time:", os.time()-ttime, 
        "clock:", os.clock()-ctime)
end

-- Spoon methods ----------------------------------------------------

--- TilingWindowManager:bindHotkeys(mapping) -> self
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
---   * float - switch current space to float layout.
---   * fullscreen - switch current space to fullscreen layout.
---   * tall - switch current space to tall layout.
---   * wide - switch current space to wide layout.
---   * display - display current space layout.
---
--- Returns:
---  * The TilingWindowManager object
function obj:bindHotkeys(mapping)
    obj.log.d("> bindHotkeys", inspect(mapping))
    local def = {
        tile = function() obj.functionTimer(
                obj.tileCurrentSpace) 
            end,
        incMainRatio = function() obj.functionTimer(
                function()
                    obj.setMainRatioRelative(0.05)
                    obj.tileCurrentSpace()
                end) 
            end,
        decMainRatio = function() obj.functionTimer(
                function()
                    obj.setMainRatioRelative(-0.05)
                    obj.tileCurrentSpace()
                end) 
            end,
        incMainWindows = function() obj.functionTimer(
                function()
                    obj.setMainWindowsRelative(1)
                    obj.tileCurrentSpace()
                end) 
            end,
        decMainWindows = function() obj.functionTimer(
                function()
                    obj.setMainWindowsRelative(-1)
                    obj.tileCurrentSpace()
                end) 
            end,
        focusNext = function() obj.focusRelative(1) end,
        focusPrev = function() obj.focusRelative(-1) end,
        swapNext = function() obj.functionTimer(
                function() 
                    obj.moveRelative(1) 
                end)
            end,
        swapPrev = function() obj.functionTimer(
                function() 
                    obj.moveRelative(-1) 
                end)
            end,
        swapFirst = function() obj.functionTimer(
                obj.swapFirst)
            end,
        toggleFirst = function() obj.functionTimer(
                obj.toggleFirst)
            end,
        float = function()
            obj.setLayoutCurrentSpace(obj.layouts.float)
        end,
        fullscreen = function() obj.functionTimer(
                function()
                    obj.setLayoutCurrentSpace(obj.layouts.fullscreen)
                    obj.tileCurrentSpace()
                end)
            end,
        tall = function() obj.functionTimer(
                function()
                    obj.setLayoutCurrentSpace(obj.layouts.tall)
                    obj.tileCurrentSpace()
                end)
            end,
        wide = function() obj.functionTimer(
                function()
                    obj.setLayoutCurrentSpace(obj.layouts.wide)
                    obj.tileCurrentSpace()
                end)
            end,
        display = obj.displayLayout,
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

--- TilingWindowManager:start([config]) -> self
--- Method
--- Starts TilingWindowManager spoon
---
--- Parameters:
---  * config
---    A table with configuration options for the spoon.
---    These keys are recognized:
---   * dynamic - if true: dynamically tile windows.
---   * layouts - a table with all layouts to be enabled.
---   * fullscreenRightApps - a table with app names, to position
---     right half only in fullscreen layout.
---   * floatApp - a table with app names to always float.
---   * displayLayout - if true: show layout when switching tiling layout.
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

    if config.layouts then
        obj.enabledLayouts = config.layouts
    end

    if config.fullscreenRightApps then
        obj.fullscreenRightApps = config.fullscreenRightApps
    end

    if config.floatApps then
        obj.floatApps = config.floatApps
    end

    if config.displayLayout then obj.displayLayoutOnLayoutChange = true end

    obj.initSpaces() -- needs obj.enabledLayouts

    if config.menubar == true then
        obj.menubar = menubar.new()
        obj.updateMenu()
        obj.spacesWatcher = hs.spaces.watcher.new(
            obj.switchedToSpace):start()
    end

    obj.log.d("< start")
    return self
end

--- TilingWindowManager:stop() -> self
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

--- TilingWindowManager:setLogLevel(level) -> self
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
