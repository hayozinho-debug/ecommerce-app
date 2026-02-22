import React, { useState, useEffect } from 'react';
import axios from 'axios';

interface CartItem {
  id: number;
  title: string;
  price: number;
  quantity: number;
}

function Cart() {
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [total, setTotal] = useState(0);

  useEffect(() => {
    loadCart();
  }, []);

  useEffect(() => {
    calculateTotal();
  }, [cartItems]);

  const loadCart = () => {
    const cart = JSON.parse(localStorage.getItem('cart') || '[]');
    setCartItems(cart);
  };

  const calculateTotal = () => {
    const sum = cartItems.reduce((acc, item) => acc + item.price * item.quantity, 0);
    setTotal(sum);
  };

  const removeFromCart = (id: number) => {
    const updatedCart = cartItems.filter((item) => item.id !== id);
    setCartItems(updatedCart);
    localStorage.setItem('cart', JSON.stringify(updatedCart));
  };

  const updateQuantity = (id: number, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(id);
      return;
    }

    const updatedCart = cartItems.map((item) =>
      item.id === id ? { ...item, quantity } : item
    );
    setCartItems(updatedCart);
    localStorage.setItem('cart', JSON.stringify(updatedCart));
  };

  const checkout = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      alert('Você precisa estar logado para fazer checkout');
      return;
    }

    try {
      const response = await axios.post(
        '/api/orders',
        { items: cartItems, total },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      alert('Pedido criado com sucesso!');
      setCartItems([]);
      localStorage.setItem('cart', JSON.stringify([]));
    } catch (error) {
      alert('Erro ao criar pedido');
    }
  };

  return (
    <div>
      <h1>Carrinho</h1>

      {cartItems.length === 0 ? (
        <p>Seu carrinho está vazio</p>
      ) : (
        <div>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ backgroundColor: '#f5f5f5' }}>
                <th style={{ padding: '10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Produto</th>
                <th style={{ padding: '10px', textAlign: 'center', borderBottom: '1px solid #ddd' }}>Preço</th>
                <th style={{ padding: '10px', textAlign: 'center', borderBottom: '1px solid #ddd' }}>Quantidade</th>
                <th style={{ padding: '10px', textAlign: 'right', borderBottom: '1px solid #ddd' }}>Subtotal</th>
                <th style={{ padding: '10px', textAlign: 'center', borderBottom: '1px solid #ddd' }}>Ação</th>
              </tr>
            </thead>
            <tbody>
              {cartItems.map((item) => (
                <tr key={item.id} style={{ borderBottom: '1px solid #ddd' }}>
                  <td style={{ padding: '10px' }}>{item.title}</td>
                  <td style={{ padding: '10px', textAlign: 'center' }}>R$ {item.price.toFixed(2)}</td>
                  <td style={{ padding: '10px', textAlign: 'center' }}>
                    <input
                      type="number"
                      value={item.quantity}
                      onChange={(e) => updateQuantity(item.id, parseInt(e.target.value))}
                      min="1"
                      style={{ width: '50px' }}
                    />
                  </td>
                  <td style={{ padding: '10px', textAlign: 'right' }}>R$ {(item.price * item.quantity).toFixed(2)}</td>
                  <td style={{ padding: '10px', textAlign: 'center' }}>
                    <button className="btn btn-danger" onClick={() => removeFromCart(item.id)}>
                      Remover
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div style={{ marginTop: '20px', textAlign: 'right' }}>
            <h2>Total: R$ {total.toFixed(2)}</h2>
            <button className="btn btn-success" onClick={checkout}>
              Fazer Checkout
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default Cart;
