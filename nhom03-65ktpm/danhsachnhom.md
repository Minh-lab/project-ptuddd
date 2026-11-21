# Danh Sách Thành Viên - Nhóm 03

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** NoteSmart - Ứng dụng ghi chú thông minh
- **Giảng viên hướng dẫn:** Đỗ Oanh Cường

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| --- | --------- | ------------ | ------------- | ------- | ------------------- | ------------ | ----- |
| 1   | Nguyễn Minh | 2351170607 | 65KTPM | Trưởng nhóm | Quản lý kho mã nguồn, kiến trúc ứng dụng, backend | 100% | [email] |
| 2   | Dương Hải Đăng | 2351170579 | 65KTPM | Thành viên | Giao diện người dùng (UI/UX) | 100% | [email] |
| 3   | Nguyễn Hữu Quân | 2351170612 | 65KTPM | Thành viên | Tính năng ghi chú, đồng bộ dữ liệu | 100% | nguyenhuuquan01122k5@gmail.com |
| 4   | Mông Thị Bích Hạnh | 2251061770 | 65KTPM | Thành viên | Kiểm thử, tài liệu, báo cáo | 100% | [email] |
| 5   | Nguyễn Tiến Đạt | 2251161967 | 65KTPM | Thành viên | Tính năng AI, tích hợp API | 100% | [email] |

## Hướng Dẫn Thiết Lập Môi Trường

Mã nguồn ứng dụng nằm trong thư mục `src/` (Flutter, package `smart_note`).

### Yêu cầu
- Flutter SDK 3.24.3 (khuyến nghị dùng [FVM](https://fvm.app/))
- Android Studio / Xcode (tùy nền tảng chạy)
- Dart 3.x

### Các bước khởi chạy

```bash
# 1. Di chuyển vào thư mục mã nguồn
cd src

# 2. Cài đặt Flutter (nếu dùng FVM)
fvm install
fvm use

# 3. Tải các gói phụ thuộc
fvm flutter pub get    # hoặc: flutter pub get

# 4. Chạy ứng dụng
fvm flutter run        # hoặc: flutter run

# 5. Chạy kiểm thử
fvm flutter test       # hoặc: flutter test
```

### Cấu hình môi trường
Sao chép `.env.example` thành `.env` và điền các khóa API cần thiết trước khi chạy.
