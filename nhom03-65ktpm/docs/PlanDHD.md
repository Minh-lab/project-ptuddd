# Kế hoạch công việc cá nhân – Dương Hải Đăng

- **Dự án:** Nhóm 03 – 65KTPM
- **Thời gian dự án:** 16/11/2026 – 10/01/2027
- **Phạm vi được phân công:** Issue #14, #16, #18, #19
- **Nhánh làm việc:** Tạo nhánh riêng từ `nhom03-65ktpm` cho từng issue; mở PR về `nhom03-65ktpm`.

## Mục tiêu

Hoàn thành lần lượt tính năng chia sẻ ghi chú chỉ xem, sao lưu/khôi phục dữ liệu, bộ kiểm thử và quy trình đóng gói APK/CI release. Mỗi đầu việc cần có kiểm thử phù hợp, được review và merge trước khi chuyển trạng thái issue sang Done.

## Lịch thực hiện

| Thời gian | Issue | Công việc và kết quả cần đạt |
| --- | --- | --- |
| 23/11 – 29/11 | Chuẩn bị | Đọc cấu trúc ứng dụng và mô hình dữ liệu; trao đổi với nhóm về luồng chia sẻ, nền tảng lưu trữ và cấu hình CI hiện có. Ghi nhận phụ thuộc hoặc quyền truy cập còn thiếu; chưa thay đổi phạm vi issue. |
| 30/11 – 13/12 | Chuẩn bị Sprint 3–4 | Chốt thiết kế sơ bộ cho #14; xác định dữ liệu cần sao lưu và cách kiểm tra khôi phục cho #16. Thống nhất tiêu chí kiểm thử với các thành viên phụ trách tính năng. |
| 14/12 – 20/12 | **#14 – Chia sẻ ghi chú chỉ xem** | Triển khai luồng chia sẻ theo phương án nhóm thống nhất; bảo đảm người nhận chỉ xem, không sửa/xóa ghi chú. Xử lý các trạng thái quyền truy cập và giao diện liên quan. |
| 21/12 – 27/12 | **#14 – Hoàn thiện** | Kiểm thử quyền chỉ xem và các trường hợp truy cập không hợp lệ; sửa lỗi, cập nhật hướng dẫn nếu cần, mở PR và xử lý review. |
| 28/12 – 03/01 | **#16 – Sao lưu và khôi phục với Supabase** | Tích hợp luồng sao lưu/khôi phục theo mô hình dữ liệu và cấu hình đã thống nhất; kiểm tra dữ liệu sau khôi phục và xử lý lỗi mạng/thiếu dữ liệu. Không đưa thông tin bí mật vào mã nguồn. |
| 04/01 – 07/01 | **#18 – Bộ kiểm thử** | Bổ sung và tổ chức unit, widget, integration tests; ưu tiên luồng sao lưu/khôi phục, quyền chia sẻ và các luồng chính của ứng dụng. Phối hợp các thành viên để nhận kiểm thử cho phần tính năng họ phụ trách. |
| 08/01 – 10/01 | **#19 – APK và CI release** | Hoàn thiện cấu hình build APK và CI release; chạy thử quy trình từ đầu đến cuối, kiểm tra đầu ra và ghi lại cách phát hành để nhóm có thể tái thực hiện. |

## Cách thực hiện từng issue

1. Đọc issue, tiêu chí chấp nhận và mã liên quan; xác nhận các quyết định chưa rõ với nhóm trước khi triển khai.
2. Cập nhật issue/Project board sang **In Progress**, tạo nhánh theo quy ước nhóm và chia thay đổi thành các commit nhỏ.
3. Chạy kiểm thử liên quan và `flutter analyze`; ghi rõ kết quả, cấu hình cần thiết và giới hạn đã biết trong PR.
4. Mở PR có liên kết `Closes #<số issue>`, xử lý phản hồi review và chỉ đánh dấu hoàn tất sau khi PR được merge.

## Tiêu chí hoàn thành cá nhân

- [ ] #14: Người được chia sẻ xem được ghi chú nhưng không thể thay đổi nội dung; kiểm thử quyền truy cập đạt.
- [ ] #16: Có thể sao lưu và khôi phục dữ liệu theo luồng đã thống nhất; kiểm tra được kết quả và lỗi được thông báo rõ ràng.
- [ ] #18: Các unit, widget và integration tests trong phạm vi thống nhất chạy đạt; có hướng dẫn chạy kiểm thử.
- [ ] #19: Quy trình CI tạo được APK theo cấu hình của dự án và có hướng dẫn phát hành.
- [ ] Các PR được review, merge vào `nhom03-65ktpm`; issue được đóng và board được cập nhật.

## Phụ thuộc và rủi ro cần theo dõi

- Chốt phương thức chia sẻ và quy tắc thu hồi quyền với nhóm trước khi triển khai #14.
- Thống nhất schema, môi trường và quyền truy cập Supabase cho #16; nếu thiếu cấu hình hoặc thông tin môi trường, báo nhóm trưởng sớm.
- Phạm vi #18 phụ thuộc vào trạng thái tính năng của cả nhóm; thống nhất chủ sở hữu test cho từng luồng để tránh bỏ sót hoặc trùng lặp.
- Xác nhận runner, secrets và điều kiện phát hành của repository trước khi hoàn thiện #19; secrets chỉ được lưu trong cấu hình bảo mật của CI.
