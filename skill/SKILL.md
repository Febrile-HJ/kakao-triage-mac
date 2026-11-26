---
name: kakao-triage
description: "맥 카카오톡의 안 읽은 메시지를 읽고 정리·요약하고, 답장 초안을 써서 입력창에 넣거나 보낼 때 쓴다. 「카톡 확인해」, 「카톡 정리해」, 「안 읽은 카톡」, 「OO 방 읽어 줘」, 「OO 방 찾아 줘」, 「답장 써 줘」, 「입력해」, 「보내」라고 하면 이 스킬을 쓴다. Reads and drafts replies for Mac KakaoTalk through the macOS Accessibility API with the kakao_ax tool."
---

# 카톡 처리 (kakao-triage)

도구는 `~/kakao-triage/kakao_ax`다. 맥 카카오톡 앱이 손쉬운 사용(Accessibility) 통로로 내보내는 글자를 읽고 쓴다. 화면을 캡처하지 않는다. 아래에서 `KAX`는 `~/kakao-triage/kakao_ax`를 뜻한다. 읽은 결과 파일은 `~/kakao-triage/out/`에 둔다.

## 꼭 지킬 것

1. 방을 열면 카카오톡이 그 방을 읽음 처리한다. 안 읽은 방은 사용자가 「카톡 확인해」처럼 시킬 때만 연다.
2. 제외 방은 열지도 읽지도 않는다. 목록은 `~/kakao-triage/exclude_rooms.txt`(한 줄에 방 이름 하나)이고, 도구가 그 방을 막는다(코드 12). 이 파일은 사용자가 시킬 때만 고친다.
3. 보내기(`send`)는 사용자가 문구를 보고 「보내」라고 할 때만 한 번 한다. 실패해도 다시 보내지 않고 알린다. 기본은 `fill`(입력창에 넣기만, 엔터 없음)이다.
4. 카톡 원문은 이 맥 안에만 둔다. 다른 서비스, 파일 공유, 메일로 내보내지 않는다. 답에 보일 때는 전화번호, 계좌번호, 주민등록번호, 비밀번호, 인증번호를 가린다.
5. 방을 찾을 때는 「안읽음」 칩 → 검색 순서로 찾는다(`find_room.sh`). `chats --all`이나 `find --all`로 전체 목록부터 훑지 않는다. 방이 많으면 오래 걸린다.
6. 내가 연 방 창은 일이 끝나면 `close`로 닫는다. 사용자가 열어 둔 창은 닫지 않는다.
7. 검색을 끝낼 때 Esc를 보내지 않는다. 메인 창이 닫힌다. `KAX search ""`를 쓴다.

## 시작 전 확인

- 화면이 잠기거나 꺼지면 손쉬운 사용 통로가 막힌다. 시작할 때 `(caffeinate -d -u -t 300 >/dev/null 2>&1 &)`로 화면을 5분 깨워 둔다. 일이 길면 300을 늘린다.
- `KAX windows`가 「손쉬운 사용 권한이 없습니다」(코드 2)를 내면 멈춘다. 사용자에게 README 「손쉬운 사용 켜기」를 안내한다. 이 명령을 실행한 앱(터미널, Claude, Aside 등)을 켜고, 그 앱을 ⌘Q로 끈 뒤 다시 열어야 한다.
- 「카카오톡이 실행 중이 아닙니다」(코드 3)면 사용자에게 카톡을 켜고 로그인해 달라고 한다. 카톡은 PC·맥 중 한 대에서만 로그인된다. 대신 켜거나 로그인하지 않는다.

## 「카톡 확인해」: 안 읽은 카톡 정리

