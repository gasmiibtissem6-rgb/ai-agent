-- IDEAL development-only seed data. Do not run in production.

insert into profiles (id, auth_user_id, email, display_name, kyc_status, is_admin, admin_role)
values
  ('00000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'creator@example.com', 'Demo Creator', 'approved', false, null),
  ('00000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'party@example.com', 'Demo Party', 'submitted', false, null),
  ('00000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', 'admin@example.com', 'Demo Admin', 'approved', true, 'admin')
on conflict (id) do nothing;

insert into companies (id, owner_profile_id, legal_name, status)
values ('20000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'IDEAL Demo Company', 'active')
on conflict (id) do nothing;

insert into company_members (id, company_id, profile_id, role)
values
  ('21000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'owner'),
  ('21000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'member')
on conflict (company_id, profile_id) do nothing;

insert into trust_counters (id, profile_id, successful_deals, ongoing_deals, breached_deals)
values
  ('22000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 2, 1, 0),
  ('22000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 1, 1, 0)
on conflict (profile_id) do nothing;

insert into kyc_submissions (id, profile_id, status, provider_reference, submitted_at)
values ('30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'submitted', 'dev_kyc_001', now())
on conflict (id) do nothing;

insert into deals (id, creator_profile_id, company_id, title, description, status)
values
  ('40000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Demo website delivery', 'Development seed deal', 'pending_approval'),
  ('40000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', null, 'Demo consulting agreement', 'Second development seed deal', 'draft')
on conflict (id) do nothing;

insert into deal_parties (id, deal_id, profile_id, email, role, party_status, required_approval, invited_by_profile_id)
values
  ('41000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'party@example.com', 'reviewer', 'accepted', true, '00000000-0000-4000-8000-000000000001'),
  ('41000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', null, 'party@example.com', 'signer', 'invited', true, '00000000-0000-4000-8000-000000000001')
on conflict (deal_id, email) do nothing;

insert into deal_versions (id, deal_id, version_number, status, title, terms_json, summary, submitted_at, created_by_profile_id)
values
  ('42000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', 1, 'pending_approval', 'Initial website terms', '{"deliverable":"MVP","payment":"50 percent upfront"}', 'Initial terms for approval', now(), '00000000-0000-4000-8000-000000000001'),
  ('42000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', 1, 'draft', 'Consulting draft', '{"hours":20}', 'Draft terms', null, '00000000-0000-4000-8000-000000000001')
on conflict (deal_id, version_number) do nothing;

update deals set current_version_id = '42000000-0000-4000-8000-000000000001' where id = '40000000-0000-4000-8000-000000000001';
update deals set current_version_id = '42000000-0000-4000-8000-000000000002' where id = '40000000-0000-4000-8000-000000000002';

insert into deal_approvals (id, version_id, party_id, profile_id, approval_status, reason)
values ('43000000-0000-4000-8000-000000000001', '42000000-0000-4000-8000-000000000001', '41000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'pending', null)
on conflict (version_id, party_id) do nothing;

insert into messages (id, deal_id, sender_profile_id, body)
values ('50000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'Please review the initial version.')
on conflict (id) do nothing;

insert into notifications (id, profile_id, notification_type, title, body, payload_json)
values ('60000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'approval_requested', 'Approval requested', 'Demo website delivery needs approval.', '{"dealId":"40000000-0000-4000-8000-000000000001"}')
on conflict (id) do nothing;

insert into audit_logs (id, actor_profile_id, action_type, resource_type, resource_id, metadata_json)
values ('70000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'deal_created', 'deal', '40000000-0000-4000-8000-000000000001', '{"seed":true}')
on conflict (id) do nothing;
