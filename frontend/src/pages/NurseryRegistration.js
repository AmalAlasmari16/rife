import { useState } from 'react';
import { api } from '../App';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Textarea } from '../components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { toast } from 'sonner';
import { Building2, Mail, User, Phone, MapPin, Lock } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { LanguageSwitcher } from '../components/LanguageSwitcher';

export default function NurseryRegistration() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    nursery_name: '',
    owner_email: '',
    owner_name: '',
    owner_password: '',
    phone: '',
    address: ''
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const res = await api.post('/nursery/register', formData);
      toast.success('Registration submitted! Awaiting admin approval.');
      setTimeout(() => navigate('/login'), 2000);
    } catch (error) {
      toast.error(error.response?.data?.detail || 'Registration failed');
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
      
      <Card className="w-full max-w-2xl rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border-border/50" data-testid="nursery-registration-card">
        <CardHeader className="text-center">
          <CardTitle className="text-3xl md:text-4xl font-bold tracking-tight text-primary mb-2" style={{ fontFamily: 'Nunito, Cairo, Tajawal, sans-serif' }}>
            Register Your Nursery
          </CardTitle>
          <CardDescription className="text-base">
            Join رِفق and start managing your nursery digitally
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="nursery-name">Nursery Name *</Label>
              <div className="relative">
                <Building2 className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="nursery-name"
                  value={formData.nursery_name}
                  onChange={(e) => setFormData({ ...formData, nursery_name: e.target.value })}
                  className="pl-10 rounded-xl"
                  placeholder="Happy Kids Nursery"
                  required
                  data-testid="nursery-name-input"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="owner-name">Owner Name *</Label>
                <div className="relative">
                  <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="owner-name"
                    value={formData.owner_name}
                    onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                    className="pl-10 rounded-xl"
                    placeholder="John Doe"
                    required
                    data-testid="owner-name-input"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="owner-email">Email *</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="owner-email"
                    type="email"
                    value={formData.owner_email}
                    onChange={(e) => setFormData({ ...formData, owner_email: e.target.value })}
                    className="pl-10 rounded-xl"
                    placeholder="owner@nursery.com"
                    required
                    data-testid="owner-email-input"
                  />
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="password">Password *</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="password"
                    type="password"
                    value={formData.owner_password}
                    onChange={(e) => setFormData({ ...formData, owner_password: e.target.value })}
                    className="pl-10 rounded-xl"
                    placeholder="••••••••"
                    required
                    data-testid="password-input"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="phone">Phone</Label>
                <div className="relative">
                  <Phone className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="phone"
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="pl-10 rounded-xl"
                    placeholder="+1 234 567 8900"
                    data-testid="phone-input"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="address">Address</Label>
              <div className="relative">
                <MapPin className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Textarea
                  id="address"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="pl-10 rounded-xl"
                  placeholder="123 Main St, City, Country"
                  rows={3}
                  data-testid="address-input"
                />
              </div>
            </div>

            <div className="bg-muted/30 p-4 rounded-2xl">
              <h3 className="font-semibold mb-2">What happens next?</h3>
              <ol className="text-sm text-muted-foreground space-y-1 list-decimal list-inside">
                <li>Your registration will be reviewed by our admin team</li>
                <li>You'll receive an email once approved (usually within 24 hours)</li>
                <li>Start your 10-day free trial immediately after approval</li>
                <li>Subscription: $50/month after trial period</li>
              </ol>
            </div>

            <Button 
              type="submit" 
              className="w-full rounded-full font-bold tracking-wide transition-transform hover:scale-105 active:scale-95" 
              disabled={loading}
              data-testid="register-nursery-button"
            >
              {loading ? 'Submitting...' : 'Register Nursery'}
            </Button>

            <div className="text-center">
              <Button
                type="button"
                variant="link"
                onClick={() => navigate('/login')}
                data-testid="back-to-login-button"
              >
                Already registered? Login here
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
