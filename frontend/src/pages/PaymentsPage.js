import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/ui/select';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { DollarSign, Plus, CreditCard, Clock } from 'lucide-react';
import { format } from 'date-fns';

export default function PaymentsPage({ user, onLogout }) {
  const [payments, setPayments] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [paymentForm, setPaymentForm] = useState({
    child_id: '',
    amount: '',
    due_date: format(new Date(), 'yyyy-MM-dd'),
    description: '',
    status: 'pending'
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [paymentsRes, childrenRes] = await Promise.all([
        api.get('/payments'),
        api.get('/children')
      ]);
      setPayments(paymentsRes.data);
      setChildren(childrenRes.data);
    } catch (error) {
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const handleCreatePayment = async (e) => {
    e.preventDefault();
    try {
      await api.post('/payments', {
        ...paymentForm,
        amount: parseFloat(paymentForm.amount)
      });
      toast.success('Payment record created');
      setShowCreateDialog(false);
      setPaymentForm({ child_id: '', amount: '', due_date: format(new Date(), 'yyyy-MM-dd'), description: '', status: 'pending' });
      loadData();
    } catch (error) {
      toast.error('Failed to create payment');
    }
  };

  const handleUpdateStatus = async (paymentId, newStatus) => {
    try {
      await api.put(`/payments/${paymentId}/status?status=${newStatus}`);
      toast.success('Payment status updated');
      loadData();
    } catch (error) {
      toast.error('Failed to update status');
    }
  };

  const getChildName = (childId) => {
    const child = children.find(c => c.id === childId);
    return child ? child.name : 'Unknown';
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      paid: 'bg-green-100 text-green-800',
      overdue: 'bg-red-100 text-red-800'
    };
    return colors[status] || colors.pending;
  };

  const totalAmount = payments.reduce((sum, p) => sum + p.amount, 0);
  const paidAmount = payments.filter(p => p.status === 'paid').reduce((sum, p) => sum + p.amount, 0);
  const pendingAmount = payments.filter(p => p.status === 'pending').reduce((sum, p) => sum + p.amount, 0);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="payments-page">
      <div className="max-w-6xl mx-auto p-4 md:p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">Payments & Billing</h1>
            <p className="text-muted-foreground text-base">Track nursery fees and payments</p>
          </div>
          {user.role === 'worker' && (
            <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
              <DialogTrigger asChild>
                <Button className="rounded-full" data-testid="create-payment-button">
                  <Plus className="h-4 w-4 mr-2" />
                  New Payment
                </Button>
              </DialogTrigger>
              <DialogContent className="rounded-3xl">
                <DialogHeader>
                  <DialogTitle>Create Payment Record</DialogTitle>
                  <DialogDescription>Add a new payment or invoice</DialogDescription>
                </DialogHeader>
                <form onSubmit={handleCreatePayment} className="space-y-4">
                  <div className="space-y-2">
                    <Label>Child</Label>
                    <Select value={paymentForm.child_id} onValueChange={(v) => setPaymentForm({ ...paymentForm, child_id: v })} required>
                      <SelectTrigger className="rounded-xl" data-testid="payment-child-select">
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
                    <Label>Amount</Label>
                    <Input
                      type="number"
                      step="0.01"
                      value={paymentForm.amount}
                      onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
                      className="rounded-xl"
                      placeholder="0.00"
                      required
                      data-testid="payment-amount-input"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Due Date</Label>
                    <Input
                      type="date"
                      value={paymentForm.due_date}
                      onChange={(e) => setPaymentForm({ ...paymentForm, due_date: e.target.value })}
                      className="rounded-xl"
                      required
                      data-testid="payment-date-input"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Description</Label>
                    <Input
                      value={paymentForm.description}
                      onChange={(e) => setPaymentForm({ ...paymentForm, description: e.target.value })}
                      className="rounded-xl"
                      placeholder="Monthly fee, Registration, etc."
                      required
                      data-testid="payment-description-input"
                    />
                  </div>
                  <Button type="submit" className="w-full rounded-full" data-testid="submit-payment-button">Create Payment</Button>
                </form>
              </DialogContent>
            </Dialog>
          )}
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="total-amount-card">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Total Amount</CardTitle>
              <DollarSign className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">${totalAmount.toFixed(2)}</div>
            </CardContent>
          </Card>
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="paid-amount-card">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Paid</CardTitle>
              <CreditCard className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-green-600">${paidAmount.toFixed(2)}</div>
            </CardContent>
          </Card>
          <Card className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid="pending-amount-card">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Pending</CardTitle>
              <Clock className="h-4 w-4 text-yellow-600" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-yellow-600">${pendingAmount.toFixed(2)}</div>
            </CardContent>
          </Card>
        </div>

        {/* Payments List */}
        <div className="space-y-4">
          {payments.length > 0 ? payments.map((payment) => (
            <Card key={payment.id} className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid={`payment-item-${payment.id}`}>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="text-lg font-bold">{getChildName(payment.child_id)}</h3>
                      <Badge className={`rounded-full ${getStatusColor(payment.status)}`}>
                        {payment.status}
                      </Badge>
                    </div>
                    <p className="text-muted-foreground mb-1">{payment.description}</p>
                    <p className="text-sm text-muted-foreground">
                      Due: {format(new Date(payment.due_date), 'MMM dd, yyyy')}
                    </p>
                  </div>
                  <div className="text-right">
                    <div className="text-3xl font-bold text-primary mb-2">
                      ${payment.amount.toFixed(2)}
                    </div>
                    {payment.status !== 'paid' && (
                      <Button
                        size="sm"
                        onClick={() => handleUpdateStatus(payment.id, 'paid')}
                        className="rounded-full"
                        data-testid={`mark-paid-${payment.id}`}
                      >
                        Mark as Paid
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          )) : (
            <Card className="rounded-3xl border-border/50 shadow-sm text-center p-12">
              <DollarSign className="h-16 w-16 text-muted-foreground mx-auto mb-4 opacity-50" />
              <h3 className="text-xl font-bold mb-2">No Payments Yet</h3>
              <p className="text-muted-foreground">
                {user.role === 'worker' ? 'Create your first payment record' : 'No payments due at this time'}
              </p>
            </Card>
          )}
        </div>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="payments" />
    </div>
  );
}
