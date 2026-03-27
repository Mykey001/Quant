import { useQueryClient } from "@tanstack/react-query";
import { 
  useListRuns, 
  useGetRun, 
  useGetRunSteps,
  getListRunsQueryKey,
  getGetRunQueryKey,
  getGetRunStepsQueryKey
} from "@workspace/api-client-react";

export function useRunsHooks() {
  return useListRuns({
    query: {
      refetchInterval: (query) => {
        const runs = query.state.data;
        // Poll if any run is pending or running
        const shouldPoll = runs?.some(r => r.status === 'pending' || r.status === 'running');
        return shouldPoll ? 3000 : false;
      }
    }
  });
}

export function useRunDetail(id: number) {
  const runQuery = useGetRun(id, {
    query: {
      enabled: !!id,
      refetchInterval: (query) => {
        const status = query.state.data?.status;
        return (status === 'pending' || status === 'running') ? 2000 : false;
      }
    }
  });

  const stepsQuery = useGetRunSteps(id, {
    query: {
      enabled: !!id,
      refetchInterval: (query) => {
        // We can just rely on the runQuery's status to determine if we should poll steps,
        // but since we don't have access to it directly here, we check if any step is pending/running
        const steps = query.state.data;
        const isCompleted = steps?.every(s => s.status === 'completed' || s.status === 'failed');
        return !isCompleted ? 2000 : false;
      }
    }
  });

  return { runQuery, stepsQuery };
}
