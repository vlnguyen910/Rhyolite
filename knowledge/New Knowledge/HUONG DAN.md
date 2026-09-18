# THIRD VAULT

Mở thư mục `THIRD VAULT` làm vault trong Obsidian, hoặc chép nội dung vào vault đang dùng.

- `Mon hoc/`: 89 môn riêng biệt, tên `Mã môn - Tên môn.md`.
- `_Du lieu/`: JSON nguồn nguyên vẹn, CSV đối chiếu chương trình và báo cáo kiểm tra.

Đã duyệt toàn bộ cây `children` và `details`: 414 lượt môn thuộc
4 curriculum. Mỗi mã môn chỉ có một note, kể cả khi xuất hiện ở nhiều nhóm.
Các đề cương khác nhau cùng mã được giữ trong cùng note, gắn curriculum áp dụng.

Mỗi note giữ `curriculumCode` dạng danh sách, học kỳ và mã học phần/nhóm trong chương trình.
`sourceGroupCodes` lưu nhóm chứa môn. Nhóm và curriculum không tạo node liên kết.
Nhóm có nhiều môn là danh sách lựa chọn theo nguồn; không tự suy luận tất cả đều bắt buộc.

Mã và tên lấy từ `details`. Riêng PEN không có đề cương chuẩn, dùng mã học phần `term`.
Các cột ngoài bị lệch: `term` = mã học phần, `code` = tên, `name` = học kỳ;
môn con kế thừa học kỳ của nhóm. Giữ cả mã có hậu tố và cách viết riêng của nguồn,
như `DBI202-OLD` và `IoT102t`. Tên tiếng Việt được ưu tiên khi có tên song ngữ.

File lần này có đề cương riêng cho `PRO192` và `PRO192c`: giữ hai note riêng,
không dùng ánh xạ PRO192 → PRO192c của lần xuất trước. Điều kiện ghi PRO192 nối vào PRO192.
Không gộp các mã khác nhau chỉ vì có cùng tên.

Graph có 78 cặp môn liên kết, theo chiều môn hiện tại → môn tiên quyết.
Chỉ mục “Môn tiên quyết” có wikilink. Backlinks cho biết môn nào cần môn hiện tại.
Lọc Graph bằng `path:"Mon hoc"` để chỉ xem các môn; hiển thị môn cô lập để thấy đầy đủ.
Các điều kiện OR, theo combo/khóa, tín chỉ và ngoại lệ giữ nguyên trong note;
Graph chỉ biểu diễn kết nối, không thể hiện đủ ý nghĩa của các điều kiện này.

Liên kết lấy từ điều kiện tiên quyết. Với GRC490 và PIT490, chỉ nối điều kiện chung
và nhánh SE cho các curriculum BIT_SE; điều kiện gốc đầy đủ vẫn có trong đề cương.
PIT490 và EXE402 gọi môn OJT bằng tên; chỉ câu yêu cầu đỗ/hoàn thành môn này được
đối chiếu với đề cương OJT202 rồi tạo liên kết. Báo cáo ghi rõ cách đối chiếu.
Mã chưa có trong file giữ dạng chữ, không tạo node ảo. Không suy diễn môn tiên quyết
từ kiến thức khuyến nghị, mô tả, học liệu, công cụ, nhóm hay học kỳ.

Markdown dùng tiêu đề, đoạn văn và bảng thông thường, không callout, không mục thu gọn.
Ô bảng được xử lý xuống dòng và dấu phân cách để không vỡ bảng. Ký tự đặc biệt của tên file
được xử lý để wikilink hợp lệ, ví dụ C# → C Sharp; tên gốc vẫn được giữ trong nội dung.
CSS của trang nguồn không đưa vào note, nhưng toàn bộ dữ liệu được giữ trong bản JSON.

Đã kiểm tra toàn bộ node nguồn, YAML, bảng, tên file, đích liên kết, trùng mã,
tự liên kết, chu trình tiên quyết và bản sao nguồn. Xem `_Du lieu/kiem-tra-import.json`
và `_Du lieu/curriculum-mapping.csv` để đối chiếu từng lượt môn theo `sourcePath`.
