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
 *  (b) reads/writes the KYC document columns `document_type`, `front`, `back`, `selfie`.
 *
 * The document columns are now mapped in schema.prisma (KycSubmission.documentType/front/
 * back/selfie), so reads/writes go through the type-safe Prisma client — no raw SQL. The
 * ONLY remaining Supabase coupling is the signed-URL SQL function, isolated below so it can
 * be corrected in one place once its exact name/signature is confirmed with Ranine.
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
   * Persists document references onto the mapped KycSubmission columns. Runs inside the
   * caller's transaction so it commits atomically with the submission state change.
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
    await tx.kycSubmission.update({
      where: { id: submissionId },
      data: {
        documentType: docs.documentType,
        front: docs.front,
        back: docs.back,
        selfie: docs.selfie,
      },
    });
  }

  /** Reads the document references for a single submission (admin detail view). */
  async getDocuments(submissionId: string): Promise<KycDocumentRow | null> {
    const row = await this.prisma.kycSubmission.findUnique({
      where: { id: submissionId },
      select: { documentType: true, front: true, back: true, selfie: true },
    });
    if (!row) {
      return null;
    }
    return {
      document_type: row.documentType,
      front: row.front,
      back: row.back,
      selfie: row.selfie,
    };
  }

  /** Batch-reads document_type for a page of submissions (admin queue view). */
  async getDocumentTypes(ids: string[]): Promise<Map<string, string | null>> {
    if (ids.length === 0) {
      return new Map();
    }
    const rows = await this.prisma.kycSubmission.findMany({
      where: { id: { in: ids } },
      select: { id: true, documentType: true },
    });
    return new Map(rows.map((row) => [row.id, row.documentType]));
  }
}
