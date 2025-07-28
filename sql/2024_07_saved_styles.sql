-- Create saved_styles table for dev favourites
CREATE TABLE IF NOT EXISTS saved_styles (
    id            serial primary key,
    user_id       text      not null,
    hairstyle_id  integer   not null references hairstyles(id) on delete cascade,
    created_at    timestamptz not null default now(),
    unique (user_id, hairstyle_id)
);

-- No RLS for dev; add later when real auth is enabled. 