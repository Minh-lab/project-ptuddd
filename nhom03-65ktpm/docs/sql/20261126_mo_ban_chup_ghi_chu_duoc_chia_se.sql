-- Allow only the intended recipient to read a shared note snapshot.
-- Run after 20261126_chia_se_ghi_chu_chi_xem.sql in Supabase SQL Editor.

create or replace function public.open_note_share(p_share_id uuid)
returns table (
  id uuid,
  title text,
  content text,
  kind text,
  created_at timestamptz,
  updated_at timestamptz,
  subject_id uuid,
  tags text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    n.id,
    n.title,
    n.content,
    n.kind,
    n.created_at,
    n.updated_at,
    n.subject_id,
    n.tags
  from public.note_shares as s
  join public.notes as n on n.id = s.note_id
  where s.id = p_share_id
    and s.shared_with = (select auth.jwt() ->> 'sub')
$$;

revoke all on function public.open_note_share(uuid)
  from public, anon, authenticated;
grant execute on function public.open_note_share(uuid)
  to authenticated;
