import type { NextConfig } from "next";
import path from "node:path";

const nextConfig: NextConfig = {
  outputFileTracingRoot: path.join(__dirname, "../.."),
  watchOptions: {
    pollIntervalMs: 1000,
  },
};

export default nextConfig;