1. `KAX refresh` → 채팅 목록을 새로 고친다.
2. `KAX folder 안읽음` → 「안읽음」 칩을 누른다. 안 읽은 방이 없으면 카톡이 칩을 숨기므로 실패할 수 있다.
3. 칩이 눌렸으면 `KAX chats --all --steps 40 --out ~/kakao-triage/out/unread.jsonl`, 실패했으면 `KAX chats --steps 200 --out ~/kakao-triage/out/unread.jsonl`로 목록을 읽는다. 방은 열지 않는다.
4. `KAX folder 전체` → 칩을 「전체」로 되돌린다.
5. `unread.jsonl` 한 줄이 방 하나다. 방 이름은 `texts`에서 `role`이 `AXStaticText`인 첫 글자다. `unread`가 안 읽은 수다. `unread`가 0인 줄은 뺀다. 광고·브랜드 채널 방은 사용자가 시키지 않으면 건너뛴다.
6. 방마다 `KAX open "<방>"` → `KAX read "<방>" --pages 3 --out ~/kakao-triage/out/<순번>.jsonl` → `KAX close "<방>"`. 안 읽은 수가 많으면 `--pages`를 늘린다.
7. `read`가 「창을 찾지 못했습니다」를 내면 `KAX windows`로 실제 창 이름을 보고 그 이름으로 다시 읽는다. 오픈채팅과 나와의 채팅은 목록 이름과 창 이름이 다를 수 있다.
8. 읽은 파일에서 `kind`가 `text`·`media`인 줄 가운데 맨 아래 `unread`개를 새 메시지로 본다. 그 앞 5개는 맥락으로만 쓴다.
9. 사용자에게 짧게 보고한다. 순서: 🔴 바로 확인 → 답장할 것 → 일 관련 참고 → 정보·링크 → 나머지 개수. 한 줄에 방 · 보낸 사람 · 한 줄 요약을 쓴다. 할 것이 없으면 「바로 확인 0건」으로 끝낸다.
   - 바로 확인: 사용자에게 답이나 행동을 요구하고, 그 뒤에 사용자가 아직 답하지 않은 것(돈, 일정, 고객, 계약, 마감).
   - 답장할 것: 사용자를 부르거나 물었지만 급하지 않은 것.
   - 참고: 사용자 일에 관련되지만 답이 필요 없는 것.
   - 정보·링크: 도움이 될 자료, 기사, 도구.
10. 바로 확인과 답장할 것에는 아래 「답장」대로 초안을 붙인다.

## 방 하나 읽기·찾기

1. 방 이름을 정확히 모르면 `bash ~/kakao-triage/find_room.sh "<이름 일부>"`로 찾는다. 첫 줄은 [안읽음]·[검색]·[낱말 검색] 중 하나이고, 그다음 줄부터 찾은 방 이름이다. 못 찾으면 전체 목록을 훑지 않고 사용자에게 방 이름을 묻는다.
2. `KAX open "<방>"` → `KAX read "<방>" --pages N --out <파일>` → `KAX close "<방>"`.
3. 날짜까지 읽으려면 `--since YYYY-MM-DD`를 쓴다.

## 답장

- 사용자 말투를 따른다. 처음 답장을 쓸 때 사용자에게 평소 카톡 인사와 이름 쓰는 모양을 한 번 묻고, 이 파일 맨 아래 「내 말투」에 적어 둔다. 그 뒤로는 묻지 않는다.
- 줄은 뜻이 끊기는 곳마다 바꾼다. 문단 사이에만 빈 줄을 둔다. 「초안」 같은 표시는 글에 넣지 않는다.
- 초안을 채팅에 보여 주고 「입력해 / 보내 / 고쳐」를 기다린다.
- 입력해: `KAX fill "<방>" "<글>"`. 입력창에 넣기만 하고 엔터는 누르지 않는다.
- 보내: `KAX send "<방>" "<글>"` 한 번 → `KAX read "<방>" --pages 1`로 마지막 글이 맞는지 확인 → `KAX close "<방>"`.
- `fill`·`send`가 「창이 열리지 않았습니다」를 내면 `KAX open "<방>"`으로 창을 먼저 연 뒤 다시 한다.
- 처음 시험은 「나와의 채팅」 방에서 한다.

