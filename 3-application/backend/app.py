from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DATABASE_HOST', 'postgres-service'),
    'port': os.getenv('DATABASE_PORT', '5432'),
    'database': os.getenv('DATABASE_NAME', 'shopease'),
    'user': os.getenv('DATABASE_USER', 'shopease'),
    'password': os.getenv('DATABASE_PASSWORD', 'changeme')
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()})

@app.route('/api/products', methods=['GET'])
def get_products():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, name, category, price, image, stock FROM products')
        products = []
        for row in cur.fetchall():
            products.append({
                'id': row[0],
                'name': row[1],
                'category': row[2],
                'price': float(row[3]),
                'image': row[4],
                'stock': row[5]
            })
        cur.close()
        conn.close()
        return jsonify(products)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, name, category, price, image, stock, description FROM products WHERE id = %s', (product_id,))
        row = cur.fetchone()
        if row:
            product = {
                'id': row[0],
                'name': row[1],
                'category': row[2],
                'price': float(row[3]),
                'image': row[4],
                'stock': row[5],
                'description': row[6]
            }
            cur.close()
            conn.close()
            return jsonify(product)
        else:
            return jsonify({'error': 'Product not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/orders', methods=['POST'])
def create_order():
    try:
        data = request.json
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO orders (customer_email, total_amount, status) VALUES (%s, %s, %s) RETURNING id',
            (data['email'], data['total'], 'pending')
        )
        order_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'order_id': order_id, 'status': 'success'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
