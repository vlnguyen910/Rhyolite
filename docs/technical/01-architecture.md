# Technical Architecture

## 1. Architecture Decision

Dự án sử dụng:

> **MVVM + Repository/Service + lightweight Domain Layer**

Lý do:

- UI desktop có nhiều screen nhưng không quá phức tạp.
- Knowledge Graph có business logic riêng, cần tách khỏi UI.
- Markdown, SQLite và file system cần được cô lập khỏi View/ViewModel.
- Timeline MVP chỉ 3 tuần, nên không dùng Clean Architecture đầy đủ để tránh boilerplate.
- Kiến trúc vẫn đủ rõ để test parser, graph và repository độc lập.

Pattern áp dụng:

| Problem | Pattern |
|---|---|
| UI architecture | MVVM |
| Data abstraction | Repository |
| File/SQLite access | Service |
| Graph business logic | Domain Service |
| Workflow phức tạp | Use Case, chỉ khi cần |
| State management | Riverpod khuyến nghị |
| Error handling | Result Pattern |
| Storage | Offline-first |

---

## 2. Kiến trúc tổng quan

```text
┌─────────────────────────────────────────────────────┐
│            FPTU SE Knowledge Desktop                │
│                    Flutter                          │
│                                                     │
│  Curriculum   Search   Course Detail   Graph        │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
                    Presentation Layer
                    View + ViewModel
                           │
                           ▼
                    Application Layer
                Use Cases khi thực sự cần
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
             Domain Layer        Repository
          Knowledge Graph            │
          Business Rules             ▼
                 │               Data Layer
                 │          ┌────────┴────────┐
                 │          ▼                 ▼
                 │   Markdown Services   SQLite Service
                 │          │                 │
                 └──────────┴────────┬────────┘
                                    ▼
                            Markdown Knowledge Base
```

Luồng đơn giản:

```text
View
  ↓
ViewModel
  ↓
Repository
  ↓
Service
```

Luồng có graph/business logic:

```text
View
  ↓
ViewModel
  ↓
Domain Service / Use Case
  ↓
Repository
  ↓
Service
```

---

## 3. Layer Responsibilities

## 3.1. Presentation Layer

Chứa Flutter UI và ViewModel.

### Views

Ví dụ:

- `CurriculumView`
- `CourseDetailView`
- `SearchView`
- `GraphView`
- `DiagnosticsView`

View chỉ chịu trách nhiệm:

- Render UI.
- Nhận user interaction.
- Gọi action trên ViewModel.
- Hiển thị loading/error/data state.
- Navigation đơn giản.

View **không được**:

- Parse Markdown.
- Query SQLite trực tiếp.
- Tính prerequisite.
- Traverse graph.
- Chứa business rule.

### ViewModels

Mỗi feature chính có ViewModel tương ứng:

```text
CurriculumView
↕
CurriculumViewModel

CourseDetailView
↕
CourseDetailViewModel

SearchView
↕
SearchViewModel

GraphView
↕
GraphViewModel
```

ViewModel chịu trách nhiệm:

- Quản lý UI state.
- Gọi repository.
- Gọi domain service/use case.
- Chuyển domain data thành data phù hợp cho UI.
- Xử lý loading/error state.

Ví dụ `CourseDetailViewModel` cung cấp:

```text
course
prerequisites
concepts
futureCourses
relatedCourses
isLoading
error
```

---

## 3.2. Application Layer

Application Layer chỉ chứa use case cho workflow đủ phức tạp hoặc được reuse.

Use case đề xuất:

- `BuildKnowledgeIndex`
- `BuildKnowledgeGraph`
- `RebuildKnowledge`
- `GetLearningPath`

Không cần tạo use case cho mọi thao tác nhỏ.

Ví dụ không cần:

```text
GetCourseNameUseCase
GetSemesterUseCase
GetCreditsUseCase
```

Các thao tác đơn giản có thể đi trực tiếp:

```text
ViewModel
  ↓
Repository
```

---

## 3.3. Domain Layer

Chứa model và logic nghiệp vụ độc lập với Flutter UI và storage.

### Core Models

- `Course`
- `Concept`
- `Semester`
- `KnowledgeNode`
- `KnowledgeEdge`
- `NodeType`
- `EdgeType`

### KnowledgeGraphService

Đây là domain service chính.

API dự kiến:

