-- Profile: add public/private visibility flag and an optional unique username.
-- Keep in sync with prisma/schema.prisma (Profile.username / Profile.isPublic).

-- AlterTable
ALTER TABLE "profiles"
  ADD COLUMN IF NOT EXISTS "username" TEXT,
  ADD COLUMN IF NOT EXISTS "is_public" BOOLEAN NOT NULL DEFAULT false;

-- Unique username (partial: NULLs are allowed and not compared).
CREATE UNIQUE INDEX IF NOT EXISTS "profiles_username_key"
  ON "profiles" ("username");
