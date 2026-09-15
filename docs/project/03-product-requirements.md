# Product Requirements

## PR-01 - Curriculum Browser

User phải có thể xem curriculum theo semester.

**Acceptance Criteria**

- Course được group theo semester.
- Course list lấy từ knowledge base.
- Không hardcode course list trong UI.
- Click course mở đúng detail.

## PR-02 - Course Detail

Course detail phải hiển thị:

- Code.
- Name.
- Semester.
- Credits nếu có.
- Overview.
- Learning outcomes nếu có.
- Sources.

**Acceptance Criteria**

- Dữ liệu lấy từ knowledge/index.
- Missing optional field không làm UI lỗi.

## PR-03 - Before This Course

User phải biết môn nào hoặc knowledge nào cần trước course hiện tại.

**Acceptance Criteria**

- Prerequisite lấy từ Knowledge Graph.
- Click prerequisite mở đúng course.
- Không hardcode relationship.

## PR-04 - Topics / Concepts

User phải biết course dạy những concept nào.

**Acceptance Criteria**

- Concept lấy từ graph.
- Click concept mở node/detail nếu tồn tại.

## PR-05 - After This Course

User phải biết knowledge của course được dùng tiếp ở đâu.

**Acceptance Criteria**

- Hiển thị dependent/future courses từ graph.
- Không hardcode future course.

## PR-06 - Search

Search tối thiểu theo:

- Course code.
- Course name.
- Concept name.
- Overview/full text cơ bản.

**Acceptance Criteria**

- Search local.
- Không cần network.
- Result mở đúng node.

## PR-07 - Graph Exploration

User phải có thể dùng graph để khám phá knowledge.

**Acceptance Criteria**

- Focus một course/node.
- Render node liên quan depth 1.
- Có pan/zoom.
- Click node mở detail.
- Incoming/outgoing relationship được phân biệt.

## PR-08 - Data Source Visibility

Official knowledge phải có nguồn.

**Acceptance Criteria**

- Course có source/reference nếu dữ liệu yêu cầu nguồn.
- Official relationship quan trọng phải có căn cứ.

## PR-09 - Offline Core Experience

Core feature phải hoạt động offline:

- Curriculum.
- Course detail.
- Search.
- Graph query.
- Local graph view.

## PR-10 - Personal Notes - Stretch

User có thể tạo personal Markdown note và link với official knowledge.

**Acceptance Criteria**

- Create/edit/delete Markdown note.
- Note có `[[wikilink]]`.
- Re-index sau save.
