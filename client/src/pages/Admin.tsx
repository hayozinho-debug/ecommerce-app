import React, { useState, useEffect } from 'react';
import axios from 'axios';

interface Product {
  id: number;
  title: string;
  description: string;
  price: number;
}

function Admin() {
  const [products, setProducts] = useState<Product[]>([]);
  const [formData, setFormData] = useState({ title: '', description: '', price: 0 });
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const token = localStorage.getItem('token');

    try {
      await axios.post('/api/products', formData, {
        headers: { Authorization: `Bearer ${token}` },
      });
      alert('Produto criado com sucesso!');
      setFormData({ title: '', description: '', price: 0 });
      fetchProducts();
    } catch (error) {
      alert('Erro ao criar produto');
    }
  };

  const deleteProduct = async (id: number) => {
    const token = localStorage.getItem('token');
    if (!window.confirm('Tem certeza que deseja deletar este produto?')) return;

    try {
      await axios.delete(`/api/products/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      alert('Produto deletado com sucesso!');
      fetchProducts();
    } catch (error) {
      alert('Erro ao deletar produto');
    }
  };

  if (loading) return <div className="loading">Carregando...</div>;

  return (
    <div>
      <h1>Painel Admin</h1>

      <div style={{ marginBottom: '40px' }}>
        <h2>Criar Novo Produto</h2>
        <form onSubmit={handleSubmit} style={{ maxWidth: '500px' }}>
          <div className="form-group">
            <label>Título</label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>
          <div className="form-group">
            <label>Descrição</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              style={{ height: '100px' }}
            />
          </div>
          <div className="form-group">
            <label>Preço</label>
            <input
              type="number"
              step="0.01"
              value={formData.price}
              onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) })}
              required
            />
          </div>
          <button type="submit" className="btn">
            Criar Produto
          </button>
        </form>
      </div>

      <h2>Produtos</h2>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ backgroundColor: '#f5f5f5' }}>
            <th style={{ padding: '10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Título</th>
            <th style={{ padding: '10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Preço</th>
            <th style={{ padding: '10px', textAlign: 'center', borderBottom: '1px solid #ddd' }}>Ação</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id} style={{ borderBottom: '1px solid #ddd' }}>
              <td style={{ padding: '10px' }}>{product.title}</td>
              <td style={{ padding: '10px' }}>R$ {product.price.toFixed(2)}</td>
              <td style={{ padding: '10px', textAlign: 'center' }}>
                <button className="btn btn-danger" onClick={() => deleteProduct(product.id)}>
                  Deletar
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default Admin;
