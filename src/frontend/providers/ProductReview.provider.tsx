// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

import { createContext, useContext, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import ApiGateway from '../gateways/Api.gateway';
import { ProductReview } from '../protos/demo';

interface IContext {
    // null = not loaded yet; [] = loaded with no reviews; array = loaded with reviews.
    productReviews: ProductReview[] | null;
    loading: boolean;
    error: Error | null;
    averageScore: string | null;
}

export const Context = createContext<IContext>({
    productReviews: null,
    loading: false,
    error: null,
    averageScore: null,
});

interface IProps {
    children: React.ReactNode;
    productId: string;
}

//export const useProductReview = () => useContext(Context);
export const useProductReview = () => {
    const value = useContext(Context);
    return value;
};

const ProductReviewProvider = ({ children, productId }: IProps) => {
    const {
        data,
        isLoading,
        isFetching,
        isError,
        error,
        isSuccess,
    } = useQuery<ProductReview[]>({
        queryKey: ['productReviews', productId],
        queryFn: () => ApiGateway.getProductReviews(productId),
        refetchOnWindowFocus: false,
    });

    // Use a sentinel: null while loading, [] if loaded but empty, array when loaded with data.
    const productReviews = useMemo((): ProductReview[] | null => {
        if (!isSuccess) return null;
        return Array.isArray(data) ? data : [];
    }, [isSuccess, data]);

    const loading = isLoading || isFetching;

    // Narrow react-query's `unknown` error to `Error | null`.
    const currentError = useMemo((): Error | null => {
        if (!isError) return null;
        return error instanceof Error ? error : new Error('Unknown error');
    }, [isError, error]);

    const { data: averageScore = '' } = useQuery({
        queryKey: ['productReviewAvgScore', productId],
        queryFn: () => ApiGateway.getAverageProductReviewScore(productId),
    });

    const value = useMemo(
        () => ({
            productReviews,
            loading,
            error: currentError,
            averageScore,
        }),
        [productReviews, loading, currentError, averageScore]
    );

    return <Context.Provider value={value}>{children}</Context.Provider>;
};

export default ProductReviewProvider;
