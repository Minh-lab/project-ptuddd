# Cơ Sở Dữ Liệu – Nhóm 03 (SmartNote)

> **Đọc file này trước khi thêm/sửa bảng, cột hay policy.** Áp dụng cho mọi thành viên và mọi agent AI (xem [rules/AGENTS.md](../rules/AGENTS.md)).
> Trạng thái: **21/11/2026** · Người phụ trách schema: Nguyễn Minh (`Minh-lab`).

## 1. Hạ tầng dữ liệu

| Thành phần | Vai trò | Ghi chú |
|---|---|---|
| **Firebase Authentication** | Xác thực (đăng ký / đăng nhập / đăng xuất) | Chỉ dùng Auth, **không** dùng Firestore |
| **Supabase (PostgreSQL)** | **Nguồn dữ liệu chính** dùng chung cả nhóm | Bật RLS cho **mọi** bảng |
| **Supabase Storage** | Ảnh quét vở, tệp đính kèm | Bucket riêng, phân quyền theo `user_id` |
| **Drift (SQLite)** | Cache offline trên máy | Chỉ là bản sao, không phải nơi lưu chính |

**Xác thực với Supabase:** bật *Authentication → Third-party auth → Firebase* (nhập Firebase Project ID). Firebase UID **không phải UUID**, nên:

- `user_id` kiểu **`text`** (chứa Firebase UID), không dùng `uuid`.
- Policy dùng `(select auth.jwt() ->> 'sub')`, **không** dùng `auth.uid()`.
- User Firebase phải có custom claim `role = "authenticated"`, nếu không request chạy như `anon` và RLS từ chối toàn bộ.
- App chỉ dùng **publishable/anon key**; **không** nhúng `service_role`.

## 2. Quy ước chung (bắt buộc)

| Quy ước | Giá trị |
|---|---|
| Tên bảng / cột | `snake_case`, số nhiều cho bảng (`notes`, `quiz_attempts`) |
| Khoá chính | `id uuid primary key default gen_random_uuid()` |
| Chủ sở hữu dữ liệu | `user_id text not null` = Firebase UID |
| Thời gian | `created_at`, `updated_at timestamptz not null default now()` |
| Xoá | **Xoá mềm**: `deleted_at timestamptz` (null = còn hiệu lực) |
| Bảo mật | Mọi bảng bật `row level security` + policy theo `user_id` |
| Quyền | `grant ... to authenticated` (không cấp cho `anon`) |
| Đặt tên ràng buộc | `<bảng>_<cột>_<loại>` khi cần unique/foreign key |
| Thay đổi schema | Có file SQL trong `docs/sql/` + cập nhật file này + báo nhóm |

## 3. Trạng thái các bảng

| Bảng | Trạng thái | Issue | Phụ trách |
|---|---|---|---|
| `profiles` | 🚧 đang làm | #2 | Minh |
| `subjects` | ✅ đã tạo (SQL bên dưới) | #6 | Hạnh |
| `notes` | ✅ đã tạo (SQL bên dưới) | #3 | Đạt |
| `note_attachments` | 📋 đề xuất | #8, #9 | Quân |
| `reminders` | 📋 đề xuất | #10 | Hạnh |
| `summaries` | 📋 đề xuất | #12 | Minh |
| `quizzes` / `quiz_questions` / `quiz_attempts` | 📋 đề xuất | #13 | Đạt |
| `note_shares` | 📋 đề xuất | #14 | Đăng |
| `study_stats` | 📋 đề xuất | #17 | Hạnh |

Chú thích: ✅ đã tạo trên Supabase · 🚧 đang làm · 📋 mới là đề xuất, **phải chốt lại trước khi code**.

## 4. Bảng đã tạo (SQL chuẩn)

```sql
-- =========================================================
-- notes: ghi chú thường (kind = 'note') và nhật ký (kind = 'diary')
-- =========================================================
create table if not exists notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     text not null,                                  -- Firebase UID
  title       text not null default '',
  content     text not null default '',
  subject_id  uuid references subjects(id) on delete set null,
  tags        text[] not null default '{}',
  kind        text not null default 'note' check (kind in ('note', 'diary')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create index if not exists notes_user_updated_idx
  on notes (user_id, updated_at desc);

-- Mỗi người chỉ có một nhật ký mỗi ngày (theo giờ Việt Nam)
create unique index if not exists notes_one_diary_per_day
  on notes (user_id, ((created_at at time zone 'Asia/Ho_Chi_Minh')::date))
  where kind = 'diary' and deleted_at is null;

-- =========================================================
-- subjects: môn học / chủ đề để phân loại ghi chú
-- =========================================================
create table if not exists subjects (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  name       text not null,
  color      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
```

### RLS cho hai bảng trên

```sql
alter table notes    enable row level security;
alter table subjects enable row level security;

grant select, insert, update, delete on notes, subjects to authenticated;

create policy "notes_owner" on notes
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "subjects_owner" on subjects
  for all to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'))
  with check (user_id = (select auth.jwt() ->> 'sub'));
```

## 5. Bảng đề xuất (chưa tạo — chốt với người phụ trách trước khi dùng)

