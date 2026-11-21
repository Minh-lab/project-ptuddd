# Kế Hoạch Công Việc – Nhóm 03 (65KTPM)

- **Repo quản lý:** https://github.com/Minh-lab/project-ptuddd (nhánh `nhom03-65ktpm`)
- **Bảng tiến độ:** https://github.com/users/Minh-lab/projects/6
- **Thời gian:** 16/11/2026 – 10/01/2027 (08 tuần, 4 sprint)

## 1. Quy trình làm việc trên GitHub

1. Mỗi đầu việc tương ứng **một issue** trong repo (đã tạo 22 issue, gắn nhãn `area:*`, `priority:*`, `sprint:*` và milestone theo sprint).
2. Issue được đưa vào **Project board** với các trường `Status` (Todo → In Progress → Done), `Sprint` (S1–S4), `Priority` (P0/P1).
3. Thành viên tạo nhánh cá nhân từ `nhom03-65ktpm`, ví dụ `feature/12-tom-tat-ai`, commit theo Conventional Commits.
4. Mở Pull Request vào `nhom03-65ktpm`, mô tả có `Closes #<số issue>` để tự đóng issue khi merge; nhóm trưởng review rồi merge.
5. Cập nhật `Status` trên board: kéo sang **In Progress** khi bắt đầu, **Done** khi PR được merge.

## 2. Phân công theo thành viên

| Thành viên | Issue | Nội dung | Sprint |
| --- | --- | --- | --- |
| **Nguyễn Minh** (nhóm trưởng) | #1 | Khởi tạo dự án Flutter, Clean Architecture | S1 |
| | #2 | Firebase Auth: đăng nhập, đăng ký, đăng xuất | S1 |
| | #3 | Ghi chú CRUD và tự lưu | S1 |
| | #5 | Nhật ký hằng ngày | S2 |
| | #21 | (P1) Đồng bộ đa thiết bị nâng cao | S4 |
| **Nguyễn Tiến Đạt** | #4 | UI/UX nền tảng: theme, điều hướng, widget dùng chung | S1 |
| | #11 | Xuất Word nhiều ghi chú ra `.docx` | S3 |
| | #15 | Bản Web: xem và sửa ghi chú cơ bản | S3 |
| **Mông Thị Bích Hạnh** | #6 | Phân loại theo môn học và tag | S2 |
| | #7 | Tìm kiếm ghi chú theo tiêu đề và nội dung | S2 |
| | #10 | Nhắc nhở học tập | S2 |
| | #17 | Thống kê tuần và chuỗi ngày học (streak) | S4 |
| | #20 | Tài liệu kỹ thuật, báo cáo cuối kỳ, video demo | S4 |
| **Nguyễn Hữu Quân** | #8 | Quét vở: chụp/chọn ảnh và cắt ảnh | S2 |
| | #9 | OCR bằng ML Kit và sửa văn bản sau quét | S2 |
| | #12 | Tóm tắt AI: ngắn, dài, gạch ý chính | S3 |
| | #13 | Bài kiểm tra trắc nghiệm AI, chấm điểm, lưu điểm | S3 |
| | #22 | (P1) Gợi ý tag thông minh bằng AI | S4 |
| **Dương Hải Đăng** | #14 | Chia sẻ ghi chú với quyền chỉ xem | S3 |
| | #16 | Sao lưu và khôi phục dữ liệu với Supabase | S4 |
| | #18 | Bộ kiểm thử: unit, widget, integration | S4 |
| | #19 | Đóng gói APK và CI release | S4 |

## 3. Mốc theo sprint

| Sprint | Thời gian | Mục tiêu | Issue |
| --- | --- | --- | --- |
| S1 | 16/11 – 29/11 | Khung dự án, auth, ghi chú CRUD, UI nền tảng | #1 – #4 |
| S2 | 30/11 – 13/12 | Môn học/tag, tìm kiếm, quét vở + OCR, nhắc nhở | #5 – #10 |
| S3 | 14/12 – 27/12 | Xuất Word, tóm tắt AI, bài kiểm tra AI, chia sẻ, Web | #11 – #15 |
| S4 | 28/12 – 10/01 | Sao lưu, kiểm thử, đóng gói APK, tài liệu, demo | #16 – #22 |

## 4. Tiêu chí hoàn thành (Definition of Done)

- [ ] Code đã merge vào `nhom03-65ktpm` qua Pull Request được review.
- [ ] `flutter analyze` không lỗi, test liên quan chạy pass.
- [ ] Issue có PR tham chiếu (`Closes #…`) và được đóng.
- [ ] Trạng thái trên board chuyển sang **Done**.
