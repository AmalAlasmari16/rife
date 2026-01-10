import { useState, useEffect } from 'react';
import { api } from '../App';
import Navigation from '../components/Navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../components/ui/dialog';
import { Label } from '../components/ui/label';
import { toast } from 'sonner';
import { FileText, Upload, Trash2, Download, FolderOpen } from 'lucide-react';
import { format } from 'date-fns';

export default function FilesPage({ user, onLogout }) {
  const [files, setFiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showUploadDialog, setShowUploadDialog] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);
  const [category, setCategory] = useState('general');

  useEffect(() => {
    loadFiles();
  }, []);

  const loadFiles = async () => {
    try {
      const res = await api.get('/files');
      setFiles(res.data);
    } catch (error) {
      toast.error('Failed to load files');
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (e) => {
    e.preventDefault();
    if (!selectedFile) return;

    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', selectedFile);
      formData.append('category', category);

      await api.post('/files/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      toast.success('File uploaded successfully');
      setShowUploadDialog(false);
      setSelectedFile(null);
      setCategory('general');
      loadFiles();
    } catch (error) {
      toast.error('Failed to upload file');
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteFile = async (fileId) => {
    try {
      await api.delete(`/files/${fileId}`);
      toast.success('File deleted');
      loadFiles();
    } catch (error) {
      toast.error('Failed to delete file');
    }
  };

  const getCategoryColor = (cat) => {
    const colors = {
      general: 'bg-muted',
      report: 'bg-primary/10 text-primary',
      medical: 'bg-destructive/10 text-destructive',
      policy: 'bg-secondary/50 text-secondary-foreground',
    };
    return colors[cat] || colors.general;
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0" data-testid="files-page">
      <div className="max-w-5xl mx-auto p-4 md:p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">File Library</h1>
            <p className="text-muted-foreground text-base">Documents, reports, and shared files</p>
          </div>
          <Dialog open={showUploadDialog} onOpenChange={setShowUploadDialog}>
            <DialogTrigger asChild>
              <Button className="rounded-full" data-testid="upload-file-button">
                <Upload className="h-4 w-4 mr-2" />
                Upload File
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl">
              <DialogHeader>
                <DialogTitle>Upload File</DialogTitle>
                <DialogDescription>Share documents with parents and staff</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleFileUpload} className="space-y-4">
                <div className="space-y-2">
                  <Label>File</Label>
                  <input
                    type="file"
                    onChange={(e) => setSelectedFile(e.target.files[0])}
                    className="flex h-10 w-full rounded-xl border border-input bg-white/50 px-3 py-2 text-sm"
                    required
                    data-testid="file-input"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Category</Label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="flex h-10 w-full rounded-xl border border-input bg-white/50 px-3 py-2 text-sm"
                    data-testid="category-select"
                  >
                    <option value="general">General</option>
                    <option value="report">Report</option>
                    <option value="medical">Medical</option>
                    <option value="policy">Policy</option>
                  </select>
                </div>
                <Button type="submit" disabled={uploading} className="w-full rounded-full" data-testid="submit-upload-button">
                  {uploading ? 'Uploading...' : 'Upload File'}
                </Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {files.length > 0 ? files.map((file) => (
            <Card key={file.id} className="rounded-3xl border-border/50 shadow-sm card-hover" data-testid={`file-item-${file.id}`}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-3 flex-1">
                    <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <FileText className="h-5 w-5 text-primary" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <CardTitle className="text-base truncate mb-1">{file.name}</CardTitle>
                      <div className="flex items-center gap-2 flex-wrap">
                        <Badge className={`rounded-full text-xs ${getCategoryColor(file.category)}`}>
                          {file.category}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          by {file.uploaded_by}
                        </span>
                      </div>
                    </div>
                  </div>
                  <Button
                    size="icon"
                    variant="ghost"
                    onClick={() => handleDeleteFile(file.id)}
                    className="rounded-full flex-shrink-0"
                    data-testid={`delete-file-${file.id}`}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-xs text-muted-foreground">
                  Uploaded {format(new Date(file.created_at), 'MMM dd, yyyy')}
                </p>
              </CardContent>
            </Card>
          )) : (
            <Card className="rounded-3xl border-border/50 shadow-sm text-center p-12 md:col-span-2">
              <FolderOpen className="h-16 w-16 text-muted-foreground mx-auto mb-4 opacity-50" />
              <h3 className="text-xl font-bold mb-2">No Files Uploaded</h3>
              <p className="text-muted-foreground">Upload your first document to get started</p>
            </Card>
          )}
        </div>
      </div>

      <Navigation user={user} onLogout={onLogout} activePage="files" />
    </div>
  );
}
