import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { Baby, Activity, Clock, Utensils, Camera, Calendar, TrendingUp } from 'lucide-react';
import { format } from 'date-fns';

export default function ParentDashboard({ user, onLogout }) {
  const [children, setChildren] = useState([]);
  const [selectedChild, setSelectedChild] = useState(null);
  const [activities, setActivities] = useState([]);
  const [attendance, setAttendance] = useState([]);
  const [meals, setMeals] = useState([]);
  const [stats, setStats] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    if (selectedChild) {
      loadChildData(selectedChild.id);
    }
  }, [selectedChild]);

  const loadData = async () => {
    try {
      const [childrenRes, statsRes] = await Promise.all([
        api.get('/children'),
        api.get('/stats')
      ]);
      setChildren(childrenRes.data);
      if (childrenRes.data.length > 0) {
        setSelectedChild(childrenRes.data[0]);
      }
      setStats(statsRes.data);
    } catch (error) {
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const loadChildData = async (childId) => {
    try {
      const [activitiesRes, attendanceRes, mealsRes] = await Promise.all([
        api.get(`/activities/${childId}`),
        api.get(`/attendance/${childId}`),
        api.get(`/meals/${childId}`)
      ]);
      setActivities(activitiesRes.data.slice(0, 5));
      setAttendance(attendanceRes.data.slice(0, 5));
      setMeals(mealsRes.data.slice(0, 5));
    } catch (error) {
      toast.error('Failed to load child data');
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
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="parent-dashboard">
      <div className="max-w-7xl mx-auto p-4 md:p-8">
        {/* Header */}
        <div className="mb-8 animate-fade-in">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Welcome, {user.name}</h1>
          <p className="text-muted-foreground text-base">Here's what's happening with your children today</p>
        </div>

        {/* Stats Overview */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="stats-children">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Children</CardTitle>
              <Baby className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.children_count || 0}</div>
            </CardContent>
          </Card>
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="stats-activities">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Activities</CardTitle>
              <Activity className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.activities_count || 0}</div>
            </CardContent>
          </Card>
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="stats-messages">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Messages</CardTitle>
              <TrendingUp className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stats.messages_count || 0}</div>
            </CardContent>
          </Card>
        </div>

        {/* Child Selector */}
        {children.length > 0 && (
          <div className="mb-6 flex gap-2 overflow-x-auto scrollbar-hide pb-2">
            {children.map((child) => (
              <Button
                key={child.id}
                onClick={() => setSelectedChild(child)}
                variant={selectedChild?.id === child.id ? 'default' : 'outline'}
                className="rounded-full whitespace-nowrap"
                data-testid={`child-selector-${child.name}`}
              >
                {child.name}
              </Button>
            ))}
          </div>
        )}

        {selectedChild ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Recent Activities */}
            <Card className="rounded-3xl border-border/50 shadow-sm" data-testid="activities-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Activity className="h-5 w-5 text-primary" />
                  Recent Activities
                </CardTitle>
                <CardDescription>Latest updates for {selectedChild.name}</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {activities.length > 0 ? activities.map((activity) => (
                  <div key={activity.id} className="flex items-start gap-3 p-3 rounded-2xl bg-muted/30 hover:bg-muted/50 transition-colors" data-testid={`activity-item-${activity.id}`}>
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

            {/* Attendance */}
            <Card className="rounded-3xl border-border/50 shadow-sm" data-testid="attendance-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Clock className="h-5 w-5 text-primary" />
                  Attendance
                </CardTitle>
                <CardDescription>Check-in and check-out times</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {attendance.length > 0 ? attendance.map((record) => (
                  <div key={record.id} className="flex items-center justify-between p-3 rounded-2xl bg-muted/30" data-testid={`attendance-item-${record.id}`}>
                    <div>
                      <p className="font-medium">{format(new Date(record.date), 'MMM dd, yyyy')}</p>
                      <p className="text-sm text-muted-foreground">In: {record.check_in}</p>
                    </div>
                    <div className="text-right">
                      {record.check_out ? (
                        <Badge variant="secondary" className="rounded-full">Out: {record.check_out}</Badge>
                      ) : (
                        <Badge className="rounded-full bg-primary">Present</Badge>
                      )}
                    </div>
                  </div>
                )) : (
                  <p className="text-sm text-muted-foreground text-center py-4">No attendance records</p>
                )}
              </CardContent>
            </Card>

            {/* Meals */}
            <Card className="rounded-3xl border-border/50 shadow-sm md:col-span-2" data-testid="meals-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Utensils className="h-5 w-5 text-primary" />
                  Meal Schedule
                </CardTitle>
                <CardDescription>Daily meals and snacks</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {meals.length > 0 ? meals.map((meal) => (
                  <div key={meal.id} className="p-4 rounded-2xl bg-muted/30" data-testid={`meal-item-${meal.id}`}>
                    <div className="flex items-center justify-between mb-2">
                      <p className="font-medium">{format(new Date(meal.date), 'EEEE, MMM dd')}</p>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                      {meal.breakfast && (
                        <div className="p-2 rounded-xl bg-background">
                          <p className="text-xs text-muted-foreground mb-1">Breakfast</p>
                          <p className="text-sm">{meal.breakfast}</p>
                        </div>
                      )}
                      {meal.lunch && (
                        <div className="p-2 rounded-xl bg-background">
                          <p className="text-xs text-muted-foreground mb-1">Lunch</p>
                          <p className="text-sm">{meal.lunch}</p>
                        </div>
                      )}
                      {meal.snack && (
                        <div className="p-2 rounded-xl bg-background">
                          <p className="text-xs text-muted-foreground mb-1">Snack</p>
                          <p className="text-sm">{meal.snack}</p>
                        </div>
                      )}
                    </div>
                  </div>
                )) : (
                  <p className="text-sm text-muted-foreground text-center py-4">No meal records</p>
                )}
              </CardContent>
            </Card>
          </div>
        ) : (
          <Card className="rounded-3xl border-border/50 shadow-sm text-center p-12">
            <Baby className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-xl font-bold mb-2">No Children Added</h3>
            <p className="text-muted-foreground mb-4">Contact your nursery to add your children</p>
          </Card>
        )}
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="dashboard" />
    </div>
  );
}
