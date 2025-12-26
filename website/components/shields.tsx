import React from 'react';

interface ShieldProps {
  href: string;
  src: string;
  alt: string;
}

function Shield({ href, src, alt }: ShieldProps) {
  return (
    <a
      href={href}
      className="inline-block mr-2"
      target="_blank"
      rel="noopener noreferrer"
    >
      <img src={src} alt={alt} className="inline-block" />
    </a>
  );
}

interface GitHubShieldProps {
  repo: string; // e.g., "vyuh-tech/vyuh_node_flow"
}

export function GitHubShield({ repo }: GitHubShieldProps) {
  const encodedLabel = encodeURIComponent(repo);
  return (
    <Shield
      href={`https://github.com/${repo}`}
      src={`https://img.shields.io/github/stars/${repo}?style=for-the-badge&logo=github&label=${encodedLabel}`}
      alt="GitHub Stars"
    />
  );
}

interface PubShieldProps {
  package: string; // e.g., "vyuh_node_flow"
}

export function PubShield({ package: pkg }: PubShieldProps) {
  return (
    <Shield
      href={`https://pub.dev/packages/${pkg}`}
      src={`https://img.shields.io/pub/v/${pkg}?style=for-the-badge&logo=dart&logoColor=white&color=0175C2`}
      alt="Pub Version"
    />
  );
}

interface LicenseShieldProps {
  license: string; // e.g., "MIT"
  url?: string;
}

export function LicenseShield({ license, url }: LicenseShieldProps) {
  const licenseUrl = url || `https://opensource.org/licenses/${license}`;
  return (
    <Shield
      href={licenseUrl}
      src={`https://img.shields.io/badge/License-${license}-yellow?style=for-the-badge`}
      alt={`${license} License`}
    />
  );
}

interface IssuesShieldProps {
  repo: string; // e.g., "vyuh-tech/vyuh_node_flow"
}

export function IssuesShield({ repo }: IssuesShieldProps) {
  return (
    <Shield
      href={`https://github.com/${repo}/issues`}
      src={`https://img.shields.io/github/issues/${repo}?style=for-the-badge`}
      alt="Issues"
    />
  );
}

interface ShieldsGroupProps {
  children: React.ReactNode;
}

export function ShieldsGroup({ children }: ShieldsGroupProps) {
  return <div className="mb-4">{children}</div>;
}
