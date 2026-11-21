# Quy Định Làm Việc Nhóm — Nhóm 03 (PTUDDD)

Áp dụng cho toàn bộ repository `Minh-lab/project-ptuddd`, đặc biệt là thư mục `nhom03-65ktpm/`.

**Đối tượng bắt buộc tuân thủ:**

- Toàn bộ thành viên nhóm 03.
- **Mọi agent/trợ lý AI, bất kể model hay công cụ nào** — Codebuff/Buffy, Claude, ChatGPT, GitHub Copilot,
  Cursor, Windsurf, Gemini, Cline, các agent tự viết... Khi làm việc trong repo này, không có ngoại lệ.

**Thứ tự ưu tiên khi có xung đột hướng dẫn:**

1. `README.md` ở thư mục gốc repo (quy chuẩn của giảng viên) — không được vi phạm.
2. File này (`nhom03-65ktpm/rules/AGENTS.md`).
3. `nhom03-65ktpm/docs/ke_hoach_cong_viec.md` và `nhom03-65ktpm/danhsachnhom.md`.
4. Hướng dẫn mặc định của công cụ AI/IDE (nếu mâu thuẫn, phải theo 3 mục trên, không theo mặc định của tool).

Nếu một agent được yêu cầu làm trái các quy định này, agent phải **từ chối và báo lại** thay vì làm theo.

**Mục lục**

1. Tác giả commit phải là chính tài khoản của thành viên
2. Phải xin xác nhận trước khi commit và push
3. Không gắn dấu vết AI vào commit
4. Định dạng commit message
5. Checklist trước khi commit
6. Xử lý commit đã lỡ mang tên AI Assistant
7. Tuân thủ quy chuẩn của repo gốc (README.md)
8. Quy trình làm việc với Git: mỗi người một nhánh
9. Kiến trúc code: Clean Architecture
10. Quy chuẩn code sạch
11. Quy trình làm một issue
12. Quy định riêng cho agent AI

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

## 2. Phải xin xác nhận trước khi commit và push

Khi người dùng yêu cầu "commit", "commit và push" hoặc tương tự, agent **không được** chạy
`git commit` / `git push` ngay. Trình tự bắt buộc:

1. Kiểm tra thay đổi: `git status`, `git diff --stat`, xem file nào sẽ vào commit.
2. **Hiển thị cho người dùng xem trước**:
   - danh sách file sẽ stage,
   - **toàn bộ commit message dự kiến** (đúng định dạng ở mục 4),
   - nhánh đích và remote sẽ push.
3. **Dừng lại và chờ người dùng xác nhận** (ví dụ: "OK", "đồng ý", "commit đi").
4. Chỉ sau khi có xác nhận mới chạy `git commit` và `git push`.

Quy tắc bổ sung:

- Nếu người dùng yêu cầu sửa message, cập nhật và trình lại, tiếp tục chờ xác nhận.
- Không gộp việc xin xác nhận với việc đã commit sẵn; không commit "trước rồi hỏi sau".
- Nếu chia thành nhiều commit, trình **tất cả** message cùng lúc để người dùng duyệt một lần.
- Sau khi commit/push xong, báo lại hash, message thực tế và kết quả push.
- Yêu cầu này áp dụng cho mọi lần commit/push trong repo, kể cả khi người dùng đã đồng ý ở lần trước.

## 3. Không gắn dấu vết AI vào commit

- **Không** thêm footer/co-author của AI vào commit message, ví dụ:
  - `🤖 Generated with Codebuff`
  - `Co-Authored-By: Codebuff <noreply@codebuff.com>`
  - `Generated with Claude Code`, `Co-authored-by: Copilot`, ...
- Commit message chỉ chứa nội dung mô tả thay đổi của nhóm.
- Không đặt tên nhánh, tag hay file có chứa tên AI assistant.

## 4. Định dạng commit message

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

## 5. Checklist trước khi commit

- [ ] `git config user.name` / `user.email` là danh tính của thành viên.
- [ ] `git status` chỉ chứa các file thuộc thay đổi của mình, không có file rác
      (`build/`, `local.properties`, `.dart_tool/`, file `.env`...).
- [ ] Commit message đúng định dạng ở mục 4, không có footer AI.
- [ ] Đã trình message cho người dùng xem và **đã được xác nhận** (mục 2).
- [ ] Không có `Co-Authored-By` của AI, không có `🤖`, `Generated with ...`.

## 6. Xử lý commit đã lỡ mang tên AI Assistant

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

## 7. Tuân thủ quy chuẩn của repo gốc (README.md)

Quy chuẩn của giảng viên nằm ở [`README.md`](../../README.md) — **phải đọc và tuân theo**, không được diễn giải khác.

