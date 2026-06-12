-- Hot Takes Wall schema
create table public.takes (
  id uuid primary key default gen_random_uuid(),
  text text not null check (char_length(text) <= 120 and char_length(text) > 0),
  topic text not null check (char_length(topic) <= 24 and char_length(topic) > 0),
  agree int not null default 0,
  disagree int not null default 0,
  spicy int not null default 0,
  created_at timestamptz not null default now()
);

create index takes_created_at_idx on public.takes (created_at desc);

-- Atomic reaction increment (prevents race conditions)
create or replace function public.increment_reaction(take_id uuid, kind text)
returns void
language plpgsql
security definer
as $$
begin
  if kind not in ('agree', 'disagree', 'spicy') then
    raise exception 'invalid reaction kind: %', kind;
  end if;

  if kind = 'agree' then
    update public.takes set agree = agree + 1 where id = take_id;
  elsif kind = 'disagree' then
    update public.takes set disagree = disagree + 1 where id = take_id;
  else
    update public.takes set spicy = spicy + 1 where id = take_id;
  end if;
end;
$$;

-- Row Level Security: anyone can read, insert takes, and call the increment RPC
alter table public.takes enable row level security;

create policy "anyone can read takes"
  on public.takes for select
  using (true);

create policy "anyone can insert takes"
  on public.takes for insert
  with check (true);

grant execute on function public.increment_reaction(uuid, text) to anon, authenticated;
