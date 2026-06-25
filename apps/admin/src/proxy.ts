import { NextRequest, NextResponse } from "next/server";

// Proxy middleware - auth removed as it will be handled by NestJS API
// TODO: Configure authentication through NestJS API integration

export async function proxy(request: NextRequest) {
  // Pass through - all auth will be handled by the NestJS backend
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico|.*\\..*).*)"],
};
