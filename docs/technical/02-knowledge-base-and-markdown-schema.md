# Knowledge Base and Markdown Schema

## 1. Knowledge Base Structure

```text
knowledge/
├── curriculum/
│   ├── semester-01.md
│   ├── semester-02.md
│   └── ...
│
├── courses/
│   ├── PRO192.md
│   ├── CSD201.md
│   ├── DBI202.md
│   └── ...
│
├── concepts/
│   ├── oop.md
│   ├── tree.md
│   ├── graph.md
│   └── ...
│
├── notes/
│   └── ...
│
└── .knowledge/
    ├── index.db
    └── cache/
```

`.knowledge/` chỉ chứa derived data.

## 2. Course Schema

```md
---
type: course
code: CSD201
name: Data Structures and Algorithms
semester: 3
credits: 3
status: official
prerequisites:
  - PRO192
concepts:
  - Tree
  - Graph
  - Sorting
sources:
  - FPTU curriculum
  - Course syllabus
---

# Data Structures and Algorithms

## Overview

Mô tả ngắn về môn học.

## Prerequisites

- [[PRO192]]

## Topics

- [[Tree]]
- [[Graph]]
- [[Sorting]]

## Related Courses

- [[SWD392]]

## Learning Outcomes

- ...

## Sources

- ...
```

## 3. Concept Schema

```md
---
type: concept
name: Tree
status: official
---

# Tree

## Definition

...

## Taught By

- [[CSD201]]

## Related Concepts

- [[Graph]]
```

## 4. Note Schema - Stretch

```md
---
type: note
status: personal
---

# My Tree Notes

## Related

- [[Tree]]
- [[CSD201]]
```

## 5. Schema Rules

- Frontmatter phục vụ machine parsing.
- Markdown body phục vụ người đọc.
- Hai phần phải nhất quán.
- Official relationship phải có căn cứ.
- AI không tự tạo official curriculum data.

## 6. Naming and Identity

Khuyến nghị canonical identity:

```text
course:CSD201
concept:tree
semester:3
note:<slug>
```

Mỗi node phải resolve về một canonical id duy nhất.
