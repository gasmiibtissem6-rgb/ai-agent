import { KycStatus } from '@prisma/client';

/**
 * DI token for the active KYC verification provider. KycService and AdminKycService
 * depend on the {@link KycProvider} interface via this token — never on a concrete
 * class — so a third-party provider can be swapped in later without touching business
 * logic (bind a different implementation to KYC_PROVIDER in the module).
 */
export const KYC_PROVIDER = Symbol('KYC_PROVIDER');

/**
 * Provider-neutral contract for identity verification. The current implementation is
 * {@link ManualKycProvider} (human review via the admin endpoints). A future external
 * vendor only needs to implement this interface.
 */
export interface KycProvider {
  /** Dispatch a submission for verification. Manual flow: no-op (humans review it). */
  submitForVerification(submissionId: string): Promise<void>;
  /** Resolve the current verification status of a submission. */
  getVerificationStatus(submissionId: string): Promise<KycStatus>;
  /** Revoke a previously granted verification. Manual flow: no external call. */
  revokeVerification(submissionId: string): Promise<void>;
}