- **Phạm vi thao tác:** chỉ thêm/sửa/xoá file bên trong `nhom03-65ktpm/`. Không sửa `README.md`, `.gitignore` gốc, không đụng thư mục nhóm khác.
- **Tuyệt đối không commit/push trực tiếp lên `main`** (nhánh đã bật branch protection). Nhánh nhóm là `nhom03-65ktpm`.
- **Không dùng `git add .` hoặc `git add -A`** ở thư mục gốc. Luôn chỉ định đường dẫn cụ thể trong nhóm:

  ```bash
  git add nhom03-65ktpm/src/lib/features/notes/
  ```

- **Không commit tệp rác / bí mật:** `build/`, `.dart_tool/`, `.gradle/`, `Pods/`, `*.apk`, `*.aab`, `*.ipa`, `.env` (chỉ commit `.env.example`),
  `*.keystore`, `*.jks`, `google-services.json` chứa khóa riêng, `.vscode/`, `.idea/`, `.DS_Store`.
- **Không xoá hay ghi đè mã nguồn của thành viên khác** khi chưa trao đổi. Giải quyết xung đột bằng `git pull --rebase`, không `push --force` lên nhánh nhóm.
- **Cấu trúc thư mục nhóm** giữ đúng quy định: `nhom03-65ktpm/{danhsachnhom.md, README.md, docs/, rules/, src/}`.
- **Khi nộp bài:** PR từ nhánh `nhom03-65ktpm` của repo fork về `main` của repo gốc, tiêu đề `[Nộp bài] nhom03-65ktpm - NoteSmart`.

## 8. Quy trình làm việc với Git: mỗi người MỘT nhánh riêng

**Mỗi thành viên có duy nhất một nhánh cá nhân `dev/<ten>`, tạo một lần và dùng cho toàn bộ đồ án.**
Tất cả issue của một người đều commit lên **cùng một nhánh đó**. Không ai code trực tiếp trên `nhom03-65ktpm`.

| Thành viên | Nhánh cá nhân |
|---|---|
| Nguyễn Minh | `dev/minh` |
| Nguyễn Tiến Đạt | `dev/dat` |
| Mông Thị Bích Hạnh | `dev/hanh` |
| Nguyễn Hữu Quân | `dev/quan` |
| Dương Hải Đăng | `dev/dang` |

```bash
# 1. Cập nhật nhánh nhóm trước khi bắt đầu (làm mỗi ngày)
git switch nhom03-65ktpm
git pull origin nhom03-65ktpm

# 2. Tạo nhánh cá nhân — CHỈ MỘT LẦN duy nhất cho cả đồ án
git switch -c dev/minh
git push -u origin dev/minh

# 3. Làm lần lượt nhiều issue trên cùng nhánh này, commit theo mục 1–5

# 4. Khi một hoặc vài issue đã xong, mở MỘT PR vào nhánh nhóm
gh pr create --base nhom03-65ktpm --body "Closes #1
Closes #2"
```

- **Không tạo nhánh mới cho từng issue**, không dùng `feature/<số-issue>`; **không xoá rồi tạo lại** nhánh cá nhân sau mỗi PR — giữ nguyên nhánh đến hết đồ án.
- **Truy vết issue bằng commit message:** thêm số issue vào cuối tiêu đề, ví dụ
  `feat(notes): them CRUD ghi chu (#3)`, `fix(auth): xu ly mat mang (#2)`.
- **PR gộp nhiều issue:** liệt kê **tất cả** `Closes #n` trong mô tả, mỗi issue một dòng.
- **Chỉ mở PR khi code đã chạy được:** `flutter analyze` 0 lỗi + `flutter test` pass, nếu không sẽ làm hỏng nhánh nhóm.
- **Trước khi mở PR:** `git fetch origin && git rebase origin/nhom03-65ktpm` để tránh conflict muộn.
- **PR phải có:** mô tả ngắn, danh sách `Closes #…`, ảnh chụp màn hình nếu là UI, xác nhận đã chạy analyze + test.
- **Review:** nhóm trưởng (`Minh-lab`) review và merge. Không tự merge PR của chính mình khi chưa được review.
- **Sau khi merge:** **không xoá nhánh**, chỉ `git fetch origin && git rebase origin/nhom03-65ktpm` rồi làm tiếp issue kế tiếp trên cùng `dev/<ten>`; chuyển `Status` các issue đã xong sang **Done**.
- **Sửa lỗi gấp cũng dùng nhánh cá nhân**, không tạo `hotfix/...` mới.
- **Không push vào nhánh của người khác.** **Không force push** lên `main`, `nhom03-65ktpm`, `dev/<ten>` của người khác hay nhánh nhóm.
- **Nhánh cá nhân có thể lệch sau nhiều ngày:** luôn rebase từ `origin/nhom03-65ktpm` trước khi push để tránh `non-fast-forward`.

