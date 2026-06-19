-- IDEAL row level security policy baseline.
-- Normal client writes to sensitive business tables are intentionally disabled.
-- NestJS service role performs business mutations after authorization and audit.

alter table profiles enable row level security;
alter table companies enable row level security;
alter table company_members enable row level security;
alter table kyc_submissions enable row level security;
alter table trust_counters enable row level security;
alter table deals enable row level security;
alter table deal_parties enable row level security;
alter table deal_versions enable row level security;
alter table deal_approvals enable row level security;
alter table deal_files enable row level security;
alter table messages enable row level security;
alter table notifications enable row level security;
alter table subscriptions enable row level security;
alter table audit_logs enable row level security;
alter table admin_actions enable row level security;
alter table reports enable row level security;

create policy profiles_select_own on profiles
  for select using (auth.uid() = auth_user_id);

create policy profiles_update_safe_own on profiles
  for update using (auth.uid() = auth_user_id)
  with check (
    auth.uid() = auth_user_id
    and kyc_status = (select kyc_status from profiles p where p.id = profiles.id)
    and is_admin = (select is_admin from profiles p where p.id = profiles.id)
    and admin_role is not distinct from (select admin_role from profiles p where p.id = profiles.id)
  );

create policy deals_select_participant on deals
  for select using (
    creator_profile_id in (select id from profiles where auth_user_id = auth.uid())
    or exists (
      select 1 from deal_parties dp
      join profiles p on p.id = dp.profile_id
      where dp.deal_id = deals.id and p.auth_user_id = auth.uid()
    )
  );

create policy deal_parties_select_for_deal_participants on deal_parties
  for select using (
    exists (
      select 1 from deals d
      where d.id = deal_parties.deal_id
      and (
        d.creator_profile_id in (select id from profiles where auth_user_id = auth.uid())
        or exists (
          select 1 from deal_parties dp
          join profiles p on p.id = dp.profile_id
          where dp.deal_id = d.id and p.auth_user_id = auth.uid()
        )
      )
    )
  );

create policy deal_versions_select_for_deal_participants on deal_versions
  for select using (
    exists (
      select 1 from deals d
      where d.id = deal_versions.deal_id
      and (
        d.creator_profile_id in (select id from profiles where auth_user_id = auth.uid())
        or exists (
          select 1 from deal_parties dp
          join profiles p on p.id = dp.profile_id
          where dp.deal_id = d.id and p.auth_user_id = auth.uid()
        )
      )
    )
  );

create policy deal_approvals_select_for_participants on deal_approvals
  for select using (
    exists (
      select 1 from deal_versions dv
      join deals d on d.id = dv.deal_id
      where dv.id = deal_approvals.version_id
      and (
        d.creator_profile_id in (select id from profiles where auth_user_id = auth.uid())
        or deal_approvals.profile_id in (select id from profiles where auth_user_id = auth.uid())
      )
    )
  );

create policy deal_files_select_for_authorized_deal on deal_files
  for select using (
    visibility <> 'admin_private'
    and exists (
      select 1 from deals d
      where d.id = deal_files.deal_id
      and (
        d.creator_profile_id in (select id from profiles where auth_user_id = auth.uid())
        or exists (
          select 1 from deal_parties dp
          join profiles p on p.id = dp.profile_id
          where dp.deal_id = d.id and p.auth_user_id = auth.uid()
        )
      )
    )
  );

create policy messages_select_for_deal_participants on messages
  for select using (
    message_status <> 'hidden'
    and exists (
      select 1 from deals d
      where d.id = messages.deal_id
      and (
        d.creator_profile_id in (select id from profiles where auth_user_id = auth.uid())
        or exists (
          select 1 from deal_parties dp
          join profiles p on p.id = dp.profile_id
          where dp.deal_id = d.id and p.auth_user_id = auth.uid()
        )
      )
    )
  );

-- Direct realtime chat can be enabled later. For now, message inserts go through NestJS.

create policy notifications_select_own on notifications
  for select using (profile_id in (select id from profiles where auth_user_id = auth.uid()));

create policy notifications_mark_own_read on notifications
  for update using (profile_id in (select id from profiles where auth_user_id = auth.uid()))
  with check (profile_id in (select id from profiles where auth_user_id = auth.uid()));

create policy kyc_submissions_select_own_summary on kyc_submissions
  for select using (profile_id in (select id from profiles where auth_user_id = auth.uid()));

create policy reports_insert_own on reports
  for insert with check (reporter_profile_id in (select id from profiles where auth_user_id = auth.uid()));

-- No policies are defined for direct insert/update/delete on deals, deal_parties,
-- deal_versions, deal_approvals, deal_files, audit_logs, or admin_actions.
-- Supabase service_role bypasses RLS and is used only by NestJS.
