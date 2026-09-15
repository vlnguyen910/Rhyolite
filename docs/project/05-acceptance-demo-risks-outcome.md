# Acceptance, Demo, Risks and Outcome

## 1. Global Acceptance Criteria

MVP hoàn thành khi:

1. App là standalone Flutter desktop app.
2. App chạy không cần Obsidian.
3. Curriculum SE mục tiêu có trong knowledge base.
4. Mỗi official course có Markdown riêng.
5. Markdown là source of truth.
6. Parser đọc được toàn bộ release dataset.
7. Knowledge Index rebuild được từ Markdown.
8. Graph được sinh tự động từ Markdown metadata/link.
9. Course detail hiển thị prerequisite.
10. Course detail hiển thị concept/topics.
11. Course detail hiển thị future/related courses.
12. Search hoạt động local.
13. Local graph render từ graph data thật.
14. Click node có thể navigate.
15. Official relationship không hardcode trong UI.
16. Official relationship có source hoặc dữ liệu có căn cứ.
17. Validator detect broken link/duplicate/missing metadata.
18. Xóa index rồi rebuild không làm mất knowledge.
19. Release build chạy được trên platform demo.
20. Demo flow không có blocking bug.

## 2. Demo Flow Cuối

```text
1. Open FPTU SE Knowledge

2. Show curriculum by semester

3. Open a course, ví dụ CSD201

4. Show:
   - Overview
   - Prerequisites
   - Topics / concepts
   - Future courses
   - Sources

5. Open local Knowledge Graph

6. Navigate from CSD201 to prerequisite or future course

7. Search another course/concept

8. Show Markdown source file

9. Explain that Graph is generated from Markdown, not hardcoded

10. Run validation report
```

## 3. Risks và Mitigation

### R1 - Thu thập curriculum mất nhiều thời gian

**Mitigation**

- Ưu tiên code/name/semester/source trước.
- Description dài và learning outcome bổ sung sau.

### R2 - Relationship không có nguồn rõ

**Mitigation**

- Phân biệt `prerequisite` chính thức và `related_to` do nhóm phân tích.
- Không gắn prerequisite nếu không có căn cứ.

### R3 - Graph UI tốn thời gian

**Mitigation**

- Chỉ làm Local Graph depth 1 trước.
- Không làm advanced layout/filter ở MVP.

### R4 - Scope creep từ Second Brain

**Mitigation**

- Personal Notes không nằm trên critical path.
- Không làm editor phức tạp trong 3 tuần.

### R5 - AI làm chậm core project

**Mitigation**

- AI là Phase 2.
- Chỉ bắt đầu AI khi toàn bộ P0 ổn định.

## 4. Outcome cuối cùng

Sản phẩm MVP là một **standalone Flutter desktop knowledge application dành cho sinh viên Software Engineering tại FPT University**.

```text
FPTU SE Curriculum
        ↓
Markdown Knowledge Base
        ↓
Parser
        ↓
Knowledge Index
        ↓
Knowledge Graph
        ↓
Curriculum / Course Detail
        ↓
Prerequisite / Topics / Future Courses
        ↓
Search + Graph Exploration
```

Outcome quan trọng không phải là có graph đẹp, mà là sinh viên hiểu được:

```text
What should I know before this course?
What will I learn in this course?
Where will this knowledge be useful later?
```