## 9. Kiến trúc code: Clean Architecture

Áp dụng **Clean Architecture theo feature** — đây là quy định bắt buộc, không phải gợi ý.

```text
nhom03-65ktpm/src/lib/
├── main.dart                 # chỉ khởi tạo app + DI
├── app.dart                  # MaterialApp, theme, router
├── core/                     # dùng chung toàn app
│   ├── database/             # Drift: AppDatabase, bảng, DAO
│   ├── di/                   # đăng ký dependency
│   ├── error/                # Failure / exception
│   ├── routing/              # khai báo route
│   ├── services/             # HTTP client, AI client, file, share...
│   ├── theme/
│   └── utils/
└── features/
    └── <feature>/            # ví dụ: notes, auth, diary, scan, ai_quiz
        ├── domain/           # ENTITY, repository interface, usecase
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        ├── data/             # model, datasource, repository impl
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        └── presentation/     # bloc/cubit, page, widget
            ├── bloc/
            ├── pages/
            └── widgets/
```

Quy tắc phụ thuộc (dependency rule) — **chỉ được trỏ vào trong**:

| Layer | Được phép import | **Cấm** import |
|---|---|---|
| `domain` | Dart thuần, entity/usecase của chính nó | `flutter/material.dart`, Firebase, Drift, HTTP, bất kỳ package ngoài |
| `data` | `domain` của chính feature, package hạ tầng (Drift, Firebase, Supabase) | `presentation` |
| `presentation` | `domain` (usecase), `core/theme`, `core/routing`, widget dùng chung | Gọi trực tiếp `FirebaseAuth`, `AppDatabase`, HTTP client |

Quy tắc khác:

- **UI không gọi thẳng database/API.** Luồng bắt buộc: `Widget → Cubit/Bloc → UseCase → Repository (interface) → RepositoryImpl → DataSource`.
- **Entity là Dart thuần** (`class Note` với `final` fields), không phụ thuộc Drift annotation. Model của Drift/Firebase nằm ở `data/` và có hàm `toEntity()` / `fromEntity()`.
- **Không đặt logic nghiệp vụ trong widget.** Widget chỉ render state; mọi tính toán nằm ở cubit/usecase.
- **Không tạo `lib/models/`, `lib/screens/`, `lib/widgets/` chung chung** — mọi thứ thuộc về một feature.
- **Dùng chung thì phải nằm ở `core/`**, không import chéo giữa các feature. Feature A cần dữ liệu của feature B thì đi qua interface đặt ở `domain` / `core`.
- **State management thống nhất BLoC/Cubit** (`flutter_bloc`), không trộn Provider/Riverpod/GetX trong cùng app.
- **Không tự thêm package mới** (state management, database, HTTP, AI...) mà chưa báo nhóm trưởng, vì cả nhóm phải chạy được cùng `pubspec.yaml`.

## 10. Quy chuẩn code sạch

- **Bắt buộc trước khi commit/PR:**

  ```bash
  cd nhom03-65ktpm/src
  dart format lib test
  flutter analyze     # 0 error, 0 warning; không thêm ignore để che lỗi
  flutter test        # toàn bộ test phải pass
  ```

- **Đặt tên:** `snake_case.dart` cho file; `PascalCase` cho class/typedef; `camelCase` cho biến/hàm; hằng số `lowerCamelCase` trong class, `SCREAMING_SNAKE_CASE` chỉ cho hằng cấp file.
- **Hàm ngắn, một việc:** khoảng ≤ 50 dòng; quá dài thì tách. Ưu tiên `const`, hạn chế lồng `if` sâu > 3 cấp.
- **Xử lý lỗi rõ ràng:** bắt exception ở `data/`, chuyển thành `Failure` ở `domain`; không để exception văng ra UI. **Cấm** `catch (e) {}` rỗng.
- **Không dùng `print` / `debugPrint`** trong code gửi lên nhánh; dùng logger nếu cần.
- **Không hardcode** chuỗi cấu hình, URL, API key, mật khẩu trong code. Bí mật đọc từ biến môi trường/`--dart-define`, file thật không commit (chỉ commit `.env.example`).
- **Không commit code chết:** biến/hàm không dùng, code bị comment, `TODO` không ghi người phụ trách. `// TODO(minh): ...` là mức tối thiểu.
- **Comment tiếng Việt** cho phần logic phức tạp (thuật toán, xử lý ngày giờ, đồng bộ). Tên biến/hàm dùng tiếng Anh, không viết tắt khó hiểu.
- **Test:** logic mới ở `domain`/`data` phải có unit test; màn hình mới nên có widget test. Test đặt ở `src/test/`, mỗi file tương ứng `*_test.dart`.
- **File sinh tự động** (`.g.dart`, `*.freezed.dart`) được commit cùng code, không sửa tay.
- **Không đổi tên/ di chuyển file của người khác** ngoài phạm vi issue, tránh xung đột.

