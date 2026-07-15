import { PrismaClient, KycStatus, AdminRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const email = 'admin@ideal.com';
  // Use environment variable or local safe development fallback string
  const rawPassword = process.env.SEED_ADMIN_PASSWORD || 'DevAdminFallback123!'; 
  
  const hashedPassword = await bcrypt.hash(rawPassword, 10);

  // 1. FIXED: Changed from 'user' to 'profile' to match your schema
  await prisma.profile.upsert({
    where: { email },
    update: {},
    create: {
      email,
      // Pass an explicit string UUID for the Supabase auth mapping tie-in if necessary
      authUserId: '00000000-0000-0000-0000-000000000000', 
      displayName: 'System Administrator',
      kycStatus: KycStatus.APPROVED,
      isAdmin: true,
      adminRole: AdminRole.SUPER_ADMIN,
    },
  });

  console.log('Seeding completed: Admin profile generated cleanly.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });