# Project Overview

## 1. Tổng quan dự án

**Tên đề xuất:** FPTU SE Knowledge - Obsidian-inspired Second Brain  
**Loại sản phẩm:** Standalone Desktop Application  
**Framework:** Flutter Desktop  
**Đối tượng chính:** Sinh viên ngành Software Engineering tại FPT University  
**Mô hình dữ liệu chính:** Markdown + Knowledge Graph  
**Nguyên tắc:** Local-first, Markdown là source of truth  
**Thời gian MVP:** 3 tuần

## 2. Ý tưởng chính

Ứng dụng cung cấp sẵn knowledge base về lộ trình học ngành Software Engineering tại FPT University.

Mỗi môn học được biểu diễn bằng một file Markdown và trở thành một node trong Knowledge Graph.

Hệ thống phân tích các mối quan hệ giữa môn học, concept và note để giúp sinh viên trả lời:

- Cần biết gì trước khi học môn này?
- Môn nào là nền tảng cho môn này?
- Môn này dạy những concept gì?
- Kiến thức từ môn này được dùng tiếp ở đâu?
- Hai môn học liên quan với nhau như thế nào?
- Một môn nằm ở đâu trong toàn bộ lộ trình SE?

Dự án lấy cảm hứng từ Obsidian ở:

- Markdown-based knowledge.
- `[[wikilink]]`.
- Backlinks.
- Knowledge Graph.
- Local-first.
- Connected knowledge.
- Personal Second Brain.

Dự án **không clone Obsidian** và **không phụ thuộc Obsidian để chạy**.

## 3. Vấn đề

Thông tin về chương trình học thường nằm rời rạc trong:

- Curriculum.
- Syllabus.
- Tài liệu môn học.
- Ghi chú cá nhân.

Sinh viên có thể biết tên môn và semester nhưng khó nhìn thấy mối liên hệ giữa các môn.

Ví dụ curriculum thông thường:

```text
Semester 3
- CSD201
- DBI202
- ...
```

Trong khi hệ thống mong muốn thể hiện:

```text
Programming Fundamentals
        ↓ prerequisite
Data Structures
        ↓ foundation_for
Algorithms
        ↓
Software Engineering
```

## 4. Mục tiêu

1. Chuẩn hóa dữ liệu curriculum SE dưới dạng Markdown.
2. Tự động parse Markdown thành Knowledge Graph.
3. Hiển thị prerequisite, related knowledge và future courses.
4. Cho phép sinh viên tìm kiếm và khám phá curriculum bằng graph.
5. Chuẩn bị nền tảng để thêm personal notes.
6. Chuẩn bị nền tảng để thêm AI/RAG mà không thay đổi source of truth.

## 5. Product Success Statement

Một sinh viên mới mở app phải có thể chọn bất kỳ môn nào trong curriculum SE và trong vài thao tác trả lời được:

1. **Tôi cần biết gì trước khi học môn này?**
2. **Môn này dạy tôi những concept gì?**
3. **Những kiến thức này sẽ được dùng tiếp ở đâu?**

MVP đạt mục tiêu chính khi các câu hỏi trên được trả lời dựa trên dữ liệu có nguồn, relationship rõ ràng và graph có thể khám phá.
