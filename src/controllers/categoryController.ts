import { Request, Response } from 'express';
import { CategoryService } from '../services/categoryService';

export class CategoryController {
    private categoryService: CategoryService;

    constructor() {
        this.categoryService = new CategoryService();
    }

    public getAllCategories = async (req: Request, res: Response): Promise<void> => {
        try {
            const categories = await this.categoryService.getAllCategories();
            res.status(200).json({ categories });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching categories', error });
        }
    };

    public getCategoryById = async (req: Request, res: Response): Promise<void> => {
        try {
            const categoryId = parseInt(req.params.id, 10);
            const category = await this.categoryService.getCategoryById(categoryId);
            if (!category) {
                res.status(404).json({ message: 'Category not found' });
                return;
            }
            res.status(200).json({ category });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching category', error });
        }
    };

    public createCategory = async (req: Request, res: Response): Promise<void> => {
        try {
            const { name, slug } = req.body;
            if (!name || !slug) {
                res.status(400).json({ message: 'Name and slug are required' });
                return;
            }

            const category = await this.categoryService.createCategory({ name, slug });
            res.status(201).json({ message: 'Category created successfully', category });
        } catch (error) {
            res.status(500).json({ message: 'Error creating category', error });
        }
    };

    public updateCategory = async (req: Request, res: Response): Promise<void> => {
        try {
            const categoryId = parseInt(req.params.id, 10);
            const { name, slug } = req.body;

            const category = await this.categoryService.updateCategory(categoryId, { name, slug });
            res.status(200).json({ message: 'Category updated successfully', category });
        } catch (error) {
            res.status(500).json({ message: 'Error updating category', error });
        }
    };

    public deleteCategory = async (req: Request, res: Response): Promise<void> => {
        try {
            const categoryId = parseInt(req.params.id, 10);
            await this.categoryService.deleteCategory(categoryId);
            res.status(200).json({ message: 'Category deleted successfully' });
        } catch (error) {
            res.status(500).json({ message: 'Error deleting category', error });
        }
    };
}
