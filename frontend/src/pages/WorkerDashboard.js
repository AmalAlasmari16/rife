import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Textarea } from '../components/ui/textarea';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/ui/select';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { Users, Baby, Activity, Calendar, TrendingUp, Plus, Clock } from 'lucide-react';
import { format } from 'date-fns';

export default function WorkerDashboard({ user, onLogout }) {
  const [children, setChildren] = useState([]);
  const [stats, setStats] = useState({});
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showActivityDialog, setShowActivityDialog] = useState(false);
  const [showAttendanceDialog, setShowAttendanceDialog] = useState(false);
  const [showMealDialog, setShowMealDialog] = useState(false);
  const [activityForm, setActivityForm] = useState({
    child_id: '',
    type: 'play',
    description: ''
  });
  const [attendanceForm, setAttendanceForm] = useState({
    child_id: '',
    date: format(new Date(), 'yyyy-MM-dd'),
    check_in: '',
    notes: ''
  });
  const [mealForm, setMealForm] = useState({
    child_id: '',
    date: format(new Date(), 'yyyy-MM-dd'),
    breakfast: '',
    lunch: '',
    snack: '',
    notes: ''
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [childrenRes, statsRes, activitiesRes] = await Promise.all([
        api.get('/children'),
        api.get('/stats'),
        api.get('/activities/all').catch(() => ({ data: [] }))
      ]);
      setChildren(childrenRes.data);
      setStats(statsRes.data);
      // Load recent activities across all children
      const allActivities = [];
      for (const child of childrenRes.data.slice(0, 5)) {
        const acts = await api.get(`/activities/${child.id}`);
        allActivities.push(...acts.data.slice(0, 2));
      }
      setActivities(allActivities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)).slice(0, 10));
    } catch (error) {
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateActivity = async (e) => {
    e.preventDefault();
    try {
      await api.post('/activities', activityForm);
      toast.success('Activity logged successfully');
      setShowActivityDialog(false);
      setActivityForm({ child_id: '', type: 'play', description: '' });
      loadData();
    } catch (error) {
      toast.error('Failed to log activity');
    }
  };

  const handleCreateAttendance = async (e) => {
    e.preventDefault();
    try {
      await api.post('/attendance', attendanceForm);
      toast.success('Attendance logged successfully');
      setShowAttendanceDialog(false);
      setAttendanceForm({ child_id: '', date: format(new Date(), 'yyyy-MM-dd'), check_in: '', notes: '' });
    } catch (error) {
      toast.error('Failed to log attendance');
    }
  };

  const handleCreateMeal = async (e) => {
    e.preventDefault();
    try {
      await api.post('/meals', mealForm);
      toast.success('Meal logged successfully');
      setShowMealDialog(false);
      setMealForm({ child_id: '', date: format(new Date(), 'yyyy-MM-dd'), breakfast: '', lunch: '', snack: '', notes: '' });
    } catch (error) {
      toast.error('Failed to log meal');
    }
  };

  const getActivityIcon = (type) => {
    const icons = {
      play: '🎮',
      learning: '📚',
      nap: '😴',
      outdoor: '🌳',
      art: '🎨'
    };
    return icons[type] || '📝';
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="worker-dashboard">
      <div className="max-w-7xl mx-auto p-4 md:p-8">
        {/* Header */}
        <div className="mb-8 animate-fade-in">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Worker Dashboard</h1>
          <p className="text-muted-foreground text-base">Manage children and daily activities</p>
        </div>

        {/* Stats Overview */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="stats-children">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Total Children</CardTitle>
              <Baby className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.children_count || 0}</div>
            </CardContent>
          </Card>
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="stats-activities">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Activities Logged</CardTitle>
              <Activity className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.activities_count || 0}</div>
            </CardContent>
          </Card>
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="stats-events">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Upcoming Events</CardTitle>
              <Calendar className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.events_count || 0}</div>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <Dialog open={showActivityDialog} onOpenChange={setShowActivityDialog}>
            <DialogTrigger asChild>
              <Button className="rounded-full h-auto py-6 flex flex-col gap-2" data-testid="add-activity-button">
                <Activity className="h-6 w-6" />
                <span>Log Activity</span>
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl">
              <DialogHeader>
                <DialogTitle>Log Child Activity</DialogTitle>
                <DialogDescription>Record a new activity for a child</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleCreateActivity} className="space-y-4">
                <div className="space-y-2">
                  <Label>Child</Label>
                  <Select value={activityForm.child_id} onValueChange={(v) => setActivityForm({ ...activityForm, child_id: v })} required>
                    <SelectTrigger className="rounded-xl" data-testid="activity-child-select">
                      <SelectValue placeholder="Select a child" />
                    </SelectTrigger>
                    <SelectContent>
                      {children.map((child) => (
                        <SelectItem key={child.id} value={child.id}>{child.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Activity Type</Label>
                  <Select value={activityForm.type} onValueChange={(v) => setActivityForm({ ...activityForm, type: v })}>
                    <SelectTrigger className="rounded-xl" data-testid="activity-type-select">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="play">Play</SelectItem>
                      <SelectItem value="learning">Learning</SelectItem>
                      <SelectItem value="nap">Nap</SelectItem>
                      <SelectItem value="outdoor">Outdoor</SelectItem>
                      <SelectItem value="art">Art</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Description</Label>
                  <Textarea
                    value={activityForm.description}
                    onChange={(e) => setActivityForm({ ...activityForm, description: e.target.value })}
                    className="rounded-xl"
                    placeholder="What did they do?"
                    required
                    data-testid="activity-description-input"
                  />
                </div>
                <Button type="submit" className="w-full rounded-full" data-testid="activity-submit-button">Log Activity</Button>
              </form>
            </DialogContent>
          </Dialog>

          <Dialog open={showAttendanceDialog} onOpenChange={setShowAttendanceDialog}>
            <DialogTrigger asChild>
              <Button className="rounded-full h-auto py-6 flex flex-col gap-2" variant="outline" data-testid="add-attendance-button">
                <Clock className="h-6 w-6" />
                <span>Log Attendance</span>
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl">
              <DialogHeader>
                <DialogTitle>Log Attendance</DialogTitle>
                <DialogDescription>Record check-in time for a child</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleCreateAttendance} className="space-y-4">
                <div className="space-y-2">
                  <Label>Child</Label>
                  <Select value={attendanceForm.child_id} onValueChange={(v) => setAttendanceForm({ ...attendanceForm, child_id: v })} required>
                    <SelectTrigger className="rounded-xl" data-testid="attendance-child-select">
                      <SelectValue placeholder="Select a child" />
                    </SelectTrigger>
                    <SelectContent>
                      {children.map((child) => (
                        <SelectItem key={child.id} value={child.id}>{child.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Date</Label>
                  <Input
                    type="date"
                    value={attendanceForm.date}
                    onChange={(e) => setAttendanceForm({ ...attendanceForm, date: e.target.value })}
                    className="rounded-xl"
                    required
                    data-testid="attendance-date-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Check-in Time</Label>
                  <Input
                    type="time"
                    value={attendanceForm.check_in}
                    onChange={(e) => setAttendanceForm({ ...attendanceForm, check_in: e.target.value })}
                    className="rounded-xl"
                    required
                    data-testid="attendance-checkin-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Notes (Optional)</Label>
                  <Textarea
                    value={attendanceForm.notes}
                    onChange={(e) => setAttendanceForm({ ...attendanceForm, notes: e.target.value })}
                    className="rounded-xl"
                    placeholder="Any notes?"
                    data-testid="attendance-notes-input"
                  />
                </div>
                <Button type="submit" className="w-full rounded-full" data-testid="attendance-submit-button">Log Attendance</Button>
              </form>
            </DialogContent>
          </Dialog>

          <Dialog open={showMealDialog} onOpenChange={setShowMealDialog}>
            <DialogTrigger asChild>
              <Button className="rounded-full h-auto py-6 flex flex-col gap-2" variant="outline" data-testid="add-meal-button">
                <TrendingUp className="h-6 w-6" />
                <span>Log Meal</span>
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl">
              <DialogHeader>
                <DialogTitle>Log Meal</DialogTitle>
                <DialogDescription>Record meals for a child</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleCreateMeal} className="space-y-4">
                <div className="space-y-2">
                  <Label>Child</Label>
                  <Select value={mealForm.child_id} onValueChange={(v) => setMealForm({ ...mealForm, child_id: v })} required>
                    <SelectTrigger className="rounded-xl" data-testid="meal-child-select">
                      <SelectValue placeholder="Select a child" />
                    </SelectTrigger>
                    <SelectContent>
                      {children.map((child) => (
                        <SelectItem key={child.id} value={child.id}>{child.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Date</Label>
                  <Input
                    type="date"
                    value={mealForm.date}
                    onChange={(e) => setMealForm({ ...mealForm, date: e.target.value })}
                    className="rounded-xl"
                    required
                    data-testid="meal-date-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Breakfast</Label>
                  <Input
                    value={mealForm.breakfast}
                    onChange={(e) => setMealForm({ ...mealForm, breakfast: e.target.value })}
                    className="rounded-xl"
                    placeholder="What did they have?"
                    data-testid="meal-breakfast-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Lunch</Label>
                  <Input
                    value={mealForm.lunch}
                    onChange={(e) => setMealForm({ ...mealForm, lunch: e.target.value })}
                    className="rounded-xl"
                    placeholder="What did they have?"
                    data-testid="meal-lunch-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Snack</Label>
                  <Input
                    value={mealForm.snack}
                    onChange={(e) => setMealForm({ ...mealForm, snack: e.target.value })}
                    className="rounded-xl"
                    placeholder="What did they have?"
                    data-testid="meal-snack-input"
                  />
                </div>
                <Button type="submit" className="w-full rounded-full" data-testid="meal-submit-button">Log Meal</Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        {/* Children List & Recent Activities */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="rounded-3xl border-border/50 shadow-sm" data-testid="children-list-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5 text-primary" />
                Children ({children.length})
              </CardTitle>
              <CardDescription>All registered children</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {children.length > 0 ? children.map((child) => (
                <div key={child.id} className="flex items-center gap-3 p-3 rounded-2xl bg-muted/30 hover:bg-muted/50 transition-colors" data-testid={`child-item-${child.id}`}>
                  <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Baby className="h-5 w-5 text-primary" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium">{child.name}</p>
                    <p className="text-xs text-muted-foreground">DOB: {format(new Date(child.dob), 'MMM dd, yyyy')}</p>
                  </div>
                </div>
              )) : (
                <p className="text-sm text-muted-foreground text-center py-4">No children registered yet</p>
              )}
            </CardContent>
          </Card>

          <Card className="rounded-3xl border-border/50 shadow-sm" data-testid="recent-activities-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-5 w-5 text-primary" />
                Recent Activities
              </CardTitle>
              <CardDescription>Latest logged activities</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {activities.length > 0 ? activities.map((activity) => (
                <div key={activity.id} className="flex items-start gap-3 p-3 rounded-2xl bg-muted/30" data-testid={`activity-item-${activity.id}`}>
                  <div className="text-2xl">{getActivityIcon(activity.type)}</div>
                  <div className="flex-1">
                    <p className="font-medium capitalize">{activity.type}</p>
                    <p className="text-sm text-muted-foreground">{activity.description}</p>
                    <p className="text-xs text-muted-foreground mt-1">
                      {format(new Date(activity.timestamp), 'MMM dd, h:mm a')}
                    </p>
                  </div>
                </div>
              )) : (
                <p className="text-sm text-muted-foreground text-center py-4">No activities yet</p>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="dashboard" />
    </div>
  );
}
