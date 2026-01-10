import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Textarea } from '../components/ui/textarea';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../components/ui/dialog';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { Calendar as CalendarIcon, Plus, Trash2, Clock } from 'lucide-react';
import { format } from 'date-fns';

export default function CalendarPage({ user, onLogout }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [eventForm, setEventForm] = useState({
    title: '',
    description: '',
    date: format(new Date(), 'yyyy-MM-dd'),
    time: ''
  });

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      const res = await api.get('/events');
      setEvents(res.data);
    } catch (error) {
      toast.error('Failed to load events');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateEvent = async (e) => {
    e.preventDefault();
    try {
      await api.post('/events', eventForm);
      toast.success('Event created successfully');
      setShowCreateDialog(false);
      setEventForm({ title: '', description: '', date: format(new Date(), 'yyyy-MM-dd'), time: '' });
      loadEvents();
    } catch (error) {
      toast.error('Failed to create event');
    }
  };

  const handleDeleteEvent = async (eventId) => {
    try {
      await api.delete(`/events/${eventId}`);
      toast.success('Event deleted');
      loadEvents();
    } catch (error) {
      toast.error('Failed to delete event');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="calendar-page">
      <div className="max-w-5xl mx-auto p-4 md:p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Calendar & Events</h1>
            <p className="text-muted-foreground text-base">Upcoming nursery events and announcements</p>
          </div>
          {user.role === 'worker' && (
            <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
              <DialogTrigger asChild>
                <Button className="rounded-full" data-testid="create-event-button">
                  <Plus className="h-4 w-4 mr-2" />
                  New Event
                </Button>
              </DialogTrigger>
              <DialogContent className="rounded-3xl">
                <DialogHeader>
                  <DialogTitle>Create Event</DialogTitle>
                  <DialogDescription>Add a new event or announcement</DialogDescription>
                </DialogHeader>
                <form onSubmit={handleCreateEvent} className="space-y-4">
                  <div className="space-y-2">
                    <Label>Title</Label>
                    <Input
                      value={eventForm.title}
                      onChange={(e) => setEventForm({ ...eventForm, title: e.target.value })}
                      className="rounded-xl"
                      placeholder="Event title"
                      required
                      data-testid="event-title-input"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Description</Label>
                    <Textarea
                      value={eventForm.description}
                      onChange={(e) => setEventForm({ ...eventForm, description: e.target.value })}
                      className="rounded-xl"
                      placeholder="Event details"
                      required
                      data-testid="event-description-input"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Date</Label>
                      <Input
                        type="date"
                        value={eventForm.date}
                        onChange={(e) => setEventForm({ ...eventForm, date: e.target.value })}
                        className="rounded-xl"
                        required
                        data-testid="event-date-input"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Time (Optional)</Label>
                      <Input
                        type="time"
                        value={eventForm.time}
                        onChange={(e) => setEventForm({ ...eventForm, time: e.target.value })}
                        className="rounded-xl"
                        data-testid="event-time-input"
                      />
                    </div>
                  </div>
                  <Button type="submit" className="w-full rounded-full" data-testid="submit-event-button">Create Event</Button>
                </form>
              </DialogContent>
            </Dialog>
          )}
        </div>

        <div className="space-y-4">
          {events.length > 0 ? events.map((event) => (
            <Card key={event.id} className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid={`event-item-${event.id}`}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="flex items-center gap-2 mb-2">
                      <CalendarIcon className="h-5 w-5 text-primary" />
                      {event.title}
                    </CardTitle>
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <CalendarIcon className="h-4 w-4" />
                        {format(new Date(event.date), 'EEEE, MMM dd, yyyy')}
                      </div>
                      {event.time && (
                        <div className="flex items-center gap-1">
                          <Clock className="h-4 w-4" />
                          {event.time}
                        </div>
                      )}
                    </div>
                  </div>
                  {user.role === 'worker' && (
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => handleDeleteEvent(event.id)}
                      className="rounded-full"
                      data-testid={`delete-event-${event.id}`}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground leading-relaxed">{event.description}</p>
              </CardContent>
            </Card>
          )) : (
            <Card className="rounded-3xl border-border/50 shadow-sm text-center p-12">
              <CalendarIcon className="h-16 w-16 text-muted-foreground mx-auto mb-4 opacity-50" />
              <h3 className="text-xl font-bold mb-2">No Events Scheduled</h3>
              <p className="text-muted-foreground">
                {user.role === 'worker' ? 'Create your first event to get started' : 'Check back later for upcoming events'}
              </p>
            </Card>
          )}
        </div>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="calendar" />
    </div>
  );
}
