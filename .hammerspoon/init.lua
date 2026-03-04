-- 영어 입력기 ID 설정 (가급적 상수로 관리)
local ENGLISH_SOURCE = "com.apple.keylayout.ABC"

-- 입력 소스를 변경하는 함수 (안정성 강화)
local function switchToEnglish()
    -- 현재 소스를 확인하여 이미 영어라면 중복 실행 방지
    if hs.keycodes.currentSourceID() ~= ENGLISH_SOURCE then
        -- 시스템 부하를 줄이기 위해 아주 짧은 지연 후 실행 (안정성 핵심)
        hs.timer.doAfter(0.1, function()
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

-- 설정 재발동 알림 (선택 사항)
hs.alert.show("Hammerspoon Config Loaded")
