import type { NextConfig } from "next";
import path from "node:path";

const nextConfig: NextConfig = {
  outputFileTracingRoot: path.join(__dirname, "../.."),
  watchOptions: {
    pollIntervalMs: 1000,
  },
  turbopack: {
    root: path.join(__dirname, "../.."),
  },
};

export default nextConfig;
