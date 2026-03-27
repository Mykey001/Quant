import { useState, useCallback } from "react";
import { Link } from "wouter";
import { Card, CardContent, CardHeader, CardTitle, Button, Badge, Input, Label } from "@/components/ui";
import { useStrategiesHooks } from "@/hooks/use-strategies";
import { FileCode2, Upload, Trash2, Search, ArrowRight } from "lucide-react";
import { useDropzone } from "react-dropzone";
import { motion, AnimatePresence } from "framer-motion";
import { format } from "date-fns";

export default function StrategiesList() {
  const { strategiesQuery, uploadMutation, deleteMutation } = useStrategiesHooks();
  const [isUploading, setIsUploading] = useState(false);
  const [search, setSearch] = useState("");

  const strategies = strategiesQuery.data || [];
  const filteredStrategies = strategies.filter(s => 
    s.name.toLowerCase().includes(search.toLowerCase()) || 
    s.fileName.toLowerCase().includes(search.toLowerCase())
  );

  const onDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) {
      const file = acceptedFiles[0];
      const name = file.name.split('.')[0]; // Default name
      
      uploadMutation.mutate({
        data: {
          file,
          name,
          description: "Uploaded via dashboard"
        }
      }, {
        onSuccess: () => setIsUploading(false)
      });
    }
  }, [uploadMutation]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight glow-text">Strategy Repository</h1>
          <p className="text-muted-foreground mt-1 font-mono text-sm">Manage and analyze quantitative models</p>
        </div>
        <Button onClick={() => setIsUploading(!isUploading)} variant="primary">
          <Upload className="mr-2 h-4 w-4" />
          {isUploading ? "Cancel Upload" : "Upload File"}
        </Button>
      </div>

      <AnimatePresence>
        {isUploading && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden"
          >
            <Card className="border-primary/50 bg-primary/5 mb-6">
              <CardContent className="p-8">
                <div 
                  {...getRootProps()} 
                  className={`border-2 border-dashed rounded-lg p-10 text-center cursor-pointer transition-colors duration-200 ${
                    isDragActive ? "border-primary bg-primary/10" : "border-border hover:border-primary/50 hover:bg-surface"
                  }`}
                >
                  <input {...getInputProps()} />
                  <Upload className={`mx-auto h-12 w-12 mb-4 ${isDragActive ? "text-primary animate-bounce" : "text-muted-foreground"}`} />
                  <p className="text-lg font-medium">
                    {isDragActive ? "Drop file to initiate transfer..." : "Drag & drop strategy file here"}
                  </p>
                  <p className="text-sm text-muted-foreground mt-2 font-mono">
                    Supported formats: .mq5, .pine, .py, .mql4, .txt
                  </p>
                  {uploadMutation.isPending && (
                    <div className="mt-4 text-primary font-mono animate-pulse">Uploading and parsing...</div>
                  )}
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}
      </AnimatePresence>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Stored Models</CardTitle>
          <div className="relative w-64">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Search strategies..."
              className="pl-9 font-mono text-xs"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {strategiesQuery.isLoading ? (
            <div className="p-8 text-center text-muted-foreground font-mono">LOADING DATA...</div>
          ) : filteredStrategies.length === 0 ? (
            <div className="p-12 text-center text-muted-foreground font-mono flex flex-col items-center">
              <FileCode2 className="h-12 w-12 mb-4 opacity-20" />
              NO_STRATEGIES_FOUND
            </div>
          ) : (
            <div className="divide-y divide-border">
              {filteredStrategies.map((strategy) => (
                <div key={strategy.id} className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 hover:bg-surface/50 transition-colors group">
                  <div className="flex items-start gap-4">
                    <div className="mt-1 p-2 rounded-md bg-surface border border-border group-hover:border-primary/30 group-hover:text-primary transition-colors">
                      <FileCode2 className="h-5 w-5" />
                    </div>
                    <div>
                      <Link href={`/strategies/${strategy.id}`}>
                        <h4 className="text-base font-semibold text-foreground group-hover:text-primary transition-colors cursor-pointer inline-flex items-center gap-2">
                          {strategy.name}
                          <ArrowRight className="h-3 w-3 opacity-0 group-hover:opacity-100 transition-opacity -ml-2 group-hover:ml-0" />
                        </h4>
                      </Link>
                      <div className="flex items-center gap-3 mt-1 text-xs text-muted-foreground font-mono">
                        <span>{strategy.fileName}</span>
                        <span>•</span>
                        <span>{format(new Date(strategy.createdAt), 'yyyy-MM-dd HH:mm')}</span>
                      </div>
                    </div>
                  </div>
                  
                  <div className="mt-4 sm:mt-0 flex items-center gap-4 w-full sm:w-auto justify-between sm:justify-end">
                    <Badge variant="default" className="bg-panel border-border/50">{strategy.fileType}</Badge>
                    <div className="flex items-center gap-2">
                      <Link href={`/strategies/${strategy.id}`}>
                        <Button variant="outline" size="sm" className="font-mono text-xs">
                          INSPECT
                        </Button>
                      </Link>
                      <Button 
                        variant="ghost" 
                        size="icon"
                        className="text-muted-foreground hover:text-danger hover:bg-danger/10"
                        onClick={() => {
                          if (confirm("Delete this strategy permanently?")) {
                            deleteMutation.mutate({ id: strategy.id });
                          }
                        }}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