```text
getPrerequisites(courseId)
getFutureCourses(courseId)
getRelatedNodes(nodeId)
getConcepts(courseId)
getIncomingEdges(nodeId)
getOutgoingEdges(nodeId)
getLocalGraph(nodeId, depth)
findPath(sourceId, targetId)
```

Domain layer không cần biết:

- Widget nào đang hiển thị.
- Markdown nằm ở folder nào.
- SQLite package nào đang dùng.

---

## 3.4. Repository Layer

Repository là abstraction giữa application/domain và data sources.

Interface đề xuất:

```dart
abstract interface class KnowledgeRepository {
  Future<Course?> getCourse(String id);
  Future<List<Course>> getCourses();
  Future<List<KnowledgeNode>> search(String query);
  Future<List<KnowledgeNode>> getNodes();
  Future<List<KnowledgeEdge>> getEdges();
  Future<void> rebuildIndex();
}
```

Implementation MVP:

```text
LocalKnowledgeRepository
```

Repository chịu trách nhiệm:

- Đọc dữ liệu từ local index.
- Kết hợp nhiều local services khi cần.
- Chuyển raw data thành domain model.
- Không expose SQLite/file details lên ViewModel.

---

## 3.5. Service / Infrastructure Layer

Service chỉ xử lý data source hoặc platform API.

### MarkdownFileService

- Scan `.md`.
- Read/write file.
- Theo dõi file path.
- File change detection nếu triển khai.

### MarkdownParserService

- Parse YAML frontmatter.
- Parse Markdown sections.
- Parse `[[wikilink]]`.
- Trả về parsed document trung gian.

### SQLiteIndexService

- Store node.
- Store edge.
- Search index.
- Rebuild derived data.
- Query local index.

### ValidationService

- Broken link.
- Duplicate course code.
- Missing metadata.
- Invalid frontmatter.
- Unknown relationship.

Service không chứa UI logic hoặc learning-path business logic.

---

## 4. State Management

### Recommended

**Riverpod** được khuyến nghị cho project.

Lý do:

- Dependency injection rõ.
- Dễ inject repository và graph service.
- Async state thuận tiện.
- Dễ test ViewModel/provider.
- Phù hợp khi nhiều feature cùng dùng `KnowledgeRepository`.

Luồng dependency:

```text
MarkdownService
       ↓
KnowledgeRepository Provider
       ↓
KnowledgeGraphService Provider
       ↓
CourseDetailViewModel Provider
       ↓
CourseDetailView
```

Nếu developer chưa quen Riverpod, `ChangeNotifier` vẫn chấp nhận được cho MVP.

Pattern kiến trúc không phụ thuộc hoàn toàn vào state-management library.

---

## 5. Result Pattern và Error Handling

Khuyến nghị dùng Result Pattern cho các operation có thể thất bại.

Ví dụ lỗi:

```text
InvalidMarkdown
InvalidFrontmatter
BrokenLink
DuplicateCourse
IndexFailure
GraphBuildFailure
```

Thay vì để exception lan qua nhiều layer:

```text
Service
  ↓
Repository
  ↓
ViewModel
```

có thể trả:

```text
Result<T>
├── Success<T>
└── Failure<KnowledgeError>
```

ViewModel chuyển Failure thành UI error state.

---

## 6. Backend Model

MVP **không cần backend server riêng**.

```text
Flutter Widgets      = Presentation
ViewModels           = UI/Application state
Dart Domain Services = Business logic
Repositories         = Data abstraction
SQLite/local index   = Local derived storage
Markdown             = Source of truth
Graph Engine         = Domain logic
```

Không cần:

```text
Flutter
  ↓ HTTP
Remote Backend
  ↓
Database
```

cho MVP.

### Khi nào mới cần remote backend?

Chỉ khi thêm:

- AI API key cần bảo vệ.
- Cloud sync.
- Account.
- Shared knowledge.
- Analytics/rate limit.

---

## 7. Local-first Architecture

Core features phải chạy offline:

- Parse Markdown.
- Build/rebuild Knowledge Index.
- Build Knowledge Graph.
- Query graph.
- Curriculum.
- Course detail.
- Search.
- Graph view.
- Validation.

AI là external feature, không được làm core app phụ thuộc network.

---

## 8. Source of Truth

```text
Markdown files = dữ liệu gốc
Knowledge Index = derived data
Knowledge Graph = derived data
AI              = optional consumer
```

