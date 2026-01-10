import { useEffect, useState } from 'react';
import '@/App.css';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import axios from 'axios';
import LoginPage from './pages/LoginPage';
import ParentDashboard from './pages/ParentDashboard';
import WorkerDashboard from './pages/WorkerDashboard';
import MessagesPage from './pages/MessagesPage';
import CalendarPage from './pages/CalendarPage';
import FilesPage from './pages/FilesPage';
import EmergencyContactsPage from './pages/EmergencyContactsPage';
import PaymentsPage from './pages/PaymentsPage';
import ProfilePage from './pages/ProfilePage';
import { Toaster } from './components/ui/sonner';

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
export const API = `${BACKEND_URL}/api`;

export const api = axios.create({
  baseURL: API,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      api.get('/auth/me')
        .then(res => {
          setUser(res.data);
          setLoading(false);
        })
        .catch(() => {
          localStorage.removeItem('token');
          setLoading(false);
        });
    } else {
      setLoading(false);
    }
  }, []);

  const handleLogin = (userData, token) => {
    localStorage.setItem('token', token);
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="App">
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={
            !user ? <LoginPage onLogin={handleLogin} /> : 
            <Navigate to={user.role === 'parent' ? '/parent' : '/worker'} />
          } />
          
          <Route path="/parent" element={
            user && user.role === 'parent' ? 
            <ParentDashboard user={user} onLogout={handleLogout} /> : 
            <Navigate to="/login" />
          } />
          
          <Route path="/worker" element={
            user && user.role === 'worker' ? 
            <WorkerDashboard user={user} onLogout={handleLogout} /> : 
            <Navigate to="/login" />
          } />
          
          <Route path="/messages" element={
            user ? <MessagesPage user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          
          <Route path="/calendar" element={
            user ? <CalendarPage user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          
          <Route path="/files" element={
            user ? <FilesPage user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          
          <Route path="/emergency-contacts" element={
            user ? <EmergencyContactsPage user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          
          <Route path="/payments" element={
            user ? <PaymentsPage user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          
          <Route path="/profile" element={
            user ? <ProfilePage user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          
          <Route path="/" element={
            <Navigate to={user ? (user.role === 'parent' ? '/parent' : '/worker') : '/login'} />
          } />
        </Routes>
      </BrowserRouter>
      <Toaster position="top-center" />
    </div>
  );
}

export default App;
