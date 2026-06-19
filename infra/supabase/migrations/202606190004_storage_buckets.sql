-- IDEAL storage bucket contract.
-- Supabase storage buckets may be created in SQL if storage schema is available,
-- otherwise create them with Supabase CLI or dashboard.

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', false),
  ('deal-files', 'deal-files', false),
  ('kyc-documents', 'kyc-documents', false)
on conflict (id) do update set public = excluded.public;

-- Storage rules:
-- 1. avatars: use signed URLs by default; public access requires explicit approval.
-- 2. deal-files: private only. Signed URLs are issued only by NestJS after deal authorization.
-- 3. kyc-documents: private only. Normal clients must not list or read this bucket.
-- 4. Normal authenticated users must not list private buckets.
-- 5. NestJS service role owns signed upload/download URL issuance.
--
-- If SQL bucket creation is unavailable in the target Supabase environment, run:
-- supabase storage create avatars --public=false
-- supabase storage create deal-files --public=false
-- supabase storage create kyc-documents --public=false
