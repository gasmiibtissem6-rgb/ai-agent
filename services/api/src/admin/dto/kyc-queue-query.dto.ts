/*
 * TODO FOR OUSSEMA
 *
 * This DTO needs to be implemented by the admin dashboard owner.
 *
 * It was created during the KYC backend session and has been removed because the
 * admin backend (src/admin/) is your responsibility.
 *
 * Expected shape — the query for GET /admin/kyc (paginated review queue):
 *   class KycQueueQueryDto extends PaginationQueryDto {   // page, limit (already in ./pagination-query.dto.ts)
 *     status?: KycStatus;   // optional filter, @IsOptional() @IsEnum(KycStatus)
 *   }
 *
 * Context:
 * - Validate with class-validator; annotate with @ApiPropertyOptional for Swagger.
 * - KycStatus is imported from '@prisma/client' (do NOT edit schema.prisma).
 * - Reuse PaginationQueryDto from ./pagination-query.dto.ts for page/limit.
 */

export {};
