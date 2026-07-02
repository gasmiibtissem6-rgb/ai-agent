import { SubmitKycDto } from './submit-kyc.dto';

/**
 * Resubmission payload. Same shape as {@link SubmitKycDto}: the applicant supplies fresh,
 * pre-authorized storage paths (and optional personal info) for a submission that was
 * REJECTED or RESUBMISSION_REQUIRED.
 */
export class ResubmitKycDto extends SubmitKycDto {}
