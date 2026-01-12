import { useState } from 'react';
import { api } from '../App';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { toast } from 'sonner';
import { User, Lock, Mail, Phone, Users } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import Logo from '../components/Logo';
import { LanguageSwitcher } from '../components/LanguageSwitcher';

export default function LoginPage({ onLogin }) {
  const { t } = useTranslation();
  const [isLogin, setIsLogin] = useState(true);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: '',
    phone: '',
    role: 'parent'
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (isLogin) {
        const res = await api.post('/auth/login', {
          email: formData.email,
          password: formData.password
        });
        onLogin(res.data.user, res.data.token);
        toast.success('Welcome back!');
      } else {
        const res = await api.post('/auth/register', formData);
        onLogin(res.data.user, res.data.token);
        toast.success('Account created successfully!');
      }
    } catch (error) {
      toast.error(error.response?.data?.detail || 'Something went wrong');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-secondary/30 via-background to-accent/20">
      {/* Language Switcher - Top Right */}
      <div className="fixed top-4 right-4 z-50">
        <LanguageSwitcher />
      </div>
      
      <Card className="w-full max-w-md rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border-border/50" data-testid="login-card">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <Logo size="xl" showText={false} />
          </div>
          <CardTitle className="text-3xl md:text-4xl font-bold tracking-tight text-primary" style={{ fontFamily: 'Nunito, Cairo, Tajawal, sans-serif' }}>
            {t('nurseryConnect')}
          </CardTitle>
          <CardDescription className="text-base">
            {t('connectWithNursery')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={isLogin ? 'login' : 'register'} onValueChange={(v) => setIsLogin(v === 'login')} className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-6 rounded-full">
              <TabsTrigger value="login" className="rounded-full" data-testid="login-tab">{t('login')}</TabsTrigger>
              <TabsTrigger value="register" className="rounded-full" data-testid="register-tab">{t('register')}</TabsTrigger>
            </TabsList>
            
            <TabsContent value="login">
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="login-email">{t('email')}</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="login-email"
                      type="email"
                      placeholder="parent@example.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="pl-10 rounded-xl"
                      required
                      data-testid="login-email-input"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="login-password">{t('password')}</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="login-password"
                      type="password"
                      placeholder="••••••••"
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      className="pl-10 rounded-xl"
                      required
                      data-testid="login-password-input"
                    />
                  </div>
                </div>
                <Button 
                  type="submit" 
                  className="w-full rounded-full font-bold tracking-wide transition-transform hover:scale-105 active:scale-95" 
                  disabled={loading}
                  data-testid="login-submit-button"
                >
                  {loading ? t('signingIn') : t('signIn')}
                </Button>
              </form>
            </TabsContent>
            
            <TabsContent value="register">
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="register-name">{t('fullName')}</Label>
                  <div className="relative">
                    <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="register-name"
                      type="text"
                      placeholder="John Doe"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="pl-10 rounded-xl"
                      required
                      data-testid="register-name-input"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="register-email">{t('email')}</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="register-email"
                      type="email"
                      placeholder="parent@example.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="pl-10 rounded-xl"
                      required
                      data-testid="register-email-input"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="register-phone">{t('phone')}</Label>
                  <div className="relative">
                    <Phone className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="register-phone"
                      type="tel"
                      placeholder="+1 234 567 8900"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="pl-10 rounded-xl"
                      data-testid="register-phone-input"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="register-password">{t('password')}</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="register-password"
                      type="password"
                      placeholder="••••••••"
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      className="pl-10 rounded-xl"
                      required
                      data-testid="register-password-input"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="register-role">{t('role')}</Label>
                  <div className="relative">
                    <Users className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <select
                      id="register-role"
                      value={formData.role}
                      onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                      className="flex h-10 w-full rounded-xl border border-input bg-white/50 px-3 py-2 pl-10 text-sm ring-offset-background focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                      data-testid="register-role-select"
                    >
                      <option value="parent">{t('parent')}</option>
                      <option value="worker">{t('nurseryWorker')}</option>
                    </select>
                  </div>
                </div>
                <Button 
                  type="submit" 
                  className="w-full rounded-full font-bold tracking-wide transition-transform hover:scale-105 active:scale-95" 
                  disabled={loading}
                  data-testid="register-submit-button"
                >
                  {loading ? t('creatingAccount') : t('createAccount')}
                </Button>
              </form>
            </TabsContent>
            <div className="text-center">
              <Button
                type="button"
                variant="link"
                onClick={() => window.location.href = '/register-nursery'}
                className="text-sm"
                data-testid="register-nursery-link"
              >
                Register your nursery
              </Button>
            </div>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}
