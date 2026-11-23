-- Cole TUDO isto no Supabase: menu "SQL Editor" -> "New query" -> Run.
-- Cria o lugar onde suas memórias ficam guardadas, protegido para que só a sua conta enxergue.

-- 1) Tabela com as memórias (um registro por conta)
create table if not exists public.memorias_estado (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  dados jsonb not null,
  atualizado_em timestamptz not null default now()
);
alter table public.memorias_estado enable row level security;
drop policy if exists "dono le" on public.memorias_estado;
drop policy if exists "dono grava" on public.memorias_estado;
drop policy if exists "dono atualiza" on public.memorias_estado;
create policy "dono le" on public.memorias_estado for select to authenticated using (user_id = auth.uid());
create policy "dono grava" on public.memorias_estado for insert to authenticated with check (user_id = auth.uid());
create policy "dono atualiza" on public.memorias_estado for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 2) Pasta privada para fotos e vídeos (limite de 50 MB por arquivo no plano gratuito)
insert into storage.buckets (id, name, public, file_size_limit)
values ('midia', 'midia', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;
drop policy if exists "midia: so o dono" on storage.objects;
create policy "midia: so o dono" on storage.objects for all to authenticated
  using (bucket_id = 'midia' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'midia' and (storage.foldername(name))[1] = auth.uid()::text);
