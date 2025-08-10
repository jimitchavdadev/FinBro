import express, { Request, Response } from 'express';
import pool from './db';
import { authMiddleware } from './authMiddleware';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET as string;

// Add this health check endpoint
app.get('/api/health', (req: Request, res: Response) => {
    res.status(200).json({ message: 'Server is up and running!' });
});

// Add basic logging middleware
app.use((req: Request, res: Response, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Test database connection
async function testDbConnection() {
    try {
        const result = await pool.query('SELECT NOW()');
        console.log('✅ Database connection successful:', result.rows[0]);
    } catch (error) {
        console.error('❌ Database connection failed:', error);
        process.exit(1);
    }
}

// ➡️ Unified Authentication Endpoint
app.post('/api/auth', async (req: Request, res: Response) => {
    const { phoneNumber, password } = req.body;

    console.log('Auth request received:', { phoneNumber, passwordLength: password?.length });

    if (!phoneNumber || !password) {
        return res.status(400).json({ message: 'Phone number and password are required' });
    }

    // Validate JWT_SECRET
    if (!JWT_SECRET) {
        console.error('❌ JWT_SECRET is not defined in environment variables');
        return res.status(500).json({ message: 'Server configuration error' });
    }

    try {
        // Check if user exists
        console.log('Checking if user exists with phone number:', phoneNumber);
        const userResult = await pool.query('SELECT * FROM users WHERE phone_number = $1', [phoneNumber]);
        const user = userResult.rows[0];

        if (user) {
            console.log('User found, verifying password...');
            // User exists, verify password
            const isPasswordValid = await bcrypt.compare(password, user.password);

            if (!isPasswordValid) {
                console.log('❌ Password validation failed');
                return res.status(401).json({ message: 'Invalid credentials' });
            }

            console.log('✅ Password valid, generating token...');
            // Password is valid, send token
            const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
            return res.status(200).json({ message: 'Login successful', token });
        } else {
            console.log('User not found, creating new user...');
            // User does not exist, create new user
            const hashedPassword = await bcrypt.hash(password, 10);
            console.log('Password hashed, inserting into database...');

            const newUserResult = await pool.query(
                'INSERT INTO users (phone_number, password) VALUES ($1, $2) RETURNING id, phone_number',
                [phoneNumber, hashedPassword]
            );

            const newUser = newUserResult.rows[0];
            console.log('New user created:', { id: newUser.id, phone_number: newUser.phone_number });

            const token = jwt.sign({ userId: newUser.id }, JWT_SECRET, { expiresIn: '7d' });
            return res.status(201).json({ message: 'User registered and logged in successfully', token });
        }
    } catch (error) {
        console.error('❌ Error in authentication:', error);

        // More specific error handling
        if (error instanceof Error) {
            if (error.message.includes('relation "users" does not exist')) {
                return res.status(500).json({
                    message: 'Database table not found. Please ensure the users table exists.'
                });
            }
            if (error.message.includes('connect')) {
                return res.status(500).json({
                    message: 'Database connection failed'
                });
            }
        }

        res.status(500).json({ message: 'Internal server error' });
    }
});

app.post('/api/expenses', authMiddleware, async (req: Request, res: Response) => {
    const { amount, date, category, notes } = req.body;
    const userId = req.user?.userId;

    if (!userId || !amount || !date || !category) {
        return res.status(400).json({ message: 'Missing required fields' });
    }

    try {
        // Change: Convert the incoming date string to a Date object
        const expenseDate = new Date(date);

        const newExpense = await pool.query(
            // Change: Use the TIMESTAMP WITH TIME ZONE data type
            'INSERT INTO expenses (user_id, amount, date, category, notes) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, amount, expenseDate, category, notes]
        );
        res.status(201).json(newExpense.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Get History Endpoint - FIXED VERSION
app.get('/api/history', authMiddleware, async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const { category } = req.query;

    if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
    }

    try {
        // FIXED: Include 'id' in the SELECT statement
        let query = 'SELECT id, amount, date, category, notes FROM expenses WHERE user_id = $1';
        const params = [userId];

        if (category) {
            query += ' AND category = $2';
            params.push(category as string);
        }

        query += ' ORDER BY date DESC';
        const history = await pool.query(query, params);
        res.status(200).json(history.rows);
    } catch (err) {
        console.error('❌ Error fetching history:', err);
        res.status(500).json({ message: 'Failed to fetch history' });
    }
});

// Delete Expense Endpoint - ADD THIS
app.delete('/api/expenses/:id', authMiddleware, async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const expenseId = parseInt(req.params.id);

    if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
    }

    if (isNaN(expenseId)) {
        return res.status(400).json({ message: 'Invalid expense ID' });
    }

    try {
        // First check if the expense exists and belongs to the user
        const checkResult = await pool.query(
            'SELECT id FROM expenses WHERE id = $1 AND user_id = $2',
            [expenseId, userId]
        );

        if (checkResult.rows.length === 0) {
            return res.status(404).json({ message: 'Expense not found or not authorized to delete' });
        }

        // Delete the expense
        await pool.query(
            'DELETE FROM expenses WHERE id = $1 AND user_id = $2',
            [expenseId, userId]
        );

        res.status(204).send(); // No content response for successful deletion
    } catch (err) {
        console.error('❌ Error deleting expense:', err);
        res.status(500).json({ message: 'Failed to delete expense' });
    }
});

// Start server and test database connection
async function startServer() {
    try {
        await testDbConnection();
        app.listen(PORT, () => {
            console.log(`🚀 Server running on port ${PORT}`);
        });
    } catch (error) {
        console.error('❌ Failed to start server:', error);
        process.exit(1);
    }
}

startServer();