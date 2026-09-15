# UI and Search

## 1. App Shell

Navigation tối thiểu:

```text
Home / Curriculum
Search
Graph
```

Stretch:

```text
Notes
Diagnostics
```

## 2. Curriculum Screen

```text
Semester 1
├── Course A
└── Course B

Semester 2
├── Course C
└── Course D
```

Course list phải lấy từ knowledge/index.

## 3. Course Detail

Bố cục ưu tiên:

```text
Course Name / Code
Semester / Credits

Overview

Before this course
- Prerequisites

What this course teaches
- Concepts

Useful later
- Future courses

Related knowledge

Sources
```

## 4. Local Graph View

Graph là navigation tool, không chỉ visualization.

User phải có thể:

- Focus node.
- Pan/zoom.
- Click node.
- Nhìn incoming/outgoing relation.
- Xem depth 1 trong MVP.

## 5. Graph Rendering Contract

Graph engine trả:

```text
nodes[]
edges[]
```

Flutter Graph Widget chỉ chịu trách nhiệm render và interaction.

```text
Graph Engine = tính graph
Graph Widget = vẽ graph
```

## 6. Search Flow

```text
SearchScreen
    ↓
SearchKnowledgeUseCase
    ↓
SearchService
    ↓
Local Index
    ↓
Results
```

Search theo:

- Course code.
- Course name.
- Concept name.
- Full text cơ bản.

## 7. Course Navigation Flow

```text
Curriculum
   ↓
Course Detail
   ↓
Prerequisite / Concept / Future Course
   ↓
Related Node Detail
```

UI không được hardcode relationship.
