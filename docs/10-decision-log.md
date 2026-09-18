# Decision Log

## Confirmed product decisions

| ID | Decision |
|---|---|
| D-001 | Product là personalized study assistant cho FPTU SE students. |
| D-002 | Hỗ trợ nhiều curriculum version. |
| D-003 | User tự chọn curriculum version. |
| D-004 | Course knowledge dùng Markdown làm Source of Truth. |
| D-005 | Curriculum structure dùng JSON. |
| D-006 | Knowledge được developer/team cập nhật thủ công từ nguồn FPTU. |
| D-007 | Không tách Official và Curated thành hai knowledge layer business riêng. |
| D-008 | MVP không có account/login. |
| D-009 | Academic Profile chỉ dựa trên transcript/grades. |
| D-010 | Browser Extension là primary transcript import path. |
| D-011 | File upload là fallback. |
| D-012 | Original uploaded transcript file được giữ local. |
| D-013 | AI dùng cloud, không dùng Local LLM. |
| D-014 | AI dùng cautious wording thay vì mạnh tay gắn nhãn weak/strong. |
| D-015 | Academic Analysis gồm overview, low-performing courses, prerequisite analysis, review topics, Study Strategy, GPA/average. |
| D-016 | Study Strategy có page riêng. |
| D-017 | Chat history có setting bật/tắt. |
| D-018 | Chatbot chỉ dựa trên project knowledge + local student data được cung cấp. |
| D-019 | Khi thiếu context, AI hỏi thêm user. |
| D-020 | Personalization có thể dùng grades + prerequisite + curriculum version + chat history. |
| D-021 | Local encryption không phải MVP requirement đã chốt. |
| D-022 | User có thể xóa transcript và chat history. |
| D-023 | Curriculum/search/transcript phải hoạt động offline; AI có thể cần internet. |
| D-024 | Academic data có thể gửi cloud AI nếu user được thông báo và consent. |
| D-025 | Knowledge Graph là secondary feature trong Course Detail. |
| D-026 | MVP search chỉ keyword theo course code/name. |
| D-027 | Course Detail có personal context. |
| D-028 | Curriculum main UI chưa quyết định. |
| D-029 | Study Strategy = Goal → Topics → Priority/order. |
| D-030 | Study Strategy lưu local. |
| D-031 | Extension gửi transcript trực tiếp về desktop qua localhost. |
| D-032 | Extension không persist transcript sau transfer. |
| D-033 | Import mới cho user chọn Replace hoặc Merge. |
| D-034 | Course không match phải được thông báo và đánh dấu. |
| D-035 | Knowledge update mechanism chưa quyết định. |
| D-036 | Desktop app dùng Flutter. |
| D-037 | Kiến trúc theo MVVM. |
| D-038 | Local database chưa quyết định. |
| D-039 | Course Markdown bundle trực tiếp trong app. |
| D-040 | Cloud AI provider chưa quyết định. |
| D-041 | Direct AI call hay backend/proxy chưa quyết định. |
| D-042 | API key strategy chưa quyết định. |
| D-043 | Định hướng AI retrieval là RAG/vector search. |
| D-044 | MVP không yêu cầu vector database. |
| D-045 | AI response phải cite source/course Markdown. |
| D-046 | Transcript parsing diễn ra local. |
| D-047 | Browser target chưa quyết định. |
| D-048 | Extension localhost transport chưa quyết định. |
| D-049 | Desktop phải preview transcript và user confirm trước import. |
| D-050 | AI consent: giải thích dữ liệu → consent một lần → có thể revoke trong Settings. |

## Open decisions

| ID | TBD |
|---|---|
| T-001 | Required fields của Course Markdown. |
| T-002 | Curriculum JSON schema. |
| T-003 | Local database technology. |
| T-004 | Cloud AI provider. |
| T-005 | Direct AI call vs backend/proxy. |
| T-006 | API key handling. |
| T-007 | Browser Extension target browser. |
| T-008 | Localhost transport protocol. |
| T-009 | File format cho transcript upload fallback. |
| T-010 | Knowledge Graph relation types. |
| T-011 | Curriculum UI layout. |
| T-012 | Knowledge update mechanism. |
| T-013 | RAG implementation không dùng vector DB. |
| T-014 | GPA/average formula. |
| T-015 | Low-performing-course rule/threshold. |
| T-016 | Study Strategy progress tracking. |
| T-017 | AI behavior sau revoke consent đối với public knowledge chat. |
| T-018 | Unmatched course có được dùng bởi AI hay không. |
| T-019 | First-run onboarding. |
| T-020 | Diagnostics screen. |
| T-021 | Fixed implementation timeline. |
| T-022 | Merge conflict rule. |
| T-023 | Data minimization payload gửi cloud AI. |
