# Validation, Testing and Performance

## 1. Validation

Detect:

- Broken wikilink.
- Duplicate course code.
- Missing required metadata.
- Invalid frontmatter.
- Unknown relation.
- Ambiguous canonical id.

Issue phải chỉ ra file gây lỗi.

## 2. Parser Tests

Test tối thiểu:

- Valid frontmatter.
- Invalid frontmatter.
- Wikilink.
- Missing node.
- Duplicate code.

## 3. Graph Tests

Test:

- prerequisite.
- future course.
- incoming edges.
- outgoing edges.
- related nodes.
- reverse dependency.

Should Have:

- backlinks.
- path query.
- local graph depth.

## 4. Integration Test

```text
Markdown
 → Parse
 → Index
 → Graph
 → Query
```

Fixture project phải chạy end-to-end.

## 5. Manual Data QA

Review:

- Course code.
- Course name.
- Semester.
- Source.
- Critical prerequisite.
- Broken official relationship.

## 6. Reliability

- Một Markdown file lỗi không làm toàn app crash.
- Xóa `.knowledge/` không làm mất knowledge gốc.
- Full rebuild phải khôi phục derived data.

## 7. Performance Targets

Dataset dưới 2,000 nodes:

- Startup: `<= 3s` trên máy dev mục tiêu.
- Search: `<= 300ms` sau khi index hoàn tất.
- Course detail: `<= 200ms`.
- Local graph: `<= 500ms` cho subgraph thông thường.

Đây là target nội bộ, không phải hard requirement nếu máy demo yếu hơn.

## 8. Complexity

### Build Index

```text
≈ O(S)
```

`S` = tổng kích thước Markdown.

### Build Graph

```text
≈ O(V + E)
```

`V` = nodes.  
`E` = relationships.

### Graph Traversal

BFS/DFS:

```text
O(V + E)
```

Với dataset curriculum SE, performance không phải rủi ro chính.

Rủi ro chính:

- Data quality.
- Relationship correctness.
- Schema consistency.
- Broken links.
