import type { Meta, StoryObj } from '@storybook/react';
import { AppCard } from './AppCard';

const meta: Meta<typeof AppCard> = {
  title: 'Components/AppCard',
  component: AppCard,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof AppCard>;

const defaultApp = {
  id: 1,
  name: 'Knowledge Base',
  summary: 'Centralize, manage, and share your knowledge library',
  icon: '📚',
  slug: 'knowledge',
  category_id: 1,
};

export const Default: Story = {
  args: {
    app: defaultApp,
    isInstalled: false,
  },
};

export const Installed: Story = {
  args: {
    app: defaultApp,
    isInstalled: true,
  },
};

export const DifferentApp: Story = {
  args: {
    app: {
      id: 2,
      name: 'Projects',
      summary: 'Plan and track your projects',
      icon: '📈',
      slug: 'projects',
      category_id: 2,
    },
    isInstalled: false,
  },
};
