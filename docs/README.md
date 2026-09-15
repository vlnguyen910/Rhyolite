# FPTU SE Knowledge - Documentation

Bộ tài liệu cho dự án **FPTU SE Knowledge - Obsidian-inspired Second Brain**.

## Cấu trúc

```text
fptu-se-knowledge-docs/
├── README.md
├── project/
│   ├── 01-overview.md
│   ├── 02-scope-and-assumptions.md
│   ├── 03-product-requirements.md
│   ├── 04-milestones-and-plan.md
│   └── 05-acceptance-demo-risks-outcome.md
└── technical/
    ├── 01-architecture.md
    ├── 02-knowledge-base-and-markdown-schema.md
    ├── 03-knowledge-index.md
    ├── 04-knowledge-graph.md
    ├── 05-ui-and-search.md
    ├── 06-validation-testing-and-performance.md
    └── 07-ai-phase-2.md
```

## Nhóm `project/`

Chứa thông tin quản lý và định nghĩa sản phẩm:

- Tổng quan và mục đích.
- Scope.
- Assumptions.
- Product requirements.
- Milestones và kế hoạch 3 tuần.
- Acceptance criteria.
- Demo flow.
- Risks.
- Outcome cuối.

## Nhóm `technical/`

Chứa tài liệu kỹ thuật phục vụ implementation:

- Kiến trúc Flutter desktop.
- Markdown knowledge base.
- Knowledge Index.
- Knowledge Graph.
- Search và UI.
- Validation, test, performance.
- AI/RAG Phase 2.

## Nguyên tắc cốt lõi

```text
Markdown files = Source of Truth
Index          = Derived Data
Graph          = Derived Data
Flutter        = Desktop Application
AI             = Optional Explanation Layer
```

Ứng dụng phải chạy độc lập, không yêu cầu Obsidian. Obsidian chỉ là nguồn cảm hứng cho Markdown, wikilink, backlink, graph và local-first workflow.
