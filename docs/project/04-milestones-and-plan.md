# Milestones and 3-Week Plan

# Week 1 - Knowledge Foundation

## M1 - Project Foundation

### T1.1 - Khởi tạo Flutter desktop project

**Acceptance Criteria**

- `flutter run` chạy được trên desktop target.
- App mở được cửa sổ desktop.

### T1.2 - Tạo project structure

```text
core/
data/
domain/
features/
ui/
```

**Acceptance Criteria**

- Parser và graph logic không nằm trong widget UI.

### T1.3 - Setup lint/test

**Acceptance Criteria**

- `flutter analyze` pass.
- `flutter test` chạy được.

---

## M2 - Knowledge Schema

### T2.1 - Chốt course schema

**Acceptance Criteria**

- Có sample course hợp lệ.
- Required/optional fields được document.

### T2.2 - Chốt concept schema

**Acceptance Criteria**

- Có sample concept hợp lệ.

### T2.3 - Chốt relationship types

**Acceptance Criteria**

- Không còn relation quan trọng chưa có định nghĩa.

### T2.4 - Chốt naming/link convention

**Acceptance Criteria**

- Course code resolve ổn định.
- Không có hai node dùng cùng canonical id.

---

## M3 - FPTU SE Knowledge Collection

### T3.1 - Thu thập semester list

**Acceptance Criteria**

- Có danh sách semester của curriculum mục tiêu.

### T3.2 - Thu thập course list

Required:

- code.
- name.
- semester.
- source.

**Acceptance Criteria**

- 100% course mục tiêu có entry.
- Không duplicate code.

### T3.3 - Tạo Markdown cho từng course

**Acceptance Criteria**

- Mỗi course có đúng một file `.md`.

### T3.4 - Bổ sung prerequisite

**Acceptance Criteria**

- Chỉ dùng prerequisite có căn cứ.
- Không dùng AI để tự suy diễn official prerequisite.

### T3.5 - Tạo concept chính

**Acceptance Criteria**

- Chỉ tạo concept thực sự được reference bởi course.

### T3.6 - Review broken links

**Acceptance Criteria**

- Không còn broken official link chưa xử lý.

---

## M4 - Parser + Index + Graph Core

### T4.1 - File scanner

**Acceptance Criteria**

- Scan recursive `.md`.

### T4.2 - Frontmatter parser

**Acceptance Criteria**

- Valid/invalid case có test.

### T4.3 - Wikilink parser

**Acceptance Criteria**

- Parse được sample links.

### T4.4 - Build Knowledge Index

**Acceptance Criteria**

- Markdown được normalize thành node index.
- Có thể rebuild toàn bộ index.

### T4.5 - Node/Edge model

**Acceptance Criteria**

- Có typed node/edge model.

### T4.6 - Build Knowledge Graph

**Acceptance Criteria**

- Metadata/link được chuyển thành typed edges.
- Knowledge base parse được mà app không crash.

### Week 1 Exit Criteria

Đến cuối tuần 1, code phải trả lời được:

```text
CSD201 prerequisite là gì?
Course nào dùng CSD201 làm nền tảng?
CSD201 dạy concept nào?
```

Không cần UI đẹp.

---

# Week 2 - Desktop Product

## M5 - Curriculum UI

### T5.1 - App shell/navigation

**Acceptance Criteria**

- Điều hướng tới Curriculum/Search/Graph.

### T5.2 - Curriculum screen

**Acceptance Criteria**

- Course group theo semester từ data thật.

### T5.3 - Course Detail overview

**Acceptance Criteria**

- Code/name/semester/overview/source render đúng.

### T5.4 - Before this course

**Acceptance Criteria**

- Render prerequisite từ graph.

### T5.5 - Topics

**Acceptance Criteria**

- Render concept từ graph.

### T5.6 - After this course

**Acceptance Criteria**

- Render future/dependent course từ graph.

### T5.7 - Navigation giữa node

**Acceptance Criteria**

- Click course/concept mở đúng detail.

---

## M6 - Search

### T6.1 - Search service

**Acceptance Criteria**

- Search code/name/concept.

### T6.2 - Search UI

**Acceptance Criteria**

- Click result mở đúng node.

---

## M7 - Graph UI

### T7.1 - Local graph renderer

**Acceptance Criteria**

- Focus một course.
- Render depth 1.

### T7.2 - Graph interaction

**Acceptance Criteria**

- Pan/zoom.
- Click node.

### T7.3 - Edge presentation

**Acceptance Criteria**

- User phân biệt prerequisite, concept và future relationship bằng label/legend/style.

### T7.4 - Graph performance guard

**Acceptance Criteria**

- Local graph không freeze với dataset mục tiêu.

### Week 2 Exit Criteria

```text
Open app
  ↓
Select semester
  ↓
Open course
  ↓
See prerequisite
  ↓
See topics
  ↓
See future course
  ↓
Open local graph
  ↓
Navigate to another course
```

---

# Week 3 - Stabilization, Validation, Release

## M8 - Data Validation

### T8.1 - Broken link validator

**Acceptance Criteria**

- Liệt kê file/link lỗi.

### T8.2 - Duplicate validator

**Acceptance Criteria**

- Detect duplicate code/id.

### T8.3 - Required metadata validator

**Acceptance Criteria**

- Detect thiếu code/name/semester/source.

### T8.4 - Diagnostics output

**Acceptance Criteria**

- Có UI hoặc debug report dễ đọc.

---

## M9 - Testing

### T9.1 - Parser unit tests

**Acceptance Criteria**

- Valid/invalid frontmatter.
- Wikilink.
- Missing node.
- Duplicate code.

### T9.2 - Graph unit tests

**Acceptance Criteria**

- prerequisite.
- future course.
- incoming/outgoing.
- related nodes.

### T9.3 - Integration test pipeline

```text
Markdown
 → Parse
 → Index
 → Graph
 → Query
```

**Acceptance Criteria**

- Pipeline pass với fixture project.

### T9.4 - Manual curriculum QA

**Acceptance Criteria**

- Course code/name/semester được review.
- Không còn critical broken official relationship.

---

## M10 - Release & Demo

### T10.1 - UX cleanup

Chỉ sửa:

- navigation.
- overflow.
- loading.
- empty state.
- graph readability.
- error state.

### T10.2 - Release build

**Acceptance Criteria**

- Build desktop release thành công trên platform target.

### T10.3 - README

README tối thiểu:

- Purpose.
- Architecture.
- Run command.
- Knowledge format.
- Dataset structure.
- Demo flow.

### T10.4 - Demo dataset validation

**Acceptance Criteria**

- 0 duplicate course code.
- 0 broken critical official link.
- 0 parse error trong release dataset.

### Week 3 Exit Criteria

Có release candidate demo được end-to-end.

---

# Daily Plan

| Ngày | Output chính |
|---|---|
| D1 | Flutter foundation + architecture |
| D2 | Markdown schema + full course list |
| D3 | Course relationships + concepts |
| D4 | Markdown parser |
| D5 | Knowledge Index + Graph engine |
| D6 | Curriculum UI |
| D7 | Course Detail |
| D8 | Search |
| D9 | Local Graph UI |
| D10 | Relationship navigation + buffer |
| D11 | Validation |
| D12 | Test + data QA |
| D13 | Integration + bug fix |
| D14 | UX cleanup + release prep |
| D15 | Release build + demo |
