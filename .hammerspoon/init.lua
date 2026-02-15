local function switchToEnglish()
  -- 영어 입력기의 ID: ABC는 "com.apple.keylayout.ABC"
  hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
end

-- 앱 변경 감지
appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
  if eventType == hs.application.watcher.activated then
    if appName == "iTerm2" then
      switchToEnglish()
    end
  end
end)

appWatcher:start()
