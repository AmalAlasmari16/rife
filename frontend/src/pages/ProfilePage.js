import Navigation from '../components/Navigation';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { User, Mail, Phone, LogOut } from 'lucide-react';

export default function ProfilePage({ user, onLogout }) {
  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="profile-page">
      <div className="max-w-3xl mx-auto p-4 md:p-8">
        <div className="mb-8">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Profile Settings</h1>
          <p className="text-muted-foreground text-base">Manage your account information</p>
        </div>

        <Card className="rounded-3xl border-border/50 shadow-sm mb-6">
          <CardHeader>
            <CardTitle>Account Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Name</Label>
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  value={user.name}
                  className="pl-10 rounded-xl"
                  disabled
                  data-testid="profile-name"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Email</Label>
              <div className="relative">
                <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  value={user.email}
                  className="pl-10 rounded-xl"
                  disabled
                  data-testid="profile-email"
                />
              </div>
            </div>
            {user.phone && (
              <div className="space-y-2">
                <Label>Phone</Label>
                <div className="relative">
                  <Phone className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    value={user.phone}
                    className="pl-10 rounded-xl"
                    disabled
                    data-testid="profile-phone"
                  />
                </div>
              </div>
            )}
            <div className="space-y-2">
              <Label>Role</Label>
              <Input
                value={user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                className="rounded-xl"
                disabled
                data-testid="profile-role"
              />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-3xl border-border/50 shadow-sm">
          <CardHeader>
            <CardTitle>Account Actions</CardTitle>
          </CardHeader>
          <CardContent>
            <Button
              variant="destructive"
              onClick={onLogout}
              className="w-full rounded-full"
              data-testid="logout-button"
            >
              <LogOut className="h-4 w-4 mr-2" />
              Logout
            </Button>
          </CardContent>
        </Card>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="profile" />
    </div>
  );
}
