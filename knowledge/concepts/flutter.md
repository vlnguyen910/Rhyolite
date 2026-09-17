---
id: "concept:flutter"
type: concept
title: "Flutter"
courses: ["course:PRM393"]
related: ["concept:dart", "concept:state-management"]
sources:
  - https://docs.flutter.dev/flutter-for/declarative
  - https://flm.fpt.edu.vn/gui/role/student/SyllabusDetails?sylID=13822
demo: false
---

# Flutter

Ghi chú khởi đầu được AI biên soạn từ nguồn để nhóm review; người học cần bổ sung ví dụ và giải thích riêng.
Liên hệ PRM393 dựa trên CLO1–CLO2 trong syllabus lưu tại vault.

## Mental model

Giao diện được mô tả bằng cây widget. Khi state thay đổi, Flutter xây lại phần mô tả UI tương ứng thay vì yêu cầu ta sửa từng thành phần giao diện bằng tay.

## Thực hành

Tạo màn hình danh sách môn và truyền Course được chọn sang trang chi tiết.

## Câu hỏi

- Widget và state có vai trò gì?
- Khi nào dữ liệu nên được đưa ra khỏi widget? Xem [[state-management]].

## Nguồn

- [Declarative UI](https://docs.flutter.dev/flutter-for/declarative)
- [[dart]]
