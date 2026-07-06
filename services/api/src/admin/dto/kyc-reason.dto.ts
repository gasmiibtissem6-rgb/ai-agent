/*
 * TODO FOR OUSSEMA
 *
 * This DTO needs to be implemented by the admin dashboard owner.
 *
 * It was created during the KYC backend session and has been removed because the
 * admin backend (src/admin/) is your responsibility.
 *
 * Expected shape — the mandatory justification body for the state-changing KYC
 * decisions (reject / request-resubmission / revoke / recheck):
 *   class KycReasonDto {
 *     reason: string;   // @IsString() @IsNotEmpty() @MaxLength(1000)
 *   }
 *
 * Context:
 * - The reason is recorded in the audit_logs metadata for the decision.
 * - Validate with class-validator; annotate with @ApiProperty for Swagger.
 * - Note: the pre-existing ./review-kyc.dto.ts (ReviewKycDto + KycReviewDecision)
 *   still backs the simpler PATCH /admin/kyc/:submissionId/review route in
 *   admin.controller.ts. Decide whether to keep both flows or consolidate.
 */

export {};