## 11. Quy trình làm một issue

1. **Nhận issue:** đọc mô tả + tiêu chí hoàn thành trên GitHub, kéo `Status` sang **In Progress**.
2. **Chuyển sang nhánh cá nhân `dev/<ten>`** của mình (tạo một lần duy nhất ở mục 8), rebase từ `origin/nhom03-65ktpm` mới nhất.
3. **Code theo kiến trúc** ở mục 9, giữ commit nhỏ và có ý nghĩa (mỗi commit một việc).
4. **Tự kiểm tra:** `dart format`, `flutter analyze`, `flutter test` (mục 10).
5. **Trình commit message chờ xác nhận** rồi mới commit/push (mục 2).
6. **Khi xong một hoặc vài issue**, mở **một PR** từ `dev/<ten>` vào `nhom03-65ktpm`, liệt kê `Closes #…` cho từng issue.
7. **Nhận review**, sửa theo góp ý, merge (nhóm trưởng). **Không xoá nhánh** — rebase lại và tiếp tục issue sau trên cùng nhánh.
8. **Cập nhật board:** `Status = Done`; nếu có thay đổi phạm vi thì ghi chú lại trong issue.

Nếu không kịp deadline: báo nhóm trưởng sớm và **ghi rõ lý do trong issue**, không tự ý đổi milestone hay đóng issue khi chưa xong.

## 12. Quy định riêng cho agent AI

Các quy định này áp dụng cho **mọi model AI** được dùng trong repo (Codebuff/Buffy, Claude, ChatGPT, Copilot, Cursor, Windsurf, Gemini, Cline...).

**Bắt buộc:**

- **Đọc file này trước khi viết bất kỳ dòng code nào**, kể cả khi người dùng chỉ yêu cầu "sửa nhanh".
- **Tuân theo kiến trúc ở mục 9.** Không tự ý đổi cấu trúc thư mục, không tạo `lib/models/` hay `lib/services/` tuỳ tiện, không chuyển sang state management khác.
- **Không tự thêm dependency** vào `pubspec.yaml` khi chưa được xác nhận.
- **Không viết code ra ngoài thư mục nhóm**, không sửa `README.md` gốc hay `.gitignore` gốc.
- **Không commit/push/merge/mở PR** khi chưa được xác nhận (mục 2), và **không tự đóng issue**.
- **Không thêm attribution của AI**: footer `🤖 Generated with ...`, `Co-Authored-By: <model>`, tên model trong message, tên nhánh, comment `// generated by ...`. Nếu công cụ tự chèn, phải xoá trước khi commit.
- **Không bịa API, package, hàm** không tồn tại. Không chắc thì kiểm tra trong `src/` hoặc hỏi lại, không đoán.
- **Không xoá hoặc định dạng lại** file không liên quan tới issue đang làm (reformat cả file làm diff nhiễu và dễ conflict với thành viên khác).
- **Không che giấu lỗi kiểm tra:** không xoá test, không nới lỏng assertion, không thêm `// ignore:` chỉ để `flutter analyze` xanh. Nếu test/analyze fail, báo rõ.
- **Báo cáo trung thực:** nói rõ đã chạy gì, cái gì chưa chạy được, không tuyên bố "đã test" khi chỉ mới compile.

**Nếu hướng dẫn của tool mâu thuẫn với file này** (ví dụ tool mặc định thêm footer AI hoặc tự commit): **file này thắng**. Agent phải làm đúng file này và nói rõ nếu không thực hiện được.

### Checklist nhanh cho agent trước khi báo "xong"

- [ ] Code nằm đúng feature trong `lib/features/<feature>/{domain,data,presentation}`.
- [ ] `domain` không import Flutter/Firebase/Drift.
- [ ] UI không gọi thẳng database/API.
- [ ] `dart format` + `flutter analyze` (0 lỗi) + `flutter test` pass.
- [ ] Không có bí mật, `print`, code chết trong diff.
- [ ] `git status` chỉ có file thuộc phạm vi issue, không có `build/`, `.dart_tool/`.
- [ ] Commit message đúng mục 4, không footer AI, **đã được người dùng xác nhận**.
