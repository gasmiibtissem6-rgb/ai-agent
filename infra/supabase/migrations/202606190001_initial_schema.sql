-- IDEAL initial Supabase PostgreSQL schema.
-- This migration defines core application tables. It is intended to be run by
-- Supabase migrations before API implementation reaches feature completeness.

create extension if not exists "pgcrypto";

create type deal_status as enum ('draft', 'negotiation', 'pending_approval', 'approved', 'locked', 'changes_requested', 'rejected', 'cancelled', 'archived');
create type party_status as enum ('invited', 'accepted', 'declined', 'removed', 'expired', 'revoked');
create type approval_status as enum ('pending', 'approved', 'rejected', 'changes_requested', 'invalidated');
create type kyc_status as enum ('not_started', 'submitted', 'under_review', 'approved', 'rejected', 'resubmission_required');
create type subscription_status as enum ('trialing', 'active', 'past_due', 'cancelled', 'expired');
create type notification_type as enum ('deal_invitation', 'approval_requested', 'approved', 'rejected', 'changes_requested', 'file_uploaded', 'kyc_updated', 'subscription_updated', 'admin_action');
create type file_type as enum ('avatar', 'deal_attachment', 'kyc_document', 'generated_contract');
create type file_visibility as enum ('private', 'participant_private', 'admin_private');
create type company_member_role as enum ('owner', 'manager', 'member', 'viewer');
create type admin_role as enum ('super_admin', 'admin', 'support_reviewer', 'finance_reviewer');
create type audit_action_type as enum ('account_created', 'kyc_submitted', 'kyc_approved', 'kyc_rejected', 'deal_created', 'party_invited', 'party_accepted', 'party_declined', 'version_created', 'version_submitted', 'version_approved', 'version_rejected', 'changes_requested', 'version_locked', 'file_uploaded', 'message_created', 'subscription_event', 'admin_action');
create type report_status as enum ('open', 'under_review', 'resolved', 'dismissed');
create type message_status as enum ('sent', 'edited', 'deleted', 'hidden');

create table profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique,
  email text not null unique,
  display_name text,
  avatar_url text,
  kyc_status kyc_status not null default 'not_started',
  is_admin boolean not null default false,
  admin_role admin_role,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table companies (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references profiles(id),
  legal_name text not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role company_member_role not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, profile_id)
);

create table kyc_submissions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  status kyc_status not null default 'submitted',
  provider_reference text,
  rejection_reason text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by_profile_id uuid references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table trust_counters (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references profiles(id) on delete cascade,
  successful_deals integer not null default 0,
  ongoing_deals integer not null default 0,
  breached_deals integer not null default 0,
  updated_at timestamptz not null default now()
);

create table deals (
  id uuid primary key default gen_random_uuid(),
  creator_profile_id uuid not null references profiles(id),
  company_id uuid references companies(id),
  title text not null,
  description text,
  status deal_status not null default 'draft',
  current_version_id uuid,
  locked_version_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  cancelled_at timestamptz
);

create table deal_parties (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references deals(id) on delete cascade,
  profile_id uuid references profiles(id),
  email text not null,
  role text not null,
  party_status party_status not null default 'invited',
  required_approval boolean not null default true,
  invited_by_profile_id uuid not null references profiles(id),
  accepted_at timestamptz,
  declined_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (deal_id, email)
);

create table deal_versions (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references deals(id) on delete cascade,
  version_number integer not null,
  status deal_status not null default 'draft',
  title text not null,
  terms_json jsonb not null,
  summary text,
  source_version_id uuid references deal_versions(id),
  submitted_at timestamptz,
  locked_at timestamptz,
  created_by_profile_id uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (deal_id, version_number)
);

alter table deals add constraint deals_current_version_fk foreign key (current_version_id) references deal_versions(id);
alter table deals add constraint deals_locked_version_fk foreign key (locked_version_id) references deal_versions(id);

create table deal_approvals (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references deal_versions(id) on delete cascade,
  party_id uuid not null references deal_parties(id) on delete cascade,
  profile_id uuid not null references profiles(id),
  approval_status approval_status not null default 'pending',
  reason text,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (version_id, party_id)
);

create table deal_files (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid references deals(id) on delete cascade,
  version_id uuid references deal_versions(id) on delete cascade,
  kyc_submission_id uuid references kyc_submissions(id) on delete cascade,
  uploaded_by_profile_id uuid not null references profiles(id),
  storage_bucket text not null,
  storage_path text not null,
  original_file_name text not null,
  content_type text not null,
  size_bytes integer not null,
  file_type file_type not null,
  visibility file_visibility not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references deals(id) on delete cascade,
  sender_profile_id uuid not null references profiles(id),
  body text not null,
  message_status message_status not null default 'sent',
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  notification_type notification_type not null,
  title text not null,
  body text,
  payload_json jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  company_id uuid references companies(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  status subscription_status not null default 'trialing',
  trial_contracts_used integer not null default 0,
  trial_contracts_limit integer not null default 5,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references profiles(id),
  action_type audit_action_type not null,
  resource_type text not null,
  resource_id uuid,
  metadata_json jsonb not null default '{}'::jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table admin_actions (
  id uuid primary key default gen_random_uuid(),
  admin_profile_id uuid not null references profiles(id),
  action_type audit_action_type not null,
  target_resource_type text not null,
  target_resource_id uuid not null,
  reason text,
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_profile_id uuid not null references profiles(id),
  resource_type text not null,
  resource_id uuid not null,
  status report_status not null default 'open',
  reason text not null,
  resolution text,
  reviewed_by_profile_id uuid references profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
