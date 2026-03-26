-- ShopEase Database Schema

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    image VARCHAR(500),
    stock INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_email VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Sample data
INSERT INTO products (name, category, price, image, stock, description) VALUES
('Classic Leather Shoes', 'Shoes', 89.99, 'https://via.placeholder.com/300x300?text=Leather+Shoes', 50, 'Premium leather shoes for formal occasions'),
('Running Sneakers', 'Shoes', 129.99, 'https://via.placeholder.com/300x300?text=Sneakers', 100, 'Comfortable running shoes with cushioned sole'),
('Designer Handbag', 'Bags', 249.99, 'https://via.placeholder.com/300x300?text=Handbag', 30, 'Elegant designer handbag for everyday use'),
('Travel Backpack', 'Bags', 79.99, 'https://via.placeholder.com/300x300?text=Backpack', 75, 'Spacious backpack perfect for travel'),
('Summer Dress', 'Dress', 59.99, 'https://via.placeholder.com/300x300?text=Summer+Dress', 60, 'Light and breezy summer dress'),
('Evening Gown', 'Dress', 199.99, 'https://via.placeholder.com/300x300?text=Evening+Gown', 20, 'Elegant evening gown for special occasions'),
('Casual T-Shirt', 'Clothing', 24.99, 'https://via.placeholder.com/300x300?text=T-Shirt', 200, 'Comfortable cotton t-shirt'),
('Denim Jeans', 'Clothing', 69.99, 'https://via.placeholder.com/300x300?text=Jeans', 150, 'Classic denim jeans'),
('Leather Wallet', 'Accessories', 39.99, 'https://via.placeholder.com/300x300?text=Wallet', 100, 'Genuine leather wallet'),
('Sunglasses', 'Accessories', 149.99, 'https://via.placeholder.com/300x300?text=Sunglasses', 80, 'UV protection sunglasses');

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
