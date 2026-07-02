import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

interface SignedUrlRow {
  signed_url: string | null;
}

export interface KycDocumentRow {
  document_type: string | null;
  front: string | null;
  back: string | null;
  selfie: string | null;
}

/**
 * Single integration seam for KYC document storage. It NEVER handles binary data — it only:
 *  (a) asks the EXISTING Supabase signed-URL SQL function for temporary URLs, and
 *  (b) reads/writes the KYC document columns that exist in the database but are not mapped
 *      by schema.prisma (Ranine-owned): `document_type`, `front`, `back`, `selfie`.
 *
 * Every Supabase / DB-function coupling is centralised here so it can be corrected in ONE
 * place once the exact function name/signature is confirmed with Ranine. schema.prisma is
 * never modified and no SQL function/policy is created here — only reused.
 */
@Injectable()
export class KycStorageService {
  // TODO(ranine): confirm the exact name/signature of the EXISTING signed-URL SQL function
  // and the private KYC bucket name. These two constants are the only coupling points.
  private static readonly SIGNED_URL_FUNCTION = 'create_signed_url';
  private static readonly KYC_BUCKET = 'kyc-documents';

  constructor(private readonly prisma: PrismaService) {}

  /** Temporary URL a client uses to PUT a document straight to private Storage. */
  createSignedUploadUrl(
    storagePath: string,
    expiresInSeconds: number,
  ): Promise<string> {
    return this.callSignedUrlFunction(storagePath, expiresInSeconds);
  }

  /** Temporary URL an admin uses to view a private document. Never a public URL. */
  createSignedDownloadUrl(
    storagePath: string,
    expiresInSeconds: number,
  ): Promise<string> {
    return this.callSignedUrlFunction(storagePath, expiresInSeconds);
  }

  private async callSignedUrlFunction(
    storagePath: string,
    expiresInSeconds: number,
  ): Promise<string> {
    // Reuses the EXISTING database signed-URL function — this code does not create it.
    const rows = await this.prisma.$queryRawUnsafe<SignedUrlRow[]>(
      `SELECT ${KycStorageService.SIGNED_URL_FUNCTION}($1, $2, $3) AS signed_url`,
      KycStorageService.KYC_BUCKET,
      storagePath,
      expiresInSeconds,
    );

    const signed = rows[0]?.signed_url;
    if (!signed) {
      throw new InternalServerErrorException(
        'Failed to generate a signed URL for the requested document.',
      );
    }
    return signed;
  }

  /**
   * Persists document references onto the EXISTING (Ranine-owned) columns that Prisma does
   * not map. Runs inside the caller's transaction. schema.prisma is untouched.
   */
  async persistDocuments(
    tx: Prisma.TransactionClient,
    submissionId: string,
    docs: {
      documentType: string;
      front: string;
      back: string | null;
      selfie: string;
    },
  ): Promise<void> {
    await tx.$executeRaw`
      UPDATE kyc_submissions
      SET document_type = ${docs.documentType},
          front = ${docs.front},
          back = ${docs.back},
          selfie = ${docs.selfie}
      WHERE id = ${submissionId}::uuid`;
  }

  /** Reads the raw document references for a single submission (admin detail view). */
  async getDocuments(submissionId: string): Promise<KycDocumentRow | null> {
    const rows = await this.prisma.$queryRaw<KycDocumentRow[]>`
      SELECT document_type, front, back, selfie
      FROM kyc_submissions
      WHERE id = ${submissionId}::uuid
      LIMIT 1`;
    return rows[0] ?? null;
  }

  /** Batch-reads document_type for a page of submissions (admin queue view). */
  async getDocumentTypes(ids: string[]): Promise<Map<string, string | null>> {
    if (ids.length === 0) {
      return new Map();
    }
    const rows = await this.prisma.$queryRaw<
      Array<{ id: string; document_type: string | null }>
    >`
      SELECT id::text AS id, document_type
      FROM kyc_submissions
      WHERE id IN (${Prisma.join(ids.map((id) => Prisma.sql`${id}::uuid`))})`;
    return new Map(rows.map((row) => [row.id, row.document_type]));
  }
}
