import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

export interface StrategyParameter {
  name: string;
  label: string;
  value: string;
  type: "int" | "double" | "bool" | "string" | "color" | "enum";
  description: string;
  options?: string[] | null;
  min?: number | null;
  max?: number | null;
}

async function fetchParameters(id: number): Promise<StrategyParameter[]> {
  const res = await fetch(`/api/strategies/${id}/parameters`);
  if (!res.ok) throw new Error("Failed to fetch parameters");
  return res.json();
}

async function saveParameters(id: number, params: StrategyParameter[]): Promise<void> {
  const res = await fetch(`/api/strategies/${id}/parameters`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(params),
  });
  if (!res.ok) throw new Error("Failed to save parameters");
}

export function useStrategyParameters(id: number) {
  return useQuery<StrategyParameter[]>({
    queryKey: ["strategy-parameters", id],
    queryFn: () => fetchParameters(id),
    enabled: !!id,
  });
}

export function useSaveParameters(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (params: StrategyParameter[]) => saveParameters(id, params),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["strategy-parameters", id] });
      queryClient.invalidateQueries({ queryKey: ["/api/strategies", id] });
    },
  });
}
