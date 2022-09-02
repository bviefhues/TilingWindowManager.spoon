# TilingWindowManager

macOS Tiling Window Manager. Spoon on top of Hammerspoon.

Example `~/.hammerspoon/init.lua` configuration:

```
hs.loadSpoon("TilingWindowManager")
    :setLogLevel("debug")
    :bindHotkeys({
        tile =           {hyper, "t"},
        incMainRatio =   {hyper, "p"},
        decMainRatio =   {hyper, "o"},
        incMainWindows = {hyper, "i"},
        decMainWindows = {hyper, "u"},
        focusNext =      {hyper, "k"},
        focusPrev =      {hyper, "j"},
        swapNext =       {hyper, "l"},
        swapPrev =       {hyper, "h"},
        toggleFirst =    {hyper, "return"},
        tall =           {hyper, ","},
        talltwo =        {hyper, "m"},
        fullscreen =     {hyper, "."},
        wide =           {hyper, "-"},
        display =        {hyper, "d"},
    })
    :start({
        menubar = true,
        dynamic = true,
        layouts = {
            spoon.TilingWindowManager.layouts.fullscreen,
            spoon.TilingWindowManager.layouts.tall,
            spoon.TilingWindowManager.layouts.talltwo,
            spoon.TilingWindowManager.layouts.wide,
            spoon.TilingWindowManager.layouts.floating,
        },
        displayLayout = true,
        floatApps = {
            "com.apple.systempreferences",
            "com.apple.ActivityMonitor",
            "com.apple.Stickies",
        }
    })
```

