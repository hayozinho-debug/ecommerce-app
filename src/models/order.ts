export interface Order {
    id: string;
    userId: string;
    productIds: string[];
    totalAmount: number;
    status: 'pending' | 'completed' | 'canceled';
    createdAt: Date;
    updatedAt: Date;
}

export class OrderModel {
    private orders: Order[] = [];

    createOrder(order: Omit<Order, 'id' | 'createdAt' | 'updatedAt'>): Order {
        const newOrder: Order = {
            ...order,
            id: this.generateId(),
            createdAt: new Date(),
            updatedAt: new Date(),
        };
        this.orders.push(newOrder);
        return newOrder;
    }

    private generateId(): string {
        return Math.random().toString(36).substr(2, 9);
    }

    getOrdersByUserId(userId: string): Order[] {
        return this.orders.filter(order => order.userId === userId);
    }

    updateOrderStatus(orderId: string, status: 'pending' | 'completed' | 'canceled'): Order | undefined {
        const order = this.orders.find(order => order.id === orderId);
        if (order) {
            order.status = status;
            order.updatedAt = new Date();
            return order;
        }
        return undefined;
    }
}