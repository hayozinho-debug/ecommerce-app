import { prisma } from '../db/prisma';

export class OrderService {
    async createOrder(data: {
        userId: string;
        items: Array<{
            productId: number;
            variantId?: number;
            quantity: number;
            price: number;
        }>;
        total: number;
    }) {
        try {
            const order = await prisma.order.create({
                data: {
                    userId: data.userId,
                    total: data.total,
                    status: 'pending',
                    items: {
                        create: data.items.map((item) => ({
                            productId: item.productId,
                            variantId: item.variantId,
                            quantity: item.quantity,
                            price: item.price,
                        })),
                    },
                },
                include: {
                    items: true,
                    user: {
                        select: {
                            id: true,
                            email: true,
                            username: true,
                        },
                    },
                },
            });

            // Atualizar estoque das variantes
            for (const item of data.items) {
                if (item.variantId) {
                    await prisma.productVariant.update({
                        where: { id: item.variantId },
                        data: {
                            stock: {
                                decrement: item.quantity,
                            },
                        },
                    });
                }
            }

            return order;
        } catch (error) {
            throw new Error(`Error creating order: ${error}`);
        }
    }

    async getUserOrders(userId: string) {
        try {
            return await prisma.order.findMany({
                where: { userId },
                include: {
                    items: true,
                    user: {
                        select: {
                            id: true,
                            email: true,
                            username: true,
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
            });
        } catch (error) {
            throw new Error(`Error fetching user orders: ${error}`);
        }
    }

    async getOrderById(orderId: string) {
        try {
            return await prisma.order.findUnique({
                where: { id: orderId },
                include: {
                    items: true,
                    user: {
                        select: {
                            id: true,
                            email: true,
                            username: true,
                        },
                    },
                },
            });
        } catch (error) {
            throw new Error(`Error fetching order: ${error}`);
        }
    }

    async getAllOrders() {
        try {
            return await prisma.order.findMany({
                include: {
                    items: true,
                    user: {
                        select: {
                            id: true,
                            email: true,
                            username: true,
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
            });
        } catch (error) {
            throw new Error(`Error fetching orders: ${error}`);
        }
    }

    async updateOrderStatus(orderId: string, status: string) {
        try {
            return await prisma.order.update({
                where: { id: orderId },
                data: { status },
                include: {
                    items: true,
                    user: {
                        select: {
                            id: true,
                            email: true,
                            username: true,
                        },
                    },
                },
            });
        } catch (error) {
            throw new Error(`Error updating order: ${error}`);
        }
    }

    async deleteOrder(orderId: string) {
        try {
            // Deletar items primeiro (FK constraint)
            await prisma.orderItem.deleteMany({
                where: { orderId },
            });
            // Depois deletar order
            return await prisma.order.delete({
                where: { id: orderId },
            });
        } catch (error) {
            throw new Error(`Error deleting order: ${error}`);
        }
    }
}
