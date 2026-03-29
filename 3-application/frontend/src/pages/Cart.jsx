import { useNavigate } from 'react-router-dom';

function Cart({ cart, removeFromCart, updateQuantity }) {
  const navigate = useNavigate();

  const getTotalPrice = () => {
    return cart.reduce((total, item) => total + (item.price * item.quantity), 0).toFixed(2);
  };

  const getTotalItems = () => {
    return cart.reduce((total, item) => total + item.quantity, 0);
  };

  if (cart.length === 0) {
    return (
      <div className="empty-cart">
        <h2>🛒 Your Cart is Empty</h2>
        <p>Add some products to your cart to see them here!</p>
        <button onClick={() => navigate('/')}>Continue Shopping</button>
      </div>
    );
  }

  return (
    <div className="cart-page">
      <h2>Shopping Cart ({getTotalItems()} items)</h2>
      
      <div className="cart-items">
        {cart.map((item, index) => (
          <div key={index} className="cart-item">
            <img src={item.image} alt={item.name} />
            <div className="item-details">
              <h3>{item.name}</h3>
              <p className="category">{item.category}</p>
              <p className="price">${item.price}</p>
            </div>
            <div className="item-quantity">
              <button onClick={() => updateQuantity(index, item.quantity - 1)}>-</button>
              <span>{item.quantity}</span>
              <button onClick={() => updateQuantity(index, item.quantity + 1)}>+</button>
            </div>
            <div className="item-total">
              ${(item.price * item.quantity).toFixed(2)}
            </div>
            <button 
              className="remove-btn"
              onClick={() => removeFromCart(index)}
            >
              Remove
            </button>
          </div>
        ))}
      </div>

      <div className="cart-summary">
        <h3>Order Summary</h3>
        <div className="summary-row">
          <span>Subtotal:</span>
          <span>${getTotalPrice()}</span>
        </div>
        <div className="summary-row">
          <span>Shipping:</span>
          <span>$10.00</span>
        </div>
        <div className="summary-row">
          <span>Tax (10%):</span>
          <span>${(getTotalPrice() * 0.1).toFixed(2)}</span>
        </div>
        <div className="summary-row total">
          <span>Total:</span>
          <span>${(parseFloat(getTotalPrice()) + 10 + parseFloat(getTotalPrice()) * 0.1).toFixed(2)}</span>
        </div>
        <button 
          className="checkout-btn"
          onClick={() => navigate('/payment')}
        >
          Proceed to Checkout
        </button>
      </div>
    </div>
  );
}

export default Cart;
