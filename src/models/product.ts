export interface Product {
    id: string;
    name: string;
    description: string;
    price: number;
    category: string;
    stock: number;
    createdAt: Date;
    updatedAt: Date;
}

export class ProductModel {
    private products: Product[] = [];

    public create(product: Product): Product {
        this.products.push(product);
        return product;
    }

    public update(id: string, updatedProduct: Partial<Product>): Product | null {
        const index = this.products.findIndex(product => product.id === id);
        if (index === -1) return null;
        this.products[index] = { ...this.products[index], ...updatedProduct };
        return this.products[index];
    }

    public delete(id: string): boolean {
        const index = this.products.findIndex(product => product.id === id);
        if (index === -1) return false;
        this.products.splice(index, 1);
        return true;
    }

    public findById(id: string): Product | null {
        return this.products.find(product => product.id === id) || null;
    }

    public findAll(): Product[] {
        return this.products;
    }
}