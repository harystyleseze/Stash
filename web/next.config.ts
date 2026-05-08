import path from "node:path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The repo root contains a separate Next.js project at `/`, with its own
  // package-lock.json. Without this, Turbopack auto-detects the higher
  // lockfile and warns: "Next.js inferred your workspace root, but it may not
  // be correct." Pinning to this directory removes the ambiguity.
  turbopack: {
    root: path.resolve(__dirname),
  },
  images: {
    // Allow `quality={95}` on next/image components (the landing-page hero photos
    // request quality=95). Next 16 requires every quality value used to be listed
    // here explicitly; the default is `[75]`.
    qualities: [75, 95],
  },
};

export default nextConfig;
