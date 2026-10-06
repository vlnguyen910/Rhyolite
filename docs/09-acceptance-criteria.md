# Acceptance Criteria

## AC-01 — Curriculum selection

**Given** app có nhiều curriculum version  
**When** user chọn một curriculum  
**Then** app sử dụng đúng curriculum đó cho course listing, relationship và personalization context.

## AC-02 — Markdown Source of Truth

**Given** một course tồn tại trong bundled Markdown  
**When** app load course  
**Then** course knowledge được lấy từ Markdown tương ứng.

Derived cache/index không được trở thành nguồn dữ liệu ưu tiên hơn Markdown.

## AC-03 — Keyword search

**Given** knowledge đã load  
**When** user search bằng course code hoặc course name  
**Then** app trả về course phù hợp.

## AC-04 — Course Detail

**Given** user mở một course  
**Then** app hiển thị course knowledge.

**And** nếu transcript có dữ liệu course tương ứng, Course Detail hiển thị personal context.

## AC-05 — Graph placement

**Given** user đang ở Course Detail  
**Then** graph/relationship có thể được truy cập như một secondary section.

Không cần main standalone Graph screen để đạt acceptance hiện tại.

## AC-06 — Extension import

**Given** extension lấy được transcript từ FAP  
**When** transfer hoàn tất  
**Then** desktop app nhận được structured data qua localhost.

**And** extension không persist transcript sau transfer.

## AC-07 — Preview before import

**Given** desktop nhận transcript từ extension hoặc file parser  
**Then** user phải được xem preview trước khi dữ liệu được lưu.

**And** import chỉ hoàn tất sau khi user confirm.

## AC-08 — Unmatched course

**Given** transcript có course code không tồn tại trong selected curriculum  
**Then** app hiển thị warning.

**And** app đánh dấu rõ course nào không match.

## AC-09 — Replace / Merge

**Given** app đã có transcript  
**When** user import transcript mới  
**Then** app cho user chọn Replace hoặc Merge.

Chi tiết merge conflict phụ thuộc business rule `TBD`.

## AC-10 — Local transcript parsing

**Given** user import transcript file  
**When** parsing diễn ra  
**Then** parsing được thực hiện local.

Raw file không cần upload tới AI để parse.

## AC-11 — Transcript deletion

**Given** user đã import transcript  
**When** user thực hiện delete transcript  
**Then** dữ liệu transcript local tương ứng bị xóa khỏi active profile.

Chi tiết xử lý file gốc liên quan: `TBD` nếu chưa được quyết định riêng.

## AC-12 — Academic overview

**Given** transcript hợp lệ  
**When** user mở Academic Analysis  
**Then** app có thể hiển thị transcript overview.

## AC-13 — GPA / average

**Given** transcript chứa dữ liệu cần thiết  
**When** calculation rule đã được cấu hình  
**Then** app hiển thị GPA/average đúng theo rule được chốt.

## AC-14 — Low-performing course analysis

**Given** low-performance rule đã được xác định  
**When** transcript được phân tích  
**Then** app xác định đúng các course cần chú ý theo rule.

## AC-15 — Prerequisite analysis

**Given** course relationship và transcript  
**When** user yêu cầu phân tích course liên quan  
**Then** app có thể xác định prerequisite context phù hợp với selected curriculum.

## AC-16 — AI consent required

**Given** user chưa consent  
**When** personalized AI cần gửi academic data lên cloud  
**Then** app không được gửi dữ liệu đó.

## AC-17 — Consent explanation

Trước khi consent, UI phải giải thích:

- Dữ liệu academic có thể được gửi.
- Dữ liệu được gửi tới third-party AI provider.
- User có thể từ chối.
- User có thể revoke sau.

## AC-18 — Revoke consent

**Given** user đã consent  
**When** user revoke consent  
**Then** app cập nhật local consent state và không tiếp tục gửi academic data cho personalized AI.

Behavior của public-knowledge chatbot sau revoke: `TBD`.

## AC-19 — AI knowledge boundary

**Given** AI trả lời câu hỏi về curriculum/course  
**Then** câu trả lời phải dựa trên project knowledge context được cung cấp.

Nếu không đủ context, AI phải hỏi thêm hoặc báo thiếu dữ liệu thay vì bịa.

## AC-20 — AI source citation

**Given** AI response sử dụng course knowledge  
**Then** response phải có reference tới source/course Markdown liên quan.

## AC-21 — AI wording

AI analysis không được mặc định dùng kết luận mạnh như "bạn yếu" chỉ dựa trên một grade.

Recommendation phải dùng wording thận trọng theo requirement.

## AC-22 — Study Strategy structure

**Given** AI tạo Study Strategy  
**Then** output tối thiểu có:

- Goal.
- Topics to review.
- Priority/order.

## AC-23 — Study Strategy persistence

**Given** Study Strategy đã được tạo  
**When** user đóng/mở lại app  
**Then** strategy vẫn tồn tại local, nếu storage implementation hoạt động đúng.

## AC-24 — Chat history preference

**Given** user tắt history  
**Then** app không persist conversation history mới.

**Given** user bật history  
**Then** app có thể lưu history local.

## AC-25 — Delete chat history

**Given** history tồn tại  
**When** user chọn delete  
**Then** history local bị xóa.

## AC-26 — Offline curriculum

Không có internet:

- Curriculum vẫn xem được.
- Course knowledge vẫn xem được.
- Keyword search vẫn dùng được.

## AC-27 — Offline transcript

Không có internet:

- Transcript local vẫn xem được.
- Local transcript-related feature không phụ thuộc AI vẫn hoạt động.

## AC-28 — No account requirement

User phải có thể sử dụng MVP mà không cần login hoặc tạo cloud account.
