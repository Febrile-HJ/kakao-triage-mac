#!/bin/bash
# 카톡 방 찾기: ① 「안읽음」 칩 목록 → ② 검색칸(「채팅방 이름, 참여자 검색」)에 이름 전체 → ③ 그래도 없으면 이름의 낱말 하나씩 다시 검색.
# 셋 다 없으면 전체 목록을 훑지 않고 멈춘다. 검색으로 못 찾는 방은 스크롤로도 거의 못 찾는다.
# 안읽음 칩 목록에서는 5화면까지만 본다. 끝나면 검색을 끝내고 「전체」 칩으로 되돌린다.
# 안 읽은 방이 하나도 없으면 카톡이 「안읽음」 칩을 숨긴다. 그때는 바로 검색으로 간다.
# 사용: bash find_room.sh "<이름 일부>[,<다른 이름>]"
#   → 첫 줄 [안읽음]·[검색]·[낱말 검색] 중 하나, 그다음 찾은 방 이름을 한 줄씩. 못 찾으면 코드 6.
set -u
K="$(cd "$(dirname "$0")" && pwd)/kakao_ax"
q="${1:?이름 일부를 주세요}"
if "$K" folder 안읽음 >/dev/null 2>&1; then
  found=$("$K" find "$q" --steps 5 2>/dev/null)
  "$K" folder 전체 >/dev/null 2>&1
  if [ -n "$found" ]; then echo "[안읽음]"; echo "$found"; exit 0; fi
else
  echo "(안읽음 칩 없음: 안 읽은 방이 없거나 칩을 못 누름)" >&2
fi
search_one() { "$K" search "$1" 2>/dev/null | sed -n 's/^결과: //p' | grep -v '^없음$'; }
sres=""; wres=""
IFS=',' read -ra parts <<< "$q"
for part in "${parts[@]}"; do
  part="$(echo "$part" | sed 's/^ *//; s/ *$//')"
  [ -z "$part" ] && continue
  r=$(search_one "$part")
  if [ -n "$r" ]; then sres="${sres}${sres:+$'\n'}${r}"; continue; fi
  read -ra words <<< "$part"
  if [ "${#words[@]}" -gt 1 ]; then
    for wd in "${words[@]}"; do
      r2=$(search_one "$wd")
      [ -n "$r2" ] && wres="${wres}${wres:+$'\n'}${r2}"
    done
  fi
done
"$K" search "" >/dev/null 2>&1
if [ -n "$sres" ]; then echo "[검색]"; echo "$sres" | awk '!seen[$0]++'; exit 0; fi
if [ -n "$wres" ]; then echo "[낱말 검색]"; echo "$wres" | awk '!seen[$0]++'; exit 0; fi
echo "찾지 못함: $q (안읽음·검색·낱말 검색 모두 없음. 전체 목록은 훑지 않음. 방 이름을 확인해 주세요)" >&2
exit 6