Quy tắc:

- Không lưu official knowledge chỉ trong SQLite.
- Không hardcode relationship trong UI.
- Nếu `.knowledge/index.db` bị xóa, app phải rebuild lại từ Markdown.
- Graph phải được sinh lại từ Markdown/index.

---

## 9. Main Runtime Flows

## 9.1. App Startup

```text
App Start
   ↓
KnowledgeInitializer
   ↓
Check local index
   ↓
Need rebuild?
  /       \
yes       no
 |         |
Rebuild   Load Index
  \       /
     ↓
Load Graph
     ↓
App Ready
```

---

## 9.2. Course Detail

```text
CourseDetailView
       ↓
CourseDetailViewModel
       ↓
┌─────────────────────────────┐
│ KnowledgeRepository         │
│ KnowledgeGraphService       │
└──────────────┬──────────────┘
               ↓
CourseDetailState
```

Output:

```text
course
prerequisites
concepts
futureCourses
relatedCourses
```

---

## 9.3. Search

```text
SearchView
    ↓
SearchViewModel
    ↓
KnowledgeRepository
    ↓
SQLite/local index
    ↓
Search Results
```

---

## 9.4. Graph View

```text
GraphView
   ↓
GraphViewModel
   ↓
KnowledgeGraphService
   ↓
getLocalGraph(nodeId, depth: 1)
   ↓
nodes[] + edges[]
   ↓
Graph Widget
```

Phân biệt:

```text
Graph Engine = tính graph
Graph Widget = render graph
```

---

## 9.5. Build/Rebuild Knowledge

```text
Rebuild Action
      ↓
BuildKnowledgeIndex
      ↓
MarkdownFileService
      ↓
MarkdownParserService
      ↓
Validation
      ↓
KnowledgeRepository
      ↓
Index
      ↓
BuildKnowledgeGraph
```

Đây là workflow phù hợp để dùng Application Use Case.

---

## 10. Folder Structure

Khuyến nghị dùng **feature-first + shared core/domain/data**.

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── dependencies.dart
│
├── core/
│   ├── errors/
│   ├── result/
│   └── utils/
│
├── domain/
│   ├── models/
│   │   ├── course.dart
│   │   ├── concept.dart
│   │   ├── knowledge_node.dart
│   │   └── knowledge_edge.dart
│   │
│   └── graph/
│       └── knowledge_graph_service.dart
│
├── data/
│   ├── services/
│   │   ├── markdown_file_service.dart
│   │   ├── markdown_parser_service.dart
│   │   ├── sqlite_index_service.dart
│   │   └── validation_service.dart
│   │
│   └── repositories/
│       ├── knowledge_repository.dart
│       └── local_knowledge_repository.dart
│
├── application/
│   └── usecases/
│       ├── build_knowledge_index.dart
│       ├── build_knowledge_graph.dart
│       └── get_learning_path.dart
│
└── features/
    ├── curriculum/
    │   ├── curriculum_view.dart
    │   └── curriculum_view_model.dart
    │
    ├── course_detail/
    │   ├── course_detail_view.dart
    │   └── course_detail_view_model.dart
    │
    ├── search/
    │   ├── search_view.dart
    │   └── search_view_model.dart
    │
    ├── graph/
    │   ├── graph_view.dart
    │   └── graph_view_model.dart
    │
    └── diagnostics/
        ├── diagnostics_view.dart
        └── diagnostics_view_model.dart
```

---

## 11. Architecture Rules

### Rule 1

View không gọi SQLite/file system trực tiếp.

### Rule 2

ViewModel không tự parse Markdown.

### Rule 3

Repository không chứa Flutter widget/UI logic.

### Rule 4

Knowledge Graph business rule phải nằm trong Domain Layer.

### Rule 5

Use Case chỉ được tạo khi workflow đủ phức tạp hoặc được reuse.

### Rule 6

Markdown luôn là source of truth.

### Rule 7

Graph/index phải rebuild được.

### Rule 8

Không thêm remote backend nếu MVP chưa cần.

---

## 12. Kiến trúc chốt cho MVP

```text
Simple Feature

View
 ↓
ViewModel
 ↓
Repository
 ↓
Service
```

```text
Complex Knowledge Feature

View
 ↓
ViewModel
 ↓
Domain Service / Use Case
 ↓
Repository
 ↓
Service
```