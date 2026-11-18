# Tài Liệu Nhóm 03 – 65KTPM

Thư mục chứa tài liệu đặc tả và báo cáo của nhóm.

## Đề cương dự án cuối kỳ

Thư mục [`de_cuong_project/`](de_cuong_project/):

| Tệp | Mô tả |
| --- | --- |
| [`de_cuong.md`](de_cuong_project/de_cuong.md) | Bản Markdown của đề cương (chuyển từ DOCX) |
| `DeCuong_Project_CuoiKy_GhiChepThongMinh_Nhom03.docx` | Bản chính thức để nộp |
| `DeCuong_Project_CuoiKy_GhiChepThongMinh_Nhom03.pdf` | Bản PDF xem trước |
| `images/` | Hình ảnh trích xuất từ DOCX, dùng trong `de_cuong.md` |
| `assets/` | Sơ đồ kiến trúc và Gantt gốc |
| `content_a.py`, `content_b.py`, `content_c.py`, `docx_helpers.py`, `build_de_cuong.py` | Mã nguồn Python dùng để sinh lại DOCX/PDF |

### Nội dung đề cương

1. Mở đầu
2. Tổng hợp các ứng dụng đã làm trong học kỳ
3. Đề cương chi tiết (mục tiêu, phạm vi, chức năng, kiến trúc, bàn giao)
4. Kế hoạch thực hiện 8 tuần
5. Kết luận, tài liệu tham khảo và phụ lục

### Sinh lại tài liệu

```bash
cd de_cuong_project
pip install python-docx matplotlib
python3 build_de_cuong.py
```
