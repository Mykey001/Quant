import { useQueryClient } from "@tanstack/react-query";
import { 
  useListStrategies, 
  useUploadStrategy, 
  useGetStrategy, 
  useDeleteStrategy, 
  useStartAnalysis,
  getListStrategiesQueryKey
} from "@workspace/api-client-react";

export function useStrategiesHooks() {
  const queryClient = useQueryClient();

  const strategiesQuery = useListStrategies();

  const uploadMutation = useUploadStrategy({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: getListStrategiesQueryKey() });
      },
    },
  });

  const deleteMutation = useDeleteStrategy({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: getListStrategiesQueryKey() });
      },
    },
  });

  const analyzeMutation = useStartAnalysis({
    mutation: {
      onSuccess: () => {
        // Also invalidate runs when a new analysis starts
        queryClient.invalidateQueries({ queryKey: ['/api/runs'] });
      }
    }
  });

  return {
    strategiesQuery,
    uploadMutation,
    deleteMutation,
    analyzeMutation
  };
}

export function useStrategyDetail(id: number) {
  return useGetStrategy(id, {
    query: {
      enabled: !!id,
    }
  });
}
