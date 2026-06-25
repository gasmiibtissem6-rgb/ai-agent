// Auth API routes removed - integrate with NestJS API instead
// TODO: Connect to NestJS API endpoints for authentication

export const dynamic = "force-dynamic";

export async function GET() {
  return Response.json({ message: "Auth routes removed - use NestJS API" });
}

export async function POST() {
  return Response.json({ message: "Auth routes removed - use NestJS API" });
}
