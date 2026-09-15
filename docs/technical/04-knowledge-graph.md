# Knowledge Graph

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
Programming Fundamentals
        │
        │ prerequisite
        ▼
Data Structures and Algorithms
        │
        ├── teaches ──> Tree
        ├── teaches ──> Graph
        ├── teaches ──> Sorting
        │
        └── foundation_for ──> Software Development
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
