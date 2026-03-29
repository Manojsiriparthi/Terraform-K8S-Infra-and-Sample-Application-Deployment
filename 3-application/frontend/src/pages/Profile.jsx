import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

function Profile() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [orders, setOrders] = useState([]);
  const [showCreateProfile, setShowCreateProfile] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    address: ''
  });

  useEffect(() => {
    // Load profile from localStorage
    const savedProfile = localStorage.getItem('userProfile');
    if (savedProfile) {
      setProfile(JSON.parse(savedProfile));
    }

    // Load orders from localStorage
    const savedOrders = localStorage.getItem('orders');
    if (savedOrders) {
      setOrders(JSON.parse(savedOrders));
    }
  }, []);

  const handleCreateProfile = (e) => {
    e.preventDefault();
    const newProfile = {
      ...formData,
      memberSince: new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    };
    localStorage.setItem('userProfile', JSON.stringify(newProfile));
    setProfile(newProfile);
    setShowCreateProfile(false);
    alert('✅ Profile created successfully!');
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const getOrderStatus = (order) => {
    const daysSinceOrder = Math.floor((new Date() - new Date(order.date)) / (1000 * 60 * 60 * 24));
    if (daysSinceOrder === 0) return { status: 'Processing', color: '#f59e0b', icon: '⏳' };
    if (daysSinceOrder === 1) return { status: 'Ready to Ship', color: '#3b82f6', icon: '📦' };
    if (daysSinceOrder <= 3) return { status: 'Shipped', color: '#8b5cf6', icon: '🚚' };
    return { status: 'Delivered', color: '#10b981', icon: '✅' };
  };

  if (!profile) {
    return (
      <div className="profile-page">
        <div className="no-profile">
          <h2>👤 Welcome to ShopEase</h2>
          <p>Create your profile to track orders and save your information</p>
          
          {!showCreateProfile ? (
            <button 
              className="create-profile-btn"
              onClick={() => setShowCreateProfile(true)}
            >
              Create Profile
            </button>
          ) : (
            <form className="create-profile-form" onSubmit={handleCreateProfile}>
              <h3>Create Your Profile</h3>
              
              <div className="form-group">
                <label>Full Name</label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  required
                  placeholder="John Doe"
                />
              </div>

              <div className="form-group">
                <label>Email Address</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                  placeholder="john.doe@example.com"
                />
              </div>

              <div className="form-group">
                <label>Phone Number</label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  required
                  placeholder="+1 (555) 123-4567"
                />
              </div>

              <div className="form-group">
                <label>Address</label>
                <textarea
                  name="address"
                  value={formData.address}
                  onChange={handleChange}
                  required
                  placeholder="123 Main St, City, State, ZIP"
                  rows="3"
                />
              </div>

              <div className="form-actions">
                <button type="submit" className="submit-btn">Create Profile</button>
                <button 
                  type="button" 
                  className="cancel-btn"
                  onClick={() => setShowCreateProfile(false)}
                >
                  Cancel
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="profile-page">
      <h2>👤 My Profile</h2>
      
      <div className="profile-section">
        <div className="section-header">
          <h3>Account Information</h3>
          <button 
            className="edit-btn"
            onClick={() => {
              setFormData({
                name: profile.name,
                email: profile.email,
                phone: profile.phone,
                address: profile.address
              });
              setShowCreateProfile(true);
            }}
          >
            Edit Profile
          </button>
        </div>
        <div className="info-grid">
          <div className="info-row">
            <span className="label">Name:</span>
            <span className="value">{profile.name}</span>
          </div>
          <div className="info-row">
            <span className="label">Email:</span>
            <span className="value">{profile.email}</span>
          </div>
          <div className="info-row">
            <span className="label">Phone:</span>
            <span className="value">{profile.phone}</span>
          </div>
          <div className="info-row">
            <span className="label">Address:</span>
            <span className="value">{profile.address}</span>
          </div>
          <div className="info-row">
            <span className="label">Member Since:</span>
            <span className="value">{profile.memberSince}</span>
          </div>
        </div>
      </div>

      <div className="profile-section">
        <h3>📦 Order History</h3>
        {orders.length === 0 ? (
          <div className="empty-state">
            <p>No orders yet. Start shopping to see your order history!</p>
            <button onClick={() => navigate('/')}>Start Shopping</button>
          </div>
        ) : (
          <div className="orders-list">
            {orders.map((order, index) => {
              const statusInfo = getOrderStatus(order);
              return (
                <div key={index} className="order-card">
                  <div className="order-header">
                    <div className="order-id">
                      <strong>Order #{order.id}</strong>
                      <span className="order-date">
                        {new Date(order.date).toLocaleDateString('en-US', { 
                          month: 'short', 
                          day: 'numeric', 
                          year: 'numeric' 
                        })}
                      </span>
                    </div>
                    <div className="order-status" style={{ color: statusInfo.color }}>
                      <span className="status-icon">{statusInfo.icon}</span>
                      <span className="status-text">{statusInfo.status}</span>
                    </div>
                  </div>
                  
                  <div className="order-items">
                    {order.items.map((item, idx) => (
                      <div key={idx} className="order-item">
                        <span>{item.name} x {item.quantity}</span>
                        <span>${(item.price * item.quantity).toFixed(2)}</span>
                      </div>
                    ))}
                  </div>
                  
                  <div className="order-footer">
                    <div className="order-total">
                      <strong>Total:</strong>
                      <strong>${order.total}</strong>
                    </div>
                    <div className="tracking-info">
                      {statusInfo.status === 'Shipped' && (
                        <span className="tracking-number">
                          📍 Tracking: TRK{order.id}US
                        </span>
                      )}
                      {statusInfo.status === 'Delivered' && (
                        <span className="delivered-badge">
                          ✅ Delivered
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {showCreateProfile && (
        <div className="modal-overlay" onClick={() => setShowCreateProfile(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <form className="create-profile-form" onSubmit={handleCreateProfile}>
              <h3>Edit Profile</h3>
              
              <div className="form-group">
                <label>Full Name</label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="form-group">
                <label>Email Address</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="form-group">
                <label>Phone Number</label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="form-group">
                <label>Address</label>
                <textarea
                  name="address"
                  value={formData.address}
                  onChange={handleChange}
                  required
                  rows="3"
                />
              </div>

              <div className="form-actions">
                <button type="submit" className="submit-btn">Save Changes</button>
                <button 
                  type="button" 
                  className="cancel-btn"
                  onClick={() => setShowCreateProfile(false)}
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Profile;
