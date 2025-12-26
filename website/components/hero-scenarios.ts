import { ConnectionData, NodeData } from './hero-visual';

export interface Scenario {
  id: string;
  label: string;
  description: string;
  nodes: NodeData[];
  connections: ConnectionData[];
}

export const SCENARIOS: Scenario[] = [
  {
    id: 'data-processing',
    label: 'Data Processing',
    description: 'Ingest, transform, and store high-volume data streams.',
    nodes: [
      { id: 'n1', type: 'source', title: 'Kafka Stream', x: 20, y: 150, width: 150, height: 90 },
      { id: 'n2', type: 'process', title: 'ETL Transformer', x: 250, y: 80, width: 200, height: 110 },
      { id: 'n3', type: 'config', title: 'Schema Registry', x: 250, y: 250, width: 160, height: 80 },
      { id: 'n4', type: 'output', title: 'Data Lake', x: 550, y: 150, width: 160, height: 100 },
    ],
    connections: [
      { id: 'c1', from: 'n1', to: 'n2', delay: 0 },
      { id: 'c2', from: 'n3', to: 'n2', delay: 0.5, color: 'var(--color-fd-muted-foreground)' },
      { id: 'c3', from: 'n2', to: 'n4', delay: 1.5 },
    ]
  },
  {
    id: 'image-processing',
    label: 'Image Processing',
    description: 'Real-time computer vision pipelines with AI integration.',
    nodes: [
      { id: 'n1', type: 'source', title: 'Camera Feed', x: 50, y: 200, width: 160, height: 100 },
      { id: 'n2', type: 'process', title: 'Object Detect', x: 300, y: 100, width: 180, height: 120 },
      { id: 'n3', type: 'process', title: 'Face Recog', x: 300, y: 280, width: 180, height: 120 },
      { id: 'n4', type: 'output', title: 'Security DB', x: 600, y: 200, width: 150, height: 100 },
    ],
    connections: [
      { id: 'c1', from: 'n1', to: 'n2', delay: 0 },
      { id: 'c2', from: 'n1', to: 'n3', delay: 0.2 },
      { id: 'c3', from: 'n2', to: 'n4', delay: 1.5 },
      { id: 'c4', from: 'n3', to: 'n4', delay: 1.8 },
    ]
  },
  {
    id: 'approval-workflow',
    label: 'Approval Flows',
    description: 'Complex human-in-the-loop workflows with conditional loops.',
    nodes: [
      { id: 'n1', type: 'source', title: 'Submit Request', x: 20, y: 180, width: 150, height: 90 },
      { id: 'n2', type: 'process', title: 'Manager Review', x: 250, y: 180, width: 180, height: 100 },
      { id: 'n3', type: 'output', title: 'Approved', x: 550, y: 100, width: 140, height: 90 },
      { id: 'n4', type: 'action', title: 'Reject / Edit', x: 550, y: 300, width: 140, height: 90 },
    ],
    connections: [
      { id: 'c1', from: 'n1', to: 'n2', delay: 0 },
      { id: 'c2', from: 'n2', to: 'n3', delay: 1.5 },
      { id: 'c3', from: 'n2', to: 'n4', delay: 1.5, color: '#f87171' },
      // Loopback connection: Goes from n4 (Reject) back to n1 (Submit)
      // The visual component will now render this as a "Step" route going to the Input port
      { id: 'c4', from: 'n4', to: 'n1', delay: 3.0, type: 'loopback', color: '#f87171' },
    ]
  },
  {
    id: 'process-automation',
    label: 'Process Automation',
    description: 'Event-driven triggers creating cascades of automated actions.',
    nodes: [
      { id: 'n1', type: 'trigger', title: 'Webhook', x: 20, y: 200, width: 120, height: 120 },
      { id: 'n2', type: 'action', title: 'Parse JSON', x: 220, y: 100, width: 140, height: 90 },
      { id: 'n3', type: 'action', title: 'Update CRM', x: 220, y: 300, width: 140, height: 90 },
      { id: 'n4', type: 'action', title: 'Send Email', x: 430, y: 200, width: 140, height: 90 },
      // Changed type to 'broadcast' for better visual
      { id: 'n5', type: 'broadcast', title: 'Slack Notify', x: 660, y: 200, width: 140, height: 90 },
    ],
    connections: [
      { id: 'c1', from: 'n1', to: 'n2', delay: 0 },
      { id: 'c2', from: 'n1', to: 'n3', delay: 0.2 },
      { id: 'c3', from: 'n2', to: 'n4', delay: 1.2 },
      { id: 'c4', from: 'n3', to: 'n4', delay: 1.4 },
      // Confirmed connection from Send Email (n4) to Slack Notify (n5)
      { id: 'c5', from: 'n4', to: 'n5', delay: 2.5 },
    ]
  }
];