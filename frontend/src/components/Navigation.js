import { Home, MessageCircle, Calendar, FileText, Phone, DollarSign, User } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { LanguageSwitcher } from './LanguageSwitcher';
import { useTranslation } from 'react-i18next';
import Logo from './Logo';

export default function Navigation({ user, onLogout, activePage }) {
  const navigate = useNavigate();
  const { t } = useTranslation();

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
          {navItems.slice(0, 3).map((item) => {
            const Icon = item.icon;
            const isActive = activePage === item.page;
            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className={`flex flex-col items-center gap-1 p-2 rounded-2xl transition-all ${
                  isActive ? 'text-primary' : 'text-muted-foreground'
                }`}
                data-testid={`mobile-nav-${item.page}`}
              >
                <Icon className={`h-5 w-5 ${isActive ? 'scale-110' : ''}`} />
                <span className="text-xs font-medium">{item.label}</span>
              </button>
            );
          })}
          <LanguageSwitcher />
          <button
            onClick={onLogout}
            className="flex flex-col items-center gap-1 p-2 rounded-2xl transition-all text-destructive"
            data-testid="mobile-logout-button"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
              <polyline points="16 17 21 12 16 7"></polyline>
              <line x1="21" y1="12" x2="9" y2="12"></line>
            </svg>
            <span className="text-xs font-medium">Logout</span>
          </button>
        </div>
      </div>

      {/* Desktop Sidebar/Top Navigation */}
      <div className="hidden md:block fixed top-0 left-0 right-0 glassmorphism border-b border-border/50 shadow-sm z-50" data-testid="desktop-navigation">
        <div className="max-w-7xl mx-auto px-8 py-4">
          <div className="flex items-center justify-between">
            <Logo size="md" showText={true} />
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
                    data-testid={`desktop-nav-${item.page}`}
                  >
                    <Icon className="h-4 w-4" />
                    <span className="text-sm">{item.label}</span>
                  </button>
                );
              })}
              <LanguageSwitcher />
              <button
                onClick={onLogout}
                className="flex items-center gap-2 px-4 py-2 rounded-full transition-all font-medium bg-destructive text-destructive-foreground hover:bg-destructive/90 ml-2"
                data-testid="desktop-logout-button"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                  <polyline points="16 17 21 12 16 7"></polyline>
                  <line x1="21" y1="12" x2="9" y2="12"></line>
                </svg>
                <span className="text-sm">Logout</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Add padding for desktop navigation */}
      <div className="hidden md:block h-20"></div>
    </>
  );
}
