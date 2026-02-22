import React, { useState, useEffect } from 'react';
import axios from 'axios';

interface Product {
  id: number;
  title: string;
  description: string;
  price: number;
  images: string[];
}

function Products() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const response = await axios.get('/api/products');
      setProducts(response.data.products || []);
    } catch (error) {
      console.error('Erro ao buscar produtos:', error);
    } finally {
      setLoading(false);
    }
  };

  const addToCart = (product: Product) => {
    const cart = JSON.parse(localStorage.getItem('cart') || '[]');
    const existingItem = cart.find((item: any) => item.id === product.id);

    if (existingItem) {
      existingItem.quantity += 1;
    } else {
      cart.push({ ...product, quantity: 1 });
    }

    localStorage.setItem('cart', JSON.stringify(cart));
    alert('Produto adicionado ao carrinho!');
  };

  if (loading) return <div className="loading">Carregando produtos...</div>;

  return (
    <div>
      <h1>Produtos</h1>

      <div className="products-grid">
        {products.map((product) => (
          <div key={product.id} className="product-card">
            <div className="product-image">Imagem: {product.title}</div>
            <div className="product-info">
              <h3 className="product-title">{product.title}</h3>
              <p>{product.description}</p>
              <div className="product-price">R$ {product.price.toFixed(2)}</div>
              <button className="btn btn-success" onClick={() => addToCart(product)}>
                Adicionar ao Carrinho
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default Products;
