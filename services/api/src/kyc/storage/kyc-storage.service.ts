import {
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export interface KycDocumentRow {
  document_type: string | null;
  front: string | null;
  back: string | null;
  selfie: string | null;
}

/**
 * Single integration seam for KYC document storage. It NEVER handles binary data — it only:
 *  (a) asks the Supabase Storage API for temporary signed URLs (upload/download), and
 *  (b) reads/writes the KYC document columns `document_type`, `front`, `back`, `selfie`.
 *
 * The document columns are mapped in schema.prisma, so reads/writes go through the type-safe
 * Prisma client. Signed URLs are issued through the Supabase Storage client (service-role key
 * so it bypasses RLS), matching the Front → NestJS → Supabase architecture.
 */
@Injectable()
export class KycStorageService {
  // The private bucket that holds KYC documents. It must exist in Supabase Storage.
  private static readonly KYC_BUCKET = 'kyc-documents';

  private readonly logger = new Logger(KycStorageService.name);
  private readonly supabase: SupabaseClient | null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    const url = this.config.get<string>('SUPABASE_URL');
    // Service-role key is required for storage admin ops on a private bucket;
    // fall back to the anon key so local setups without it still boot.
    const key =
      this.config.get<string>('SUPABASE_SERVICE_ROLE_KEY') ??
      this.config.get<string>('SUPABASE_ANON_KEY');

    this.supabase =
      url && key
        ? createClient(url, key, { auth: { persistSession: false } })
        : null;
  }

  private bucket() {
    if (!this.supabase) {
      throw new InternalServerErrorException(
        'Supabase Storage is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.',
      );
    }
    return this.supabase.storage.from(KycStorageService.KYC_BUCKET);
  }

  /** Temporary URL a client uses to PUT a document straight to private Storage. */
  async createSignedUploadUrl(
    storagePath: string,
    _expiresInSeconds: number,
  ): Promise<string> {
    const { data, error } = await this.bucket().createSignedUploadUrl(
      storagePath,
      { upsert: true },
    );
    if (error || !data?.signedUrl) {
      this.logger.error(
        `createSignedUploadUrl failed for "${storagePath}": ${error?.message ?? 'no URL returned'}`,
      );
      throw new InternalServerErrorException(
        'Failed to generate a signed upload URL for the KYC document. ' +
          `Ensure the private "${KycStorageService.KYC_BUCKET}" bucket exists in Supabase Storage.`,
      );
    }
    return this.toAbsolute(data.signedUrl);
  }

  /** Temporary URL an admin uses to view a private document. Never a public URL. */
  async createSignedDownloadUrl(
    storagePath: string,
    expiresInSeconds: number,
  ): Promise<string> {
    const { data, error } = await this.bucket().createSignedUrl(
      storagePath,
      expiresInSeconds,
    );
    if (error || !data?.signedUrl) {
      this.logger.error(
        `createSignedUrl failed for "${storagePath}": ${error?.message ?? 'no URL returned'}`,
      );
      throw new InternalServerErrorException(
        'Failed to generate a signed URL for the requested document.',
      );
    }
    return this.toAbsolute(data.signedUrl);
  }

  /** Supabase returns a relative signed URL; make it absolute for the client. */
  private toAbsolute(signedUrl: string): string {
    if (signedUrl.startsWith('http')) {
      return signedUrl;
    }
    const base = (this.config.get<string>('SUPABASE_URL') ?? '').replace(
      /\/$/,
      '',
    );
    return `${base}${signedUrl.startsWith('/') ? '' : '/'}${signedUrl}`;
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
