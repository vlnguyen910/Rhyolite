# Knowledge Specification

## 1. Knowledge architecture

Knowledge được chia thành hai phần chính:

```text
knowledge/
├── curricula/
│   └── <curriculum-version>.json
└── courses/
    ├── <COURSE_CODE>.md
    └── ...
```

Tên folder cụ thể có thể thay đổi trong implementation, nhưng hai loại Source Data phải được giữ tách biệt:

- Curriculum structure: JSON.
- Course knowledge: Markdown.

## 2. Course Markdown

### 2.1 Source of Truth

Course Markdown là Source of Truth cho course knowledge.

Mọi derived representation phải có khả năng rebuild từ Markdown.

### 2.2 Required fields

Danh sách field bắt buộc: `TBD`.

Không tự mặc định các field như:

- Credits.
- Topics.
- CLO.
- Grading structure.
- Learning resources.
- Study tips.

cho tới khi có quyết định.

### 2.3 Content ownership

Developer/team nhập và cập nhật Markdown thủ công từ nguồn FPTU.

Không có requirement cho automatic crawler/import pipeline ở thời điểm hiện tại.

### 2.4 Official vs curated

Không cần phân tách Official Knowledge và Curated Knowledge thành hai lớp business khác nhau.

Toàn bộ được sử dụng như một knowledge base thống nhất.

## 3. Curriculum JSON

### 3.1 Purpose

Curriculum JSON mô tả cấu trúc chương trình học của từng curriculum version.

### 3.2 Multiple versions

Mỗi curriculum version phải có identifier riêng.

Naming/versioning convention: `TBD`.

### 3.3 Course references

Curriculum phải có cách tham chiếu course bằng course code.

Schema đầy đủ: `TBD`.

## 4. Knowledge relationships

Knowledge relationship được dùng cho:

- Course Detail.
- Knowledge Graph.
- Prerequisite analysis.
- AI personalization.

Các relation type chính thức: `TBD`.

## 5. Derived data

Các dữ liệu sau không phải Source of Truth:

- Search index.
- Graph cache.
- AI retrieval index.
- Parsed course model.
- Runtime course relation map.

Derived data phải có khả năng xóa và rebuild.

## 6. Knowledge packaging

Course Markdown được bundle trực tiếp cùng app.

Cơ chế update knowledge độc lập với app release: `TBD`.

## 7. Search behavior

MVP search chỉ yêu cầu:

- Match course code.
- Match course name.

Ranking rule: `TBD`.

## 8. AI retrieval

Định hướng đã chọn:

- AI context retrieval theo hướng RAG/vector search.

Tuy nhiên:

- MVP không yêu cầu embedding/vector database.
- Vì vậy implementation cụ thể của retrieval layer hiện đang `TBD`.

Đây là một quyết định kỹ thuật còn mở và không được tự động suy ra trong implementation.

## 9. Source citation

AI answer phải có khả năng map context trở lại course/source Markdown để hiển thị citation cho user.
