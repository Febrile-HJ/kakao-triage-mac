#!/bin/bash
# 카톡 스킬(kakao-triage) 설치
# 1) 이 맥 확인 → 2) 실행 파일(kakao_ax) 받기·해시 확인 → 3) ~/kakao-triage 에 두기
# → 4) AI 비서 스킬 폴더에 SKILL.md 넣기 → 5) 손쉬운 사용 권한 확인(없으면 설정 화면 열기)
# 관리자 암호는 묻지 않습니다. 모든 파일은 내 홈 폴더 안에만 둡니다.
set -euo pipefail

REPO="Febrile-HJ/kakao-triage-mac"
RAW="https://raw.githubusercontent.com/$REPO/main"
REL="https://github.com/$REPO/releases/latest/download"
DEST="$HOME/kakao-triage"
LOCAL="${KT_LOCAL:-}"   # 시험용: 받을 파일이 든 폴더. 비워 두면 인터넷에서 받는다.

say()  { printf '%s\n' "$*"; }
fail() { printf '\n설치를 멈췄습니다: %s\n' "$*" >&2; exit 1; }
fetch() { # fetch <원본 이름> <저장 경로> <받을 곳: raw|rel>
  if [ -n "$LOCAL" ]; then cp "$LOCAL/$1" "$2"; return; fi
  if [ "$3" = "rel" ]; then curl -fsSL "$REL/$1" -o "$2"; else curl -fsSL "$RAW/$1" -o "$2"; fi
}

say "== 카톡 스킬 설치 =="

# 1) 이 맥 확인
arch="$(uname -m)"
ver="$(sw_vers -productVersion)"
major="${ver%%.*}"
say "이 맥: $arch, macOS $ver"
if [ "$arch" = "x86_64" ] && [ "$major" -lt 13 ]; then
  fail "인텔 맥은 macOS 13 이상이 필요합니다. 지금 macOS $ver 입니다."
fi
if [ "$major" -lt 11 ]; then
  fail "macOS 11 이상이 필요합니다. 지금 macOS $ver 입니다."
fi
if [ ! -d "/Applications/KakaoTalk.app" ]; then
  say "알림: 응용 프로그램 폴더에 카카오톡이 없습니다. App Store에서 카카오톡을 설치하세요. 설치는 계속합니다."
fi

# 2) 실행 파일 받기와 해시 확인
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
say "실행 파일을 받습니다..."
fetch "kakao_ax-macos.zip" "$tmp/kakao_ax-macos.zip" rel || fail "실행 파일을 받지 못했습니다. 인터넷 연결을 확인하세요."
fetch "SHA256SUMS" "$tmp/SHA256SUMS" rel || fail "해시 파일을 받지 못했습니다."
( cd "$tmp" && shasum -a 256 -c SHA256SUMS >/dev/null ) || fail "받은 파일의 SHA-256이 맞지 않습니다. 넣지 않았습니다."
ditto -x -k "$tmp/kakao_ax-macos.zip" "$tmp/x"

# 3) ~/kakao-triage 에 두기 (제외 방 목록과 읽은 결과는 그대로 둔다)
mkdir -p "$DEST/out"
install -m 755 "$tmp/x/kakao_ax" "$DEST/kakao_ax"
xattr -dr com.apple.quarantine "$DEST/kakao_ax" 2>/dev/null || true
fetch "skill/SKILL.md" "$DEST/SKILL.md" raw || fail "스킬 파일을 받지 못했습니다."
fetch "find_room.sh" "$DEST/find_room.sh" raw || fail "방 찾기 파일을 받지 못했습니다."
chmod 755 "$DEST/find_room.sh"
if [ ! -f "$DEST/exclude_rooms.txt" ]; then
  fetch "exclude_rooms.txt" "$DEST/exclude_rooms.txt" raw || true
fi
chmod 700 "$DEST/out"
say "설치한 곳: $DEST ($("$DEST/kakao_ax" version))"

# 4) AI 비서 스킬 폴더에 SKILL.md 넣기
put_skill() { mkdir -p "$1" && cp "$DEST/SKILL.md" "$1/SKILL.md" && say "스킬 넣음: $2 ($1)"; }
found=0
if [ -d "$HOME/.claude" ]; then put_skill "$HOME/.claude/skills/kakao-triage" "Claude Code"; found=1; fi
for d in "$HOME"/.aside/u/*/skills; do
  [ -d "$d" ] || continue
  put_skill "$d/user/kakao-triage" "Aside"; found=1
done
if [ "$found" = 0 ]; then
  say "알림: Claude Code·Aside 스킬 폴더를 찾지 못했습니다. 쓰는 AI 비서에게 $DEST/SKILL.md 를 읽고 따르라고 말하세요."
fi

# 5) 손쉬운 사용 권한 확인
say ""
set +e
"$DEST/kakao_ax" windows >/dev/null 2>"$tmp/check.txt"
code=$?
set -e
if [ "$code" = 2 ]; then
  say "손쉬운 사용 권한이 아직 없습니다. 설정 화면을 엽니다."
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
  say "다음 순서로 하세요:"
  say "  1. 목록에서 「터미널」을 켭니다. AI 비서를 돌리는 앱(Claude, Aside 등)도 켭니다."
  say "  2. 목록에 없으면 아래 「+」를 눌러 그 앱을 넣습니다. 터미널은 응용 프로그램 > 유틸리티 안에 있습니다."
  say "  3. 켠 앱을 ⌘Q로 완전히 끄고 다시 엽니다."
  say "  4. 터미널에서 시험합니다:  ~/kakao-triage/kakao_ax chats"
  say "  (macOS 27부터는 목록 이름이 「기기 제어 및 데이터 접근」, 그 전에는 「손쉬운 사용」입니다)"
elif [ "$code" = 3 ]; then
  say "권한은 있습니다. 카카오톡이 꺼져 있습니다. 카카오톡을 켜고 로그인한 뒤 시험하세요:  ~/kakao-triage/kakao_ax chats"
elif [ "$code" = 0 ]; then
  say "권한 확인 끝. 시험:  ~/kakao-triage/kakao_ax chats"
else
  say "권한 확인 중 다른 응답(코드 $code): $(tail -1 "$tmp/check.txt")"
fi
say ""
say "끝. AI 비서에서 새 대화를 열고 「카톡 확인해」라고 말하세요."
