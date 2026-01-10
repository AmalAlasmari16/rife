import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/ui/select';
import { toast } from 'sonner';
import { Phone, Plus, Trash2, Mail, User } from 'lucide-react';

export default function EmergencyContactsPage({ user, onLogout }) {
  const [children, setChildren] = useState([]);
  const [contacts, setContacts] = useState({});
  const [loading, setLoading] = useState(true);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [contactForm, setContactForm] = useState({
    child_id: '',
    name: '',
    relationship: '',
    phone: '',
    email: ''
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const childrenRes = await api.get('/children');
      setChildren(childrenRes.data);

      // Load contacts for each child
      const contactsData = {};
      for (const child of childrenRes.data) {
        const contactsRes = await api.get(`/emergency-contacts/${child.id}`);
        contactsData[child.id] = contactsRes.data;
      }
      setContacts(contactsData);
    } catch (error) {
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const handleAddContact = async (e) => {
    e.preventDefault();
    try {
      await api.post('/emergency-contacts', contactForm);
      toast.success('Contact added successfully');
      setShowAddDialog(false);
      setContactForm({ child_id: '', name: '', relationship: '', phone: '', email: '' });
      loadData();
    } catch (error) {
      toast.error('Failed to add contact');
    }
  };

  const handleDeleteContact = async (contactId, childId) => {
    try {
      await api.delete(`/emergency-contacts/${contactId}`);
      toast.success('Contact deleted');
      loadData();
    } catch (error) {
      toast.error('Failed to delete contact');
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
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="emergency-contacts-page">
      <div className="max-w-5xl mx-auto p-4 md:p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Emergency Contacts</h1>
            <p className="text-muted-foreground text-base">Important contact information</p>
          </div>
          <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
            <DialogTrigger asChild>
              <Button className="rounded-full" data-testid="add-contact-button">
                <Plus className="h-4 w-4 mr-2" />
                Add Contact
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl">
              <DialogHeader>
                <DialogTitle>Add Emergency Contact</DialogTitle>
                <DialogDescription>Add a new emergency contact for a child</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleAddContact} className="space-y-4">
                <div className="space-y-2">
                  <Label>Child</Label>
                  <Select value={contactForm.child_id} onValueChange={(v) => setContactForm({ ...contactForm, child_id: v })} required>
                    <SelectTrigger className="rounded-xl" data-testid="contact-child-select">
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
                  <Label>Name</Label>
                  <Input
                    value={contactForm.name}
                    onChange={(e) => setContactForm({ ...contactForm, name: e.target.value })}
                    className="rounded-xl"
                    placeholder="Contact name"
                    required
                    data-testid="contact-name-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Relationship</Label>
                  <Input
                    value={contactForm.relationship}
                    onChange={(e) => setContactForm({ ...contactForm, relationship: e.target.value })}
                    className="rounded-xl"
                    placeholder="e.g., Grandmother, Uncle"
                    required
                    data-testid="contact-relationship-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Phone</Label>
                  <Input
                    value={contactForm.phone}
                    onChange={(e) => setContactForm({ ...contactForm, phone: e.target.value })}
                    className="rounded-xl"
                    placeholder="+1 234 567 8900"
                    required
                    data-testid="contact-phone-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Email (Optional)</Label>
                  <Input
                    type="email"
                    value={contactForm.email}
                    onChange={(e) => setContactForm({ ...contactForm, email: e.target.value })}
                    className="rounded-xl"
                    placeholder="contact@example.com"
                    data-testid="contact-email-input"
                  />
                </div>
                <Button type="submit" className="w-full rounded-full" data-testid="submit-contact-button">Add Contact</Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <div className="space-y-6">
          {children.length > 0 ? children.map((child) => (
            <Card key={child.id} className="rounded-3xl border-border/50 shadow-sm" data-testid={`child-contacts-${child.id}`}>
              <CardHeader>
                <CardTitle className="text-2xl">{child.name}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {contacts[child.id] && contacts[child.id].length > 0 ? (
                    contacts[child.id].map((contact) => (
                      <div
                        key={contact.id}
                        className="p-4 rounded-2xl bg-muted/30 hover:bg-muted/50 transition-colors"
                        data-testid={`contact-item-${contact.id}`}
                      >
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex items-center gap-2">
                            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                              <User className="h-5 w-5 text-primary" />
                            </div>
                            <div>
                              <p className="font-medium">{contact.name}</p>
                              <p className="text-xs text-muted-foreground">{contact.relationship}</p>
                            </div>
                          </div>
                          <Button
                            size="icon"
                            variant="ghost"
                            onClick={() => handleDeleteContact(contact.id, child.id)}
                            className="rounded-full"
                            data-testid={`delete-contact-${contact.id}`}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                        <div className="space-y-2">
                          <div className="flex items-center gap-2 text-sm">
                            <Phone className="h-4 w-4 text-muted-foreground" />
                            <span>{contact.phone}</span>
                          </div>
                          {contact.email && (
                            <div className="flex items-center gap-2 text-sm">
                              <Mail className="h-4 w-4 text-muted-foreground" />
                              <span>{contact.email}</span>
                            </div>
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-muted-foreground col-span-2 text-center py-4">
                      No emergency contacts added yet
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          )) : (
            <Card className="rounded-3xl border-border/50 shadow-sm text-center p-12">
              <Phone className="h-16 w-16 text-muted-foreground mx-auto mb-4 opacity-50" />
              <h3 className="text-xl font-bold mb-2">No Children Found</h3>
              <p className="text-muted-foreground">Add children first to manage emergency contacts</p>
            </Card>
          )}
        </div>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="emergency" />
    </div>
  );
}
