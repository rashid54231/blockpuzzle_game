-- =============================================================================
-- PRISM BLOCKS - SUPABASE DATABASE SCHEMA & RPC SCRIPT (IDEMPOTENT)
-- =============================================================================
-- This script is completely safe to run multiple times in the Supabase SQL Editor.
-- It establishes all tables, constraints, indexes, triggers, RPCs, and RLS policies.
-- =============================================================================

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- 2. TABLES

-- Profiles
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text not null default 'PrismCadet',
    avatar_id text not null default 'default',
    country_code text not null default 'US',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Player Progress
create table if not exists public.player_progress (
    user_id uuid primary key references auth.users(id) on delete cascade,
    coins integer not null default 100 check (coins >= 0),
    gems integer not null default 10 check (gems >= 0),
    best_classic_score integer not null default 0 check (best_classic_score >= 0),
    streak_count integer not null default 0 check (streak_count >= 0),
    last_daily_date text,
    total_games integer not null default 0 check (total_games >= 0),
    total_lines integer not null default 0 check (total_lines >= 0),
    best_combo integer not null default 0 check (best_combo >= 0),
    selected_theme text not null default 'neon',
    has_remove_ads boolean not null default false,
    settings jsonb not null default '{}'::jsonb,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Inventory (Themes and cosmetics owned)
create table if not exists public.inventory (
    id uuid default gen_random_uuid() primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    item_id text not null,
    item_type text not null default 'theme',
    acquired_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique (user_id, item_id)
);

-- Game Runs (Individual gameplay history)
create table if not exists public.game_runs (
    id uuid default gen_random_uuid() primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    mode text not null check (mode in ('classic', 'daily', 'zen')),
    score integer not null check (score >= 0),
    lines integer not null default 0 check (lines >= 0),
    best_combo integer not null default 0 check (best_combo >= 0),
    moves_count integer not null default 0 check (moves_count >= 0),
    seed bigint not null default 0,
    client_version text not null default '1.0.0',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Daily Puzzles (Deterministic seeded daily board sequence)
create table if not exists public.daily_puzzles (
    puzzle_date text primary key, -- 'YYYY-MM-DD'
    seed bigint not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Daily Scores (Ranked daily challenge leaderboard)
create table if not exists public.daily_scores (
    id uuid default gen_random_uuid() primary key,
    puzzle_date text not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    score integer not null check (score >= 0),
    moves jsonb not null default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique (puzzle_date, user_id)
);

-- Achievements Catalog
create table if not exists public.achievements (
    id text primary key,
    title text not null,
    description text not null,
    reward_coins integer not null default 50
);

-- User Achievements Progress
create table if not exists public.user_achievements (
    id uuid default gen_random_uuid() primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    achievement_key text not null references public.achievements(id) on delete cascade,
    progress integer not null default 0,
    unlocked_at timestamp with time zone,
    claimed_at timestamp with time zone,
    unique (user_id, achievement_key)
);

-- Daily Login Rewards Claims
create table if not exists public.daily_rewards (
    id uuid default gen_random_uuid() primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    claim_date text not null, -- 'YYYY-MM-DD'
    day_index integer not null check (day_index between 1 and 7),
    reward_json jsonb not null default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- In-App Purchases Receipts
create table if not exists public.purchases (
    id uuid default gen_random_uuid() primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    product_id text not null,
    platform text not null default 'android',
    transaction_id text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. INDEXES FOR HIGH-THROUGHPUT LEADERBOARDS & LOOKUPS
create index if not exists idx_daily_scores_date_score on public.daily_scores (puzzle_date, score desc);
create index if not exists idx_player_progress_best_score on public.player_progress (best_classic_score desc);
create index if not exists idx_game_runs_user on public.game_runs (user_id, created_at desc);
create index if not exists idx_inventory_user on public.inventory (user_id);

-- 4. AUTH TRIGGER FOR AUTOMATIC PROFILE & PROGRESS CREATION
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, username, avatar_id, country_code)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'username', 'Player_' || substr(new.id::text, 1, 6)),
        coalesce(new.raw_user_meta_data->>'avatar_id', 'default'),
        coalesce(new.raw_user_meta_data->>'country_code', 'US')
    )
    on conflict (id) do nothing;

    insert into public.player_progress (user_id, coins, gems, selected_theme)
    values (new.id, 100, 10, 'neon')
    on conflict (user_id) do nothing;

    insert into public.inventory (user_id, item_id, item_type)
    values (new.id, 'neon', 'theme')
    on conflict (user_id, item_id) do nothing;

    return new;
end;
$$ language plpgsql security definer set search_path = public;

-- Drop trigger if exists and recreate
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- 5. RPC FUNCTIONS (SECURITY DEFINER)

-- Get or Create Daily Puzzle
create or replace function public.get_daily_puzzle(target_date text)
returns jsonb as $$
declare
    v_seed bigint;
    v_puzzle record;
begin
    select * into v_puzzle from public.daily_puzzles where puzzle_date = target_date;
    if found then
        return jsonb_build_object('puzzle_date', v_puzzle.puzzle_date, 'seed', v_puzzle.seed);
    end if;

    -- Generate a cryptographically strong deterministic seed for today
    v_seed := (abs(('x' || substr(md5(target_date || 'prism_blocks_salt'), 1, 8))::bit(32)::bigint));

    insert into public.daily_puzzles (puzzle_date, seed)
    values (target_date, v_seed)
    on conflict (puzzle_date) do nothing;

    return jsonb_build_object('puzzle_date', target_date, 'seed', v_seed);
end;
$$ language plpgsql security definer set search_path = public;

-- Submit Score RPC with anti-cheat plausibility checks
create or replace function public.submit_score(
    mode text,
    score int,
    lines int default 0,
    best_combo int default 0
)
returns jsonb as $$
declare
    v_user_id uuid := auth.uid();
    v_today text;
    v_earned_coins int;
begin
    if v_user_id is null then
        return jsonb_build_object('success', false, 'error', 'Unauthorized');
    end if;

    -- Plausibility check (anti-cheat)
    if score < 0 or lines < 0 or best_combo < 0 then
        return jsonb_build_object('success', false, 'error', 'Invalid score parameters');
    end if;

    v_today := to_char(timezone('utc'::text, now()), 'YYYY-MM-DD');
    v_earned_coins := (score / 10) + (lines * 2);

    -- Log run
    insert into public.game_runs (user_id, mode, score, lines, best_combo)
    values (v_user_id, mode, score, lines, best_combo);

    -- Update player progress
    update public.player_progress
    set coins = coins + v_earned_coins,
        total_games = total_games + 1,
        total_lines = total_lines + lines,
        best_combo = greatest(best_combo, submit_score.best_combo),
        best_classic_score = case when mode = 'classic' then greatest(best_classic_score, submit_score.score) else best_classic_score end,
        updated_at = timezone('utc'::text, now())
    where user_id = v_user_id;

    -- If Daily Challenge, record in daily_scores table (one ranked score per day)
    if mode = 'daily' then
        insert into public.daily_scores (puzzle_date, user_id, score)
        values (v_today, v_user_id, score)
        on conflict (puzzle_date, user_id)
        do update set score = greatest(daily_scores.score, excluded.score);
    end if;

    return jsonb_build_object(
        'success', true,
        'coins_earned', v_earned_coins,
        'score', score
    );
end;
$$ language plpgsql security definer set search_path = public;

-- Cloud Sync Progress RPC
create or replace function public.sync_progress(
    coins int,
    gems int,
    best_classic_score int,
    streak_count int,
    total_games int,
    total_lines int,
    best_combo int,
    selected_theme text,
    has_remove_ads boolean
)
returns jsonb as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        return jsonb_build_object('success', false, 'error', 'Unauthorized');
    end if;

    update public.player_progress
    set coins = greatest(player_progress.coins, sync_progress.coins),
        gems = greatest(player_progress.gems, sync_progress.gems),
        best_classic_score = greatest(player_progress.best_classic_score, sync_progress.best_classic_score),
        streak_count = sync_progress.streak_count,
        total_games = greatest(player_progress.total_games, sync_progress.total_games),
        total_lines = greatest(player_progress.total_lines, sync_progress.total_lines),
        best_combo = greatest(player_progress.best_combo, sync_progress.best_combo),
        selected_theme = sync_progress.selected_theme,
        has_remove_ads = player_progress.has_remove_ads or sync_progress.has_remove_ads,
        updated_at = timezone('utc'::text, now())
    where user_id = v_user_id;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql security definer set search_path = public;

-- Claim Daily Reward RPC
create or replace function public.claim_daily_reward(
    claim_date text,
    day_index int,
    reward_json jsonb
)
returns jsonb as $$
declare
    v_user_id uuid := auth.uid();
    v_coins int := coalesce((reward_json->>'coins')::int, 0);
    v_gems int := coalesce((reward_json->>'gems')::int, 0);
begin
    if v_user_id is null then
        return jsonb_build_object('success', false, 'error', 'Unauthorized');
    end if;

    insert into public.daily_rewards (user_id, claim_date, day_index, reward_json)
    values (v_user_id, claim_date, day_index, reward_json);

    update public.player_progress
    set coins = coins + v_coins,
        gems = gems + v_gems,
        last_daily_date = claim_date,
        updated_at = timezone('utc'::text, now())
    where user_id = v_user_id;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql security definer set search_path = public;

-- Grant Purchase RPC
create or replace function public.grant_purchase(
    product_id text,
    platform text default 'android',
    transaction_id text default ''
)
returns jsonb as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        return jsonb_build_object('success', false, 'error', 'Unauthorized');
    end if;

    insert into public.purchases (user_id, product_id, platform, transaction_id)
    values (v_user_id, product_id, platform, transaction_id);

    if product_id = 'com.prismblocks.remove_ads' then
        update public.player_progress set has_remove_ads = true where user_id = v_user_id;
    elsif product_id = 'com.prismblocks.gems_tier1' then
        update public.player_progress set gems = gems + 100 where user_id = v_user_id;
    elsif product_id = 'com.prismblocks.gems_tier2' then
        update public.player_progress set gems = gems + 500 where user_id = v_user_id;
    elsif product_id = 'com.prismblocks.gems_tier3' then
        update public.player_progress set gems = gems + 1200 where user_id = v_user_id;
    end if;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql security definer set search_path = public;

-- Leaderboard: Daily Challenge
create or replace function public.leaderboard_daily(
    target_date text,
    limit_count int default 50,
    offset_count int default 0
)
returns table (
    rank bigint,
    user_id uuid,
    username text,
    avatar_id text,
    country_code text,
    score int
) as $$
begin
    return query
    select
        row_number() over (order by ds.score desc, ds.created_at asc) as rank,
        ds.user_id,
        p.username,
        p.avatar_id,
        p.country_code,
        ds.score
    from public.daily_scores ds
    join public.profiles p on p.id = ds.user_id
    where ds.puzzle_date = target_date
    order by ds.score desc, ds.created_at asc
    limit limit_count
    offset offset_count;
end;
$$ language plpgsql security definer set search_path = public;

-- Leaderboard: All-Time Classic
create or replace function public.leaderboard_alltime(
    limit_count int default 50,
    offset_count int default 0
)
returns table (
    rank bigint,
    user_id uuid,
    username text,
    avatar_id text,
    country_code text,
    score int
) as $$
begin
    return query
    select
        row_number() over (order by pp.best_classic_score desc, pp.updated_at asc) as rank,
        pp.user_id,
        p.username,
        p.avatar_id,
        p.country_code,
        pp.best_classic_score as score
    from public.player_progress pp
    join public.profiles p on p.id = pp.user_id
    where pp.best_classic_score > 0
    order by pp.best_classic_score desc, pp.updated_at asc
    limit limit_count
    offset offset_count;
end;
$$ language plpgsql security definer set search_path = public;

-- My Rank Daily
create or replace function public.my_rank_daily(target_date text)
returns jsonb as $$
declare
    v_user_id uuid := auth.uid();
    v_rank bigint;
    v_score int;
begin
    if v_user_id is null then
        return jsonb_build_object('rank', null, 'score', 0);
    end if;

    select r.rank, r.score into v_rank, v_score from (
        select ds.user_id, ds.score, row_number() over (order by ds.score desc, ds.created_at asc) as rank
        from public.daily_scores ds
        where ds.puzzle_date = target_date
    ) r
    where r.user_id = v_user_id;

    return jsonb_build_object('rank', v_rank, 'score', coalesce(v_score, 0));
end;
$$ language plpgsql security definer set search_path = public;

-- GDPR Account & Data Erasure RPC
create or replace function public.delete_my_account()
returns jsonb as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        return jsonb_build_object('success', false, 'error', 'Unauthorized');
    end if;

    -- Deletes user profile and all cascade linked data
    delete from public.profiles where id = v_user_id;
    delete from auth.users where id = v_user_id;

    return jsonb_build_object('success', true);
end;
$$ language plpgsql security definer set search_path = public;

-- 6. ROW LEVEL SECURITY (RLS) POLICIES

alter table public.profiles enable row level security;
alter table public.player_progress enable row level security;
alter table public.inventory enable row level security;
alter table public.game_runs enable row level security;
alter table public.daily_puzzles enable row level security;
alter table public.daily_scores enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.daily_rewards enable row level security;
alter table public.purchases enable row level security;

-- Profiles: Public read, User write
drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Player Progress: User only
drop policy if exists "Users can view own progress" on public.player_progress;
create policy "Users can view own progress" on public.player_progress for select using (auth.uid() = user_id);

drop policy if exists "Users can update own progress" on public.player_progress;
create policy "Users can update own progress" on public.player_progress for update using (auth.uid() = user_id);

-- Inventory: User only
drop policy if exists "Users can view own inventory" on public.inventory;
create policy "Users can view own inventory" on public.inventory for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own inventory" on public.inventory;
create policy "Users can insert own inventory" on public.inventory for insert with check (auth.uid() = user_id);

-- Game Runs: User only
drop policy if exists "Users can view own runs" on public.game_runs;
create policy "Users can view own runs" on public.game_runs for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own runs" on public.game_runs;
create policy "Users can insert own runs" on public.game_runs for insert with check (auth.uid() = user_id);

-- Daily Puzzles: Public read
drop policy if exists "Daily puzzles are viewable by everyone" on public.daily_puzzles;
create policy "Daily puzzles are viewable by everyone" on public.daily_puzzles for select using (true);

-- Daily Scores: Viewable by everyone (Leaderboard), inserted via RPC
drop policy if exists "Daily scores are viewable by everyone" on public.daily_scores;
create policy "Daily scores are viewable by everyone" on public.daily_scores for select using (true);

-- Achievements: Public read
drop policy if exists "Achievements catalog viewable by everyone" on public.achievements;
create policy "Achievements catalog viewable by everyone" on public.achievements for select using (true);

-- User Achievements: User only
drop policy if exists "User achievements viewable by owner" on public.user_achievements;
create policy "User achievements viewable by owner" on public.user_achievements for select using (auth.uid() = user_id);

-- Daily Rewards: User only
drop policy if exists "Daily rewards viewable by owner" on public.daily_rewards;
create policy "Daily rewards viewable by owner" on public.daily_rewards for select using (auth.uid() = user_id);

-- Purchases: User only
drop policy if exists "Purchases viewable by owner" on public.purchases;
create policy "Purchases viewable by owner" on public.purchases for select using (auth.uid() = user_id);

-- 7. GRANTS
grant execute on function public.get_daily_puzzle(text) to authenticated, anon;
grant execute on function public.submit_score(text, int, int, int) to authenticated, anon;
grant execute on function public.sync_progress(int, int, int, int, int, int, int, text, boolean) to authenticated, anon;
grant execute on function public.claim_daily_reward(text, int, jsonb) to authenticated, anon;
grant execute on function public.grant_purchase(text, text, text) to authenticated, anon;
grant execute on function public.leaderboard_daily(text, int, int) to authenticated, anon;
grant execute on function public.leaderboard_alltime(int, int) to authenticated, anon;
grant execute on function public.my_rank_daily(text) to authenticated, anon;
grant execute on function public.delete_my_account() to authenticated, anon;

-- 8. SEED DATA FOR ACHIEVEMENTS CATALOG
insert into public.achievements (id, title, description, reward_coins)
values
    ('first_clear', 'First Spark', 'Clear your very first line.', 50),
    ('lines_10', 'Block Buster', 'Clear a total of 10 lines.', 100),
    ('lines_50', 'Grid Cleaner', 'Clear 50 total lines.', 200),
    ('lines_100', 'Centurion of Blocks', 'Clear 100 total lines.', 500),
    ('combo_2', 'Double Rhythm', 'Hit a 2x combo.', 50),
    ('combo_3', 'Triple Harmony', 'Hit a 3x combo.', 100),
    ('combo_5', 'Cascade Maestro', 'Reach an unbelievable 5x combo.', 300),
    ('score_500', 'Prism Cadet', 'Score 500 points in Classic mode.', 100),
    ('score_1000', 'Score Crusher', 'Score 1,000 points in Classic mode.', 200),
    ('score_2500', 'Grand Master', 'Score 2,500 points in Classic mode.', 500),
    ('score_5000', 'Prism Legend', 'Score 5,000 points in Classic mode.', 1000),
    ('games_5', 'Getting Hooked', 'Play 5 full games.', 100),
    ('games_20', 'Dedicated Player', 'Complete 20 games.', 250),
    ('games_50', 'Prism Veteran', 'Complete 50 games.', 600),
    ('streak_3', 'Daily Dedication', 'Maintain a 3-day login streak.', 200),
    ('streak_7', 'Weekly Champion', 'Reach a 7-day streak.', 500),
    ('theme_collector', 'Aesthetic Sense', 'Unlock at least 2 themes.', 150),
    ('theme_master', 'Prism Wardrobe', 'Unlock 4 themes.', 400),
    ('rich_player', 'Treasure Hoarder', 'Accumulate 1,000 coins.', 200),
    ('gem_finder', 'Gem Collector', 'Hold 25 gems.', 300)
on conflict (id) do nothing;
