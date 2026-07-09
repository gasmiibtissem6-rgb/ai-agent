# TODO FOR OUSSEMA — admin KYC tests

The KYC backend session had added Jest specs for the admin KYC review surface.
They were removed together with their implementation because `src/admin/` is your
responsibility. This file is **not** a test (it is intentionally not `*.spec.ts`,
so Jest ignores it) — it lists what to re-create once you implement
`admin-kyc.controller.ts` / `admin-kyc.service.ts`.

## admin-kyc.service.spec.ts (unit — mock PrismaService, KycStorageService, provider)
- `approve` → sets status APPROVED, mirrors Profile.kycStatus, writes an audit row
  with `AuditActionType.KYC_APPROVED`.
- `reject` → status REJECTED + `KYC_REJECTED` audit; reason stored.
- `requestResubmission` → status RESUBMISSION_REQUIRED + `KYC_RESUBMISSION_REQUESTED`.
- `revoke` → **blocked (400/BadRequest) unless current status is APPROVED**; happy path
  sets status REVOKED + `KYC_REVOKED` audit and calls the provider's revoke hook.
- `recheck` → status UNDER_REVIEW + `KYC_RECHECK` audit.
- `getById` → returns TEMPORARY signed URLs (never raw paths / public URLs) + audit history.

## admin-kyc.controller.spec.ts (metadata/guards)
- Every route is decorated with `@UseGuards(JwtAuthGuard, RolesGuard)`.
- Review routes allow roles SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER.
- `recheck` allows only SUPER_ADMIN, ADMIN (SUPPORT_REVIEWER excluded).
- Reason-bearing routes (reject/request-resubmission/revoke/recheck) require a non-empty reason.

Reference for mocking style: the user-facing KYC specs under `src/kyc/` (still green)
and the deals specs under `src/deals/` fully mock Prisma via `$transaction(cb => cb(tx))`.
