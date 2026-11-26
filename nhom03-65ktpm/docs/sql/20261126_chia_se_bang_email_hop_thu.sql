-- Email-based note sharing and recipient inbox.
-- Run after 20261126_chia_se_ghi_chu_chi_xem.sql and
-- 20261126_mo_ban_chup_ghi_chu_duoc_chia_se.sql.

alter table public.note_shares
  add column if not exists shared_with_email text;

create or replace function public.sync_my_profile()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id text := auth.jwt() ->> 'sub';
  v_email text := lower(btrim(auth.jwt() ->> 'email'));
begin
  if v_user_id is null or v_user_id = '' or v_email is null or v_email = '' then
    raise exception 'Authenticated Firebase UID and email are required'
      using errcode = '42501';
  end if;

  insert into public.profiles (user_id, email, updated_at)
  values (v_user_id, v_email, now())
  on conflict (user_id) do update
    set email = excluded.email,
        updated_at = now();
end;
$$;

create or replace function public.create_note_share_by_email(
  p_source_note_id text,
  p_recipient_email text,
  p_title text,
  p_content text,
  p_kind text,
  p_tags text[]
)
returns table (
  id uuid,
  note_id uuid,
  source_note_id text,
  owner_id text,
  shared_with text,
  shared_with_email text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id text := auth.jwt() ->> 'sub';
  v_owner_email text := lower(btrim(auth.jwt() ->> 'email'));
  v_recipient_email text := lower(btrim(p_recipient_email));
  v_recipient_id text;
  v_note_id uuid;
  v_share_id uuid;
begin
  if v_owner_id is null or v_owner_id = '' or
     v_owner_email is null or v_owner_email = '' then
    raise exception 'Authenticated Firebase UID and email are required'
      using errcode = '42501';
  end if;
  if p_source_note_id is null or p_source_note_id = '' or
     v_recipient_email is null or v_recipient_email = '' or
     v_recipient_email = v_owner_email then
    raise exception 'A valid recipient email is required'
      using errcode = '22023';
  end if;

  insert into public.profiles (user_id, email, updated_at)
  values (v_owner_id, v_owner_email, now())
  on conflict (user_id) do update
    set email = excluded.email,
        updated_at = now();

  select p.user_id
    into v_recipient_id
    from public.profiles as p
    where lower(btrim(p.email)) = v_recipient_email
    limit 1;

  if v_recipient_id is null then
    raise exception 'No SmartNote account found for this email'
      using errcode = 'P0002';
  end if;
  if v_recipient_id = v_owner_id then
    raise exception 'Cannot share a note with yourself'
      using errcode = '22023';
  end if;

  insert into public.notes (user_id, title, content, kind, tags)
  values (
    v_owner_id,
    coalesce(p_title, ''),
    coalesce(p_content, ''),
    case when p_kind = 'diary' then 'diary' else 'note' end,
    coalesce(p_tags, array[]::text[])
  )
  returning notes.id into v_note_id;

  insert into public.note_shares (
    note_id,
    source_note_id,
    owner_id,
    shared_with,
    shared_with_email,
    permission
  )
  values (
    v_note_id,
    p_source_note_id,
    v_owner_id,
    v_recipient_id,
    v_recipient_email,
    'view'
  )
  returning note_shares.id into v_share_id;

  return query
    select s.id, s.note_id, s.source_note_id, s.owner_id, s.shared_with,
           s.shared_with_email, s.created_at
    from public.note_shares as s
    where s.id = v_share_id;
end;
$$;

create or replace function public.list_received_note_shares()
returns table (
  id uuid,
  note_id uuid,
  owner_id text,
  owner_email text,
  title text,
  kind text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select s.id, s.note_id, s.owner_id, p.email, n.title, n.kind, s.created_at
  from public.note_shares as s
  join public.notes as n on n.id = s.note_id
  left join public.profiles as p on p.user_id = s.owner_id
  where s.shared_with = (select auth.jwt() ->> 'sub')
  order by s.created_at desc
$$;

revoke all on function public.sync_my_profile()
  from public, anon, authenticated;
revoke all on function public.create_note_share_by_email(text, text, text, text, text, text[])
  from public, anon, authenticated;
revoke all on function public.list_received_note_shares()
  from public, anon, authenticated;

grant execute on function public.sync_my_profile()
  to authenticated;
grant execute on function public.create_note_share_by_email(text, text, text, text, text, text[])
  to authenticated;
grant execute on function public.list_received_note_shares()
  to authenticated;

notify pgrst, 'reload schema';
