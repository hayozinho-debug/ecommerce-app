import { prisma } from '../db/prisma';

export class CategoryService {
    async getAllCategories() {
        try {
            return await prisma.category.findMany({
                include: {
                    products: true,
                },
            });
        } catch (error) {
            throw new Error(`Error fetching categories: ${error}`);
        }
    }

    async getCategoryById(id: number) {
        try {
            return await prisma.category.findUnique({
                where: { id },
                include: {
                    products: {
                        include: {
                            variants: true,
                        },
                    },
                },
            });
        } catch (error) {
            throw new Error(`Error fetching category: ${error}`);
        }
    }

    async createCategory(data: { name: string; slug: string }) {
        try {
            return await prisma.category.create({
                data,
            });
        } catch (error) {
            throw new Error(`Error creating category: ${error}`);
        }
    }

    async updateCategory(id: number, data: { name?: string; slug?: string }) {
        try {
            return await prisma.category.update({
                where: { id },
                data,
            });
        } catch (error) {
            throw new Error(`Error updating category: ${error}`);
        }
    }

    async deleteCategory(id: number) {
        try {
            return await prisma.category.delete({
                where: { id },
            });
        } catch (error) {
            throw new Error(`Error deleting category: ${error}`);
        }
    }
}
