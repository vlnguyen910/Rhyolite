# Privacy & Data Policy

## 1. Privacy principle

Ứng dụng ưu tiên local-first storage đối với personal data.

Không có account trong MVP.

Mỗi installation được xem là một local user profile.

## 2. Personal data stored locally

Các dữ liệu sau được lưu local:

- Transcript file đã upload.
- Structured transcript data.
- Grades.
- Academic analysis.
- Study Strategy.
- Chat history nếu được bật.
- AI consent state.

## 3. Cloud AI exception

Personal data có thể được gửi tới cloud AI để thực hiện personalization.

Điều kiện:

- App phải thông báo rõ trước.
- User phải consent.
- User có thể revoke consent.

Đây là ngoại lệ đối với nguyên tắc local storage, không phải cloud persistence của app.

## 4. Raw transcript

Transcript được parse local.

Raw transcript file được giữ local khi import qua file upload.

Không có requirement gửi raw transcript file cho AI provider.

## 5. Browser Extension

Extension:

- Đọc transcript từ FAP.
- Gửi dữ liệu trực tiếp về desktop app qua localhost.
- Không persist transcript sau khi transfer.

Transport cụ thể: `TBD`.

## 6. User control

User phải có khả năng:

- Xóa transcript đã import.
- Xóa AI chat history.
- Revoke AI consent.

Các quyền sau chưa được xác nhận:

- Export all personal data.
- Delete all personal data bằng một thao tác.
- Reset toàn bộ Academic Profile.

## 7. Local encryption

Local encryption không phải requirement MVP đã chốt.

Storage encryption strategy: `TBD`.

## 8. Consent UX

Consent screen phải mô tả:

- AI personalization cần academic data.
- Loại dữ liệu nào có thể được gửi.
- Dữ liệu được gửi tới third-party AI provider.
- User có thể từ chối.
- User có thể revoke về sau.

Exact wording/UI: `TBD`.

## 9. Data minimization

Mức độ data minimization khi gửi cloud AI chưa được chốt.

Không tự mặc định chỉ gửi course code/grade hoặc gửi toàn bộ structured transcript.

Phần payload AI phải được quyết định riêng.

## 10. No account

MVP không yêu cầu:

- Login.
- Cloud user account.
- Cloud profile sync.
- Multi-device sync.
