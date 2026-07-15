/*
 * TODO FOR OUSSEMA
 *
 * This file needs to be implemented by the admin dashboard owner.
 *
 * It was created during the KYC backend session and has been removed because the
 * admin backend (src/admin/) is your responsibility. The basic KYC review routes
 * still live in admin.controller.ts (restored to their pre-KYC form). This file is
 * the intended home for the *enhanced* admin KYC review surface if you want it.
 *
 * Expected responsibility:
 * A dedicated @Controller('admin/kyc') exposing the full reviewer workflow
 * (paginated queue with status filter, detail view with signed document URLs and
 * audit history, and the individual decision actions).
 *
 * API contracts to implement (NestJS side, inside src/admin/):
 *   Base path: /api/v1/admin/kyc   (global prefix api/v1 is applied in main.ts)
 *   Guards:  @UseGuards(JwtAuthGuard, RolesGuard)   +   @ApiBearerAuth()
 *
 *   GET    /admin/kyc
 *            Roles: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 *            Query: KycQueueQueryDto { page, limit, status? }  (see kyc-queue-query.dto.ts placeholder)
 *            Returns: { items[], total, page, limit, totalPages }
 *
 *   GET    /admin/kyc/:id
 *            Roles: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 *            Returns: submission detail + applicant + TEMPORARY signed document URLs
 *                     (front/back/selfie) + audit history. Never public URLs.
 *
 *   PATCH  /admin/kyc/:id/approve
 *            Roles: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 *
 *   PATCH  /admin/kyc/:id/reject
 *            Roles: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 *            Body: KycReasonDto { reason }  (required)
 *
 *   PATCH  /admin/kyc/:id/request-resubmission
 *            Roles: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 *            Body: KycReasonDto { reason }  (required)
 *
 *   PATCH  /admin/kyc/:id/revoke
 *            Roles: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 *            Body: KycReasonDto { reason }  (required)
 *            Only an APPROVED submission may be revoked (else 400).
 *
 *   POST   /admin/kyc/:id/recheck
 *            Roles: SUPER_ADMIN, ADMIN   (SUPPORT_REVIEWER intentionally excluded — elevated action)
 *            Body: KycReasonDto { reason }  (required)
 *            Moves the submission back to UNDER_REVIEW.
 *
 * Context:
 * - Guards to use: JwtAuthGuard + RolesGuard
 * - Roles for KYC review: SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
 * - Role for recheck only: SUPER_ADMIN, ADMIN
 * - FINANCE_REVIEWER and normal users must be rejected by RolesGuard
 * - Capture @Ip() + @Headers('user-agent') and thread them into the audit context
 * - Read the reviewer id via @CurrentUser('profileId')
 * - Use @ApiTags / @ApiOperation / @ApiResponse for Swagger
 * - Response envelope { success, message, data, requestId } is applied globally
 * - Every state change must write to audit_logs via Prisma
 * - KYC documents must never be returned as public URLs — use the signed URL
 *   mechanism in KycStorageService (src/kyc/storage/kyc-storage.service.ts),
 *   which is exported from KycModule for AdminModule to import.
 * - Implement the logic in admin-kyc.service.ts (see its placeholder).
 */

export {};
