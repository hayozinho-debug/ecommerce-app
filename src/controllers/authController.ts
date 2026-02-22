import { Request, Response } from 'express';
import { AuthService } from '../services/authService';

export class AuthController {
    private authService: AuthService;

    constructor() {
        this.authService = new AuthService();
    }

    public async register(req: Request, res: Response): Promise<void> {
        try {
            const { email, username, password } = req.body;

            // Validação básica
            if (!email || !username || !password) {
                res.status(400).json({ message: 'Email, username, and password are required' });
                return;
            }

            const user = await this.authService.register({ email, username, password });
            res.status(201).json({ message: 'User registered successfully', user });
        } catch (error) {
            res.status(400).json({ message: error instanceof Error ? error.message : 'Registration failed' });
        }
    }

    public async login(req: Request, res: Response): Promise<void> {
        try {
            const { email, password } = req.body;

            // Validação básica
            if (!email || !password) {
                res.status(400).json({ message: 'Email and password are required' });
                return;
            }

            const result = await this.authService.login({ email, password });
            res.status(200).json(result);
        } catch (error) {
            res.status(401).json({ message: error instanceof Error ? error.message : 'Login failed' });
        }
    }

    public async authenticate(req: Request, res: Response): Promise<void> {
        try {
            const token = req.headers.authorization?.split(' ')[1];

            if (!token) {
                res.status(401).json({ message: 'Token is required' });
                return;
            }

            const user = await this.authService.authenticate(token);
            res.status(200).json({ message: 'Token is valid', user });
        } catch (error) {
            res.status(401).json({ message: error instanceof Error ? error.message : 'Authentication failed' });
        }
    }
}