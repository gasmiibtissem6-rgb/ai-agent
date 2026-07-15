/*
 * TODO FOR OUSSEMA
 *
 * This file needs to be implemented by the admin dashboard owner.
 *
 * It was created during the KYC backend session and has been removed because the
 * admin backend (src/admin/) is your responsibility.
 *
 * Expected responsibility:
 * The service backing admin-kyc.controller.ts — reading the KYC review queue and
 * applying reviewer decisions. Each decision runs in a single Prisma transaction
 * that (a) updates the KycSubmission, (b) mirrors the status onto the applicant's
 * Profile.kycStatus, and (c) writes an audit_logs row.
 *
 * Service methods to implement (all take the reviewer profileId + an audit context
 * carrying { ipAddress?, userAgent? } with NO personal data / document paths):
 *
 *   getQueue(query)          -> paginated submissions (+ optional status filter),
 *                               each with applicant summary, document_type and a
 *                               count of prior audit actions.
 *   getById(id)              -> submission detail + applicant + TEMPORARY signed
 *                               document URLs + audit history (most recent first).
 *   approve(id, reviewerId, audit)
 *   reject(id, reviewerId, reason, audit)
 *   requestResubmission(id, reviewerId, reason, audit)
 *   revoke(id, reviewerId, reason, audit)   // only when currently APPROVED, else 400
 *   recheck(id, reviewerId, reason, audit)  // back to UNDER_REVIEW
 *
 * Status + audit mapping (enums already exist in schema.prisma — do NOT edit schema):
 *   approve              -> KycStatus.APPROVED               , AuditActionType.KYC_APPROVED
 *   reject               -> KycStatus.REJECTED               , AuditActionType.KYC_REJECTED
 *   requestResubmission  -> KycStatus.RESUBMISSION_REQUIRED  , AuditActionType.KYC_RESUBMISSION_REQUESTED
 *   revoke               -> KycStatus.REVOKED                , AuditActionType.KYC_REVOKED
 *   recheck              -> KycStatus.UNDER_REVIEW           , AuditActionType.KYC_RECHECK
 *
 * Context:
 * - Inject PrismaService.
 * - For signed document URLs, inject KycStorageService (exported from KycModule):
 *   createSignedDownloadUrl(storagePath, expiresInSeconds). Never build public URLs.
 * - The KYC document columns (document_type/front/back/selfie) are mapped on the
 *   KycSubmission model, so read them via Prisma directly.
 * - A revoked/rejected/resubmission profile loses verified access automatically via
 *   KycVerifiedGuard (which requires KycStatus.APPROVED).
 * - No `any` types. No secrets or personal data in logs or audit metadata.
 */

export {};
