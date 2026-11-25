-- English input source ID (kept as a constant)
local ENGLISH_SOURCE = "com.apple.keylayout.ABC"

local function switchToEnglish()
    if hs.keycodes.currentSourceID() ~= ENGLISH_SOURCE then
        -- 0.05s (50ms) delay: short enough to feel instant, long enough to switch reliably
        hs.timer.doAfter(0.05, function()
            hs.keycodes.currentSourceID(ENGLISH_SOURCE)
        end)
    end
end
-- Watcher for app activation
-- Declared global so garbage collection (GC) does not release it
appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    if eventType == hs.application.watcher.activated then
        -- bundleID is more reliable than appName (e.g. for iTerm2)
        local bundleID = appObject:bundleID()
        
        if appName == "iTerm2" or bundleID == "com.googlecode.iterm2"
            or appName == "Ghostty" or bundleID == "com.mitchellh.ghostty" then
            switchToEnglish()
        end
    end
end)

appWatcher:start()
