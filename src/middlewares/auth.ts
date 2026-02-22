import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

declare global {
    namespace Express {
        interface Request {
            user?: {
                id: string;
                email: string;
                role: string;
            };
        }
    }
}

const secretKey = process.env.JWT_SECRET || 'your_secret_key';

export const authMiddleware = (req: Request, res: Response, next: NextFunction): void => {
    try {
        const token = req.headers['authorization']?.split(' ')[1];

        if (!token) {
            res.status(401).json({ message: 'Unauthorized: Token is required' });
            return;
        }

        const decoded = jwt.verify(token, secretKey) as any;
        req.user = {
            id: decoded.id,
            email: decoded.email,
            role: decoded.role || 'user',
        };
        next();
    } catch (error) {
        res.status(401).json({ message: 'Unauthorized: Invalid token' });
    }
};

export const authenticate = authMiddleware;

export const adminMiddleware = (req: Request, res: Response, next: NextFunction): void => {
    try {
        if (!req.user || req.user.role !== 'admin') {
            res.status(403).json({ message: 'Forbidden: Admin access required' });
            return;
        }
        next();
    } catch (error) {
        res.status(403).json({ message: 'Forbidden' });
    }
};
