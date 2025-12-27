import { createMDX } from 'fumadocs-mdx/next';

const withMDX = createMDX();

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
  transpilePackages: ['shiki', '@shikijs/core', '@shikijs/engine-javascript'],
};

export default withMDX(config);
