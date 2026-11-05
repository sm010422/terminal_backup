#!/bin/bash
# SessionEnd hook: read the finished session's transcript and record durable facts
# about the user in personal-kg, via a headless Claude that may only use four
# personal-kg tools (search + three writes; nothing can be deleted).
#
# - Runs detached: Claude Code does not wait for SessionEnd hooks to finish.
# - KG_SYNC_RUNNING stops the headless session's own SessionEnd from recursing.
# - personal-kg is registered at user scope, so the headless Claude inherits it
#   (and its token) without another config file.
# - Log: ~/.claude/kg-sync.log (what was written; the transcript itself is not logged).

[ -n "$KG_SYNC_RUNNING" ] && exit 0
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

INPUT=$(cat)
TRANSCRIPT=$(jq -r '.transcript_path // empty' <<<"$INPUT")
SESSION=$(jq -r '.session_id // "?"' <<<"$INPUT")
[ -f "$TRANSCRIPT" ] || exit 0

LOG="$HOME/.claude/kg-sync.log"
WORKDIR="$HOME/.claude/kg-sync"   # neutral cwd: no project CLAUDE.md gets loaded
MIN_USER_MESSAGES=${KG_SYNC_MIN_USER_MESSAGES:-3}
MIN_CHARS=${KG_SYNC_MIN_CHARS:-1500}   # env overrides are for testing
MAX_CHARS=60000

PROMPT='아래는 방금 끝난 Claude Code 세션의 대화다. 사용자(박상민)에 대해 오래 유지될 사실만 personal-kg에 반영해라.

넣을 것: 프로젝트의 시작·진행·완료, 기술 선택과 그 이유, 회사 지원 현황(회사·직무·단계), 진로·관심사 변화, 새로 익힌 기술.
넣지 말 것: 일회성 잡담, 코드·명령어·에러 같은 작업 세부, 이미 그래프에 있는 사실, 건강·재정·인증정보·식별번호.

규칙:
- 쓰기 전에 반드시 search로 기존 엔티티를 찾아 재사용한다. 새로 만들 때만 upsert_entity.
- 모든 쓰기에 provenance="inferred"를 쓴다.
- 확실하지 않으면 넣지 않는다. 넣을 게 없으면 아무것도 쓰지 않는다.
- 끝나면 무엇을 썼는지 한두 줄로만 답한다(없으면 "변경 없음").
- 기존 엔티티에 관계나 노트를 더하기 전에 get_context로 이미 있는 관계·노트를 확인한다. 같은 뜻이면 쓰지 않는다.'

(
  export KG_SYNC_RUNNING=1
  unset TMUX_PANE TMUX   # keep the headless claude out of tmux-agent-sidebar's pane state
  umask 077
  mkdir -p "$WORKDIR"
  cd "$WORKDIR" || exit 0

  TEXT=$(jq -r '
      select(.type == "user" or .type == "assistant")
      | (.type | ascii_upcase) as $who
      | .message.content
      | (if type == "string" then . else map(select(.type == "text") | .text) | join("\n") end) as $t
      | select($t != "" and ($t | startswith("<") | not))
      | "[\($who)] \($t)"' "$TRANSCRIPT" 2>/dev/null)
  USER_MSGS=$(grep -c '^\[USER\]' <<<"$TEXT")

  {
    echo "=== $(date '+%F %T') session=$SESSION user_msgs=$USER_MSGS chars=${#TEXT}"
    if [ "$USER_MSGS" -lt "$MIN_USER_MESSAGES" ] || [ "${#TEXT}" -lt "$MIN_CHARS" ]; then
      echo "skip: short session"
      exit 0
    fi
    tail -c "$MAX_CHARS" <<<"$TEXT" | claude -p "$PROMPT" \
      --model sonnet \
      --tools "" \
      --allowedTools "mcp__personal-kg__search,mcp__personal-kg__get_context,mcp__personal-kg__list_entities,mcp__personal-kg__upsert_entity,mcp__personal-kg__add_relation,mcp__personal-kg__add_note" \
      --no-session-persistence
    echo "exit=$?"
  } >>"$LOG" 2>&1
) </dev/null >/dev/null 2>&1 &
disown
exit 0
