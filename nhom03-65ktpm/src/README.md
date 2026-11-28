# SmartNote

Ứng dụng ghi chép thông minh cho học sinh, viết bằng Flutter.

## Tính năng chính

- Ghi chú hằng ngày: tạo, sửa, xoá, tự lưu; phân loại theo môn học và tag; tìm kiếm.
- Quét vở giấy: chụp/chọn ảnh, cắt ảnh, nhận dạng chữ bằng ML Kit, sửa văn bản.
- Xuất Word: chọn một hoặc nhiều ghi chú, xuất tệp `.docx`.
- AI: tóm tắt nội dung, gạch ý chính và tạo bài kiểm tra trắc nghiệm.
- Nhắc nhở, chuỗi ngày học, thống kê tuần, chia sẻ ghi chú và sao lưu.

## Yêu cầu môi trường

- [FVM](https://fvm.app/) và Flutter 3.47.5 (xem `.fvmrc`)
- Android SDK (nền tảng chính) hoặc Xcode nếu chạy iOS

## Chạy ứng dụng

```bash
cd nhom03-65ktpm/src
fvm install
fvm flutter pub get
fvm flutter run --dart-define-from-file=config/shared_client.json
```

Trước khi chạy trên Android, iOS hoặc Web, nhận file `shared_client.json` qua kênh
riêng của nhóm và đặt ở `src/config/shared_client.json`. Git bỏ qua file thật.
Repo có `config/shared_client.example.json` để đối chiếu các trường. Sau đó chọn
thiết bị và đăng nhập bằng tài khoản thử. Khóa Gemini nằm ở Edge Function.

Khi chọn Chrome, dùng phiên bản file riêng có các trường `TEAM_FIREBASE_WEB_…`.
`google-services.json` chỉ dành cho Android.

```bash
fvm flutter run -d chrome --dart-define-from-file=config/shared_client.json
```

SQLite trên Web dùng `web/sqlite3.wasm` và `web/drift_worker.js` cùng phiên bản
Drift khóa trong `pubspec.lock`. Khi nâng Drift, cập nhật hai tệp từ cùng bản
phát hành trên [GitHub của Drift](https://github.com/simolus3/drift/releases).

Chạy giao diện mẫu khi chưa nhận file cấu hình:

```bash
fvm flutter run -t lib/main_preview.dart
```

Kiểm thử:

```bash
fvm flutter test
```

Kiểm tra mã nguồn:

```bash
fvm flutter analyze
```

## Cấu hình tính năng cloud

- Ghi chú lưu cục bộ khi chạy mặc định. Để thử đồng bộ bằng cấu hình Supabase
  chung, thêm `--dart-define=SMARTNOTE_ENABLE_SYNC=true` vào lệnh chạy có file.
  Môi trường đồng bộ cần SQL phiên bản ghi chú và tài khoản Firebase có
  claim `role=authenticated` theo hướng dẫn bên dưới.
- Cấu hình Firebase riêng vẫn có thể dùng qua file native hoặc bộ
  `--dart-define=FIREBASE_…`. Có thể ghi đè Edge Function bằng
  `AI_SUMMARY_ENDPOINT` và Supabase bằng cặp `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

- [Tóm tắt AI](../docs/tom_tat_ai.md) mô tả cách triển khai Edge Function và cấu hình endpoint.
- [Đồng bộ ghi chú](../docs/dong_bo_du_lieu.md) mô tả SQL, cấu hình Supabase và cách thử hai thiết bị.
- Để kiểm tra giao diện tóm tắt trên Android bằng dữ liệu cục bộ, dùng
  `fvm flutter run --dart-define=AI_SUMMARY_ENDPOINT=mock`.
