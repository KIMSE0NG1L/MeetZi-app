# 열람권 / 매칭권 / 등록권 API·DB 스펙

계정별로 **등록권**, **열람권**, **매칭권**을 크레딧처럼 보유합니다.  
**등록권 1장 사용 → 게시판 등록 → 매칭권 1장 지급** 로직입니다.

## DB

- 사용자(또는 계정) 테이블에 컬럼 추가 권장:
  - `register_ticket_count` (int, 기본값 0) — 등록권 (게시판 등록 시 1 소비, 성공 시 매칭권 +1)
  - `view_ticket_count` (int, 기본값 0) — 열람권
  - `matching_ticket_count` (int, 기본값 0) — 매칭권
- 또는 별도 `user_tickets` 테이블: `user_id`, `register_ticket`, `view_ticket`, `matching_ticket`

## API

### 1. 내 등록권/열람권/매칭권 조회

- **GET** `/users/me/tickets`
- **Response**
  ```json
  {
    "registerTicket": 2,
    "viewTicket": 5,
    "matchingTicket": 3
  }
  ```
- **등록권**: 게시판 등록 시 1 소비, 등록 성공 시 **매칭권 1 지급**
- **열람권**: 프로필 상세 열람 시 1 소비
- **매칭권**: 가져가기 요청 시 1 소비 (거절 시 환불)

### 2. 열람권 소비 (프로필 상세 열람 시)

- **POST** `/matching-board/consume-view-ticket`
- **Body** `{ "profileId": "프로필ID문자열" }`
- 동작: `view_ticket_count` 1 감소 (0이면 4xx 에러 가능)
- 성공 시 200, 실패 시 4xx + 메시지

### 3. 가져가기 요청 (매칭권 사용 → 상대에게 알림, 수락 시에만 매칭 성사)

- **POST** `/matching-board/take-note`
- **Body** `{ "profileId": "대상 프로필(유저) ID" }`
- 동작:
  1. 요청자 `matching_ticket_count` 1 감소
  2. **가져가기 요청** 레코드 생성 (request_id, from_user_id, to_user_id, status: pending)
  3. **대상 유저에게 알림** 발송 (푸시 또는 알림 목록에 추가). 알림 payload 예: `{ type: "take_note_request", requestId: "...", requesterProfile: { ... } }`
- 성공 시 200. **즉시 매칭 아님** → 상대가 알림 보고 수락할 때만 매칭 성사.

### 4. 가져가기 요청 상세 조회

- **GET** `/matching-board/take-note-requests/:requestId`
- **Response** `{ "requestId": "...", "requester": { 프로필 맵 } }`  
  (상대가 알림 탭 → 상세 보기용)

### 5. 가져가기 요청 수락 (매칭 성사)

- **POST** `/matching-board/take-note-requests/:requestId/accept`
- 동작: 요청 상태를 수락으로 변경, 매칭 생성 (채팅 가능 등). 매칭권은 이미 차감된 상태 유지.

### 6. 가져가기 요청 거절 (환불 없음)

- **POST** `/matching-board/take-note-requests/:requestId/reject`
- 동작: 요청 상태를 거절로 변경. **매칭권은 환불되지 않음** (신청 시 이미 차감된 상태 유지 — 확정된 정책).

### 등록권 사용 (게시판 등록 → 매칭권 1 지급)

- **POST** `/matching-board/register`
- **Body** 기존과 동일 (nickname, gender, school, department 등)
- 동작:
  1. 요청자 `register_ticket_count` >= 1 확인, 아니면 4xx
  2. `register_ticket_count` 1 감소
  3. `matching_ticket_count` 1 증가
  4. 게시판 프로필 등록
- 성공 시 200.

## 앱 동작 요약

| 액션 | 사용 권한 | API |
|------|-----------|-----|
| **등록** 버튼 (게시판) | 등록권 1장 | `POST /matching-board/register` → 등록권 -1, 매칭권 +1 |
| 카드 탭 → 상세 | 열람권 1장 | `POST /matching-board/consume-view-ticket` 후 시트 오픈 |
| 가져가기 버튼 | 매칭권 1장 | `POST /matching-board/take-note` → 요청 생성 + 상대 알림 (수락 시에만 매칭) |
| 알림에서 가져가기 요청 탭 | - | `GET /take-note-requests/:id` 후 상세 화면 (받기/거절) |
| 받기 | - | `POST .../accept` → 매칭 성사 |
| 거절 | - | `POST .../reject` → 환불 없음 (매칭권 차감 상태 유지) |

