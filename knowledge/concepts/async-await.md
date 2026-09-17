---
id: "concept:async-await"
type: concept
title: "Future và async/await"
courses: ["course:PRM393"]
related: ["concept:dart", "concept:flutter"]
sources:
  - https://dart.dev/libraries/async/async-await
  - https://flm.fpt.edu.vn/gui/role/student/SyllabusDetails?sylID=13822
demo: false
---

# Future và async/await

Ghi chú khởi đầu được AI biên soạn từ nguồn để nhóm review, không tự đánh giá mức độ thành thạo của người học.
Liên hệ PRM393 dựa trên CLO4 trong syllabus lưu tại vault.

## Mental model

Future biểu diễn kết quả hoặc lỗi sẽ có sau. async cho phép dùng await trong hàm; await chờ Future hoàn tất trước khi tiếp tục phần sau của hàm đó.

## Ví dụ

```dart
Future<String> readCourse() async {
  final content = await bundle.loadString('knowledge/courses/DEMO_SQL.md');
  return content;
}
```

Ví dụ giả định bundle là AssetBundle đã được cung cấp.

## Common mistake

async/await không tự đưa phép tính nặng sang một isolate khác. UI vẫn cần xử lý loading và error.

## Tự kiểm tra

- Bắt lỗi từ Future ở đâu?
- await khác việc tạo thêm isolate thế nào?

## Nguồn

- [Dart asynchronous programming](https://dart.dev/libraries/async/async-await)
- [[dart]]
