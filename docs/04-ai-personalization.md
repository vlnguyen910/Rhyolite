# AI & Personalization Specification

## 1. Role of AI

AI là một core feature của sản phẩm.

AI phục vụ:

- Hỏi đáp về curriculum.
- Hỏi đáp về course.
- Phân tích transcript.
- Phân tích prerequisite liên quan tới tình trạng học tập.
- Đề xuất topic cần củng cố.
- Tạo Study Strategy.

## 2. AI provider

Cloud AI provider của MVP: Groq, dùng OpenAI-compatible Chat Completions API.
Model được cấu hình bằng `GROQ_MODEL` để có thể thay đổi mà không sửa UI.

## 3. AI call architecture

Desktop app lab gọi Groq trực tiếp qua `GroqCourseAssistantService`. Key được đọc
từ `GROQ_API_KEY` trong environment hoặc `.env` local bị Git ignore. Khi không có
key hoặc request lỗi, app dùng local assistant. Interface service giữ khả năng
chuyển sang backend/proxy cho bản phân phối rộng hơn.

## 4. Knowledge boundary

AI chỉ được dựa trên:

1. Knowledge base của project.
2. Local academic data mà user cho phép sử dụng.
3. Context từ conversation nếu chat history được bật.

AI không được tự do dùng general knowledge của model như nguồn chính thức nếu knowledge base không cung cấp thông tin đó.

## 5. Personalization inputs

AI personalization có thể sử dụng:

- Selected curriculum version.
- Transcript grades.
- Course relationships.
- Prerequisite context.
- Chat history nếu được bật.

## 6. Academic analysis behavior

AI phải dùng wording thận trọng.

Không nên nói:

> Bạn yếu Data Structures.

Nên nói:

> Kết quả hiện tại cho thấy bạn có thể cần củng cố Data Structures trước khi học các môn phụ thuộc vào nền tảng này.

## 7. Insufficient context

Nếu context không đủ:

- AI phải hỏi user thêm thông tin.
- AI không được bịa course relation.
- AI không được bịa grade.
- AI không được bịa curriculum requirement.

## 8. Study Strategy

Study Strategy là structured output gồm:

```text
Goal
  ↓
Topics to Review
  ↓
Priority / Order
```

Các field chi tiết của structured output: `TBD`.

Study Strategy được lưu local.

## 9. Source citation

Mỗi AI response dựa trên course knowledge phải có citation/source reference.

Citation cần ít nhất map được tới:

- Course code.
- Markdown source.

Format UI: `TBD`.

## 10. Transcript handling

Transcript parsing diễn ra local.

Raw transcript file không cần được gửi cho AI để parse.

Dữ liệu academic sau khi parse có thể được gửi tới cloud AI nếu:

- AI personalization cần dữ liệu đó.
- User đã consent.

## 11. AI consent

Trước khi personalized AI được bật:

1. App giải thích dữ liệu nào có thể được gửi.
2. App giải thích dữ liệu được gửi tới third-party AI service.
3. User chủ động consent.
4. Consent được ghi nhận local.
5. User có thể revoke consent trong Settings.

Sau khi revoke, behavior chính xác của chatbot đối với public knowledge: `TBD`.

## 12. Chat history

User có thể bật/tắt việc lưu history.

Nếu bật:

- History lưu local.
- History có thể được dùng làm personalization context.

User có thể xóa history.

## 13. Internet dependency

AI có thể cần internet.

Các feature bắt buộc hoạt động offline:

- Curriculum.
- Search.
- Transcript-related local features.

Exact offline behavior của AI UI: `TBD`.
