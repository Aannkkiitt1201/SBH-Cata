import express from 'express';
import { createServer as createViteServer } from 'vite';
import Database from 'better-sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';
import session from 'express-session';
import bcrypt from 'bcryptjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const db = new Database('catalogue.db');

// Initialize database
db.exec(`
  CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    name TEXT NOT NULL,
    description TEXT,
    price TEXT,
    image TEXT,
    FOREIGN KEY (category_id) REFERENCES categories(id)
  );

  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT
  );

  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL
  );
`);

// Seed initial data if empty
const categoryCount = db.prepare('SELECT COUNT(*) as count FROM categories').get() as { count: number };
if (categoryCount.count === 0) {
  db.prepare('INSERT INTO categories (name) VALUES (?)').run('General');
  db.prepare('INSERT INTO settings (key, value) VALUES (?, ?)').run('banner_text', 'Welcome to our Catalogue');
}

// Force update admin credentials to ensure they are correct
const hashedPassword = bcrypt.hashSync('priyankacho8146', 10);
const existingUser = db.prepare('SELECT * FROM users WHERE username = ?').get('shreebabahandicraft') as any;
if (existingUser) {
  db.prepare('UPDATE users SET password = ? WHERE id = ?').run(hashedPassword, existingUser.id);
} else {
  // Check if 'admin' exists and rename it
  const adminUser = db.prepare('SELECT * FROM users WHERE username = ?').get('admin') as any;
  if (adminUser) {
    db.prepare('UPDATE users SET username = ?, password = ? WHERE id = ?').run('shreebabahandicraft', hashedPassword, adminUser.id);
  } else {
    // Create new if none of the above
    db.prepare('INSERT INTO users (username, password) VALUES (?, ?)').run('shreebabahandicraft', hashedPassword);
  }
}

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Trust proxy is required for secure cookies behind a load balancer/proxy
  app.set('trust proxy', 1);

  app.use(express.json({ limit: '200mb' }));
  app.use(session({
    secret: 'sbh-cata-secret-123-v2',
    resave: true,
    saveUninitialized: true,
    proxy: true,
    name: 'sbh_cata_sid',
    cookie: {
      secure: true,
      sameSite: 'none',
      maxAge: 1000 * 60 * 60 * 24, // 24 hours
      httpOnly: true
    }
  }));

  // Auth Middleware - Disabled as per request
  const requireAuth = (req: express.Request, res: express.Response, next: express.NextFunction) => {
    next();
  };

  // Auth Routes
  app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    console.log(`Login attempt for: ${username}`);
    
    const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username) as any;
    
    if (user) {
      const isMatch = bcrypt.compareSync(password, user.password);
      if (isMatch) {
        (req.session as any).userId = user.id;
        (req.session as any).username = user.username;
        
        req.session.save((err) => {
          if (err) {
            console.error('Session save error:', err);
            return res.status(500).json({ error: 'Failed to save session' });
          }
          console.log(`Login successful for: ${username}`);
          res.json({ success: true, user: { id: user.id, username: user.username } });
        });
        return;
      }
    }
    
    console.log(`Login failed for: ${username}`);
    res.status(401).json({ error: 'Invalid credentials' });
  });

  app.post('/api/logout', (req, res) => {
    req.session.destroy(() => {
      res.json({ success: true });
    });
  });

  app.get('/api/me', (req, res) => {
    if ((req.session as any).userId) {
      const user = db.prepare('SELECT id, username FROM users WHERE id = ?').get((req.session as any).userId) as any;
      res.json(user);
    } else {
      res.status(401).json({ error: 'Not logged in' });
    }
  });

  // API Routes
  app.get('/api/categories', (req, res) => {
    try {
      const categories = db.prepare('SELECT * FROM categories ORDER BY name ASC').all();
      res.json(categories);
    } catch (err) {
      console.error('Error fetching categories:', err);
      res.status(500).json({ error: 'Failed to fetch categories' });
    }
  });

  app.post('/api/categories', requireAuth, (req, res) => {
    try {
      const { name } = req.body;
      if (!name) return res.status(400).json({ error: 'Category name is required' });
      
      console.log('Adding category:', name);
      const info = db.prepare('INSERT INTO categories (name) VALUES (?)').run(name);
      res.json({ id: info.lastInsertRowid, name });
    } catch (err) {
      console.error('Error adding category:', err);
      res.status(500).json({ error: 'Failed to add category' });
    }
  });

  app.delete('/api/categories/:id', requireAuth, (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) return res.status(400).json({ error: 'Invalid category ID' });
      
      console.log('Deleting category:', id);
      // Optional: Check if products exist in this category
      const productCount = db.prepare('SELECT COUNT(*) as count FROM products WHERE category_id = ?').get(id) as any;
      if (productCount.count > 0) {
        console.log(`Warning: Deleting category ${id} which has ${productCount.count} products`);
        // Set products in this category to NULL to avoid FK constraint issues
        db.prepare('UPDATE products SET category_id = NULL WHERE category_id = ?').run(id);
      }
      
      const info = db.prepare('DELETE FROM categories WHERE id = ?').run(id);
      console.log('Delete result:', info);
      res.json({ success: true, changes: info.changes });
    } catch (err) {
      console.error('Error deleting category:', err);
      res.status(500).json({ error: 'Failed to delete category' });
    }
  });

  app.delete('/api/categories', requireAuth, (req, res) => {
    try {
      console.log('Deleting all categories');
      // Set all products category_id to NULL first to avoid FK constraint issues
      db.prepare('UPDATE products SET category_id = NULL').run();
      const info = db.prepare('DELETE FROM categories').run();
      console.log('Delete result:', info);
      res.json({ success: true, changes: info.changes });
    } catch (err) {
      console.error('Error deleting all categories:', err);
      res.status(500).json({ error: 'Failed to delete all categories' });
    }
  });

  app.get('/api/products', (req, res) => {
    try {
      const products = db.prepare('SELECT * FROM products ORDER BY id DESC').all();
      res.json(products);
    } catch (err) {
      console.error('Error fetching products:', err);
      res.status(500).json({ error: 'Failed to fetch products' });
    }
  });

  app.post('/api/products', requireAuth, (req, res) => {
    try {
      const { category_id, name, description, price, image } = req.body;
      if (!name || !category_id) return res.status(400).json({ error: 'Name and Category are required' });
      
      console.log('Adding product:', name);
      const info = db.prepare('INSERT INTO products (category_id, name, description, price, image) VALUES (?, ?, ?, ?, ?)').run(
        category_id, 
        name, 
        description || '', 
        price || '', 
        image || null
      );
      res.json({ id: info.lastInsertRowid, category_id, name, description, price, image });
    } catch (err) {
      console.error('Error adding product:', err);
      res.status(500).json({ error: 'Failed to add product' });
    }
  });

  app.post('/api/products/bulk', requireAuth, (req, res) => {
    try {
      const { products } = req.body;
      if (!Array.isArray(products)) return res.status(400).json({ error: 'Products must be an array' });
      
      console.log(`Bulk adding ${products.length} products`);
      
      const insert = db.prepare('INSERT INTO products (category_id, name, description, price, image) VALUES (?, ?, ?, ?, ?)');
      
      const transaction = db.transaction((prods) => {
        for (const p of prods) {
          insert.run(
            p.category_id,
            p.name,
            p.description || '',
            p.price || '',
            p.image || null
          );
        }
      });
      
      transaction(products);
      res.json({ success: true, count: products.length });
    } catch (err) {
      console.error('Error bulk adding products:', err);
      res.status(500).json({ error: 'Failed to bulk add products' });
    }
  });

  app.put('/api/products/:id', requireAuth, (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) return res.status(400).json({ error: 'Invalid product ID' });
      
      const { category_id, name, description, price, image } = req.body;
      if (!name || !category_id) return res.status(400).json({ error: 'Name and Category are required' });

      console.log('Updating product:', id, name);
      const info = db.prepare('UPDATE products SET category_id = ?, name = ?, description = ?, price = ?, image = ? WHERE id = ?').run(
        category_id, 
        name, 
        description || '', 
        price || '', 
        image || null, 
        id
      );
      
      if (info.changes === 0) {
        return res.status(404).json({ error: 'Product not found' });
      }
      
      res.json({ success: true, changes: info.changes });
    } catch (err) {
      console.error('Error updating product:', err);
      res.status(500).json({ error: 'Failed to update product' });
    }
  });

  app.delete('/api/products/:id', requireAuth, (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) return res.status(400).json({ error: 'Invalid product ID' });
      
      console.log('Deleting product:', id);
      const info = db.prepare('DELETE FROM products WHERE id = ?').run(id);
      console.log('Delete result:', info);
      
      if (info.changes === 0) {
        return res.status(404).json({ error: 'Product not found' });
      }
      
      res.json({ success: true, changes: info.changes });
    } catch (err) {
      console.error('Error deleting product:', err);
      res.status(500).json({ error: 'Failed to delete product' });
    }
  });

  app.get('/api/settings', (req, res) => {
    const settings = db.prepare('SELECT * FROM settings').all();
    const settingsObj = settings.reduce((acc: any, curr: any) => {
      acc[curr.key] = curr.value;
      return acc;
    }, {});
    res.json(settingsObj);
  });

  app.post('/api/settings', requireAuth, (req, res) => {
    const { key, value } = req.body;
    db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)').run(key, value);
    res.json({ success: true });
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    app.use(express.static(path.join(__dirname, 'dist')));
    app.get('*', (req, res) => {
      res.sendFile(path.join(__dirname, 'dist', 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
