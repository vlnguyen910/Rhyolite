# Project Overview

## 1. Tên dự án

**FPTU SE Personalized Study Assistant**

## 2. Product vision

Ứng dụng đóng vai trò là một **trợ lý học tập được cá nhân hóa** cho sinh viên ngành Software Engineering tại FPT University.

Ứng dụng kết hợp:

- Curriculum knowledge.
- Course knowledge.
- Quan hệ giữa các môn học.
- Dữ liệu bảng điểm của sinh viên.
- AI chatbot.
- Study Strategy.

Mục tiêu là giúp sinh viên:

- Hiểu chương trình học tổng thể.
- Tra cứu thông tin môn học.
- Hiểu môn nào là nền tảng cho môn nào.
- Nhận biết những môn hoặc nhóm kiến thức nên củng cố.
- Nhận gợi ý học tập phù hợp với kết quả học tập cá nhân.
- Tạo Study Strategy dựa trên curriculum và transcript.

## 3. Target users

### Primary user

Sinh viên ngành **Software Engineering — FPT University**.

Ứng dụng hỗ trợ **nhiều curriculum version** khác nhau.

User tự chọn curriculum version của mình.

## 4. Core product principles

### 4.1 Markdown as Source of Truth

Thông tin course được lưu dưới dạng Markdown.

Markdown course là nguồn dữ liệu chính thức của ứng dụng đối với thông tin môn học.

Các index, graph hoặc cache được tạo ra từ Markdown chỉ là derived data và không được xem là Source of Truth.

### 4.2 Local-first personal data

Dữ liệu cá nhân của sinh viên được lưu local trên thiết bị.

Bao gồm:

- Transcript đã import.
- Structured grade data.
- Academic analysis.
- Study Strategy.
- Chat history nếu user bật lưu history.

### 4.3 Personalization-first

Knowledge Graph, search và curriculum không phải mục tiêu độc lập.

Các thành phần này phục vụ mục tiêu chính:

> tạo trải nghiệm học tập được cá nhân hóa từ curriculum + transcript + AI.

### 4.4 Privacy-aware cloud AI

AI có thể sử dụng cloud provider.

Trước khi personalized AI được sử dụng:

- App phải giải thích dữ liệu nào có thể được gửi tới AI provider.
- User phải consent.
- User có thể revoke consent trong Settings.

## 5. Core product capabilities

1. Curriculum Explorer.
2. Course Detail.
3. Keyword Search.
4. Course Relationship / Knowledge Graph trong Course Detail.
5. Transcript import bằng Browser Extension.
6. Transcript import bằng file upload fallback.
7. Academic Analysis.
8. AI Chatbot.
9. Personalized Study Strategy.
10. Local data management.
11. AI privacy consent.

## 6. Out of scope / chưa xác nhận

Các capability sau chưa được xác nhận là requirement:

- Social features.
- LMS.
- Assignment submission.
- Teacher management.
- Classroom management.
- Online examination.
- Cloud account sync.
- Multi-device personal-data sync.
- Semantic search trong UI.
- Predict chính xác điểm số tương lai.

Không đưa các capability này vào implementation nếu chưa có quyết định mới.
