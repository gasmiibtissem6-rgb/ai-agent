import { Injectable } from '@nestjs/common';

export type DocumentSide = 'front' | 'back' | 'selfie';

export interface PendingUpload {
  profileId: string;
  side: DocumentSide;
  /** Deterministic storage object path the client is authorized to upload to. */
  storagePath: string;
  mimeType: string;
  sizeBytes: number;
  /** Expiry as an epoch-millisecond timestamp. */
  expiresAt: number;
}

/**
 * In-memory registry of upload authorizations issued by `POST /kyc/storage/authorize`.
 * A KYC submission may only reference storage paths that were pre-authorized here — this
 * is what enforces "Flutter never writes to Storage without prior NestJS authorization".
 *
 * FLAGGED (see summary): this store is process-local and non-persistent. It is correct for
 * a single API instance but MUST be moved to a shared backend (a DB table or Redis) before
 * running multiple instances — otherwise an authorize served by instance A cannot be
 * validated by a submit served by instance B, and all pending refs are lost on restart.
 */
@Injectable()
export class PendingUploadRegistry {
  private readonly store = new Map<string, PendingUpload>();

  register(pending: PendingUpload): void {
    this.store.set(this.key(pending.profileId, pending.storagePath), pending);
  }

  /** Returns the pending upload only if it exists, belongs to the profile and is unexpired. */
  peek(profileId: string, storagePath: string): PendingUpload | null {
    const found = this.store.get(this.key(profileId, storagePath));
    if (!found) {
      return null;
    }
    if (found.expiresAt < Date.now()) {
      this.store.delete(this.key(profileId, storagePath));
      return null;
    }
    return found;
  }

  /** Removes a pending upload once its submission has been persisted. */
  consume(profileId: string, storagePath: string): void {
    this.store.delete(this.key(profileId, storagePath));
  }

  private key(profileId: string, storagePath: string): string {
    return `${profileId}::${storagePath}`;
  }
}
