import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { ScrollArea } from '../components/ui/scroll-area';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { MessageCircle, Send, Users, Plus } from 'lucide-react';
import { format } from 'date-fns';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../components/ui/dialog';
import { Label } from '../components/ui/label';

export default function MessagesPage({ user, onLogout }) {
  const [groups, setGroups] = useState([]);
  const [selectedGroup, setSelectedGroup] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [showNewGroupDialog, setShowNewGroupDialog] = useState(false);
  const [newGroupName, setNewGroupName] = useState('');

  useEffect(() => {
    loadGroups();
  }, []);

  useEffect(() => {
    if (selectedGroup) {
      loadMessages(selectedGroup.id);
    }
  }, [selectedGroup]);

  const loadGroups = async () => {
    try {
      const res = await api.get('/message-groups');
      setGroups(res.data);
      if (res.data.length > 0 && !selectedGroup) {
        setSelectedGroup(res.data[0]);
      }
    } catch (error) {
      toast.error('Failed to load groups');
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (groupId) => {
    try {
      const res = await api.get(`/messages/${groupId}`);
      setMessages(res.data);
    } catch (error) {
      toast.error('Failed to load messages');
    }
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedGroup) return;

    try {
      await api.post('/messages', {
        group_id: selectedGroup.id,
        content: newMessage,
        attachments: []
      });
      setNewMessage('');
      loadMessages(selectedGroup.id);
    } catch (error) {
      toast.error('Failed to send message');
    }
  };

  const handleCreateGroup = async (e) => {
    e.preventDefault();
    try {
      await api.post('/message-groups', {
        name: newGroupName,
        member_ids: [user.id],
        type: 'group'
      });
      toast.success('Group created successfully');
      setShowNewGroupDialog(false);
      setNewGroupName('');
      loadGroups();
    } catch (error) {
      toast.error('Failed to create group');
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
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="messages-page">
      <div className="max-w-7xl mx-auto p-4 md:p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Messages</h1>
            <p className="text-muted-foreground text-base">Stay connected with parents and staff</p>
          </div>
          {user.role === 'worker' && (
            <Dialog open={showNewGroupDialog} onOpenChange={setShowNewGroupDialog}>
              <DialogTrigger asChild>
                <Button className="rounded-full" data-testid="new-group-button">
                  <Plus className="h-4 w-4 mr-2" />
                  New Group
                </Button>
              </DialogTrigger>
              <DialogContent className="rounded-3xl">
                <DialogHeader>
                  <DialogTitle>Create Message Group</DialogTitle>
                  <DialogDescription>Start a new conversation group</DialogDescription>
                </DialogHeader>
                <form onSubmit={handleCreateGroup} className="space-y-4">
                  <div className="space-y-2">
                    <Label>Group Name</Label>
                    <Input
                      value={newGroupName}
                      onChange={(e) => setNewGroupName(e.target.value)}
                      className="rounded-xl"
                      placeholder="e.g., Toddler Room Updates"
                      required
                      data-testid="group-name-input"
                    />
                  </div>
                  <Button type="submit" className="w-full rounded-full" data-testid="create-group-button">Create Group</Button>
                </form>
              </DialogContent>
            </Dialog>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Groups List */}
          <Card className="rounded-3xl border-border/50 shadow-sm" data-testid="groups-list">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5 text-primary" />
                Groups
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[500px]">
                <div className="space-y-2">
                  {groups.length > 0 ? groups.map((group) => (
                    <button
                      key={group.id}
                      onClick={() => setSelectedGroup(group)}
                      className={`w-full text-left p-4 rounded-2xl transition-all ${
                        selectedGroup?.id === group.id
                          ? 'bg-primary text-primary-foreground'
                          : 'bg-muted/30 hover:bg-muted/50'
                      }`}
                      data-testid={`group-item-${group.id}`}
                    >
                      <div className="flex items-center gap-2">
                        <MessageCircle className="h-4 w-4" />
                        <div className="flex-1 min-w-0">
                          <p className="font-medium truncate">{group.name}</p>
                          <p className={`text-xs truncate ${
                            selectedGroup?.id === group.id ? 'opacity-80' : 'text-muted-foreground'
                          }`}>
                            {group.member_ids.length} members
                          </p>
                        </div>
                      </div>
                    </button>
                  )) : (
                    <p className="text-sm text-muted-foreground text-center py-8">No message groups yet</p>
                  )}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>

          {/* Messages */}
          <Card className="rounded-3xl border-border/50 shadow-sm md:col-span-2" data-testid="messages-container">
            {selectedGroup ? (
              <>
                <CardHeader className="border-b">
                  <CardTitle className="flex items-center gap-2">
                    <MessageCircle className="h-5 w-5 text-primary" />
                    {selectedGroup.name}
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  <ScrollArea className="h-[400px] p-4" data-testid="messages-scroll">
                    <div className="space-y-4">
                      {messages.length > 0 ? messages.map((message) => (
                        <div
                          key={message.id}
                          className={`flex ${
                            message.sender_id === user.id ? 'justify-end' : 'justify-start'
                          }`}
                          data-testid={`message-${message.id}`}
                        >
                          <div
                            className={`max-w-[70%] p-3 rounded-2xl ${
                              message.sender_id === user.id
                                ? 'bg-primary text-primary-foreground'
                                : 'bg-muted'
                            }`}
                          >
                            {message.sender_id !== user.id && (
                              <p className="text-xs font-medium mb-1 opacity-70">{message.sender_name}</p>
                            )}
                            <p className="text-sm">{message.content}</p>
                            <p className="text-xs opacity-70 mt-1">
                              {format(new Date(message.timestamp), 'h:mm a')}
                            </p>
                          </div>
                        </div>
                      )) : (
                        <p className="text-sm text-muted-foreground text-center py-8">No messages yet. Start the conversation!</p>
                      )}
                    </div>
                  </ScrollArea>
                  <div className="p-4 border-t">
                    <form onSubmit={handleSendMessage} className="flex gap-2">
                      <Input
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        placeholder="Type your message..."
                        className="rounded-full"
                        data-testid="message-input"
                      />
                      <Button type="submit" size="icon" className="rounded-full" data-testid="send-message-button">
                        <Send className="h-4 w-4" />
                      </Button>
                    </form>
                  </div>
                </CardContent>
              </>
            ) : (
              <div className="flex items-center justify-center h-[500px] text-muted-foreground">
                <div className="text-center">
                  <MessageCircle className="h-16 w-16 mx-auto mb-4 opacity-50" />
                  <p>Select a group to start messaging</p>
                </div>
              </div>
            )}
          </Card>
        </div>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="messages" />
    </div>
  );
}
