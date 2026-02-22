export interface User {
    id: string;
    username: string;
    email: string;
    password: string;
    createdAt: Date;
    updatedAt: Date;
}

export interface Product {
    id: string;
    name: string;
    description: string;
    price: number;
    stock: number;
    createdAt: Date;
    updatedAt: Date;
}

export interface Order {
    id: string;
    userId: string;
    productIds: string[];
    totalAmount: number;
    createdAt: Date;
    updatedAt: Date;
}

export interface AuthResponse {
    token: string;
    user: User;
}

export interface RegisterRequest {
    username: string;
    email: string;
    password: string;
}

export interface LoginRequest {
    email: string;
    password: string;
}

export interface PaymentDetails {
    amount: number;
    currency: string;
    description: string;
    customerId: string;
}

export interface PaymentResponse {
    success: boolean;
    transactionId: string;
    message: string;
}