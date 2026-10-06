# Technical Architecture

## 1. Platform

Desktop application sử dụng **Flutter**.

## 2. Architecture pattern

Ứng dụng theo hướng **MVVM**.

High-level structure:

```text
View
  ↓
ViewModel
  ↓
Application / Service Layer
  ↓
Knowledge / Transcript / AI Services
  ↓
Local Storage + Bundled Knowledge
```

Tên package/folder cụ thể: `TBD`.

## 3. High-level architecture

```text
┌────────────────────────────────────────────┐
│               Flutter Desktop              │
│                                            │
│ Curriculum  Course Detail  Search          │
│ Transcript  AI Chat        Study Strategy  │
└─────────────────────┬──────────────────────┘
                      │
                    MVVM
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
 Knowledge        Transcript        AI
 Service           Service        Service
        │             │             │
        ▼             ▼             ▼
 Markdown +       Local Parser   Cloud AI
 Curriculum JSON     │            Provider
        │             │             │
        └──────┬──────┴──────┬─────┘
               ▼             ▼
         Local Storage   Local Chat /
                         Strategy Data
```

## 4. Knowledge storage

### Course knowledge

- Markdown.
- Bundled with app.
- Source of Truth.

### Curriculum

- JSON.
- Supports multiple curriculum versions.

## 5. Local database

Local database technology: `TBD`.

Không tự chốt SQLite hay một Flutter ORM trước khi có quyết định.

## 6. Search

MVP search:

- Keyword search.
- Course code.
- Course name.

## 7. Graph

Knowledge Graph là secondary feature trong Course Detail.

Graph engine implementation: `TBD`.

## 8. Browser Extension integration

Flow:

```text
FAP
 ↓
Browser Extension
 ↓
Extract Transcript
 ↓
localhost
 ↓
Flutter Desktop
 ↓
Preview
 ↓
User Confirm
 ↓
Local Storage
```

Browser target: `TBD`.

Local transport:

- HTTP / WebSocket / Native Messaging / khác: `TBD`.

Requirement duy nhất đã chốt là data đi trực tiếp về desktop app qua localhost.

## 9. Transcript pipeline

```text
Input
 ↓
Local Parser
 ↓
Structured Transcript
 ↓
Validation / Match Curriculum
 ↓
Preview
 ↓
User Confirm
 ↓
Replace or Merge
 ↓
Local Storage
```

Nếu course không match:

```text
Course not matched
 ↓
Show warning
 ↓
Mark unmatched course
```

Post-warning behavior: `TBD`.

## 10. AI architecture

MVP provider: Groq qua OpenAI-compatible Chat Completions API.

```text
Flutter → GroqCourseAssistantService → Groq API
                       ↓ khi lỗi/chưa có key
              CourseAssistantService local
```

Flutter gọi Groq trực tiếp trong bản lab desktop. Provider nằm sau
`ICourseAssistantService` để có thể chuyển sang backend/proxy mà không đổi UI.
Key được đọc từ biến môi trường hệ điều hành hoặc `.env` local đã bị Git ignore;
không hard-code hoặc bundle key vào source.

## 11. Retrieval architecture

Định hướng target:

- RAG/vector-style retrieval.

Constraint hiện tại:

- MVP không yêu cầu vector database.
- Retrieval implementation cụ thể chưa được chốt.

Do đó retrieval layer phải được thiết kế sao cho strategy có thể thay đổi mà không ảnh hưởng View/ViewModel.

## 12. Offline capability

Phải hoạt động offline:

- Curriculum.
- Course information.
- Keyword search.
- Local transcript data.

AI có thể yêu cầu internet.

## 13. Security

Không có requirement local encryption đã chốt.

Không được tự thêm encryption dependency vào MVP nếu chưa có quyết định mới.
