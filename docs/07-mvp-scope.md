# MVP Scope

## 1. MVP goal

MVP phải chứng minh được core value:

> Kết hợp FPTU SE curriculum knowledge với transcript của sinh viên để cung cấp AI study assistance được cá nhân hóa.

## 2. Confirmed in-scope capabilities

### 2.1 Curriculum

- Hỗ trợ nhiều curriculum version.
- User tự chọn curriculum.
- Load curriculum từ JSON.
- Hiển thị course trong curriculum.
- Keyword search theo code/name.

### 2.2 Course

- Load Course Markdown.
- Course Detail.
- Hiển thị personal context trong Course Detail.
- Hiển thị graph/relationship như secondary feature.

### 2.3 Transcript

- Browser Extension là primary import path.
- File upload là fallback.
- Parse local.
- Preview trước khi import.
- User confirm.
- Replace hoặc Merge.
- Detect unmatched course.
- Mark unmatched course.
- Giữ uploaded transcript file local.

### 2.4 Academic Analysis

- Transcript overview.
- GPA / average grade.
- Low-performing course detection.
- Prerequisite-related analysis.
- Recommended review topics.
- Study Strategy generation.

### 2.5 AI

- Cloud AI.
- Consent trước personalized AI.
- Knowledge-base-bounded answers.
- Source citation.
- Cautious wording.
- Ask user when context insufficient.

### 2.6 Study Strategy

- Dedicated page.
- Structured plan:
  - Goal.
  - Topics to review.
  - Priority/order.
- Save local.

### 2.7 Privacy

- No login.
- Local personal storage.
- User can delete transcript.
- User can delete chat history.
- User can enable/disable chat history.
- User can revoke AI consent.

## 3. Confirmed constraints

- Flutter Desktop.
- MVVM.
- Course Markdown bundled with app.
- Curriculum JSON.
- Keyword search only for MVP search UI.
- Transcript parsing local.
- AI may require internet.
- Curriculum/search/transcript local features must work offline.

## 4. TBD items

Không block việc viết spec, nhưng block implementation tương ứng:

- Course Markdown required fields.
- Local database technology.
- AI provider.
- Direct AI call vs backend/proxy.
- API key strategy.
- Browser target.
- Localhost transport protocol.
- Transcript fallback file formats.
- Knowledge update mechanism.
- RAG implementation without vector DB.
- GPA formula.
- Low-performing-course threshold.
- Study Strategy progress tracking.
- AI revoke behavior for public-knowledge chat.
- Unmatched course usage by AI.
- First-run onboarding.
- Diagnostics/debug screen.
- Fixed delivery timeline.
