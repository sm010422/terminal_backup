# 백그라운드·상주 프로세스

이 터미널 환경(tmux + Claude Code)이 알아서 실행하는 것들을 언제 실행되는지, 비용은 얼마나 드는지와 함께 정리한 문서입니다.
모두 이 Mac 안에서만 실행됩니다. 모델 토큰을 쓰는 것은 `kg-sync` 훅 하나뿐입니다(아래 참고).

영문판: [background-processes.md](background-processes.md)

마지막 점검: 2026-11-07

## 요약

| 종류 | 대상 | 언제 | 비용 |
|---|---|---|---|
| 상주 | tmux 서버 | tmux 세션이 하나라도 있는 동안 | — |
| 상주 | tmux-agent-sidebar TUI (창마다 하나) | 사이드바 pane이 열려 있을 때만 (`prefix + e` / `prefix + E`) | 1초마다 갱신, 매번 `ps`로 백그라운드 작업 확인 |
| 주기 실행 | Powerline 상태바 왼쪽/오른쪽 (`powerline` Python) | `status-interval`(2초)마다 2개 | 주기 실행 중 가장 무거움 (매번 Python 시작) |
| 주기 실행 | `tmux-continuum`의 `continuum_save.sh` | status-right를 통해 2초마다 확인, 실제 저장은 15분마다 | 확인 비용은 아주 작음, 15분마다 resurrect 저장 |
| 주기 실행 | `~/.tmux/scripts/agent-dot.sh` | 2초마다 창마다 한 번 | `tmux list-panes` 한 번 |
| 이벤트 | tmux 훅 | 새 창 / pane 포커스 / pane 종료 / resurrect 저장·복원 | 잠깐 실행되고 끝남 |
| 이벤트 | Claude Code 훅 | 도구 사용, 입력 전송, 세션 시작·종료, 컨텍스트 압축 | 잠깐 실행되고 끝남. `kg-sync`는 분리된 headless Claude를 띄움 |
| 직접 실행 | 키 바인딩 (`prefix + T`, `prefix + E` 등) | 누를 때만 | — |

`.tmux.conf`가 띄우는 상시 실행 보조 데몬은 **없습니다.** `run-shell -b`로 도는 루프도, `powerline-daemon`도 없습니다.

## 주기 실행: tmux 상태바 (`status-interval 2`)

tmux는 상태바 안의 `#(...)` 명령을 갱신 주기마다 다시 실행합니다. 각각 잠깐 실행되고 끝나는 프로세스입니다.

- **Powerline** (`status-left`, `status-right`): `powerline tmux left|right`를 실행합니다. 매번 Python 프로세스를 새로 띄우고, 2초마다 두 번 실행됩니다.
  `powerline-daemon -q`를 켜면 이 호출이 가벼워집니다. CPU가 신경 쓰이면 `status-interval`을 늘리는 방법도 있습니다.
- **continuum_save.sh** (tmux-continuum이 `status-right` 앞에 붙임): 갱신 때마다 마지막 저장 시각을 확인하고,
  `@continuum-save-interval`(15분)마다 tmux-resurrect 저장을 실행합니다. 저장 후 훅이 `~/.tmux/window-colors.txt`를 쓰고,
  resurrect 저장 파일은 최신 5개만 남깁니다.
- **agent-dot.sh** (모든 탭 포맷의 `@agent_dot`): 창마다 `tmux list-panes`를 한 번 실행해서 에이전트 상태 점을 출력합니다.

## 이벤트로 실행: tmux 훅과 키 바인딩

| 계기 | 실행하는 것 | 출처 |
|---|---|---|
| `after-new-window[90]` | `sidebar-all.sh new-window`: `prefix + E` 모드가 켜져 있을 때만 사이드바 생성 | `.tmux.conf` |
| `after-select-pane`, `after-select-window` | 열려 있는 사이드바에 `SIGUSR1`을 보내 다시 그리게 함 | tmux-agent-sidebar |
| `pane-exited` | `tmux-agent-sidebar auto-close`: 사이드바만 남은 창을 닫음 | tmux-agent-sidebar |
| resurrect 저장 후 / 복원 후 | 창별 탭 색 저장 / 다시 적용 | `.tmux.conf` |
| `prefix + T` | `sesh` 세션 선택기 (fzf 팝업) | `.tmux.conf` |
| `prefix + E` / `prefix + e` | 모든 창 / 이 창의 사이드바 켜고 끄기 | `.tmux.conf` / 플러그인 |

## 이벤트로 실행: Claude Code 훅

훅은 그 훅을 발생시킨 Claude Code 세션의 자식 프로세스로 실행됩니다.

| 이벤트 | 훅 | 비고 |
|---|---|---|
| 대부분의 이벤트 | tmux-agent-sidebar `hook.sh` (플러그인) | tmux pane에 `@pane_status`, `@pane_subagents` 등을 기록 |
| PreToolUse / PostToolUse / UserPromptSubmit / SessionStart / PreCompact | `~/.tmux/scripts/agent-phase.sh` | `@pane_phase`를 기록. `claude/settings.json`에 연결돼 있음 (변경 후 새로 시작한 세션부터 적용) |
| PreToolUse (Grep, Glob, Bash) / PostToolUse (Bash) | GitNexus `gitnexus-hook.cjs` | 해당 도구를 쓸 때마다 Node 프로세스 실행 |
| SessionStart | `herdr-agent-state.sh session` | |
| SessionEnd | `~/.claude/hooks/kg-sync.sh` | 끝난 대화 기록을 읽어 personal-kg에 기록하는 **분리된 headless `claude -p`**. 세션이 끝난 뒤에도 잠시 실행되며 **모델 토큰을 사용**함. 로그: `~/.claude/kg-sync.log` |

## 일부러 뺀 것

- **TokenEater tmux watcher** (`~/Library/Application Support/com.tokeneater.shared/tmux-watcher.sh`):
  TokenEater에서 세션을 클릭하면 해당 tmux pane으로 이동할 수 있도록, trigger 파일을 0.3초마다 확인하는 bash 루프입니다.
  앱이 이 루프를 스스로 띄우지 않았고, 이 기능 하나 때문에 상주 루프를 두는 건 가치가 없다고 판단했습니다.
  그래서 실행하지 않으며, `update-environment TERM_PROGRAM` 줄도 함께 뺐습니다.
  따라서 TokenEater에서 세션을 클릭해도 tmux pane은 이동하지 않습니다.

## 지금 무엇이 실행 중인지 확인하기

```sh
# tmux 서버가 지금 띄운 프로세스 전부 (pane의 셸은 제외)
srv=$(tmux display -p '#{pid}'); ps -Ao pid,ppid,etime,command | awk -v p=$srv '$2==p' | grep -v -E 'zsh$'

# 떠 있으면 안 되는 상주 보조 프로세스
pgrep -fl 'tmux-watcher|powerline-daemon'

# tmux에 현재 등록된 훅
tmux show-hooks -g
```
