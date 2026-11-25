# Checklist Công Việc – Dương Hải Đăng

Danh sách này tổng hợp các issue được phân công cho Dương Hải Đăng. Thực hiện từng issue trên nhánh riêng, cập nhật trạng thái issue/Project board và đánh dấu checklist khi hoàn thành.

## 1. Issue được giao

| Issue | Công việc | Sprint | Trạng thái |
| --- | --- | --- | --- |
| #7 | Tìm kiếm ghi chú theo tiêu đề và nội dung | S2 | **Đang thực hiện** |
| #14 | Chia sẻ ghi chú với quyền chỉ xem | S3 | [ ] Chưa bắt đầu |
| #16 | Sao lưu và khôi phục dữ liệu với Supabase | S4 | [ ] Chưa bắt đầu |
| #22 | Gợi ý tag thông minh bằng AI (P1) | S4 | [ ] Chưa bắt đầu |

## 2. Chuẩn bị trước khi làm

- [ ] Đọc [kế hoạch công việc](ke_hoach_cong_viec.md), [cơ sở dữ liệu](co_so_du_lieu.md) và [quy định nhóm](../rules/AGENTS.md).
- [ ] Mở issue tương ứng, đọc acceptance criteria, phạm vi và các trao đổi mới nhất.
- [ ] Nếu tiêu chí hoặc cách xử lý chưa rõ, hỏi nhóm trưởng/nhóm trước khi triển khai; không tự mở rộng phạm vi.
- [ ] Đồng bộ nhánh `nhom03-65ktpm` mới nhất và tạo nhánh riêng theo quy ước, ví dụ `feature/nhom03-65ktpm/search-notes`.
- [ ] Cập nhật issue/Project board sang **In Progress** khi bắt đầu.
- [ ] Chạy `flutter pub get`, `flutter analyze` và các test hiện có để nắm trạng thái ban đầu.
- [ ] Xác nhận với nhóm cách cấu hình Supabase và Firebase JWT/RLS trước các issue cần Supabase.
- [ ] Chỉ dùng publishable/anon key ở ứng dụng; không đưa `service_role`, API secret hoặc thông tin nhạy cảm vào mã nguồn, `.env` được commit hay log.

> **Lưu ý hiện trạng:** tại thời điểm lập checklist, `src/pubspec.yaml` chưa khai báo Supabase client và `.env.example` vẫn chứa biến mẫu `API_BASE_URL`/`API_KEY`. Cần xác nhận việc kết nối Supabase và tên biến cấu hình với nhóm trước khi làm #14 hoặc #16; chỉ điền `.env` hiện chưa đủ để ứng dụng kết nối Supabase.

## 3. Issue #7 – Tìm kiếm ghi chú

- [x] Xác nhận trong issue các trường cần tìm kiếm, quy tắc khớp từ khóa và cách giữ thứ tự kết quả.
- [x] Thêm ô tìm kiếm có debounce và thao tác xóa truy vấn.
- [x] Tìm được ghi chú khi từ khóa khớp tiêu đề hoặc nội dung, có dấu hoặc không dấu.
- [x] Hiển thị trạng thái phù hợp khi chưa có ghi chú hoặc không có kết quả.
- [x] Đảm bảo tìm kiếm không sửa/xóa dữ liệu và không làm thay đổi luồng ghi chú hiện tại.
- [x] Bổ sung test cho khớp tiêu đề, khớp nội dung, không khớp, truy vấn rỗng và xóa truy vấn; kiểm tra debounce và tô sáng.
- [x] Chạy test liên quan và `flutter analyze`.
- [ ] Tạo PR vào `nhom03-65ktpm`, mô tả có `Closes #7`; cập nhật checklist sau khi PR được merge.

## 4. Issue #14 – Chia sẻ ghi chú chỉ xem

