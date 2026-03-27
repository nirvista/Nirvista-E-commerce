import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
dotenv.config();
import sequelize from "./config/db.js";
import authRoutes from './routes/authRoutes.js';
import userRoutes from './routes/userRoutes.js';
import productRoutes from './routes/productRoutes.js';
import cartRoutes from './routes/cartRoutes.js';
import addressRoutes from './routes/addressRoutes.js';

const app = express();

app.use(cors());
app.use(express.json());

//Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/address', addressRoutes);

app.get('/', (req, res) => {
  res.send('API is running...');
});

const PORT = process.env.PORT || 5000;

sequelize.sync()
.then(() => {
  console.log('Database connected and synced');
  app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
})
.catch((err) => {
  console.error("Database sync failed:", err);
})