import { prisma } from '../db/prisma';

export class ProductService {
    public async getAllProducts(categoryId?: number) {
        try {
            return await prisma.product.findMany({
                where: categoryId ? { categoryId } : {},
                include: {
                    variants: true,
                    category: true,
                },
            });
        } catch (error) {
            throw new Error(`Error fetching products: ${error}`);
        }
    }

    public async getProductById(id: number | string) {
        try {
            const productId = typeof id === 'string' ? parseInt(id, 10) : id;
            return await prisma.product.findUnique({
                where: { id: productId },
                include: {
                    variants: true,
                    category: true,
                },
            });
        } catch (error) {
            throw new Error(`Error fetching product: ${error}`);
        }
    }

    public async addProduct(data: {
        title: string;
        description?: string;
        price: number;
        sku?: string;
        categoryId?: number;
        images?: string[];
    }) {
        try {
            return await prisma.product.create({
                data: {
                    title: data.title,
                    description: data.description || '',
                    price: data.price,
                    sku: data.sku,
                    categoryId: data.categoryId,
                    images: data.images || [],
                },
                include: {
                    variants: true,
                    category: true,
                },
            });
        } catch (error) {
            throw new Error(`Error adding product: ${error}`);
        }
    }

    public async updateProduct(
        id: number | string,
        data: {
            title?: string;
            description?: string;
            price?: number;
            categoryId?: number;
            images?: string[];
        }
    ) {
        try {
            const productId = typeof id === 'string' ? parseInt(id, 10) : id;
            return await prisma.product.update({
                where: { id: productId },
                data,
                include: {
                    variants: true,
                    category: true,
                },
            });
        } catch (error) {
            throw new Error(`Error updating product: ${error}`);
        }
    }

    public async deleteProduct(id: number | string) {
        try {
            const productId = typeof id === 'string' ? parseInt(id, 10) : id;
            // Deletar variantes primeiro (FK constraint)
            await prisma.productVariant.deleteMany({
                where: { productId },
            });
            // Depois deletar produto
            return await prisma.product.delete({
                where: { id: productId },
            });
        } catch (error) {
            throw new Error(`Error deleting product: ${error}`);
        }
    }

    public async addProductVariant(data: {
        productId: number;
        sku: string;
        size?: string;
        color?: string;
        stock?: number;
        price?: number;
    }) {
        try {
            return await prisma.productVariant.create({
                data: {
                    productId: data.productId,
                    sku: data.sku,
                    size: data.size,
                    color: data.color,
                    stock: data.stock || 0,
                    price: data.price,
                },
            });
        } catch (error) {
            throw new Error(`Error adding variant: ${error}`);
        }
    }

    public async getProductVariants(productId: number) {
        try {
            return await prisma.productVariant.findMany({
                where: { productId },
            });
        } catch (error) {
            throw new Error(`Error fetching variants: ${error}`);
        }
    }
}