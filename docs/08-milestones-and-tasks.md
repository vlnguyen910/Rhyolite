# Milestones & Tasks

> Các task được chia nhỏ để một developer có thể nhận và hoàn thành độc lập. Timeline tổng thể chưa được chốt.

## Milestone 0 — Project Foundation

### M0-T01 — Create Flutter desktop shell

**Goal:** Tạo application shell chạy được.

**Dependencies:** None.

**Done when:**
- App chạy được trên target desktop environment.
- Có cấu trúc MVVM cơ bản.
- Chưa cần business logic.

### M0-T02 — Define base MVVM conventions

**Goal:** Chốt convention cho View, ViewModel, Service.

**Dependencies:** M0-T01.

**Done when:**
- Có ví dụ một screen đơn giản.
- View không chứa business parsing logic.
- Service không phụ thuộc UI.

### M0-T03 — Create bundled knowledge directory

**Goal:** Bundle `courses/*.md` và `curricula/*.json`.

**Dependencies:** M0-T01.

**Done when:**
- App đọc được file bundle.
- Có ít nhất một fixture course và một curriculum fixture dùng cho test.

---

## Milestone 1 — Knowledge & Curriculum

### M1-T01 — Implement Curriculum JSON loader

**Goal:** Parse curriculum JSON thành domain/application model.

**Dependencies:** M0-T03.

**TBD blocker:** Curriculum JSON schema.

### M1-T02 — Implement Course Markdown loader

**Goal:** Đọc Markdown course từ bundled assets.

**Dependencies:** M0-T03.

**TBD blocker:** Required course fields.

### M1-T03 — Implement curriculum version selector logic

**Goal:** Cho phép application state biết user đang dùng curriculum version nào.

**Dependencies:** M1-T01.

**UI:** TBD.

### M1-T04 — Implement keyword course search

**Goal:** Search theo course code/name.

**Dependencies:** M1-T01, M1-T02.

### M1-T05 — Implement Course Detail data aggregation

**Goal:** Kết hợp course knowledge + curriculum relationship để cung cấp data cho UI.

**Dependencies:** M1-T01, M1-T02.

### M1-T06 — Implement Course Detail relationship view model

**Goal:** Chuẩn bị data cho graph/relationship section.

**Dependencies:** M1-T05.

**TBD blocker:** Relation types.

---

## Milestone 2 — Local Transcript Core

### M2-T01 — Define structured transcript model

**Goal:** Model hóa transcript/course grade.

**Dependencies:** None.

**TBD blocker:** Exact transcript fields.

### M2-T02 — Implement local transcript parser interface

**Goal:** Tạo abstraction cho local parsing.

**Dependencies:** M2-T01.

### M2-T03 — Implement transcript-course matcher

**Goal:** Match imported course code với selected curriculum.

**Dependencies:** M1-T01, M2-T01.

### M2-T04 — Implement unmatched-course detection

**Goal:** Trả về danh sách course không match.

**Dependencies:** M2-T03.

### M2-T05 — Implement transcript preview model

**Goal:** Chuẩn bị structured data cho preview trước import.

**Dependencies:** M2-T02, M2-T04.

### M2-T06 — Implement transcript Replace operation

**Goal:** Replace local transcript hiện tại.

**Dependencies:** Local storage decision.

### M2-T07 — Implement transcript Merge operation

**Goal:** Merge transcript mới với dữ liệu hiện tại.

**Dependencies:** Local storage decision.

**Conflict-resolution rule:** TBD.

### M2-T08 — Implement transcript deletion

**Goal:** Cho user xóa transcript đã import.

**Dependencies:** Local storage decision.

---

## Milestone 3 — Browser Extension Import

### M3-T01 — Define extension payload contract

**Goal:** Định nghĩa payload mà extension gửi sang desktop app.

**Dependencies:** M2-T01.

### M3-T02 — Implement FAP transcript extraction logic

**Goal:** Extension đọc transcript từ FAP.

**Dependencies:** Target browser TBD.

### M3-T03 — Implement localhost communication layer

**Goal:** Gửi payload từ extension sang desktop.

**Dependencies:** Localhost transport TBD.

### M3-T04 — Enforce non-persistent extension behavior

**Goal:** Không lưu transcript persistent trong extension.

**Dependencies:** M3-T02, M3-T03.

### M3-T05 — Connect extension import to desktop preview

**Goal:** Payload nhận được phải đi vào cùng preview flow với file import.

**Dependencies:** M2-T05, M3-T03.

---

## Milestone 4 — File Upload Fallback

### M4-T01 — Implement transcript file picker

**Goal:** User chọn transcript file local.

**Dependencies:** File format TBD.

### M4-T02 — Implement format-specific parser

