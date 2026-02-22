import { PrismaClient } from '@prisma/client';
import bcryptjs from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  // Limpar dados anteriores
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.cartItem.deleteMany();
  await prisma.productVariant.deleteMany();
  await prisma.product.deleteMany();
  await prisma.category.deleteMany();
  await prisma.user.deleteMany();

  // Criar usuários
  const hashedPassword = await bcryptjs.hash('password123', 10);
  const user = await prisma.user.create({
    data: {
      email: 'user@example.com',
      username: 'john_doe',
      password: hashedPassword,
      role: 'user',
    },
  });

  const admin = await prisma.user.create({
    data: {
      email: 'admin@example.com',
      username: 'admin',
      password: hashedPassword,
      role: 'admin',
    },
  });

  // Criar categorias de moda
  const categories = await Promise.all([
    prisma.category.create({
      data: {
        name: 'Camisetas',
        slug: 'camisetas',
      },
    }),
    prisma.category.create({
      data: {
        name: 'Calças',
        slug: 'calcas',
      },
    }),
    prisma.category.create({
      data: {
        name: 'Vestidos',
        slug: 'vestidos',
      },
    }),
    prisma.category.create({
      data: {
        name: 'Jaquetas',
        slug: 'jaquetas',
      },
    }),
  ]);

  // Criar produtos de moda
  const product1 = await prisma.product.create({
    data: {
      title: 'Camiseta Premium 100% Algodão',
      description: 'Camiseta confortável e respirável para uso casual. Perfeita para qualquer ocasião.',
      price: 79.90,
      sku: 'SHIRT-001',
      categoryId: categories[0].id,
      images: ['/images/shirt-001.jpg'],
      variants: {
        create: [
          {
            sku: 'SHIRT-001-GG-BK',
            size: 'GG',
            color: 'Preto',
            stock: 15,
            price: 79.90,
          },
          {
            sku: 'SHIRT-001-GG-WH',
            size: 'GG',
            color: 'Branco',
            stock: 20,
            price: 79.90,
          },
          {
            sku: 'SHIRT-001-P-BK',
            size: 'P',
            color: 'Preto',
            stock: 10,
            price: 79.90,
          },
          {
            sku: 'SHIRT-001-P-BL',
            size: 'P',
            color: 'Azul',
            stock: 12,
            price: 79.90,
          },
        ],
      },
    },
  });

  const product2 = await prisma.product.create({
    data: {
      title: 'Calça Jeans Skinny',
      description: 'Calça jeans moderna e confortável com acabamento impecável. Ideal para um visual elegante.',
      price: 149.90,
      sku: 'JEANS-001',
      categoryId: categories[1].id,
      images: ['/images/jeans-001.jpg'],
      variants: {
        create: [
          {
            sku: 'JEANS-001-P-BK',
            size: 'P',
            color: 'Preto',
            stock: 8,
            price: 149.90,
          },
          {
            sku: 'JEANS-001-M-BK',
            size: 'M',
            color: 'Preto',
            stock: 12,
            price: 149.90,
          },
          {
            sku: 'JEANS-001-G-BK',
            size: 'G',
            color: 'Preto',
            stock: 10,
            price: 149.90,
          },
          {
            sku: 'JEANS-001-M-BL',
            size: 'M',
            color: 'Azul Claro',
            stock: 15,
            price: 149.90,
          },
        ],
      },
    },
  });

  const product3 = await prisma.product.create({
    data: {
      title: 'Vestido Festa Elegante',
      description: 'Vestido sofisticado e elegante, perfeito para eventos especiais. Confeccionado em tecido premium.',
      price: 299.90,
      sku: 'DRESS-001',
      categoryId: categories[2].id,
      images: ['/images/dress-001.jpg'],
      variants: {
        create: [
          {
            sku: 'DRESS-001-P-RD',
            size: 'P',
            color: 'Vermelho',
            stock: 5,
            price: 299.90,
          },
          {
            sku: 'DRESS-001-M-RD',
            size: 'M',
            color: 'Vermelho',
            stock: 7,
            price: 299.90,
          },
          {
            sku: 'DRESS-001-G-BK',
            size: 'G',
            color: 'Preto',
            stock: 6,
            price: 299.90,
          },
        ],
      },
    },
  });

  const product4 = await prisma.product.create({
    data: {
      title: 'Jaqueta de Couro Premium',
      description: 'Jaqueta clássica de couro legítimo para um estilo impactante. Resistente e duradoura.',
      price: 499.90,
      sku: 'JACKET-001',
      categoryId: categories[3].id,
      images: ['/images/jacket-001.jpg'],
      variants: {
        create: [
          {
            sku: 'JACKET-001-P-BK',
            size: 'P',
            color: 'Preto',
            stock: 3,
            price: 499.90,
          },
          {
            sku: 'JACKET-001-M-BK',
            size: 'M',
            color: 'Preto',
            stock: 5,
            price: 499.90,
          },
          {
            sku: 'JACKET-001-G-BK',
            size: 'G',
            color: 'Preto',
            stock: 4,
            price: 499.90,
          },
        ],
      },
    },
  });

  console.log('✅ Seed criado com sucesso!');
  console.log(`✅ Admin: ${admin.email} / password123`);
  console.log(`✅ User: ${user.email} / password123`);
  console.log(`✅ ${categories.length} categorias criadas`);
  console.log('✅ 4 produtos de moda criados com variantes');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
