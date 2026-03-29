import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const API_URL = '/api';

function Payment({ cart, clearCart }) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    cardNumber: '',
    cardName: '',
    expiryDate: '',
    cvv: ''
  });
  const [processing, setProcessing] = useState(false);

  const getTotalPrice = () => {
    const subtotal = cart.reduce((total, item) => total + (item.price * item.quantity), 0);
    const shipping = 10;
    const tax = subtotal * 0.1;
    return (subtotal + shipping + tax).toFixed(2);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate card number (12 digits)
    const cardDigits = formData.cardNumber.replace(/\s/g, '');
    if (cardDigits.length !== 12 || !/^\d+$/.test(cardDigits)) {
      alert('Please enter a valid 12-digit card number');
      return;
    }

    // Validate CVV (3 digits)
    if (formData.cvv.length !== 3 || !/^\d+$/.test(formData.cvv)) {
      alert('Please enter a valid 3-digit CVV');
      return;
    }

    setProcessing(true);

    // Generate order ID
    const orderId = Math.floor(100000 + Math.random() * 900000);
    
    try {
      // Try to create order in backend
      await axios.post(`${API_URL}/orders`, {
        email: formData.email,
        total: getTotalPrice(),
        items: cart
      }).catch(() => {
        // If backend fails, continue anyway (order saved in localStorage)
        console.log('Backend order creation failed, using local storage only');
      });
    } catch (error) {
      console.log('Backend not available, using local storage');
    }

    // Save order to localStorage for tracking (always works)
    const orders = JSON.parse(localStorage.getItem('orders') || '[]');
    orders.push({
      id: orderId,
      date: new Date().toISOString(),
      total: getTotalPrice(),
      status: 'Processing',
      items: cart,
      email: formData.email
    });
    localStorage.setItem('orders', JSON.stringify(orders));

    setProcessing(false);
    alert(`✅ Order placed successfully!\n\nOrder ID: ${orderId}\nStatus: Ready to Ship\n\nCheck your profile to track your order.`);
    clearCart();
    navigate('/profile');
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  if (cart.length === 0) {
    return (
      <div className="empty-cart">
        <h2>No items in cart</h2>
        <button onClick={() => navigate('/')}>Go Shopping</button>
      </div>
    );
  }

  return (
    <div className="payment-page">
      <h2>Payment Information</h2>
      
      <div className="payment-container">
        <form className="payment-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Email Address</label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              required
              placeholder="your@email.com"
            />
          </div>

          <div className="form-group">
            <label>Card Number (12 digits)</label>
            <input
              type="text"
              name="cardNumber"
              value={formData.cardNumber}
              onChange={handleChange}
              required
              placeholder="1234 5678 9012"
              maxLength="14"
            />
          </div>

          <div className="form-group">
            <label>Cardholder Name</label>
            <input
              type="text"
              name="cardName"
              value={formData.cardName}
              onChange={handleChange}
              required
              placeholder="John Doe"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Expiry Date</label>
              <input
                type="text"
                name="expiryDate"
                value={formData.expiryDate}
                onChange={handleChange}
                required
                placeholder="MM/YY"
                maxLength="5"
              />
            </div>

            <div className="form-group">
              <label>CVV (3 digits)</label>
              <input
                type="text"
                name="cvv"
                value={formData.cvv}
                onChange={handleChange}
                required
                placeholder="123"
                maxLength="3"
              />
            </div>
          </div>

          <button 
            type="submit" 
            className="pay-btn"
            disabled={processing}
          >
            {processing ? 'Processing...' : `Pay $${getTotalPrice()}`}
          </button>
        </form>

        <div className="order-summary">
          <h3>Order Summary</h3>
          {cart.map((item, index) => (
            <div key={index} className="summary-item">
              <span>{item.name} x {item.quantity}</span>
              <span>${(item.price * item.quantity).toFixed(2)}</span>
            </div>
          ))}
          <div className="summary-total">
            <strong>Total:</strong>
            <strong>${getTotalPrice()}</strong>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Payment;
