---
id: "concept:state-management"
type: concept
title: "State management"
courses: ["course:PRM393"]
related: ["concept:flutter"]
sources:
  - https://docs.flutter.dev/data-and-backend/state-mgmt/intro
  - https://flm.fpt.edu.vn/gui/role/student/SyllabusDetails?sylID=13822
demo: false
---

# State management

Ghi chú khởi đầu được AI biên soạn từ nguồn để nhóm review; bổ sung bằng chứng thực hành trước khi tự đánh giá hiểu biết.
Liên hệ PRM393 dựa trên CLO3 trong syllabus lưu tại vault.

## Mental model

State management tổ chức dữ liệu có thể thay đổi và cách UI phản ánh thay đổi đó. Cần xác định dữ liệu thuộc một widget hay được nhiều màn hình dùng chung.

## Thực hành

Theo dõi query tìm kiếm và môn đang chọn. Thử cập nhật một state rồi kiểm tra phần UI nào thay đổi.

## Trade-off

MVP nhỏ có thể dùng state cục bộ; dữ liệu dùng chung cần cách quản lý phù hợp. Chọn công cụ sau khi hiểu phạm vi dữ liệu.

## Tự kiểm tra

- Query tìm kiếm có cần là state toàn app không?
- Dữ liệu knowledge base được chia sẻ giữa các màn hình thế nào?

## Nguồn

- [Flutter state management](https://docs.flutter.dev/data-and-backend/state-mgmt/intro)
- [[flutter]]
