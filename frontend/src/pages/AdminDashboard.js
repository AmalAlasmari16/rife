import { useState, useEffect } from 'react';
import { api } from '../App';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { Building2, Users, Baby, DollarSign, TrendingUp, Check, X, Ban } from 'lucide-react';
import { format } from 'date-fns';

export default function AdminDashboard({ user, onLogout }) {
  const [nurseries, setNurseries] = useState([]);
  const [stats, setStats] = useState({});
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all'); // all, pending, active, suspended

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [nurseriesRes, statsRes] = await Promise.all([
        api.get('/admin/nurseries'),
        api.get('/admin/stats')
      ]);
      setNurseries(nurseriesRes.data);
      setStats(statsRes.data);
    } catch (error) {
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (nurseryId) => {
    try {
      await api.put(`/admin/nursery/${nurseryId}/approve`);
      toast.success('Nursery approved successfully');
      loadData();
    } catch (error) {
      toast.error('Failed to approve nursery');
    }
  };

  const handleSuspend = async (nurseryId) => {
    try {
      await api.put(`/admin/nursery/${nurseryId}/suspend`);
      toast.success('Nursery suspended');
      loadData();
    } catch (error) {
      toast.error('Failed to suspend nursery');
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      active: 'bg-green-100 text-green-800',
      suspended: 'bg-red-100 text-red-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const filteredNurseries = nurseries.filter(n => 
    filter === 'all' ? true : n.status === filter
  );

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-8" data-testid="admin-dashboard">
      <div className="max-w-7xl mx-auto p-4 md:p-8">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Platform Admin</h1>
            <p className="text-muted-foreground text-base">Manage nurseries and monitor platform performance</p>
          </div>
          <Button
            variant="destructive"
            onClick={onLogout}
            className="rounded-full"
            data-testid="admin-logout-button"
          >
            Logout
          </Button>
        </div>

        {/* Stats Overview */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Total Nurseries</CardTitle>
              <Building2 className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.total_nurseries || 0}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.active_nurseries || 0} active
              </p>
            </CardContent>
          </Card>

          <Card className="rounded-3xl border-border/50 shadow-sm card-hover">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Pending Approvals</CardTitle>
              <TrendingUp className="h-4 w-4 text-yellow-600" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-yellow-600">{stats.pending_nurseries || 0}</div>
            </CardContent>
          </Card>

          <Card className="rounded-3xl border-border/50 shadow-sm card-hover">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Total Users</CardTitle>
              <Users className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.total_users || 0}</div>
            </CardContent>
          </Card>

          <Card className="rounded-3xl border-border/50 shadow-sm card-hover">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Monthly Revenue</CardTitle>
              <DollarSign className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-green-600">${stats.monthly_revenue || 0}</div>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <div className="flex gap-2 mb-6">
          <Button
            variant={filter === 'all' ? 'default' : 'outline'}
            onClick={() => setFilter('all')}
            className="rounded-full"
          >
            All ({nurseries.length})
          </Button>
          <Button
            variant={filter === 'pending' ? 'default' : 'outline'}
            onClick={() => setFilter('pending')}
            className="rounded-full"
          >
            Pending ({nurseries.filter(n => n.status === 'pending').length})
          </Button>
          <Button
            variant={filter === 'active' ? 'default' : 'outline'}
            onClick={() => setFilter('active')}
            className="rounded-full"
          >
            Active ({nurseries.filter(n => n.status === 'active').length})
          </Button>
          <Button
            variant={filter === 'suspended' ? 'default' : 'outline'}
            onClick={() => setFilter('suspended')}
            className="rounded-full"
          >
            Suspended ({nurseries.filter(n => n.status === 'suspended').length})
          </Button>
        </div>

        {/* Nurseries List */}
        <div className="space-y-4">
          {filteredNurseries.map((nursery) => (
            <Card key={nursery.id} className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid={`nursery-${nursery.id}`}>
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="text-xl font-bold">{nursery.nursery_name}</h3>
                      <Badge className={`rounded-full ${getStatusColor(nursery.status)}`}>
                        {nursery.status}
                      </Badge>
                      <Badge variant="outline" className="rounded-full">
                        {nursery.subscription_status}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-muted-foreground">
                      <p><strong>Owner:</strong> {nursery.owner_name}</p>
                      <p><strong>Email:</strong> {nursery.owner_email}</p>
                      <p><strong>Phone:</strong> {nursery.phone || 'N/A'}</p>
                      <p><strong>Registered:</strong> {format(new Date(nursery.created_at), 'MMM dd, yyyy')}</p>
                      {nursery.subscription_status === 'trial' && (
                        <p><strong>Trial Ends:</strong> {format(new Date(nursery.trial_ends_at), 'MMM dd, yyyy')}</p>
                      )}
                    </div>
                    {nursery.address && (
                      <p className="text-sm text-muted-foreground mt-2">
                        <strong>Address:</strong> {nursery.address}
                      </p>
                    )}
                  </div>

                  <div className="flex gap-2">
                    {nursery.status === 'pending' && (
                      <Button
                        size="sm"
                        onClick={() => handleApprove(nursery.id)}
                        className="rounded-full"
                        data-testid={`approve-${nursery.id}`}
                      >
                        <Check className="h-4 w-4 mr-1" />
                        Approve
                      </Button>
                    )}
                    {nursery.status === 'active' && (
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={() => handleSuspend(nursery.id)}
                        className="rounded-full"
                        data-testid={`suspend-${nursery.id}`}
                      >
                        <Ban className="h-4 w-4 mr-1" />
                        Suspend
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}

          {filteredNurseries.length === 0 && (
            <Card className="rounded-3xl border-border/50 shadow-sm text-center p-12">
              <Building2 className="h-16 w-16 text-muted-foreground mx-auto mb-4 opacity-50" />
              <h3 className="text-xl font-bold mb-2">No Nurseries Found</h3>
              <p className="text-muted-foreground">
                {filter === 'all' ? 'No nurseries have registered yet' : `No ${filter} nurseries`}
              </p>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
