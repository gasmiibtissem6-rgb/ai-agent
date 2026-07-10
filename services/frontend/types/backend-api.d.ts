// Auto-generated from Backend DTOs - Do not edit manually

export interface ReviewKycDto {
  status: string;
  reason?: string;
}

export interface OverrideTrustDto {
  successfulDeals: number;
  ongoingDeals: number;
  breachedDeals: number;
  reason: string;
}

export interface AdminLoginDto {
  email: string;
  password: string;
}

export interface RegisterDto {
  email: string;
  password: string;
  fullName: string;
}

export interface LoginDto {
  email: string;
  password: string;
}

export interface RefreshTokenDto {
  refresh_token: string;
}

export interface ForgotPasswordDto {
  email: string;
}

export interface ChatMessageDto {
}

export interface DealPartyInputDto {
  email: string;
  role: string;
  requiredApproval?: boolean;
}

export interface CreateDealDto {
  title: string;
  description?: string;
  dealType?: string;
  parties?: any[];
  terms: any;
}

export interface ShareDealDto {
  expiresInHours?: number;
  permissions: string[];
  maxUses?: number;
}

export interface CreateDealVersionDto {
  terms: any;
  title?: string;
  summary?: string;
}

export interface UpdateDealDto {
  title?: string;
  description?: string;
  dealType?: string;
  terms?: any;
}

export interface AuthorizeUploadDto {
  fileName: string;
  mimeType: string;
  sizeBytes: number;
  documentSide: string;
}

export interface KycPersonalInfoDto {
  firstName?: string;
  lastName?: string;
  dateOfBirth?: string;
  nationality?: string;
  documentNumber?: string;
}

export interface SubmitKycDto {
  documentType: string;
  storagePathFront: string;
  storagePathBack?: string;
  storagePathSelfie: string;
  personalInfo?: any;
}

export interface ResubmitKycDto {
  documentType: string;
  storagePathFront: string;
  storagePathBack?: string;
  storagePathSelfie: string;
  personalInfo?: any;
}

export interface InitiateKycDto {
  providerReference?: string;
}

export interface ProviderWebhookDto {
  reference: string;
  status: string;
  reason?: string;
}

