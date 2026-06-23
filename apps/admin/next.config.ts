import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    root: __dirname,
  },
  watchOptions: {
    pollIntervalMs: 1000,
  },
};

export default nextConfig;
