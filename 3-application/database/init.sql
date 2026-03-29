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

-- Insert 24 products (12 Men's + 12 Women's) for 3 pages with 8 products per page
INSERT INTO products (name, category, price, image, stock, description) VALUES
-- MEN'S PRODUCTS (12 products)
-- Men's Shoes (4 products)
('Men''s Leather Oxford Shoes', 'Men Shoes', 129.99, 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=400', 45, 'Classic leather oxford shoes for formal occasions'),
('Men''s Running Sneakers', 'Men Shoes', 89.99, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 80, 'Comfortable running shoes with cushioned sole'),
('Men''s Casual Loafers', 'Men Shoes', 79.99, 'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=400', 60, 'Slip-on loafers perfect for casual wear'),
('Men''s Sports Trainers', 'Men Shoes', 99.99, 'https://images.unsplash.com/photo-1605348532760-6753d2c43329?w=400', 70, 'High-performance sports training shoes'),

-- Men's Clothing (4 products)
('Men''s Denim Jeans', 'Men Clothing', 69.99, 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400', 100, 'Classic blue denim jeans'),
('Men''s Casual T-Shirt', 'Men Clothing', 24.99, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400', 150, 'Comfortable cotton t-shirt'),
('Men''s Formal Shirt', 'Men Clothing', 49.99, 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400', 90, 'Professional formal shirt'),
('Men''s Hoodie', 'Men Clothing', 59.99, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400', 75, 'Warm and comfortable hoodie'),

-- Men's Accessories (4 products)
('Men''s Leather Wallet', 'Men Accessories', 49.99, 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=400', 120, 'Genuine leather bifold wallet'),
('Men''s Sunglasses', 'Men Accessories', 89.99, 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400', 85, 'UV protection aviator sunglasses'),
('Men''s Watch', 'Men Accessories', 199.99, 'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400', 50, 'Elegant analog wristwatch'),
('Men''s Leather Belt', 'Men Accessories', 39.99, 'https://images.unsplash.com/photo-1624222247344-550fb60583bb?w=400', 95, 'Classic leather belt'),

-- WOMEN'S PRODUCTS (12 products)
-- Women's Shoes (4 products)
('Women''s High Heels', 'Women Shoes', 119.99, 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400', 55, 'Elegant high heel shoes'),
('Women''s Sneakers', 'Women Shoes', 79.99, 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400', 90, 'Comfortable casual sneakers'),
('Women''s Sandals', 'Women Shoes', 59.99, 'https://images.unsplash.com/photo-1603487742131-4160ec999306?w=400', 70, 'Summer sandals with ankle strap'),
('Women''s Boots', 'Women Shoes', 149.99, 'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=400', 40, 'Stylish ankle boots'),

-- Women's Clothing (4 products)
('Women''s Summer Dress', 'Women Clothing', 79.99, 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400', 65, 'Light and breezy summer dress'),
('Women''s Evening Gown', 'Women Clothing', 199.99, 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400', 30, 'Elegant evening gown'),
('Women''s Blouse', 'Women Clothing', 44.99, 'https://images.unsplash.com/photo-1564257577-4f0b4c8c8f1c?w=400', 85, 'Stylish office blouse'),
('Women''s Jeans', 'Women Clothing', 69.99, 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400', 95, 'Skinny fit denim jeans'),

-- Women's Accessories (4 products)
('Women''s Designer Handbag', 'Women Accessories', 249.99, 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400', 35, 'Luxury designer handbag'),
('Women''s Sunglasses', 'Women Accessories', 79.99, 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400', 75, 'Fashionable cat-eye sunglasses'),
('Women''s Jewelry Set', 'Women Accessories', 129.99, 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400', 60, 'Elegant necklace and earring set'),
('Women''s Scarf', 'Women Accessories', 34.99, 'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=400', 100, 'Silk scarf with floral pattern');

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
