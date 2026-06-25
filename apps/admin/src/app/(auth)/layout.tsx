import { ReactNode } from "react";

export default function WithoutLayout({ children }: { children: ReactNode }) {
  // No auth required for login/signup routes
  return <>{children}</>;
}