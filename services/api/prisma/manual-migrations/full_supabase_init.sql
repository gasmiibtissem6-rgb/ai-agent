-- CreateEnum
CREATE TYPE "deal_status" AS ENUM ('DRAFT', 'NEGOTIATION', 'PENDING_APPROVAL', 'APPROVED', 'LOCKED', 'CHANGES_REQUESTED', 'REJECTED', 'CANCELLED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "party_status" AS ENUM ('INVITED', 'ACCEPTED', 'DECLINED', 'REMOVED', 'EXPIRED', 'REVOKED');

-- CreateEnum
CREATE TYPE "approval_status" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CHANGES_REQUESTED', 'INVALIDATED');

-- CreateEnum
CREATE TYPE "kyc_status" AS ENUM ('NOT_STARTED', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'RESUBMISSION_REQUIRED', 'REVOKED');

-- CreateEnum
CREATE TYPE "subscription_status" AS ENUM ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "notification_type" AS ENUM ('DEAL_INVITATION', 'APPROVAL_REQUESTED', 'APPROVED', 'REJECTED', 'CHANGES_REQUESTED', 'FILE_UPLOADED', 'KYC_UPDATED', 'SUBSCRIPTION_UPDATED', 'ADMIN_ACTION');

-- CreateEnum
CREATE TYPE "file_type" AS ENUM ('AVATAR', 'DEAL_ATTACHMENT', 'KYC_DOCUMENT', 'GENERATED_CONTRACT');

-- CreateEnum
CREATE TYPE "file_visibility" AS ENUM ('PRIVATE', 'PARTICIPANT_PRIVATE', 'ADMIN_PRIVATE');

-- CreateEnum
CREATE TYPE "company_member_role" AS ENUM ('OWNER', 'MANAGER', 'MEMBER', 'VIEWER');

-- CreateEnum
CREATE TYPE "admin_role" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'SUPPORT_REVIEWER', 'FINANCE_REVIEWER');

-- CreateEnum
CREATE TYPE "audit_action_type" AS ENUM ('ACCOUNT_CREATED', 'KYC_SUBMITTED', 'KYC_APPROVED', 'KYC_REJECTED', 'KYC_REVOKED', 'KYC_RECHECK', 'KYC_RESUBMISSION_REQUESTED', 'DEAL_CREATED', 'DEAL_UPDATED', 'DEAL_DELETED', 'DEAL_VERSION_CREATED', 'DEAL_SHARED', 'DEAL_INVITE_ACCEPTED', 'DEAL_INVITE_REVOKED', 'PARTY_INVITED', 'PARTY_ACCEPTED', 'PARTY_DECLINED', 'VERSION_CREATED', 'VERSION_SUBMITTED', 'VERSION_APPROVED', 'VERSION_REJECTED', 'CHANGES_REQUESTED', 'VERSION_LOCKED', 'FILE_UPLOADED', 'MESSAGE_CREATED', 'SUBSCRIPTION_EVENT', 'ADMIN_ACTION');

-- CreateEnum
CREATE TYPE "report_status" AS ENUM ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "message_status" AS ENUM ('SENT', 'EDITED', 'DELETED', 'HIDDEN');

