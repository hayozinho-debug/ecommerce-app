import { prisma } from '../db/prisma';
import bcryptjs from 'bcryptjs';
import jwt from 'jsonwebtoken';

export class AuthService {
    async register(data: { email: string; username: string; password: string }) {
        try {
            // Verificar se usuário já existe
            const existingUser = await prisma.user.findUnique({
                where: { email: data.email },
            });
            if (existingUser) {
                throw new Error('Email already in use');
            }

            // Hash da senha
            const hashedPassword = await bcryptjs.hash(data.password, 10);

            // Criar usuário
            const user = await prisma.user.create({
                data: {
                    email: data.email,
                    username: data.username,
                    password: hashedPassword,
                    role: 'user',
                },
            });

            // Remover senha do response
            const { password, ...userWithoutPassword } = user;
            return userWithoutPassword;
        } catch (error) {
            throw new Error(`Registration error: ${error}`);
        }
    }

    async login(data: { email: string; password: string }) {
        try {
            // Encontrar usuário
            const user = await prisma.user.findUnique({
                where: { email: data.email },
            });
            if (!user) {
                throw new Error('Invalid email or password');
            }

            // Verificar senha
            const isPasswordValid = await bcryptjs.compare(data.password, user.password);
            if (!isPasswordValid) {
                throw new Error('Invalid email or password');
            }

            // Gerar JWT
            const token = jwt.sign(
                { id: user.id, email: user.email, role: user.role },
                process.env.JWT_SECRET || 'your_jwt_secret',
                { expiresIn: '24h' }
            );

            return {
                token,
                user: {
                    id: user.id,
                    email: user.email,
                    username: user.username,
                    role: user.role,
                },
            };
        } catch (error) {
            throw new Error(`Login error: ${error}`);
        }
    }

    async authenticate(token: string) {
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret') as any;
            const user = await prisma.user.findUnique({
                where: { id: decoded.id },
            });
            if (!user) {
                throw new Error('User not found');
            }
            return {
                id: user.id,
                email: user.email,
                username: user.username,
                role: user.role,
            };
        } catch (error) {
            throw new Error(`Authentication error: ${error}`);
        }
    }
}