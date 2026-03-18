import { Sequelize } from "sequelize";
import dotenv from 'dotenv';
dotenv.config();
const sequelize = new Sequelize(process.env.PG_NAME, process.env.PG_OWNER, process.env.PG_PASSWORD, {
  host: process.env.PG_HOST || 'localhost',
  dialect: 'postgres'
});

export default sequelize;