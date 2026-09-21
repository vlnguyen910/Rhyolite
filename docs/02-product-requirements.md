# Product Requirements

## 1. Curriculum

### PR-CUR-01 — Multiple curriculum versions

Hệ thống phải hỗ trợ nhiều curriculum version của ngành Software Engineering.

### PR-CUR-02 — User selects curriculum version

User tự chọn curriculum version đang sử dụng.

Cơ chế UI cụ thể để chọn curriculum: `TBD`.

### PR-CUR-03 — Curriculum data format

Curriculum structure được lưu dưới dạng JSON.

Curriculum JSON có thể tham chiếu tới course code tương ứng với các Markdown course.

Schema JSON cụ thể: `TBD`.

## 2. Course knowledge

### PR-COURSE-01 — Course Markdown

Mỗi course được biểu diễn bằng một Markdown file.

Course Markdown là Source of Truth.

### PR-COURSE-02 — Course detail

User có thể mở Course Detail để xem thông tin course.

Các field bắt buộc trong Course Markdown: `TBD`.

### PR-COURSE-03 — Personal context in Course Detail

Course Detail phải có khả năng hiển thị context cá nhân của user khi transcript đã được import.

Ví dụ loại context có thể bao gồm trạng thái và grade tương ứng.

Cách trình bày UI cụ thể: `TBD`.

## 3. Search

### PR-SEARCH-01 — Keyword search

MVP hỗ trợ keyword search theo:

- Course code.
- Course name.

Semantic search không phải requirement đã chốt cho UI search.

## 4. Course relationships

### PR-GRAPH-01 — Graph as secondary Course Detail feature

Knowledge Graph không phải main navigation feature.

Graph được hiển thị như một phần phụ trong Course Detail.

Course Detail graph biểu diễn course đang chọn, prerequisite/dependent course,
syllabus topic và personal note. Curriculum overview graph được truy cập từ
dashboard hoặc curriculum page và không chiếm một main navigation destination.

### PR-GRAPH-02 — Relation types

Các relation type trong MVP:

- `prerequisite`: course tiên quyết dẫn tới course phụ thuộc.
- `syllabus-topic`: course dẫn tới module/topic trích từ syllabus.
- `personal-note`: course dẫn tới note do sinh viên tạo.

## 5. Transcript import

### PR-TRANSCRIPT-01 — Primary import method

Browser Extension là phương thức chính để lấy transcript.

### PR-TRANSCRIPT-02 — Extension to desktop flow

Browser Extension đọc dữ liệu từ FAP và gửi trực tiếp tới desktop app thông qua localhost.

Transport protocol cụ thể: `TBD`.

### PR-TRANSCRIPT-03 — Extension persistence

Browser Extension không được lưu persistent transcript data sau khi transfer hoàn tất.

### PR-TRANSCRIPT-04 — Desktop preview

Desktop app phải hiển thị dữ liệu transcript đã nhận để user preview trước khi import.

User phải confirm trước khi lưu.

### PR-TRANSCRIPT-05 — File upload fallback

App phải có file upload transcript làm fallback.

File format MVP hỗ trợ: `TBD`.

### PR-TRANSCRIPT-06 — Local parsing

Transcript parsing phải diễn ra local trước khi AI processing.

### PR-TRANSCRIPT-07 — Original file retention

Nếu user import bằng file upload, file transcript gốc được giữ local.

Vị trí lưu cụ thể: `TBD`.

### PR-TRANSCRIPT-08 — Re-import behavior

Khi import transcript mới, app phải cho user chọn:

- Replace.
- Merge.

### PR-TRANSCRIPT-09 — Unmatched courses

Nếu course trong transcript không match curriculum đã chọn:

- App phải thông báo cho user.
- App phải đánh dấu course nào không match.

Business rule cho unmatched course sau đó: `TBD`.

## 6. Academic Profile

### PR-PROFILE-01 — Scope

Academic Profile chỉ dựa trên bảng điểm.

Không thêm các dữ liệu như:

- Career goal.
- Target GPA.
- Weekly study time.
- Learning style.

trừ khi có quyết định mới.

## 7. Academic Analysis

MVP phải hỗ trợ các loại phân tích sau:

### PR-ANALYSIS-01 — Transcript overview

Hiển thị tổng quan bảng điểm.

### PR-ANALYSIS-02 — Low-performing courses

Xác định các môn có kết quả thấp cần chú ý.

Ngưỡng hoặc rule cụ thể: `TBD`.

### PR-ANALYSIS-03 — GPA / average grade

Hiển thị GPA hoặc average grade dựa trên dữ liệu transcript.

Công thức cụ thể phụ thuộc format transcript và được để `TBD`.

### PR-ANALYSIS-04 — Prerequisite analysis

Phân tích prerequisite liên quan tới course hoặc course sắp học.

### PR-ANALYSIS-05 — Review-topic recommendation

Đề xuất các topic nên ôn lại.

### PR-ANALYSIS-06 — Study Strategy generation

Tạo Study Strategy có cấu trúc.

## 8. AI Chatbot

### PR-AI-00 — Local course Q&A

Các câu hỏi cơ bản về course/curriculum có thể được trả lời offline trực tiếp từ
bundled Markdown và curriculum JSON. Câu trả lời phải chỉ ra syllabus source khi
có. Tính năng này không gửi academic data tới cloud AI.

### PR-AI-01 — Knowledge boundary

Chatbot chỉ được trả lời dựa trên:

- Project knowledge base.
- Local student data được phép sử dụng.

Chatbot không được tự do sử dụng unrestricted general model knowledge như một nguồn độc lập.

### PR-AI-02 — Source citation

AI response phải chỉ ra source/course Markdown mà câu trả lời dựa trên.

### PR-AI-03 — Insufficient context

Nếu không đủ dữ liệu để đưa recommendation cá nhân hóa, chatbot phải hỏi user thêm thông tin thay vì tự suy diễn.

### PR-AI-04 — Cautious academic language

AI không nên gắn nhãn mạnh như:

- "Bạn yếu môn X".
- "Bạn kém kỹ năng Y".

Ưu tiên wording như:

- "Nên củng cố..."
- "Kết quả hiện tại cho thấy có thể cần cải thiện..."
- "Bạn có thể ưu tiên ôn lại..."

## 9. Study Strategy

### PR-STRATEGY-01 — Dedicated feature

Study Strategy có trang riêng.

### PR-STRATEGY-02 — Structure

Study Strategy phải có cấu trúc tối thiểu:

1. Goal.
2. Topics cần ôn.
3. Priority / thứ tự học.

### PR-STRATEGY-03 — Local persistence

Study Strategy được lưu local.

Progress tracking: `TBD`.

## 10. Chat history

### PR-CHAT-01 — Optional persistence

User có thể bật hoặc tắt việc lưu chat history.

### PR-CHAT-02 — Local only

Chat history được lưu local.

### PR-CHAT-03 — Delete

User có thể xóa AI chat history.

## 11. Personalization inputs

Personalization có thể sử dụng:

- Grades.
- Prerequisite relationships.
- Selected curriculum version.
- Chat history nếu user bật lưu.

## 12. UI decisions not yet finalized

Các UI decision sau chưa được chốt:

- Curriculum main layout.
- First-run onboarding.
- Diagnostics screen.
- Full navigation structure.