**Goal:** Parse supported fallback format.

**Dependencies:** M2-T02, file format decision.

### M4-T03 — Preserve original uploaded file locally

**Goal:** File gốc được giữ local.

**Dependencies:** Local storage/file-path decision.

### M4-T04 — Connect upload parser to preview

**Goal:** File import dùng chung preview/confirm/match pipeline.

**Dependencies:** M2-T05, M4-T02.

---

## Milestone 5 — Academic Analysis

### M5-T01 — Implement transcript overview

**Dependencies:** M2 transcript storage.

### M5-T02 — Implement GPA/average calculator

**Dependencies:** GPA formula TBD.

### M5-T03 — Implement low-performing-course detector

**Dependencies:** Threshold/rule TBD.

### M5-T04 — Implement prerequisite-context analyzer

**Goal:** Liên kết grade/current course với prerequisite graph.

**Dependencies:** M1-T05, M2 transcript.

### M5-T05 — Implement review-topic context builder

**Goal:** Chuẩn bị context cho AI đề xuất topic nên ôn.

**Dependencies:** Course Markdown field decision.

---

## Milestone 6 — AI & Consent

### M6-T01 — Implement AI consent state

**Goal:** Lưu trạng thái consent local.

### M6-T02 — Implement AI consent screen

**Goal:** Giải thích dữ liệu có thể được gửi và third-party AI usage.

### M6-T03 — Implement revoke consent

**Goal:** User revoke trong Settings.

### M6-T04 — Define AI provider interface

**Goal:** Tách application logic khỏi provider cụ thể.

**Dependencies:** None.

### M6-T05 — Implement selected cloud AI adapter

**Dependencies:** AI provider TBD.

### M6-T06 — Implement AI connection path

**Dependencies:** Direct vs backend/proxy TBD; API key strategy TBD.

### M6-T07 — Implement context builder

**Goal:** Kết hợp knowledge + selected curriculum + academic context + chat context.

**Dependencies:** M1, M2, M5.

### M6-T08 — Implement source tracking

**Goal:** Mỗi knowledge chunk/context map được về source Markdown.

**Dependencies:** M1-T02.

### M6-T09 — Implement source citation in AI response

**Dependencies:** M6-T08.

### M6-T10 — Implement insufficient-context handling

**Goal:** AI hỏi thêm user khi thiếu dữ liệu thay vì suy diễn.

---

## Milestone 7 — Chat & Study Strategy

### M7-T01 — Implement chatbot UI state

**Dependencies:** M6 AI layer.

### M7-T02 — Implement optional local chat history

**Goal:** User bật/tắt history.

**Dependencies:** Local storage TBD.

### M7-T03 — Implement delete chat history

**Dependencies:** M7-T02.

### M7-T04 — Define Study Strategy schema

**Goal:** Model tối thiểu Goal → Topics → Priority.

### M7-T05 — Implement Study Strategy generation

**Dependencies:** M6-T07, M7-T04.

### M7-T06 — Implement Study Strategy local persistence

**Dependencies:** Local storage TBD.

### M7-T07 — Implement Study Strategy page

**Dependencies:** M7-T05, M7-T06.

---

## Milestone 8 — Personalization Integration

### M8-T01 — Add transcript context to Course Detail

**Goal:** Hiển thị grade/status/context cá nhân tương ứng.

**Dependencies:** M1-T05, M2 transcript.

### M8-T02 — Add prerequisite warning/context to Course Detail

**Dependencies:** M5-T04.

### M8-T03 — Connect Academic Analysis to AI context

**Dependencies:** M5, M6.

### M8-T04 — Verify curriculum-version-aware personalization

**Goal:** AI và analysis luôn sử dụng selected curriculum version.

---

## Milestone 9 — Offline & Quality

### M9-T01 — Verify curriculum offline behavior

### M9-T02 — Verify keyword search offline behavior

### M9-T03 — Verify transcript data offline behavior

### M9-T04 — Define AI offline state UI

**Behavior:** TBD.

### M9-T05 — Add tests for Markdown/JSON parsing

### M9-T06 — Add tests for transcript matching

### M9-T07 — Add tests for Replace/Merge

**Conflict rules:** TBD.

### M9-T08 — Add tests for consent gating

### M9-T09 — Add tests for source citation mapping

---

# Open implementation blockers

Các task sau không nên bắt đầu implementation đầy đủ trước khi chốt tương ứng:

- Course Markdown schema.
- Curriculum JSON schema.
- Local database.
- Transcript file formats.
- GPA formula.
- Low-performance threshold.
- Browser target.
- Extension transport.
- AI provider.
- AI networking architecture.
- API key strategy.
- Relation types.
