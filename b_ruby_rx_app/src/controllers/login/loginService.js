const pool = require('../../config/dbConnection');
const STATUS = require('../../utils/constants').STATUS;

exports.getUserDataFromDB = async function (email) {
    try {
        const query = 'SELECT user_id, full_name, email, picture, source_id, user_type FROM users WHERE email = $1';
        const { rows } = await pool.query(query, [email]);
        return { status: STATUS.SUCCESS, data: rows[0] || null };
    } catch (error) {
        return { status: STATUS.FAILURE, message: 'Database query error', error };
    }
}

exports.createUserInDB = async function (userData) {
    try {
        const columns = Object.keys(userData).join(', ');
        const values = Object.values(userData);
        const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

        const query = `INSERT INTO public.users (${columns}) VALUES (${placeholders}) RETURNING *`;
        const { rows, error } = await pool.query(query, values);
        if (error) return { status: STATUS.FAILURE, message: "Database query error" };
        return { status: STATUS.SUCCESS, data: { id: rows[0].id, ...userData } };
    } catch (error) {
        return { status: STATUS.FAILURE, message: 'Database query error', error };
    }
}
