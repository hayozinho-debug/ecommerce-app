import { prisma } from '../db/prisma';

export class CartService {
    async addToCart(data: {
        userId: string;
        productId: number;
        variantId?: number;
        quantity: number;
    }) {
        try {
            // Verificar se item já existe no carrinho
            const existingItem = await prisma.cartItem.findFirst({
                where: {
                    userId: data.userId,
                    productId: data.productId,
                    variantId: data.variantId || null,
                },
            });

            if (existingItem) {
                // Atualizar quantidade
                return await prisma.cartItem.update({
                    where: { id: existingItem.id },
                    data: {
                        quantity: {
                            increment: data.quantity,
                        },
                    },
                });
            }

            // Criar novo item no carrinho
            return await prisma.cartItem.create({
                data: {
                    userId: data.userId,
                    productId: data.productId,
                    variantId: data.variantId,
                    quantity: data.quantity,
                },
            });
        } catch (error) {
            throw new Error(`Error adding to cart: ${error}`);
        }
    }

    async getCartItems(userId: string) {
        try {
            const cartItems = await prisma.cartItem.findMany({
                where: { userId },
            });

            // Enriquecer com dados do produto
            const enrichedItems = await Promise.all(
                cartItems.map(async (item) => {
                    const product = await prisma.product.findUnique({
                        where: { id: item.productId },
                        include: { variants: true },
                    });
                    const variant = item.variantId
                        ? await prisma.productVariant.findUnique({
                              where: { id: item.variantId },
                          })
                        : null;
                    return {
                        ...item,
                        product,
                        variant,
                    };
                })
            );

            return enrichedItems;
        } catch (error) {
            throw new Error(`Error fetching cart: ${error}`);
        }
    }

    async updateCartItem(cartItemId: number, quantity: number) {
        try {
            if (quantity <= 0) {
                return await this.removeFromCart(cartItemId);
            }
            return await prisma.cartItem.update({
                where: { id: cartItemId },
                data: { quantity },
            });
        } catch (error) {
            throw new Error(`Error updating cart item: ${error}`);
        }
    }

    async removeFromCart(cartItemId: number) {
        try {
            return await prisma.cartItem.delete({
                where: { id: cartItemId },
            });
        } catch (error) {
            throw new Error(`Error removing from cart: ${error}`);
        }
    }

    async clearCart(userId: string) {
        try {
            return await prisma.cartItem.deleteMany({
                where: { userId },
            });
        } catch (error) {
            throw new Error(`Error clearing cart: ${error}`);
        }
    }
}
