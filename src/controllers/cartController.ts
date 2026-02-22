import { Request, Response } from 'express';
import { CartService } from '../services/cartService';

export class CartController {
    private cartService: CartService;

    constructor() {
        this.cartService = new CartService();
    }

    public addToCart = async (req: Request, res: Response): Promise<void> => {
        try {
            const userId = (req as any).user?.id;
            if (!userId) {
                res.status(401).json({ message: 'Unauthorized' });
                return;
            }

            const { productId, variantId, quantity } = req.body;
            if (!productId || !quantity) {
                res.status(400).json({ message: 'productId and quantity are required' });
                return;
            }

            const cartItem = await this.cartService.addToCart({
                userId,
                productId,
                variantId,
                quantity,
            });
            res.status(201).json({ message: 'Item added to cart', cartItem });
        } catch (error) {
            res.status(500).json({ message: 'Error adding to cart', error });
        }
    };

    public getCart = async (req: Request, res: Response): Promise<void> => {
        try {
            const userId = (req as any).user?.id;
            if (!userId) {
                res.status(401).json({ message: 'Unauthorized' });
                return;
            }

            const cartItems = await this.cartService.getCartItems(userId);
            res.status(200).json({ cartItems });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching cart', error });
        }
    };

    public updateCartItem = async (req: Request, res: Response): Promise<void> => {
        try {
            const cartItemId = parseInt(req.params.id, 10);
            const { quantity } = req.body;

            if (quantity === undefined) {
                res.status(400).json({ message: 'Quantity is required' });
                return;
            }

            const updatedItem = await this.cartService.updateCartItem(cartItemId, quantity);
            res.status(200).json({ message: 'Cart item updated', cartItem: updatedItem });
        } catch (error) {
            res.status(500).json({ message: 'Error updating cart item', error });
        }
    };

    public removeFromCart = async (req: Request, res: Response): Promise<void> => {
        try {
            const cartItemId = parseInt(req.params.id, 10);
            await this.cartService.removeFromCart(cartItemId);
            res.status(200).json({ message: 'Item removed from cart' });
        } catch (error) {
            res.status(500).json({ message: 'Error removing from cart', error });
        }
    };

    public clearCart = async (req: Request, res: Response): Promise<void> => {
        try {
            const userId = (req as any).user?.id;
            if (!userId) {
                res.status(401).json({ message: 'Unauthorized' });
                return;
            }

            await this.cartService.clearCart(userId);
            res.status(200).json({ message: 'Cart cleared' });
        } catch (error) {
            res.status(500).json({ message: 'Error clearing cart', error });
        }
    };
}
