# Quy định Commit — Nhóm 03 (PTUDDD)

Áp dụng cho toàn bộ repository `Minh-lab/project-ptuddd`, đặc biệt là thư mục `nhom03-65ktpm/`.
Mọi agent/trợ lý AI làm việc trong repo này **phải tuân thủ** các quy định dưới đây.

---

## 1. Tác giả commit phải là chính tài khoản của thành viên

- Commit **phải** được tạo dưới danh nghĩa tài khoản GitHub của thành viên thực hiện.
  Danh tính chuẩn của nhóm:

  ```
  Minh-lab <minhn6673@gmail.com>
  ```

- **Tuyệt đối không** để tên tác giả/committer là AI assistant, bot hay tên công cụ, ví dụ:
  - `AI Assistant <bot@example.com>` ❌
  - `Codebuff`, `Claude`, `ChatGPT`, `Copilot`, `Cursor`, `Buffy`... ❌
  - Bất kỳ email dạng `*@example.com`, `bot@*`, `noreply@anthropic.com`, `noreply@openai.com` ❌

- Trước khi commit, kiểm tra cấu hình danh tính của repo:

  ```bash
  git config user.name    # phải là tên của bạn, không phải "AI Assistant"
  git config user.email   # phải là email gắn với tài khoản GitHub của bạn
  ```

  Nếu sai, đặt lại ngay:

  ```bash
  git config user.name "Minh-lab"
  git config user.email "minhn6673@gmail.com"
  ```

- Kiểm tra lại tác giả của commit vừa tạo:

  ```bash
  git log -1 --format='%an <%ae> | %cn <%ce>'
  ```

  Kết quả phải là tên/email của thành viên, không được chứa `AI`, `bot`, `Assistant`.

## 2. Không gắn dấu vết AI vào commit

- **Không** thêm footer/co-author của AI vào commit message, ví dụ:
  - `🤖 Generated with Codebuff`
  - `Co-Authored-By: Codebuff <noreply@codebuff.com>`
  - `Generated with Claude Code`, `Co-authored-by: Copilot`, ...
- Commit message chỉ chứa nội dung mô tả thay đổi của nhóm.
- Không đặt tên nhánh, tag hay file có chứa tên AI assistant.

## 3. Định dạng commit message

Theo Conventional Commits, tiếng Việt không dấu ở phần `type`/`scope`:

```
<type>(<scope>): <mô tả ngắn ở thể mệnh lệnh>
```

- `type`: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- `scope`: tên module/thư mục, ví dụ `nhom03-65ktpm`, `src`, `docs`
- Dòng tiêu đề ≤ 72 ký tự, không kết thúc bằng dấu chấm.
- Mỗi commit chỉ nên giải quyết một việc; tránh commit gộp nhiều thay đổi không liên quan.

Ví dụ hợp lệ:

```
feat(src): them man hinh ghi chu am thanh
docs(nhom03-65ktpm): cap nhat ke hoach cong viec tuan 5
fix(src): sua loi luu ghi chu khi mat ket noi
```

## 4. Checklist trước khi commit

- [ ] `git config user.name` / `user.email` là danh tính của thành viên.
- [ ] `git status` chỉ chứa các file thuộc thay đổi của mình, không có file rác
      (`build/`, `local.properties`, `.dart_tool/`, file `.env`...).
- [ ] Commit message đúng định dạng ở mục 3, không có footer AI.
- [ ] Không có `Co-Authored-By` của AI, không có `🤖`, `Generated with ...`.

## 5. Xử lý commit đã lỡ mang tên AI Assistant

Nếu phát hiện commit gần nhất (chưa push) có tác giả sai:

```bash
git commit --amend --reset-author --no-edit
```

Với nhiều commit chưa push:

```bash
git rebase -i --root
# đổi "pick" thành "edit" ở các commit cần sửa, rồi với mỗi commit:
git commit --amend --reset-author --no-edit
git rebase --continue
```

Nếu commit đã push lên nhánh chung, **không** tự ý `force push`; báo nhóm trưởng để thống nhất trước.
