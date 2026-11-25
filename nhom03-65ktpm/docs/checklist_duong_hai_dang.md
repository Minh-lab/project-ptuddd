# Checklist công việc — Dương Hải Đăng

- **MSSV:** 2351170579
- **Phạm vi:** tìm kiếm ghi chú, chia sẻ ghi chú, sao lưu/khôi phục Supabase và gợi ý tag AI.
- **Nguồn phân công:** [Danh sách nhóm](../danhsachnhom.md), [Kế hoạch công việc](./ke_hoach_cong_viec.md), GitHub issues [#7](https://github.com/Minh-lab/project-ptuddd/issues/7), [#14](https://github.com/Minh-lab/project-ptuddd/issues/14), [#16](https://github.com/Minh-lab/project-ptuddd/issues/16), [#22](https://github.com/Minh-lab/project-ptuddd/issues/22).
- **Tài liệu phải theo:** [Quy định nhóm](../rules/AGENTS.md), [Quy ước database và RLS](./co_so_du_lieu.md).

## Thứ tự ưu tiên

| Issue | Việc | Sprint | Ưu tiên |
|---|---|---|---|
| #7 | Tìm kiếm ghi chú theo tiêu đề và nội dung | S2 | P0 |
| #14 | Chia sẻ ghi chú chỉ xem qua liên kết | S3 | P0 |
| #16 | Sao lưu và khôi phục với Supabase | S4 | P0 |
| #22 | Gợi ý tag thông minh bằng AI | S4 | P1 — làm sau các việc P0 nếu còn thời gian |

## Trước khi bắt đầu mỗi issue

- [ ] Đọc mô tả và tiêu chí hoàn thành mới nhất trên GitHub; xác nhận issue còn phù hợp với kế hoạch nhóm.
- [ ] Chuyển issue sang **In Progress** khi bắt đầu.
- [ ] Tạo nhánh riêng từ `nhom03-65ktpm` theo mẫu `feature/nhom03-65ktpm/<tinh-nang>`; không làm trực tiếp trên `main` hoặc nhánh nhóm.
- [ ] Đồng bộ/rebase nhánh nhóm trước khi làm; chỉ sửa phần thuộc phạm vi issue.
- [ ] Giữ luồng Clean Architecture: UI → Cubit/Bloc → UseCase → repository interface → repository implementation → datasource.
- [ ] Không gọi Firebase, Supabase hay API trực tiếp từ UI; không thêm dependency mới nếu chưa được nhóm trưởng đồng ý.
- [ ] Nếu cần đổi schema/policy, trao đổi với nhóm trước; tạo SQL migration mới trong `docs/sql/` và cập nhật `docs/co_so_du_lieu.md`. Không tự sửa RLS hoặc cấu hình database ngoài quy trình nhóm.

## #7 — Tìm kiếm ghi chú

**Mục tiêu:** tìm theo tiêu đề và nội dung, hỗ trợ tiếng Việt có dấu/không dấu.

- [ ] Thêm ô tìm kiếm vào màn hình danh sách ghi chú theo UI hiện có.
- [ ] Lọc kết quả theo cả tiêu đề lẫn nội dung.
- [ ] Chuẩn hóa truy vấn và dữ liệu để tìm được tiếng Việt không dấu, ví dụ `ghi chu` khớp `ghi chú`.
- [ ] Debounce thao tác gõ; cập nhật kết quả trong lúc người dùng nhập.
- [ ] Tô sáng từ khóa khớp trong kết quả; xử lý đúng trường hợp truy vấn rỗng hoặc không có kết quả.
- [ ] Viết unit test cho truy vấn: khớp tiêu đề, khớp nội dung, có/không dấu, chữ hoa/thường, truy vấn rỗng và không khớp.
- [ ] Kiểm tra debounce và kết quả cập nhật khi gõ bằng test phù hợp.
- [ ] Chạy `dart format`, `flutter analyze` và test liên quan.
- [ ] Mở PR vào `nhom03-65ktpm`, ghi `Closes #7`; cập nhật board thành **Done** sau khi PR được merge.

## #14 — Chia sẻ ghi chú chỉ xem

**Mục tiêu:** tạo liên kết chia sẻ, thu hồi được; người nhận chỉ xem, không sửa.

- [ ] Chốt cách liên kết xác định người nhận/ghi chú và cách thu hồi liên kết với nhóm trước khi triển khai.
- [ ] Đối chiếu mô hình hiện có `note_shares` trong `docs/co_so_du_lieu.md`. Schema hiện có `note_id`, `owner_id`, `shared_with`, `permission = 'view'`; nếu chưa biểu diễn được link/token, xin thống nhất thay đổi schema trước khi tạo migration.
- [ ] Tạo liên kết chia sẻ cho ghi chú được phép; không để lộ thông tin xác thực hoặc quyền truy cập rộng hơn dự định trong URL.
- [ ] Cho chủ sở hữu xem và thu hồi các liên kết đã tạo.
- [ ] Xây luồng mở liên kết để người nhận xem được đúng ghi chú, nhưng không sửa, xóa hoặc chia sẻ tiếp.
- [ ] Bảo vệ quyền ở backend bằng RLS/policy theo tài liệu; không chỉ ẩn nút sửa ở giao diện.
- [ ] Kiểm thử bằng ít nhất hai tài khoản: chủ ghi chú và người nhận; kiểm tra người không được chia sẻ không đọc được.
- [ ] Kiểm thử thu hồi liên kết và các thao tác ghi bị từ chối.
- [ ] Chạy `dart format`, `flutter analyze` và test liên quan.
- [ ] Mở PR vào `nhom03-65ktpm`, ghi `Closes #14`; cập nhật board thành **Done** sau khi PR được merge.

## #16 — Sao lưu và khôi phục với Supabase

**Mục tiêu:** sao lưu ghi chú/ảnh quét lên Supabase, khôi phục trên thiết bị mới và xử lý thay đổi offline.

- [ ] Kiểm kê dữ liệu cần đồng bộ: ghi chú, metadata và tệp/ảnh đính kèm; xác định trạng thái hiện có trong Drift.
- [ ] Xác nhận Supabase dùng làm nguồn dữ liệu chính, Drift chỉ là cache offline; không tạo một nguồn dữ liệu chính song song.
- [ ] Tạo datasource/repository remote trong `data/datasources/remote/`; giữ UI và domain độc lập với Supabase.
- [ ] Xác thực Supabase bằng Firebase ID token theo quy ước nhóm; chỉ dùng anon/publishable key, tuyệt đối không dùng `service_role`.
- [ ] Sao lưu ghi chú lên các bảng đã thống nhất và ảnh lên bucket private `note-images`, theo đường dẫn `{user_id}/{note_id}/{page}.jpg`.
- [ ] Khôi phục dữ liệu của đúng người dùng về thiết bị mới, bao gồm quan hệ và tệp đính kèm; không tải dữ liệu người khác.
- [ ] Chốt và triển khai quy tắc giải quyết xung đột khi có thay đổi offline rồi đồng bộ; không tự ghi đè dữ liệu mới hơn mà không có quy tắc rõ ràng.
- [ ] Hiển thị trạng thái đồng bộ: đang chạy, thành công, lỗi và thao tác thử lại phù hợp.
- [ ] Kiểm thử sao lưu/khôi phục, mất mạng, xung đột, quyền truy cập và RLS; không chỉ kiểm tra giao diện.
- [ ] Chạy `dart format`, `flutter analyze` và test liên quan.
- [ ] Mở PR vào `nhom03-65ktpm`, ghi `Closes #16`; cập nhật board thành **Done** sau khi PR được merge.

## #22 — Gợi ý tag thông minh bằng AI (P1)

**Chỉ thực hiện sau các issue P0 nếu còn thời gian.**

- [ ] Chốt ngưỡng tối thiểu của nội dung để gọi AI; nội dung ngắn hơn ngưỡng không được gửi request.
- [ ] Gửi nội dung ghi chú qua service/repository phù hợp; không gọi API trực tiếp từ widget.
- [ ] Đưa ra 3–5 tag phù hợp; nếu có gợi ý môn học, hiển thị tách biệt để người dùng nhận biết.
- [ ] Cho người dùng chấp nhận hoặc bỏ qua gợi ý; không tự ghi đè tag/môn học hiện tại.
- [ ] Xử lý trạng thái đang tải, lỗi mạng/API và phản hồi rỗng mà không làm mất nội dung ghi chú.
- [ ] Không hardcode API key; không ghi nội dung riêng tư vào log; kiểm tra chính sách dữ liệu trước khi gửi nội dung tới dịch vụ AI.
- [ ] Viết test cho nội dung quá ngắn (không gọi API), phản hồi 3–5 tag, chấp nhận/bỏ qua và lỗi API.
- [ ] Chạy `dart format`, `flutter analyze` và test liên quan.
- [ ] Mở PR vào `nhom03-65ktpm`, ghi `Closes #22`; cập nhật board thành **Done** sau khi PR được merge.

## Hoàn tất chung

- [ ] `dart format lib test`
- [ ] `flutter analyze` không có lỗi mới.
- [ ] `flutter test` và các kiểm thử liên quan đều pass.
- [ ] PR có mô tả thay đổi, cách kiểm thử và `Closes #<issue>`; được nhóm trưởng review/merge.
- [ ] Chỉ sau khi merge, chuyển issue/board sang **Done**.
