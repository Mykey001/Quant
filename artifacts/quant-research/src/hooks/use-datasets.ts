import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

export interface ColumnStats {
  name: string;
  min: number | null;
  max: number | null;
  mean: number | null;
  std: number | null;
  nullCount: number;
}

export interface Dataset {
  id: number;
  name: string;
  asset: string | null;
  timeframe: string | null;
  fileName: string;
  fileType: string;
  rowCount: number;
  columns: string[];
  startDate: string | null;
  endDate: string | null;
  columnStats: ColumnStats[] | null;
  previewRows: Record<string, string>[] | null;
  gapsDetected: number | null;
  nullsRemoved: number | null;
  isPrepared: boolean;
  preparationReport: string | null;
  createdAt: string;
  updatedAt: string;
}

const BASE = "/api";

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, init);
  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(err.message ?? "API error");
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export function useDatasets() {
  return useQuery<Dataset[]>({
    queryKey: ["datasets"],
    queryFn: () => apiFetch<Dataset[]>("/datasets"),
  });
}

export function useDataset(id: number) {
  return useQuery<Dataset>({
    queryKey: ["datasets", id],
    queryFn: () => apiFetch<Dataset>(`/datasets/${id}`),
    enabled: !!id,
  });
}

export function useUploadDataset() {
  const qc = useQueryClient();
  return useMutation<Dataset, Error, FormData>({
    mutationFn: (fd) =>
      apiFetch<Dataset>("/datasets", { method: "POST", body: fd }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["datasets"] }),
  });
}

export function useDeleteDataset() {
  const qc = useQueryClient();
  return useMutation<void, Error, number>({
    mutationFn: (id) => apiFetch<void>(`/datasets/${id}`, { method: "DELETE" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["datasets"] }),
  });
}

export function usePrepareDataset() {
  const qc = useQueryClient();
  return useMutation<Dataset, Error, { id: number; options: { removeNulls: boolean; detectGaps: boolean; normalize: boolean } }>({
    mutationFn: ({ id, options }) =>
      apiFetch<Dataset>(`/datasets/${id}/prepare`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(options),
      }),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["datasets"] });
      qc.invalidateQueries({ queryKey: ["datasets", data.id] });
    },
  });
}
