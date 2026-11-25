-- Issue #14: immutable note snapshots, recipient-only reads, and revocation.
-- Run after 20261121_tao_bang_co_ban.sql in Supabase SQL Editor.

alter table public.note_shares
  add column if not exists source_note_id text;

create index if not exists note_shares_source_owner_idx
  on public.note_shares (source_note_id, owner_id);

-- Clients may list shares but must use the RPCs for creation and revocation.
drop policy if exists "shares_owner_manage" on public.note_shares;

create policy "shares_owner_read" on public.note_shares
  for select to authenticated
  using (owner_id = (select auth.jwt() ->> 'sub'));

grant select on public.note_shares to authenticated;
revoke insert, update, delete on public.note_shares from authenticated;

-- Shared snapshots cannot be changed or deleted through the client API.
drop policy if exists "notes_owner" on public.notes;

create policy "notes_owner_read" on public.notes
  for select to authenticated
  using (user_id = (select auth.jwt() ->> 'sub'));

create policy "notes_owner_insert" on public.notes
  for insert to authenticated
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "notes_owner_update" on public.notes
  for update to authenticated
  using (
    user_id = (select auth.jwt() ->> 'sub')
    and not exists (
      select 1 from public.note_shares s where s.note_id = notes.id
    )
  )
  with check (user_id = (select auth.jwt() ->> 'sub'));

create policy "notes_owner_delete" on public.notes
  for delete to authenticated
  using (
    user_id = (select auth.jwt() ->> 'sub')
    and not exists (
      select 1 from public.note_shares s where s.note_id = notes.id
    )
  );

create or replace function public.create_note_share(
  p_source_note_id text,
  p_shared_with text,
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
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id text := auth.jwt() ->> 'sub';
  v_recipient_id text := btrim(p_shared_with);
  v_note_id uuid;
  v_share_id uuid;
begin
  if v_owner_id is null or v_owner_id = '' then
    raise exception 'Authenticated Firebase UID is required'
      using errcode = '42501';
  end if;
  if p_source_note_id is null or p_source_note_id = '' or
     v_recipient_id is null or v_recipient_id = '' or
     v_recipient_id = v_owner_id then
    raise exception 'A valid recipient Firebase UID is required'
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
    note_id, source_note_id, owner_id, shared_with, permission
  )
  values (v_note_id, p_source_note_id, v_owner_id, v_recipient_id, 'view')
  returning note_shares.id into v_share_id;

  return query
    select s.id, s.note_id, s.source_note_id, s.owner_id, s.shared_with, s.created_at
    from public.note_shares s
    where s.id = v_share_id;
end;
$$;

create or replace function public.revoke_note_share(p_share_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id text := auth.jwt() ->> 'sub';
  v_note_id uuid;
  v_source_note_id text;
begin
  select s.note_id, s.source_note_id
    into v_note_id, v_source_note_id
    from public.note_shares s
    where s.id = p_share_id and s.owner_id = v_owner_id;

  if not found then
    raise exception 'Share not found or not owned by the caller'
      using errcode = '42501';
  end if;

  delete from public.note_shares where id = p_share_id;

  -- Keep legacy shares (which have no source_note_id) from deleting originals.
  if v_source_note_id is not null then
    delete from public.notes n
      where n.id = v_note_id and n.user_id = v_owner_id;
  end if;
end;
$$;

revoke all on function public.create_note_share(text, text, text, text, text, text[])
  from public, anon, authenticated;
revoke all on function public.revoke_note_share(uuid)
  from public, anon, authenticated;

grant execute on function public.create_note_share(text, text, text, text, text, text[])
  to authenticated;
grant execute on function public.revoke_note_share(uuid)
  to authenticated;
