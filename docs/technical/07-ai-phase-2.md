# AI / RAG - Phase 2

## 1. Vai trò AI

AI không thay thế Knowledge Graph.

```text
Knowledge Graph
      ↓
Question Answering
      ↓
AI Explanation
```

Graph giữ facts và relationships. AI dùng facts để giải thích bằng ngôn ngữ tự nhiên.

## 2. Không cần AI cho structured query

Các câu hỏi sau có thể query graph trực tiếp:

```text
CSD201 prerequisite là gì?
Môn nào học sau CSD201?
CSD201 dạy concept nào?
A liên kết với B qua path nào?
```

## 3. AI phù hợp cho open-ended question

Ví dụ:

```text
Tại sao CSD201 quan trọng với SWD392?
Tôi muốn theo backend thì nên chú ý môn nào?
Giải thích learning path từ A tới B.
```

## 4. Suggested Pipeline

```text
User Question
      ↓
Find relevant course/concept
      ↓
Query / expand Knowledge Graph
      ↓
Retrieve related Markdown
      ↓
Build context
      ↓
LLM
      ↓
Answer + Sources
```

## 5. MVP AI Recommendation

Nếu còn thời gian:

- Không cần vector database.
- Không cần GraphRAG phức tạp.
- Dùng graph retrieval + Markdown retrieval + LLM.

## 6. AI Acceptance Criteria

- Retrieve knowledge trước khi trả lời.
- Answer có source.
- Không invent curriculum.
- Khi thiếu dữ liệu phải nói rõ không đủ dữ liệu.
- Phân biệt stored facts và phần giải thích.

## 7. Backend cho AI

Core app vẫn local.

Nếu gọi model trực tiếp trong demo:

```text
Flutter
  ↓
AI Provider API
```

Đơn giản nhưng API key có thể bị extract.

Kiến trúc dài hạn:

```text
Flutter Desktop
      ↓
Minimal Remote Backend
      ↓
AI Provider
```

Remote backend chỉ cần khi cần bảo vệ API key, rate limiting hoặc cloud feature.
