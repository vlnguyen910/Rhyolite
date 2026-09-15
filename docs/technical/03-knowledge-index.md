# Knowledge Index

## 1. Mục đích

Knowledge Index trả lời:

> Knowledge base hiện có những node nào, nằm ở file nào và có nội dung gì?

Index không phải source of truth. Index được sinh từ Markdown.

## 2. Pipeline

```text
knowledge/
    │
    ▼
Scan .md files
    │
    ▼
Parse frontmatter
    │
    ▼
Parse Markdown / wikilinks
    │
    ▼
Normalize node identity
    │
    ▼
Validate
    │
    ▼
Store local index
```

## 3. Index Data

Tối thiểu:

```text
nodes
--------------------------------
id
type
code
title
semester
file_path
searchable_text
updated_at
```

Ví dụ:

```text
course:CSD201
type      = course
code      = CSD201
title     = Data Structures and Algorithms
semester  = 3
file_path = courses/CSD201.md
```

## 4. Build Rules

- Markdown được parse một lần thành normalized node.
- Index có thể insert/update/delete.
- Full rebuild phải hỗ trợ xóa toàn bộ index rồi tạo lại.
- Một file lỗi không làm cả build crash.
- Error phải chứa file path.

## 5. Incremental Re-index - Should Have

Khi file thay đổi:

```text
File changed
    ↓
Parse changed file
    ↓
Update node
    ↓
Update related edges
```

MVP có thể dùng manual/full rebuild nếu incremental indexing gây chậm tiến độ.

## 6. Search

Search cơ bản trên:

- code.
- title.
- concept name.
- searchable text.

SQLite FTS có thể dùng nếu cần full-text search nhanh.

## 7. Complexity

Với tổng kích thước Markdown là `S`:

```text
Build Index ≈ O(S)
```

Dataset mục tiêu nhỏ nên bottleneck chính là data quality, không phải performance.
