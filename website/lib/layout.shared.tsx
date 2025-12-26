import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';

function VyuhLogo() {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 1024 1024"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="shrink-0"
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M812.138 26L423.723 732.209H635.586L1024 26H812.138Z"
        fill="#5856D6"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M211.863 26L441.38 432.07L335.449 643.933L9.15527e-05 26H211.863Z"
        fill="#5856D6"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M617.933 820.485H406.07L512.002 997.037L617.933 820.485Z"
        fill="#5856D6"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M865.114 997.037H653.251L759.182 820.485L865.114 997.037Z"
        fill="#5856D6"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M1006.36 732.209H794.493L900.424 555.657L1006.36 732.209Z"
        fill="#5856D6"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M617.933 26H406.07L512.002 202.552L617.933 26Z"
        fill="#5856D6"
      />
    </svg>
  );
}

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: (
        <div className="flex items-center gap-2">
          <VyuhLogo />
          <span className="font-bold">Vyuh Node Flow</span>
        </div>
      ),
    },
    githubUrl: 'https://github.com/vyuh-tech/vyuh_node_flow',
    links: [
      {
        text: 'Documentation',
        url: '/docs',
        active: 'nested-url',
      },
    ],
  };
}
