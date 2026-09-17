# Knowledge Graph

## Trạng thái implementation Lab 1

Code hiện tại nằm ở `lib/domain/knowledge_graph.dart` và
`lib/features/graph/local_graph_screen.dart`. Graph được sinh trong bộ nhớ từ
`KnowledgeSnapshot`, không ghi ngược vào vault và không có database graph riêng.

Ba relation đã triển khai:

| Relation | Chiều / ý nghĩa |
| --- | --- |
| `prerequisite` | `A → B`: A tham chiếu B là môn cần trước. Giữ riêng điều kiện nguyên văn để không mất AND/OR. |
| `topic` | `course → concept`: từ `course.concepts` hoặc `concept.courses`. Hai cách khai báo cùng fact được deduplicate. |
| `related` | Liên kết tham khảo không định hướng giữa course/concept; không tự suy thành prerequisite. |

Ví dụ đúng chiều implementation: `PRM393 → PRO192` với relation `prerequisite`.
Môn học dùng tiếp PRO192 được tìm bằng truy vấn ngược, không nhập thêm cạnh
`foundation_for`. Wikilink ngược trong phần “Mon hoc nang cao” không tạo thêm
cạnh tham khảo khi cặp node đã có relation định kiểu.

UI có local graph độ sâu 1, tối đa 24 node gồm focus; hub/reference không được vẽ.
Các node còn lại vẫn có trong dữ liệu và số bị lược được hiển thị. Layout theo
lane cố định; `CustomPainter` vẽ cạnh và `InteractiveViewer` xử lý pan/zoom.
Click node mở trang nội dung; nút “Vừa khung” khôi phục view.

Concept exploration hỗ trợ tìm tên/nội dung, course liên quan và concept liên quan.
Bốn note PRM393 ban đầu có nguồn, đánh dấu là bản khởi đầu AI biên soạn để review;
không được coi là bằng chứng người học đã hiểu hoặc là toàn bộ topics của môn.
Syllabus gốc được giữ nguyên.

Các phần bên dưới là thiết kế ban đầu và hướng mở rộng; các relation khác,
global graph, lưu index và path query chưa đều được triển khai.

## 1. Mục đích

Knowledge Graph trả lời:

> Những knowledge node liên quan với nhau như thế nào?

## 2. Node Types

MVP:

- `course`
- `concept`
- `semester`

Stretch:

- `note`
- `resource`

## 3. Edge Types

- `prerequisite`
- `foundation_for`
- `related_to`
- `teaches`
- `uses`
- `part_of_semester`
- `references`

## 4. Example

```text
PRM393
  ├── prerequisite ──> PRO192
  ├── topic ──> Dart
  ├── topic ──> Flutter
  ├── topic ──> Future và async/await
  └── topic ──> State management
```

## 5. Relationship Rule

Relationship official phải đến từ structured metadata hoặc section được định nghĩa rõ.

Không dùng AI để tự tạo official relationship trong MVP.

## 6. Build Graph Pipeline

```text
Parsed Nodes
     │
     ▼
Extract relationship metadata
     │
     ▼
Resolve target IDs
     │
     ▼
Validate target nodes
     │
     ▼
Create typed edges
     │
     ▼
Knowledge Graph
```

## 7. Suggested Storage

```text
nodes
----------------
id
type
title
...

edges
----------------
source_id
target_id
type
source_file
source_section
```

Không cần Neo4j cho MVP.

## 8. In-memory Graph Structure

```text
Map<NodeId, KnowledgeNode> nodes

Map<NodeId, List<KnowledgeEdge>> outgoingEdges

Map<NodeId, List<KnowledgeEdge>> incomingEdges
```

## 9. Required Queries

```text
getPrerequisites(course)
getFutureCourses(course)
getRelatedNodes(node)
getConcepts(course)
getIncomingEdges(node)
getOutgoingEdges(node)
```

Should Have:

```text
getBacklinks(node)
getLocalGraph(node, depth)
findPath(from, to)
```

## 10. Reverse Relationship

Không nên nhập cùng một fact hai lần.

Ví dụ chỉ lưu:

```text
SWD392 --prerequisite--> CSD201
```

Graph engine có thể suy ra reverse view:

```text
CSD201 --foundation_for--> SWD392
```

Điều này giảm inconsistency trong dữ liệu.

## 11. Path Query

Basic BFS:

```text
PRO192
  ↓
CSD201
  ↓
SWD392
```

Complexity:

```text
O(V + E)
```

Với dataset dự án, query gần như tức thời.