- `GET /users/me/tickets` 에 `registerTicket` 포함. 없으면 앱은 0으로 표시하고, 등록 시 "등록권이 부족해요" 메시지를 냅니다.
- 구독(월 구독 무제한, `Subscription.status === 'active'`)이 활성 상태인 유저는 `take-note` 요청 시 매칭권 확인/차감 자체를 건너뜁니다.

---

## 매칭권 획득 경로

기존 출석체크(+1/일)·추천인(+3, 양방향)·개별 소모품 결제 외에 아래 두 경로가 추가됨:

### 리워드 광고 시청 (하루 5회 제한)

- **POST** `/ad-reward/claim` — 리워드 광고 시청 완료 시 매칭권 1장 지급. 하루 5회 초과 시 403.
- **GET** `/ad-reward/status` — `{ remainingToday, limit: 5 }` 오늘 남은 횟수 조회.
- 부정 방지는 클라이언트 콜백(AdMob `onUserEarnedReward`) 신뢰 + 서버 측 일일 횟수 제한만 적용 (서버 측 영수증 검증(SSV) 없음).

### 월 구독 → 매칭권 무제한

- RevenueCat 구독 상품(Package ID `monthly_unlimited`)을 구매하면 기존 `Subscription` 모델의 웹훅 처리(INITIAL_PURCHASE/RENEWAL)를 그대로 재사용해 `status = active`로 전환됨.
- `status === 'active'`인 동안에는 매칭권 잔고와 무관하게 `take-note` 요청이 항상 허용되고, 매칭권도 차감되지 않음 (소모성 매칭권 잔고는 그대로 유지되어 구독 해지 후에도 남아있는 매칭권을 계속 사용 가능).
- 개별 매칭권 구매(`single_ticket`)와는 별개 상품이라 공존 가능.

## 게시판 카드(걸어놓는 프로필) 관리 DB·API

게시판에 **카드로 보이는 항목**은 “누가 등록해 둔 프로필” 하나하나입니다. 아래 API가 이걸 다룹니다.

### API

| 용도 | 메서드 | 경로 | 설명 |
|------|--------|------|------|
| 카드 목록 조회 (게시판 그리드) | GET | `/matching-board` | 게시판에 등록된 프로필 목록. 응답이 곧 “카드” 리스트. |
| 카드 등록 (내 카드 걸기) | POST | `/matching-board/register` | Body: `nickname`, `gender`, `school`, `department` 등. 등록권 1 소비 후 이 리스트에 한 건 추가. |

- **GET /matching-board**  
  - 응답: 배열. 각 요소는 “카드 한 장”에 대응.  
  - 앱이 쓰는 필드 예: `id`, `userId`, `nickname`, `gender`, `department`, `idealType`, `user`(아바타/상세 정보 등).

### DB 영역 제안

“카드 걸어놓는 것”을 관리하는 DB는 **게시판에 올라온 프로필(등록 건)** 을 저장하는 영역입니다.

- **테이블 이름 예**: `matching_board_profiles` 또는 `board_cards`
- **역할**: “누가 게시판에 내 프로필을 등록해 놓았는지” 한 건 한 건 저장.
- **컬럼 예**:
  - `id` (PK)
  - `user_id` (게시판에 올린 사용자)
  - `nickname`, `gender`, `school`, `department` (등록 시 넣는 값)
  - `created_at`, `updated_at`
  - (선택) 상세 프로필 스냅샷용 컬럼 또는 `user` 테이블과 조인해서 GET 시 채움

**GET /matching-board** 구현 시: 이 테이블(또는 동일 역할 테이블)을 조회해서, 필요하면 `users` 등과 조인해 앱이 기대하는 형태(`id`, `userId`, `nickname`, `user` 등)로 내려주면 됩니다.

**POST /matching-board/register** 구현 시: 등록권 차감·매칭권 지급 후, 이 테이블에 `user_id`와 nickname/gender/school/department 등을 넣어 한 row 추가하면 “카드 한 장 추가”가 됩니다.