## API Overview
* Variables - Configurable values
  * [displayLayoutOnLayoutChange](#displayLayoutOnLayoutChange)
  * [enabledLayouts](#enabledLayouts)
  * [floatApps](#floatApps)
  * [fullscreenRightApps](#fullscreenRightApps)
  * [layouts](#layouts)
  * [tilingStrategy](#tilingStrategy)
* Functions - API calls offered directly by the extension
  * [displayLayout](#displayLayout)
  * [focusRelative](#focusRelative)
  * [moveRelative](#moveRelative)
  * [swapFirst](#swapFirst)
  * [toggleFirst](#toggleFirst)
* Methods - API calls which can only be made on an object returned by a constructor
  * [bindHotkeys](#bindHotkeys)
  * [setLogLevel](#setLogLevel)
  * [start](#start)
  * [stop](#stop)

## API Documentation

### Variables

| [displayLayoutOnLayoutChange](#displayLayoutOnLayoutChange)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.displayLayoutOnLayoutChange`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | If true: show `hs.alert()` with layout name when changing layout.                                                                     |
| **Notes**                                   | <ul><li>Can be set as a config option in the spoons `start()` method.</li></ul>                |

| [enabledLayouts](#enabledLayouts)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.enabledLayouts`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | A table holding all enabled tiling layouts.                                                                     |
| **Notes**                                   | <ul><li>Can be set as a config option in the spoons `start()` method.</li><li>Default: `TilingWindowManager.layouts.floating`</li></ul>                |

| [floatApps](#floatApps)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.floatApps`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | A table holding bundleID's of applications which shall not be tiled.                                                                     |
| **Notes**                                   | <ul><li>* These application's windows are never modified by the spoon.</li><li>* Can be set as a config option in the spoons `start()` method.</li></ul>                |

| [fullscreenRightApps](#fullscreenRightApps)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.fullscreenRightApps`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | A table holding names of applications which shall be positioned on right half of screen only for fullscreen layout.                                                                     |
| **Notes**                                   | <ul><li>Can be set as a config option in the spoons `start()` method.</li></ul>                |

| [layouts](#layouts)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.layouts`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | A table holding all known tiling layouts. Maps keys to descriptive strings. The strings show up in the user interface.                                                                     |

| [tilingStrategy](#tilingStrategy)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.tilingStrategy`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | A table holding everything necessary for each layout.                                                                     |
| **Notes**                                   | <ul><li>The table key is a tiling layout, as per </li><li>`TilingWindowManager.layouts`.</li><li></li><li>The table value for each layout is a table with these keys:</li><li>tile(windows) - a function to move windows in place.</li><li>symbol - a string formatted as ASCII image, the layouts icon.</li></ul>                |

### Functions

| [displayLayout](#displayLayout)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.displayLayout() -> nil`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Shows an alert displaying the current spaces current layout.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>None</li></ul>          |
| **Notes**                                   | <ul></ul>                |

| [focusRelative](#focusRelative)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.focusRelative(relativeIndex) -> nil`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Change window focus.                                                                      |
| **Parameters**                              | <ul><li>relativeIndex - positive moves focus next, negative moves focus previous.</li></ul> |
| **Returns**                                 | <ul><li>None</li></ul>          |
| **Notes**                                   | <ul><li>Newly focussed window is determined by relative </li><li>distance `relativeIndex` from current window in ordered tileable </li><li>windows table.  Wraps around if current window is first or last window.</li><li>`+1` focuses next window, `-1` focuses previous window.</li></ul>                |

| [moveRelative](#moveRelative)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.moveRelative(relativeIndex) -> nil`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Moves window to different position in table of tileable windows.                                                                     |
| **Parameters**                              | <ul><li>relativeIndex - positive moves window next, negative moves window previous.</li></ul> |
| **Returns**                                 | <ul><li>None</li></ul>          |
| **Notes**                                   | <ul><li>Wraps around if current window is first or last window. </li><li>Tiles the current space.</li></ul>                |

| [swapFirst](#swapFirst)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.swapFirst() -> nil`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Swaps first window.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>None</li></ul>          |
| **Notes**                                   | <ul><li>* If current window is first window:</li><li>  Swaps window order and position with second window in tileable </li><li>  windows.</li><li>* If current window is not first window:</li><li>  Swaps window order and position with first window in tileable </li><li>  windows.</li><li>* Tiles the current space.</li></ul>                |

| [toggleFirst](#toggleFirst)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager.toggleFirst() -> nil`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Toggles first window.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>None</li></ul>          |
| **Notes**                                   | <ul><li>* If current window is first window:</li><li>  Swaps window order and position with second window in tileable </li><li>  windows.</li><li>* If current window is not first window:</li><li>  Makes current window the first window. Previous first window becomes</li><li>  the second window.</li><li>* Tiles the current space.</li></ul>                |

### Methods

| [bindHotkeys](#bindHotkeys)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager:bindHotkeys(mapping) -> self`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Binds hotkeys for TilingWindowManager                                                                     |
| **Parameters**                              | <ul><li>mapping - A table containing hotkey modifier/key details for the following items:
  tile - Manually tiles the current macOS space.
  focusNext - move focus to next window.
  focusPrev - move focus to previous window.
  swapNext - swap current window with next window.
  swapPrev - swap current window with previous window.
  swapFirst - swap current window with first window.
  toggleFirst - Toggle current window with first window.
  float - switch current space to float layout.
  fullscreen - switch current space to fullscreen layout.
  tall - switch current space to tall layout.
  wide - switch current space to wide layout.
  display - display current space layout.</li></ul> |
| **Returns**                                 | <ul><li>The TilingWindowManager object</li></ul>          |
| **Notes**                                   | <ul></ul>                |

| [setLogLevel](#setLogLevel)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager:setLogLevel(level) -> self`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Set the log level of the spoon logger.                                                                     |
| **Parameters**                              | <ul><li>Log level</li></ul> |
| **Returns**                                 | <ul><li>The TilingWindowManager object</li></ul>          |
| **Notes**                                   | <ul></ul>                |

| [start](#start)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager:start([config]) -> self`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Starts TilingWindowManager spoon                                                                     |
| **Parameters**                              | <ul><li>config A table with configuration options for the spoon. These keys are recognized:
  dynamic - if true: dynamically tile windows.
  layouts - a table with all layouts to be enabled.
  fullscreenRightApps - a table with app names, to position right half only in fullscreen layout.
  floatApp - a table with app names to always float.
  displayLayout - if true: show layout when switching tiling layout.
  menubar - if true: enable menubar item.</li></ul> |
| **Returns**                                 | <ul><li>The TilingWindowManager object</li></ul>          |
| **Notes**                                   | <ul></ul>                |

| [stop](#stop)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `TilingWindowManager:stop() -> self`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Stops TilingWindowManager spoon                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>The TilingWindowManager object</li></ul>          |
| **Notes**                                   | <ul></ul>                |