> Đây là đề xuất để cả nhóm thống nhất sớm. Người phụ trách issue có thể sửa cột, **nhưng phải cập nhật file này** trước khi merge.

### `profiles` (#2)
```sql
create table profiles (
  user_id      text primary key,              -- Firebase UID
  display_name text,
  email        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
```

### `note_attachments` (#8, #9) — ảnh quét vở
```sql
create table note_attachments (
  id          uuid primary key default gen_random_uuid(),
  note_id     uuid not null references notes(id) on delete cascade,
  user_id     text not null,
  storage_path text not null,                 -- đường dẫn trong bucket
  page_order  int  not null default 0,
  ocr_text    text,                           -- kết quả OCR
  created_at  timestamptz not null default now()
);
```

### `reminders` (#10)
```sql
create table reminders (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  note_id    uuid references notes(id) on delete cascade,
  remind_at  timestamptz not null,
  is_done    boolean not null default false,
  created_at timestamptz not null default now()
);
```

### `summaries` (#12) — kết quả tóm tắt AI
```sql
create table summaries (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid not null references notes(id) on delete cascade,
  user_id    text not null,
  mode       text not null check (mode in ('short', 'long', 'bullets')),
  content    text not null,                   -- kết quả trả về, KHÔNG ghi đè notes.content
  model      text,
  created_at timestamptz not null default now()
);
```

### `quizzes` / `quiz_questions` / `quiz_attempts` (#13)
```sql
create table quizzes (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid references notes(id) on delete set null,
  user_id    text not null,
  title      text not null default '',
  created_at timestamptz not null default now()
);

create table quiz_questions (
  id         uuid primary key default gen_random_uuid(),
  quiz_id    uuid not null references quizzes(id) on delete cascade,
  question   text not null,
  options    jsonb not null,                  -- ["A", "B", ...]
  answer_idx int not null,
  order_idx  int not null default 0
);

create table quiz_attempts (
  id         uuid primary key default gen_random_uuid(),
  quiz_id    uuid not null references quizzes(id) on delete cascade,
  user_id    text not null,
  score      int not null,
  total      int not null,
  answers    jsonb,
  created_at timestamptz not null default now()
);
```

### `note_shares` (#14) — chia sẻ chỉ xem
```sql
create table note_shares (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid not null references notes(id) on delete cascade,
  owner_id   text not null,
  shared_with text not null,                  -- Firebase UID người được xem
  permission text not null default 'view' check (permission in ('view')),
  created_at timestamptz not null default now(),
  unique (note_id, shared_with)
);
```
Policy cần thêm nhánh: người được chia sẻ `select` được `notes` khi có dòng trong `note_shares`.

### `study_stats` (#17) — thống kê/streak
```sql
create table study_stats (
  user_id      text not null,
  day          date not null,
  note_count   int not null default 0,
  diary_done   boolean not null default false,
  primary key (user_id, day)
);
```
Có thể tính từ `notes` thay vì lưu bảng riêng — chốt với Hạnh trước khi tạo.

## 6. Storage

| Bucket | Dùng cho | Quy ước đường dẫn | Issue |
|---|---|---|---|
| `note-images` | Ảnh chụp vở đã cắt | `{user_id}/{note_id}/{page}.jpg` | #8, #9 |

- Bucket **private**; truy cập bằng signed URL.
- Policy Storage cũng so sánh `auth.jwt() ->> 'sub'` với thư mục đầu tiên của đường dẫn.

## 7. Ánh xạ xuống Drift (cache offline)

| Supabase | Drift | Ghi chú |
|---|---|---|
| `notes` | `Notes` (`lib/core/database/tables.dart`) | Thiếu `user_id`, `tags` lưu dạng text phân tách bằng dấu phẩy |
| `subjects` | chưa có | Bổ sung khi làm #6 |
| — | `synced_at` (dự kiến) | Thời điểm đồng bộ gần nhất để biết bản nào mới |

Quy tắc đồng bộ: ghi Supabase trước → cập nhật Drift; khi mất mạng thì ghi Drift và đánh dấu chờ đồng bộ.

## 8. Cách thêm/sửa schema (checklist)

1. Đọc file này và [rules/AGENTS.md](../rules/AGENTS.md).
2. Tạo file SQL trong `docs/sql/<YYYYMMDD>_<mô-tả>.sql` (không sửa file SQL cũ).
3. Thêm bảng vào mục **3. Trạng thái** và SQL vào mục **4 hoặc 5**.
4. Luôn: `user_id`, `created_at`, `updated_at`, `deleted_at`, `enable row level security`, `grant ... to authenticated`, policy.
5. Cập nhật tầng Drift + `data/datasources/remote` tương ứng.
6. Ghi vào **mục 9. Lịch sử thay đổi**.
7. Báo nhóm trước khi merge; agent **không** tự tạo bảng ngoài file này.

## 9. Lịch sử thay đổi

| Ngày | Người | Nội dung |
|---|---|---|
| 21/11/2026 | Minh | Tạo file; chốt `notes`, `subjects`, RLS theo Firebase UID; đề xuất các bảng còn lại |
