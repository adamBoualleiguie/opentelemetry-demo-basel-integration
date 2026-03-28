// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

import { createContext, useContext, useEffect, useMemo } from 'react';
import { useMutation, MutateOptions } from '@tanstack/react-query';
import ApiGateway from '../gateways/Api.gateway';

export interface AiRequestPayload {
    question: string;
}

export type AiResponse = { text: string } | string;

interface AiAssistantContextValue {
    aiResponse: AiResponse | null;
    aiLoading: boolean;
    aiError: Error | null;
    sendAiRequest: (
        payload: AiRequestPayload,
        options?: MutateOptions<AiResponse, Error, AiRequestPayload, unknown>
    ) => void;
    reset: () => void;
}

const Context = createContext<AiAssistantContextValue>({
    aiResponse: null,
    aiLoading: false,
    aiError: null,
    sendAiRequest: () => {},
    reset: () => {},
});

export const useAiAssistant = () => useContext(Context);

interface ProductAIAssistantProviderProps {
    children: React.ReactNode;
    productId: string;
}

const ProductAIAssistantProvider = ({ children, productId }: ProductAIAssistantProviderProps) => {
    const mutation = useMutation<AiResponse, Error, AiRequestPayload>({
        mutationFn: ({ question }) => ApiGateway.askProductAIAssistant(productId, question),
    });

    // Clear AI state when switching products.
    useEffect(() => {
        mutation.reset();
        // Only reset when route product changes; mutation identity is unstable across renders.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [productId]);

    const value = useMemo(
        () => ({
            aiResponse: mutation.data ?? null,
            aiLoading: mutation.isPending,
            aiError: mutation.error ?? null,
            sendAiRequest: (
                payload: AiRequestPayload,
                options?: MutateOptions<AiResponse, Error, AiRequestPayload, unknown>
            ) => {
                mutation.mutate(payload, options);
            },
            reset: () => mutation.reset(),
        }),
        [mutation]
    );

    return <Context.Provider value={value}>{children}</Context.Provider>;
};

export default ProductAIAssistantProvider;
