import { Home, MessageCircle, Calendar, FileText, Phone, DollarSign, User } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function Navigation({ user, onLogout, activePage }) {
  const navigate = useNavigate();

  const parentNav = [
    { icon: Home, label: 'Home', path: '/parent', page: 'dashboard' },
    { icon: MessageCircle, label: 'Messages', path: '/messages', page: 'messages' },
    { icon: Calendar, label: 'Calendar', path: '/calendar', page: 'calendar' },
    { icon: FileText, label: 'Files', path: '/files', page: 'files' },
    { icon: Phone, label: 'Emergency', path: '/emergency-contacts', page: 'emergency' },
    { icon: DollarSign, label: 'Payments', path: '/payments', page: 'payments' },
    { icon: User, label: 'Profile', path: '/profile', page: 'profile' },
  ];

  const workerNav = [
    { icon: Home, label: 'Home', path: '/worker', page: 'dashboard' },
    { icon: MessageCircle, label: 'Messages', path: '/messages', page: 'messages' },
    { icon: Calendar, label: 'Events', path: '/calendar', page: 'calendar' },
    { icon: FileText, label: 'Files', path: '/files', page: 'files' },
    { icon: Phone, label: 'Contacts', path: '/emergency-contacts', page: 'emergency' },
    { icon: DollarSign, label: 'Billing', path: '/payments', page: 'payments' },
    { icon: User, label: 'Profile', path: '/profile', page: 'profile' },
  ];

  const navItems = user.role === 'parent' ? parentNav : workerNav;

  return (
    <>
      {/* Mobile Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 md:hidden glassmorphism border-t border-border/50 rounded-t-3xl shadow-[0_-4px_20px_rgba(0,0,0,0.05)] z-50" data-testid="mobile-navigation">
        <div className="flex items-center justify-around p-3">
          {navItems.slice(0, 5).map((item) => {
            const Icon = item.icon;
            const isActive = activePage === item.page;
            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className={`flex flex-col items-center gap-1 p-2 rounded-2xl transition-all ${
                  isActive ? 'text-primary' : 'text-muted-foreground'
                }`}
                data-testid={`nav-${item.page}`}
              >
                <Icon className={`h-5 w-5 ${isActive ? 'scale-110' : ''}`} />
                <span className="text-xs font-medium">{item.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Desktop Sidebar/Top Navigation */}
      <div className="hidden md:block fixed top-0 left-0 right-0 glassmorphism border-b border-border/50 shadow-sm z-50" data-testid="desktop-navigation">
        <div className="max-w-7xl mx-auto px-8 py-4">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-bold text-primary">NurseryConnect</h2>
            <div className="flex items-center gap-2">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activePage === item.page;
                return (
                  <button
                    key={item.path}
                    onClick={() => navigate(item.path)}
                    className={`flex items-center gap-2 px-4 py-2 rounded-full transition-all font-medium ${
                      isActive
                        ? 'bg-primary text-primary-foreground'
                        : 'hover:bg-muted text-muted-foreground'
                    }`}
                    data-testid={`nav-${item.page}`}
                  >
                    <Icon className="h-4 w-4" />
                    <span className="text-sm">{item.label}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* Add padding for desktop navigation */}
      <div className="hidden md:block h-20"></div>
    </>
  );
}
