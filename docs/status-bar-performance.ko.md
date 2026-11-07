# tmux 상태바 성능

tmux 상태바가 CPU를 얼마나 쓰는지, 그 비용을 줄이려고 무엇을 바꿨는지, 무엇을 그대로 두었는지 정리한 문서입니다.
여기서 바꾼 것들은 상태바의 겉모습이나 표시 내용을 바꾸지 않습니다.

영문판: [status-bar-performance.md](status-bar-performance.md)

측정: 2026-11-07 / 2026-11-08, macOS, tmux 3.8, 창 11개를 연 상태

## 왜 중요한가

tmux는 상태바 안의 `#(...)` 명령을 `status-interval`마다 다시 실행합니다. 실행할 때마다 프로세스를 새로 띄우므로,
화면에서 아무 일도 일어나지 않을 때도 이 비용이 계속 듭니다.

## 변경 전

`status-interval 2` (Powerline의 `powerline-base.conf`가 설정). 갱신 한 번에 드는 CPU 시간:

| 항목 | 갱신당 CPU | 비고 |
|---|---|---|
| Powerline 왼쪽 + 오른쪽 | 163ms | Python을 두 번 새로 띄움 (`powerline tmux left` / `right`), 데몬 없음 |
| `agent-dot.sh` × 창 11개 | 94ms | 창 하나당 약 9ms, 창이 늘수록 증가 |
| `continuum_save.sh` | 51ms | 15분 자동 저장 시각이 됐는지 확인 |
| **합계** | **2초마다 약 308ms** | **CPU 코어 하나의 약 15%를 계속 사용** |

이벤트가 있을 때만 실행되는 훅(사이드바 포커스 훅 약 11ms, `agent-phase.sh` 약 9ms)은 그대로 두었습니다.

## 바꾼 것

### 1. 에이전트 상태 점을 tmux 포맷으로 계산 (커밋 `1e8ab7e`)

창 탭의 에이전트 상태 점은 원래 갱신 때마다 창마다 `~/.tmux/scripts/agent-dot.sh <window_id>`를 한 번씩 실행했습니다.
이제는 같은 판단을 `.tmux.conf`의 tmux 포맷 옵션으로 하고, tmux 서버 안에서 계산합니다.

| 옵션 | 역할 |
|---|---|
| `@agent_codes` | `#{P:...}`로 창의 pane을 순회하면서 에이전트 pane마다 글자 하나를 냄 (E 오류, W 입력 대기, I 대기/백그라운드, S 서브에이전트, X 실행 중, T 생각 중, C 압축 중) |
| `@agent_state` | 우선순위 순서대로 `#{m:*E*,...}`를 확인해서 가장 높은 글자를 고름 |
| `@agent_tabbg` | 탭 배경색 (활성 탭 `colour31` / 창별 `@mycolor` / `colour233`) |
| `@agent_fg` | 상태 색. 탭 색과 같은 계열이면 `colour233` |
| `@agent_dot` | 실제 표시되는 점. 모든 탭 포맷이 `#{E:@agent_dot}`로 참조 |

- 결과: 갱신당 94ms → 0 (프로세스를 띄우지 않음). 캐시된 작업 결과 대신 다시 그릴 때마다 계산하므로, 창을 바꾸면 점도 바로 따라옵니다.
- 동작은 그대로: 300가지 조합(상태 10가지 × 탭 색 10가지, 활성/비활성 탭, 창 안의 두 번째 pane 포함)과
  지금 열려 있는 모든 창에서 예전 스크립트와 결과를 비교했고, 모두 같았습니다.
- `agent-dot.sh`는 삭제했습니다.

### 2. `status-interval 5`

Powerline 설정이 `status-interval 2`를 넣습니다. `.tmux.conf`에서 Powerline을 불러온 직후 덮어씁니다.

```tmux
# Powerline sets status-interval 2; refresh every 5s instead to cut its periodic CPU cost
set -g status-interval 5
```

- 결과: Powerline과 `continuum_save.sh`가 2.5배 덜 실행됩니다.
- 대가: 오른쪽의 시계·업타임·로드 평균이 최대 5초 늦게 갱신됩니다(예전에는 최대 2초).
  에이전트 상태 점은 다시 그릴 때(창 전환, 키 입력 등)마다 계산되고, 늦어도 다음 5초 갱신 때 반영됩니다.
  15분 자동 저장에는 영향이 없습니다.

## 변경 후

| 항목 | CPU | 주기 |
|---|---|---|
| Powerline 왼쪽 + 오른쪽 | 163ms | 5초마다 |
| `continuum_save.sh` | 51ms | 5초마다 |
| 에이전트 상태 점 | 약 0 | — |
| **합계** | **5초마다 약 214ms** | **CPU 코어 하나의 약 4%** |

초당 약 154ms에서 초당 약 43ms로, **약 72% 줄었습니다.**

## 바꾸지 않은 것 (나중에 고를 수 있는 것)

- **Powerline 상태바 구간을 tmux 기본 포맷으로 대체.** 남은 비용은 거의 다 Powerline입니다.
  날짜·시간·사용자 이름은 tmux에 내장돼 있고, 업타임과 로드 평균은 `uptime` 한 번이면 됩니다.
  비용이 몇 ms로 줄지만, 상태바 왼쪽/오른쪽 디자인을 새로 만들어야 해서 나중으로 미뤘습니다.
- **`powerline-daemon`.** Powerline 호출이 가벼워지지만 상주 프로세스가 생깁니다.
  이 환경은 상주 프로세스를 피하는 방향입니다([background-processes.ko.md](background-processes.ko.md) 참고).
- **`continuum_save.sh`.** tmux-continuum 플러그인의 일부라 그대로 두었습니다.

## 확인 방법

```sh
tmux show -g status-interval          # 5
pgrep -fl agent-dot                   # 아무것도 안 나와야 정상
# 창마다 에이전트 상태 점 (tmux 스타일 코드, 비어 있으면 에이전트 없음)
for w in $(tmux list-windows -a -F '#{window_id}'); do printf '%s %s\n' $w "$(tmux display -p -t $w '#{E:@agent_dot}')"; done
# Powerline 갱신 한 번의 CPU 시간
time (powerline tmux left >/dev/null; powerline tmux right >/dev/null)
```
