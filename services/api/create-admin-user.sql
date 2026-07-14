-- Run this in the Supabase SQL editor.
-- Update the email, password, and display name before executing.

create extension if not exists pgcrypto;

do $$
declare
  admin_user_id uuid := gen_random_uuid();
  admin_email text := 'admin@ideal.local';
  admin_password text := 'ChangeMe123!';
  admin_display_name text := 'IDEAL Admin';
begin
  if exists (select 1 from auth.users where email = admin_email) then
    raise notice 'Auth user already exists for %', admin_email;
  else
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      recovery_token,
      confirmation_token,
      email_change,
      email_change_token_new,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmed_at
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      admin_user_id,
      'authenticated',
      'authenticated',
      admin_email,
      crypt(admin_password, gen_salt('bf')),
      now(),
      '',
      '',
      '',
      '',
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      jsonb_build_object('display_name', admin_display_name),
      now(),
      now(),
      now()
    );

    insert into auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      created_at,
      updated_at,
      last_sign_in_at
    )
    values (
      admin_user_id,
      admin_user_id,
      jsonb_build_object(
        'sub', admin_user_id::text,
        'email', admin_email,
        'email_verified', true
      ),
      'email',
      admin_user_id::text,
      now(),
      now(),
      now()
    );
  end if;

  insert into public.profiles (
    auth_user_id,
    email,
    display_name,
    is_admin,
    admin_role,
    kyc_status
  )
  values (
    coalesce(
      (select id from auth.users where email = admin_email limit 1),
      admin_user_id
    ),
    admin_email,
    admin_display_name,
    true,
    'SUPER_ADMIN'::admin_role,
    'APPROVED'::kyc_status
  )
  on conflict (auth_user_id) do update
  set
    email = excluded.email,
    display_name = excluded.display_name,
    is_admin = true,
    admin_role = 'SUPER_ADMIN'::admin_role,
    kyc_status = 'APPROVED'::kyc_status,
    archived_at = null;
end $$;
