# Scope and Assumptions

## 1. Must Have - MVP 3 tuần

- Standalone Flutter desktop app.
- Built-in FPTU SE curriculum knowledge base.
- Mỗi course có một file Markdown riêng.
- Markdown frontmatter.
- `[[wikilink]]`.
- Markdown parser.
- Local knowledge index.
- Course node.
- Concept node cơ bản.
- Typed relationships.
- Knowledge Graph engine.
- Curriculum screen.
- Course detail screen.
- Before this course.
- Topics / concepts.
- After this course.
- Search.
- Local graph view.
- Data validation.
- Desktop release build.

## 2. Should Have

- Backlinks.
- Global graph view.
- Personal Markdown notes.
- Re-index file khi thay đổi.
- Basic learning path traversal.

## 3. Could Have / Phase 2

- AI assistant.
- RAG.
- Semantic search.
- Graph-assisted retrieval.
- Natural language learning path.
- Personal learning history.
- Smart recommendation.
- Obsidian interoperability nâng cao.

## 4. Out of Scope cho MVP

- Mobile app.
- Login/account.
- Backend server.
- Cloud sync.
- Realtime collaboration.
- Social features.
- Plugin marketplace.
- Neo4j server.
- Vector database.
- Advanced Markdown editor.
- Automatic web crawling.
- AI tự tạo curriculum không có nguồn.

## 5. Assumptions

1. MVP được thực hiện bởi **4 developer chính**.
2. Thời gian implementation là **3 tuần làm việc**.
3. Chỉ cần **một desktop platform chính** để demo/release trong MVP; platform khác là best effort.
4. AI không bắt buộc để MVP hoàn thành.
5. Curriculum và course data được thu thập từ nguồn có thể xác minh như curriculum, syllabus hoặc tài liệu chính thức.
6. Obsidian chỉ là design inspiration và optional compatibility target.
7. App phải hoạt động độc lập, không yêu cầu cài Obsidian.

## 6. Priority

### P0 - Bắt buộc

- Flutter desktop foundation.
- Course Markdown dataset.
- Parser.
- Knowledge Index.
- Graph engine.
- Curriculum screen.
- Course detail.
- Prerequisite/future relationship.
- Search.
- Local graph.
- Validation.
- Release.

### P1 - Nên có

- Global graph.
- Backlinks.
- Path query.
- Diagnostics UI.

### P2 - Chỉ làm nếu còn thời gian

- Personal notes.
- AI/RAG.
- Semantic search.
- Obsidian integration.
