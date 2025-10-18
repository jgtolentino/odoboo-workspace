import { render, screen } from '@testing-library/react';
import { AppCard } from '../AppCard';

const mockApp = {
  id: 1,
  name: 'Test App',
  summary: 'This is a test app',
  icon: '🧪',
  slug: 'test-app',
  category_id: 1,
};

describe('AppCard', () => {
  it('renders app information correctly', () => {
    render(<AppCard app={mockApp} isInstalled={false} />);

    expect(screen.getByText('Test App')).toBeInTheDocument();
    expect(screen.getByText('This is a test app')).toBeInTheDocument();
    expect(screen.getByText('🧪')).toBeInTheDocument();
    expect(screen.getByText('Install')).toBeInTheDocument();
  });

  it('shows Open button when app is installed', () => {
    render(<AppCard app={mockApp} isInstalled={true} />);

    expect(screen.getByText('Open')).toBeInTheDocument();
    expect(screen.getByText('Open')).toBeDisabled();
  });

  it('shows Install button when app is not installed', () => {
    render(<AppCard app={mockApp} isInstalled={false} />);

    expect(screen.getByText('Install')).toBeInTheDocument();
    expect(screen.getByText('Install')).not.toBeDisabled();
  });
});
