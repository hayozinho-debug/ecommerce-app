import { Router, Express } from 'express';
import { AuthController } from '../controllers/authController';
import { ProductController } from '../controllers/productController';
import { OrderController } from '../controllers/orderController';
import { CartController } from '../controllers/cartController';
import { CategoryController } from '../controllers/categoryController';
import { ShopifyController } from '../controllers/shopifyController';
import { authMiddleware, adminMiddleware } from '../middlewares/auth';

const router = Router();

// Controladores
const authController = new AuthController();
const productController = new ProductController();
const orderController = new OrderController();
const cartController = new CartController();
const categoryController = new CategoryController();
const shopifyController = new ShopifyController();

// ==================== PUBLIC ROUTES ====================

// Autenticação (público)
router.post('/auth/register', authController.register.bind(authController));
router.post('/auth/login', authController.login.bind(authController));
router.post('/auth/verify', authController.authenticate.bind(authController));

// Produtos (public read)
router.get('/products', productController.getProducts.bind(productController));
router.get('/products/:id', productController.getProduct.bind(productController));

// Categorias (public read)
router.get('/categories', categoryController.getAllCategories.bind(categoryController));
router.get('/categories/:id', categoryController.getCategoryById.bind(categoryController));

// Shopify (public read)
router.get('/shopify/products', shopifyController.getProducts.bind(shopifyController));
router.get('/shopify/products/:id', shopifyController.getProductById.bind(shopifyController));
router.get('/shopify/collections', shopifyController.getCollections.bind(shopifyController));
router.get('/shopify/stories-collections', shopifyController.getStoriesCollections.bind(shopifyController));
router.get('/shopify/collection-products', shopifyController.getProductsByCollection.bind(shopifyController));
router.get('/shopify/shop-metafields', shopifyController.getShopMetafields.bind(shopifyController));
router.get('/shopify/clips', shopifyController.getClips.bind(shopifyController));
router.get('/shopify/reviews', shopifyController.getProductReviews.bind(shopifyController));
router.post('/shopify/checkout', shopifyController.createCheckout.bind(shopifyController));

// ==================== PROTECTED ROUTES (USER) ====================

// Carrinho (usuário autenticado)
router.post('/cart', authMiddleware, cartController.addToCart.bind(cartController));
router.get('/cart', authMiddleware, cartController.getCart.bind(cartController));
router.put('/cart/:id', authMiddleware, cartController.updateCartItem.bind(cartController));
router.delete('/cart/:id', authMiddleware, cartController.removeFromCart.bind(cartController));
router.delete('/cart', authMiddleware, cartController.clearCart.bind(cartController));

// Pedidos (usuário autenticado)
router.post('/orders', authMiddleware, orderController.createOrder.bind(orderController));
router.get('/orders', authMiddleware, orderController.getUserOrders.bind(orderController));
router.get('/orders/:id', authMiddleware, orderController.getOrderById.bind(orderController));

// ==================== ADMIN ROUTES ====================

// Produtos (admin only)
router.post('/products', authMiddleware, adminMiddleware, productController.addProduct.bind(productController));
router.put('/products/:id', authMiddleware, adminMiddleware, productController.updateProduct.bind(productController));
router.delete('/products/:id', authMiddleware, adminMiddleware, productController.deleteProduct.bind(productController));

// Variantes de produtos (admin only)
router.post('/products/:id/variants', authMiddleware, adminMiddleware, productController.addVariant.bind(productController));
router.get('/products/:id/variants', productController.getVariants.bind(productController));

// Categorias (admin only)
router.post('/categories', authMiddleware, adminMiddleware, categoryController.createCategory.bind(categoryController));
router.put('/categories/:id', authMiddleware, adminMiddleware, categoryController.updateCategory.bind(categoryController));
router.delete('/categories/:id', authMiddleware, adminMiddleware, categoryController.deleteCategory.bind(categoryController));

// Pedidos (admin - visualizar e gerenciar)
router.get('/admin/orders', authMiddleware, adminMiddleware, orderController.getAllOrders.bind(orderController));
router.put('/admin/orders/:id/status', authMiddleware, adminMiddleware, orderController.updateOrderStatus.bind(orderController));
router.delete('/admin/orders/:id', authMiddleware, adminMiddleware, orderController.deleteOrder.bind(orderController));

// Health check
router.get('/health', (req, res) => {
    res.status(200).json({ message: 'Server is running', timestamp: new Date().toISOString() });
});

// Shopify webhooks
router.post('/webhooks/shopify', shopifyController.webhook.bind(shopifyController));

export default router;

export function setupRoutes(app: Express) {
    app.use('/api', router);
}
