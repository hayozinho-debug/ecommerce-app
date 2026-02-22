import { Request, Response } from 'express';
import { ProductService } from '../services/productService';

export class ProductController {
    private productService: ProductService;

    constructor() {
        this.productService = new ProductService();
    }

    public async addProduct(req: Request, res: Response): Promise<void> {
        try {
            const productData = req.body;
            const newProduct = await this.productService.addProduct(productData);
            res.status(201).json({ message: 'Product created successfully', product: newProduct });
        } catch (error) {
            res.status(500).json({ message: 'Error adding product', error });
        }
    }

    public async getProducts(req: Request, res: Response): Promise<void> {
        try {
            const categoryId = req.query.categoryId ? parseInt(req.query.categoryId as string, 10) : undefined;
            const products = await this.productService.getAllProducts(categoryId);
            res.status(200).json({ products });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching products', error });
        }
    }

    public async getProduct(req: Request, res: Response): Promise<void> {
        try {
            const productId = req.params.id;
            const product = await this.productService.getProductById(productId);
            if (!product) {
                res.status(404).json({ message: 'Product not found' });
                return;
            }
            res.status(200).json({ product });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching product', error });
        }
    }

    public async updateProduct(req: Request, res: Response): Promise<void> {
        try {
            const productId = req.params.id;
            const productData = req.body;
            const updatedProduct = await this.productService.updateProduct(productId, productData);
            res.status(200).json({ message: 'Product updated successfully', product: updatedProduct });
        } catch (error) {
            res.status(500).json({ message: 'Error updating product', error });
        }
    }

    public async deleteProduct(req: Request, res: Response): Promise<void> {
        try {
            const productId = req.params.id;
            await this.productService.deleteProduct(productId);
            res.status(200).json({ message: 'Product deleted successfully' });
        } catch (error) {
            res.status(500).json({ message: 'Error deleting product', error });
        }
    }

    public async addVariant(req: Request, res: Response): Promise<void> {
        try {
            const variantData = req.body;
            const newVariant = await this.productService.addProductVariant(variantData);
            res.status(201).json({ message: 'Variant created successfully', variant: newVariant });
        } catch (error) {
            res.status(500).json({ message: 'Error adding variant', error });
        }
    }

    public async getVariants(req: Request, res: Response): Promise<void> {
        try {
            const productId = parseInt(req.params.id, 10);
            const variants = await this.productService.getProductVariants(productId);
            res.status(200).json({ variants });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching variants', error });
        }
    }
}