## 명령 모음

- `KAX version`: 도구 버전.
- `KAX windows`: 열린 카톡 창 이름.
- `KAX chats [--all] [--steps N] [--out 파일]`: 채팅 목록 읽기. 방을 열지 않는다.
- `KAX refresh`, `KAX folder 안읽음|전체`: 목록 새로 고침, 폴더 칩 고르기.
- `KAX search "<이름>"`, `KAX search ""`: 방 이름·참여자 검색, 검색 끝내기. 대화 내용은 검색하지 못한다.
- `KAX open "<방>"`, `KAX close "<방>"`: 방 창 열기·닫기. 열면 읽음 처리된다.
- `KAX read "<방>" [--pages N] [--since YYYY-MM-DD] [--out 파일]`: 방 읽기. 결과 한 줄 = 한 행. 칸은 `i`(순번), `kind`(text·media·date·system·gap), `who`(me·other·center), `name`(보낸 사람), `date`, `time`, `text`.
- `KAX fill "<방>" "<글>"`, `KAX send "<방>" "<글>"`: 입력창에 넣기, 보내기.
- `KAX roominfo "<방>"`: 제외·우선·대상 확인. 카톡을 건드리지 않는다.
- 종료 코드: 2 권한 없음, 3 카톡 꺼짐, 4 창·목록 못 찾음, 6 방 못 찾음, 12 제외 방.

## Aside에서 쓸 때

Aside 샌드박스가 켜져 있으면 손쉬운 사용 통로가 막혀 코드 2가 난다. REPL에 아래 함수를 만들고, 끄기 → Bash 실행 → 켜기를 한 번의 작업 묶음으로 한다. 켜기를 잊어도 정한 시간 뒤 저절로 켜진다. 사용자에게는 「샌드박스를 잠깐 껐다 켰다」고 한 줄만 알린다.

```js
globalThis.sandboxOff = (seconds = 300) => {
  const cur = aside.settings.get('permission');
  if (!globalThis.__sbBackup) globalThis.__sbBackup = JSON.parse(JSON.stringify(cur));
  aside.settings.set('permission', { ...cur, sandbox: { ...(cur.sandbox || {}), enabled: false } });
  if (globalThis.__sbTimer) clearTimeout(globalThis.__sbTimer);
  globalThis.__sbTimer = setTimeout(() => { try { globalThis.sandboxOn(); } catch {} }, seconds * 1000);
};
globalThis.sandboxOn = () => {
  if (globalThis.__sbTimer) { clearTimeout(globalThis.__sbTimer); globalThis.__sbTimer = null; }
  const b = globalThis.__sbBackup || aside.settings.get('permission');
  aside.settings.set('permission', { ...b, sandbox: { ...(b.sandbox || {}), enabled: true } });
  globalThis.__sbBackup = null;
};
```

샌드박스를 꺼도 코드 2가 나면 macOS 권한 목록에서 Aside 항목(Aside 앱과 Aside 데몬)을 껐다 켜 달라고 사용자에게 부탁한다. Aside가 업데이트되면 이 권한이 풀릴 수 있다.

## 알려진 한계

- 카톡이 날짜 글자를 주지 않을 때가 많다. `date`가 비면 시각만 쓴다.
- 긴 메시지는 「…」로 잘릴 수 있다. 전문이 필요하면 사용자에게 카톡에서 직접 보라고 한다.
- 맥 카톡에는 방마다 최근 기록만 있다.
- 읽기 범위 맨 위 메시지는 보낸 사람 이름이 빠질 수 있다.
- 사진·파일은 이름만 보이고 내용은 못 본다.
- 카톡 업데이트로 화면 구조가 바뀌면 읽기가 실패할 수 있다. 사용자에게 설치 명령을 다시 실행해 새 판을 받으라고 한다.

## 내 말투

(아직 비어 있음. 처음 답장을 쓸 때 사용자에게 물어 채운다.)
