-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "audit_action_type" ADD VALUE 'KYC_REVOKED';
ALTER TYPE "audit_action_type" ADD VALUE 'KYC_RECHECK';
ALTER TYPE "audit_action_type" ADD VALUE 'KYC_RESUBMISSION_REQUESTED';
ALTER TYPE "audit_action_type" ADD VALUE 'DEAL_UPDATED';
ALTER TYPE "audit_action_type" ADD VALUE 'DEAL_DELETED';
ALTER TYPE "audit_action_type" ADD VALUE 'DEAL_VERSION_CREATED';
ALTER TYPE "audit_action_type" ADD VALUE 'DEAL_SHARED';
ALTER TYPE "audit_action_type" ADD VALUE 'DEAL_INVITE_ACCEPTED';
ALTER TYPE "audit_action_type" ADD VALUE 'DEAL_INVITE_REVOKED';

-- AlterEnum
ALTER TYPE "kyc_status" ADD VALUE 'REVOKED';

-- AlterTable
ALTER TABLE "deals" ADD COLUMN     "deal_type" TEXT;

-- AlterTable
ALTER TABLE "kyc_submissions" ADD COLUMN     "back" TEXT,
ADD COLUMN     "document_type" TEXT,
ADD COLUMN     "front" TEXT,
ADD COLUMN     "personal_info" JSONB,
ADD COLUMN     "selfie" TEXT;

-- AlterTable
ALTER TABLE "subscriptions" ADD COLUMN     "plan_id" UUID;

-- CreateTable
CREATE TABLE "plans" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "monthly_deal_limit" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deal_invite_links" (
    "id" UUID NOT NULL,
    "deal_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "created_by_profile_id" UUID NOT NULL,
    "permissions" JSONB NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "max_uses" INTEGER,
    "used_count" INTEGER NOT NULL DEFAULT 0,
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "deal_invite_links_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "plans_code_key" ON "plans"("code");

-- CreateIndex
CREATE UNIQUE INDEX "deal_invite_links_token_key" ON "deal_invite_links"("token");

-- CreateIndex
CREATE INDEX "deal_invite_links_deal_id_idx" ON "deal_invite_links"("deal_id");

-- CreateIndex
CREATE INDEX "deal_invite_links_token_idx" ON "deal_invite_links"("token");

-- CreateIndex
CREATE INDEX "subscriptions_plan_id_idx" ON "subscriptions"("plan_id");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_invite_links" ADD CONSTRAINT "deal_invite_links_created_by_profile_id_fkey" FOREIGN KEY ("created_by_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_invite_links" ADD CONSTRAINT "deal_invite_links_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

