export enum ContractStatus {
  DRAFT = 'DRAFT',
  REVIEW = 'REVIEW',
  WAITING_SIGNATURE = 'WAITING_SIGNATURE',
  SIGNED = 'SIGNED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
}

export class Contract {
  id: string;

  title: string;

  description: string;

  clientName: string;

  freelancerName: string;

  amount: number;

  currency: string;

  status: ContractStatus;

  pdfUrl?: string;

  signedPdfUrl?: string;

  signatureHash?: string;

  createdAt: Date;

  updatedAt: Date;
}
