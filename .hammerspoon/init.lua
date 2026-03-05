-- 영어 입력기 ID 설정 (가급적 상수로 관리)
local ENGLISH_SOURCE = "com.apple.keylayout.ABC"

local function switchToEnglish()
    if hs.keycodes.currentSourceID() ~= ENGLISH_SOURCE then
        -- 0.05초(50ms) 지연: 딜레이는 줄이고 안정성을 확보한 수치
        hs.timer.doAfter(0.05, function()
            hs.keycodes.currentSourceID(ENGLISH_SOURCE)
        end)
    end
end
-- 앱 변경 감지 워처
-- 전역 변수로 선언하여 가비지 컬렉션(GC)에 의해 해제되는 것을 방지
appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    if eventType == hs.application.watcher.activated then
        -- appName 대신 bundleID를 사용하는 것이 더 정확합니다 (iTerm2의 경우)
        local bundleID = appObject:bundleID()
        
        if appName == "iTerm2" or bundleID == "com.googlecode.iterm2" then
            switchToEnglish()
        end
    end
end)

appWatcher:start()