-- CreateTable
CREATE TABLE "profiles" (
    "id" UUID NOT NULL,
    "auth_user_id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "display_name" TEXT,
    "avatar_url" TEXT,
    "kyc_status" "kyc_status" NOT NULL DEFAULT 'NOT_STARTED',
    "is_admin" BOOLEAN NOT NULL DEFAULT false,
    "admin_role" "admin_role",
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "archived_at" TIMESTAMP(3),

    CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "companies" (
    "id" UUID NOT NULL,
    "owner_profile_id" UUID NOT NULL,
    "legal_name" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "archived_at" TIMESTAMP(3),

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "company_members" (
    "id" UUID NOT NULL,
    "company_id" UUID NOT NULL,
    "profile_id" UUID NOT NULL,
    "role" "company_member_role" NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "company_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kyc_submissions" (
    "id" UUID NOT NULL,
    "profile_id" UUID NOT NULL,
    "status" "kyc_status" NOT NULL DEFAULT 'SUBMITTED',
    "document_type" TEXT,
    "front" TEXT,
    "back" TEXT,
    "selfie" TEXT,
    "personal_info" JSONB,
    "provider_reference" TEXT,
    "rejection_reason" TEXT,
    "submitted_at" TIMESTAMP(3),
    "reviewed_at" TIMESTAMP(3),
    "reviewed_by_profile_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kyc_submissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trust_counters" (
    "id" UUID NOT NULL,
    "profile_id" UUID NOT NULL,
    "successful_deals" INTEGER NOT NULL DEFAULT 0,
    "ongoing_deals" INTEGER NOT NULL DEFAULT 0,
    "breached_deals" INTEGER NOT NULL DEFAULT 0,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "trust_counters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deals" (
    "id" UUID NOT NULL,
    "creator_profile_id" UUID NOT NULL,
    "company_id" UUID,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "deal_type" TEXT,
    "status" "deal_status" NOT NULL DEFAULT 'DRAFT',
    "current_version_id" UUID,
    "locked_version_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "archived_at" TIMESTAMP(3),
    "cancelled_at" TIMESTAMP(3),

    CONSTRAINT "deals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deal_parties" (
    "id" UUID NOT NULL,
    "deal_id" UUID NOT NULL,
    "profile_id" UUID,
    "email" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "party_status" "party_status" NOT NULL DEFAULT 'INVITED',
    "required_approval" BOOLEAN NOT NULL DEFAULT true,
    "invited_by_profile_id" UUID NOT NULL,
    "accepted_at" TIMESTAMP(3),
    "declined_at" TIMESTAMP(3),
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "deal_parties_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deal_versions" (
    "id" UUID NOT NULL,
    "deal_id" UUID NOT NULL,
    "version_number" INTEGER NOT NULL,
    "status" "deal_status" NOT NULL DEFAULT 'DRAFT',
    "title" TEXT NOT NULL,
    "terms_json" JSONB NOT NULL,
    "summary" TEXT,
    "source_version_id" UUID,
    "submitted_at" TIMESTAMP(3),
    "locked_at" TIMESTAMP(3),
    "created_by_profile_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "deal_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deal_approvals" (
    "id" UUID NOT NULL,
    "version_id" UUID NOT NULL,
    "party_id" UUID NOT NULL,
    "profile_id" UUID NOT NULL,
    "approval_status" "approval_status" NOT NULL DEFAULT 'PENDING',
    "reason" TEXT,
    "decided_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "deal_approvals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deal_files" (
    "id" UUID NOT NULL,
    "deal_id" UUID,
    "version_id" UUID,
    "kyc_submission_id" UUID,
    "uploaded_by_profile_id" UUID NOT NULL,
    "storage_bucket" TEXT NOT NULL,
    "storage_path" TEXT NOT NULL,
    "original_file_name" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "size_bytes" INTEGER NOT NULL,
    "file_type" "file_type" NOT NULL,
    "visibility" "file_visibility" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "deal_files_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "deal_id" UUID NOT NULL,
    "sender_profile_id" UUID NOT NULL,
    "body" TEXT NOT NULL,
    "message_status" "message_status" NOT NULL DEFAULT 'SENT',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "edited_at" TIMESTAMP(3),
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "profile_id" UUID NOT NULL,
    "notification_type" "notification_type" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT,
    "payload_json" JSONB NOT NULL,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" UUID NOT NULL,
    "profile_id" UUID,
    "company_id" UUID,
    "plan_id" UUID,
    "stripe_customer_id" TEXT,
    "stripe_subscription_id" TEXT,
    "status" "subscription_status" NOT NULL DEFAULT 'TRIALING',
    "trial_contracts_used" INTEGER NOT NULL DEFAULT 0,
    "trial_contracts_limit" INTEGER NOT NULL DEFAULT 5,
    "current_period_end" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

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

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "actor_profile_id" UUID,
    "action_type" "audit_action_type" NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" UUID,
    "metadata_json" JSONB NOT NULL,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admin_actions" (
    "id" UUID NOT NULL,
    "admin_profile_id" UUID NOT NULL,
    "action_type" "audit_action_type" NOT NULL,
    "target_resource_type" TEXT NOT NULL,
    "target_resource_id" UUID NOT NULL,
    "reason" TEXT,
    "metadata_json" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_actions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reports" (
    "id" UUID NOT NULL,
    "reporter_profile_id" UUID NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" UUID NOT NULL,
    "status" "report_status" NOT NULL DEFAULT 'OPEN',
    "reason" TEXT NOT NULL,
    "resolution" TEXT,
    "reviewed_by_profile_id" UUID,
    "reviewed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "profiles_auth_user_id_key" ON "profiles"("auth_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "profiles_email_key" ON "profiles"("email");

-- CreateIndex
CREATE INDEX "profiles_auth_user_id_idx" ON "profiles"("auth_user_id");

-- CreateIndex
CREATE INDEX "profiles_email_idx" ON "profiles"("email");

-- CreateIndex
CREATE INDEX "profiles_kyc_status_idx" ON "profiles"("kyc_status");

-- CreateIndex
CREATE INDEX "companies_owner_profile_id_idx" ON "companies"("owner_profile_id");

-- CreateIndex
CREATE INDEX "company_members_company_id_idx" ON "company_members"("company_id");

-- CreateIndex
CREATE INDEX "company_members_profile_id_idx" ON "company_members"("profile_id");

-- CreateIndex
CREATE UNIQUE INDEX "company_members_company_id_profile_id_key" ON "company_members"("company_id", "profile_id");

-- CreateIndex
CREATE INDEX "kyc_submissions_profile_id_idx" ON "kyc_submissions"("profile_id");

-- CreateIndex
CREATE INDEX "kyc_submissions_status_idx" ON "kyc_submissions"("status");

-- CreateIndex
CREATE UNIQUE INDEX "trust_counters_profile_id_key" ON "trust_counters"("profile_id");

-- CreateIndex
CREATE INDEX "deals_creator_profile_id_idx" ON "deals"("creator_profile_id");

-- CreateIndex
CREATE INDEX "deals_company_id_idx" ON "deals"("company_id");

-- CreateIndex
CREATE INDEX "deals_status_idx" ON "deals"("status");

-- CreateIndex
CREATE INDEX "deal_parties_deal_id_idx" ON "deal_parties"("deal_id");

-- CreateIndex
CREATE INDEX "deal_parties_profile_id_idx" ON "deal_parties"("profile_id");

-- CreateIndex
CREATE INDEX "deal_parties_email_idx" ON "deal_parties"("email");

-- CreateIndex
CREATE UNIQUE INDEX "deal_parties_deal_id_email_key" ON "deal_parties"("deal_id", "email");

-- CreateIndex
CREATE INDEX "deal_versions_deal_id_idx" ON "deal_versions"("deal_id");

-- CreateIndex
CREATE INDEX "deal_versions_status_idx" ON "deal_versions"("status");

-- CreateIndex
CREATE UNIQUE INDEX "deal_versions_deal_id_version_number_key" ON "deal_versions"("deal_id", "version_number");

-- CreateIndex
CREATE INDEX "deal_approvals_version_id_idx" ON "deal_approvals"("version_id");

-- CreateIndex
CREATE INDEX "deal_approvals_party_id_idx" ON "deal_approvals"("party_id");

-- CreateIndex
CREATE UNIQUE INDEX "deal_approvals_version_id_party_id_key" ON "deal_approvals"("version_id", "party_id");

-- CreateIndex
CREATE INDEX "deal_files_deal_id_idx" ON "deal_files"("deal_id");

-- CreateIndex
CREATE INDEX "deal_files_version_id_idx" ON "deal_files"("version_id");

-- CreateIndex
CREATE INDEX "deal_files_kyc_submission_id_idx" ON "deal_files"("kyc_submission_id");

-- CreateIndex
CREATE INDEX "messages_deal_id_idx" ON "messages"("deal_id");

-- CreateIndex
CREATE INDEX "messages_created_at_idx" ON "messages"("created_at");

-- CreateIndex
CREATE INDEX "notifications_profile_id_idx" ON "notifications"("profile_id");

-- CreateIndex
CREATE INDEX "notifications_read_at_idx" ON "notifications"("read_at");

-- CreateIndex
CREATE INDEX "subscriptions_profile_id_idx" ON "subscriptions"("profile_id");

-- CreateIndex
CREATE INDEX "subscriptions_company_id_idx" ON "subscriptions"("company_id");

-- CreateIndex
CREATE INDEX "subscriptions_plan_id_idx" ON "subscriptions"("plan_id");

-- CreateIndex
CREATE UNIQUE INDEX "plans_code_key" ON "plans"("code");

-- CreateIndex
CREATE UNIQUE INDEX "deal_invite_links_token_key" ON "deal_invite_links"("token");

-- CreateIndex
CREATE INDEX "deal_invite_links_deal_id_idx" ON "deal_invite_links"("deal_id");

-- CreateIndex
CREATE INDEX "deal_invite_links_token_idx" ON "deal_invite_links"("token");

-- CreateIndex
CREATE INDEX "audit_logs_action_type_idx" ON "audit_logs"("action_type");

-- CreateIndex
CREATE INDEX "audit_logs_resource_type_idx" ON "audit_logs"("resource_type");

-- CreateIndex
CREATE INDEX "audit_logs_resource_id_idx" ON "audit_logs"("resource_id");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- CreateIndex
CREATE INDEX "admin_actions_admin_profile_id_idx" ON "admin_actions"("admin_profile_id");

-- CreateIndex
CREATE INDEX "reports_status_idx" ON "reports"("status");

-- AddForeignKey
ALTER TABLE "companies" ADD CONSTRAINT "companies_owner_profile_id_fkey" FOREIGN KEY ("owner_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kyc_submissions" ADD CONSTRAINT "kyc_submissions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kyc_submissions" ADD CONSTRAINT "kyc_submissions_reviewed_by_profile_id_fkey" FOREIGN KEY ("reviewed_by_profile_id") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trust_counters" ADD CONSTRAINT "trust_counters_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deals" ADD CONSTRAINT "deals_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deals" ADD CONSTRAINT "deals_creator_profile_id_fkey" FOREIGN KEY ("creator_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_parties" ADD CONSTRAINT "deal_parties_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_parties" ADD CONSTRAINT "deal_parties_invited_by_profile_id_fkey" FOREIGN KEY ("invited_by_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_parties" ADD CONSTRAINT "deal_parties_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_versions" ADD CONSTRAINT "deal_versions_created_by_profile_id_fkey" FOREIGN KEY ("created_by_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_versions" ADD CONSTRAINT "deal_versions_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_versions" ADD CONSTRAINT "deal_versions_source_version_id_fkey" FOREIGN KEY ("source_version_id") REFERENCES "deal_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_approvals" ADD CONSTRAINT "deal_approvals_party_id_fkey" FOREIGN KEY ("party_id") REFERENCES "deal_parties"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_approvals" ADD CONSTRAINT "deal_approvals_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_approvals" ADD CONSTRAINT "deal_approvals_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "deal_versions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_files" ADD CONSTRAINT "deal_files_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_files" ADD CONSTRAINT "deal_files_kyc_submission_id_fkey" FOREIGN KEY ("kyc_submission_id") REFERENCES "kyc_submissions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_files" ADD CONSTRAINT "deal_files_uploaded_by_profile_id_fkey" FOREIGN KEY ("uploaded_by_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_files" ADD CONSTRAINT "deal_files_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "deal_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_profile_id_fkey" FOREIGN KEY ("sender_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_invite_links" ADD CONSTRAINT "deal_invite_links_created_by_profile_id_fkey" FOREIGN KEY ("created_by_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deal_invite_links" ADD CONSTRAINT "deal_invite_links_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actor_profile_id_fkey" FOREIGN KEY ("actor_profile_id") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "admin_actions" ADD CONSTRAINT "admin_actions_admin_profile_id_fkey" FOREIGN KEY ("admin_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporter_profile_id_fkey" FOREIGN KEY ("reporter_profile_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reviewed_by_profile_id_fkey" FOREIGN KEY ("reviewed_by_profile_id") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

