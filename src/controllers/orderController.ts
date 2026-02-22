import { Request, Response } from 'express';
import { OrderService } from '../services/orderService';

export class OrderController {
    private orderService: OrderService;

    constructor() {
        this.orderService = new OrderService();
    }

    public createOrder = async (req: Request, res: Response): Promise<void> => {
        try {
            const userId = (req as any).user?.id;
            if (!userId) {
                res.status(401).json({ message: 'Unauthorized' });
                return;
            }

            const { items, total } = req.body;
            if (!items || !total) {
                res.status(400).json({ message: 'Items and total are required' });
                return;
            }

            const newOrder = await this.orderService.createOrder({
                userId,
                items,
                total,
            });
            res.status(201).json({ message: 'Order created successfully', order: newOrder });
        } catch (error) {
            res.status(500).json({ message: 'Error creating order', error });
        }
    };

    public getUserOrders = async (req: Request, res: Response): Promise<void> => {
        try {
            const userId = (req as any).user?.id;
            if (!userId) {
                res.status(401).json({ message: 'Unauthorized' });
                return;
            }

            const orders = await this.orderService.getUserOrders(userId);
            res.status(200).json({ orders });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching orders', error });
        }
    };

    public getOrderById = async (req: Request, res: Response): Promise<void> => {
        try {
            const orderId = req.params.id;
            const order = await this.orderService.getOrderById(orderId);
            if (!order) {
                res.status(404).json({ message: 'Order not found' });
                return;
            }
            res.status(200).json({ order });
        } catch (error) {
            res.status(500).json({ message: 'Error retrieving order', error });
        }
    };

    public getAllOrders = async (req: Request, res: Response): Promise<void> => {
        try {
            const orders = await this.orderService.getAllOrders();
            res.status(200).json({ orders });
        } catch (error) {
            res.status(500).json({ message: 'Error fetching orders', error });
        }
    };

    public updateOrderStatus = async (req: Request, res: Response): Promise<void> => {
        try {
            const orderId = req.params.id;
            const { status } = req.body;

            if (!status) {
                res.status(400).json({ message: 'Status is required' });
                return;
            }

            const updatedOrder = await this.orderService.updateOrderStatus(orderId, status);
            res.status(200).json({ message: 'Order updated successfully', order: updatedOrder });
        } catch (error) {
            res.status(500).json({ message: 'Error updating order', error });
        }
    };

    public deleteOrder = async (req: Request, res: Response): Promise<void> => {
        try {
            const orderId = req.params.id;
            await this.orderService.deleteOrder(orderId);
            res.status(200).json({ message: 'Order deleted successfully' });
        } catch (error) {
            res.status(500).json({ message: 'Error deleting order', error });
        }
    };
}