- [ ] Chốt trong issue cách chọn người nhận và cách người nhận mở ghi chú được chia sẻ.
- [ ] Kiểm tra schema `note_shares`, Firebase UID và chính sách RLS trong tài liệu cơ sở dữ liệu.
- [ ] Chỉ cho phép chủ sở hữu tạo hoặc thu hồi lượt chia sẻ hợp lệ.
- [ ] Người nhận được quyền đọc ghi chú được chia sẻ; không được sửa, xóa hoặc chia sẻ lại ghi chú.
- [ ] Kiểm tra người không liên quan không thể đọc ghi chú; không dựa riêng vào ẩn/hiện nút trên giao diện để bảo vệ dữ liệu.
- [ ] Bổ sung test cho quyền chủ sở hữu, người nhận, người không được chia sẻ và thao tác ghi bị từ chối.
- [ ] Cập nhật tài liệu/schema và migration SQL nếu issue yêu cầu thay đổi; bật RLS và kiểm tra policy theo quy ước nhóm.
- [ ] Chạy test liên quan và `flutter analyze`.
- [ ] Tạo PR vào `nhom03-65ktpm`, mô tả có `Closes #14`; cập nhật checklist sau khi PR được merge.

## 5. Issue #16 – Sao lưu và khôi phục với Supabase

- [ ] Chốt phạm vi dữ liệu cần sao lưu/khôi phục (ví dụ ghi chú, môn học, tag, tệp đính kèm) và cách xử lý khi bản local/remote khác nhau.
- [ ] Xác nhận cơ chế khởi tạo Supabase, cấu hình môi trường và xác thực Firebase JWT với nhóm trước khi triển khai.
- [ ] Chỉ truy cập dữ liệu của tài khoản hiện tại; tuân thủ `user_id` kiểu `text`, Firebase UID và RLS trong tài liệu.
- [ ] Xác định rõ hành vi khi chưa đăng nhập, mất mạng, lỗi server, dữ liệu rỗng hoặc khôi phục thất bại.
- [ ] Có thông báo trạng thái thành công/lỗi rõ ràng; tránh báo thành công nếu một phần dữ liệu chưa được xử lý.
- [ ] Kiểm tra không làm mất dữ liệu local ngoài ý muốn khi sao lưu/khôi phục hoặc gặp lỗi giữa chừng.
- [ ] Bổ sung test cho dữ liệu rỗng, lỗi mạng/server, dữ liệu thuộc tài khoản khác và trường hợp khôi phục có xung đột theo tiêu chí issue.
- [ ] Cập nhật tài liệu/schema và migration SQL nếu có thay đổi cấu trúc; không dùng `service_role` trong ứng dụng.
- [ ] Chạy test liên quan và `flutter analyze`.
- [ ] Tạo PR vào `nhom03-65ktpm`, mô tả có `Closes #16`; cập nhật checklist sau khi PR được merge.

## 6. Issue #22 – Gợi ý tag thông minh bằng AI (P1)

- [ ] Chốt trong issue đầu vào, số lượng/định dạng tag gợi ý, dịch vụ AI được phép dùng và nơi lưu API secret.
- [ ] Không nhúng API secret vào ứng dụng Flutter, Git hoặc log; nếu cần secret thì thống nhất phương án backend/proxy với nhóm.
- [ ] Hiển thị trạng thái đang xử lý, kết quả, không có gợi ý và lỗi/mất mạng.
- [ ] Xác nhận tag gợi ý không tự áp dụng lên ghi chú nếu chưa được người dùng chấp thuận (trừ khi issue quy định khác).
- [ ] Bổ sung test cho nội dung trống, kết quả hợp lệ, lỗi dịch vụ và phản hồi không đúng định dạng.
- [ ] Chạy test liên quan và `flutter analyze`.
- [ ] Tạo PR vào `nhom03-65ktpm`, mô tả có `Closes #22`; cập nhật checklist sau khi PR được merge.

## 7. Hoàn tất mỗi issue

- [ ] Đã tự review diff, chỉ gồm thay đổi thuộc issue và không có khóa/config cục bộ.
- [ ] `flutter analyze` không có lỗi; test liên quan chạy thành công.
- [ ] Đã kiểm tra luồng trên emulator/thiết bị nếu issue có thay đổi UI hoặc tích hợp dịch vụ.
- [ ] PR được review và merge vào `nhom03-65ktpm`, có `Closes #<issue>`.
- [ ] Issue đóng và Project board chuyển sang **Done** sau khi PR được merge.

## 8. Tổng kết

| Issue | PR | Test/analyze | Đã merge | Issue/board hoàn tất |
| --- | --- | --- | --- | --- |
| #7 |  | [ ] | [ ] | [ ] |
| #14 |  | [ ] | [ ] | [ ] |
| #16 |  | [ ] | [ ] | [ ] |
| #22 |  | [ ] | [ ] | [ ] |
