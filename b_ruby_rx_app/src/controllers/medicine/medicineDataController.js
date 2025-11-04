const { medicinePool } = require('../../config/multiDbConnection');
const { STATUS } = require('../../utils/constants');

exports.getPopularMedicines = async (req, res, next) => {
    const client = await medicinePool.connect();

    try {
        const {
            limit = 10,
            type = ''
        } = req.query;

        // Define popular medicine IDs as per requirements
        const popularMedicineIds = [13795, 46743, 6508, 48998, 19412, 24054, 125520, 10061, 84278];

        // Validate and cap the limit
        const medicineLimit = Math.min(Math.max(parseInt(limit) || 10, 1), 50);

        let whereClause = 'WHERE md.is_active = 1 AND md.is_deactivated = 0 AND md.med_id = ANY($1)';
        let queryParams = [popularMedicineIds];
        let paramIndex = 2;

        // Add type filter if provided
        if (type && type.trim()) {
            whereClause += ` AND md.med_type ILIKE $${paramIndex}`;
            queryParams.push(`%${type.trim()}%`);
            paramIndex++;
        }

        // Query to get popular medicines
        // Prioritize by the order in the popularMedicineIds array
        const popularMedicinesQuery = `
            SELECT 
                md.*,
                CASE 
                    WHEN md.med_type ILIKE '%tablet%' THEN 1
                    WHEN md.med_type ILIKE '%capsule%' THEN 2
                    WHEN md.med_type ILIKE '%syrup%' THEN 3
                    WHEN md.med_type ILIKE '%injection%' THEN 4
                    ELSE 5
                END as type_priority
            FROM med_details md
            ${whereClause}
            ORDER BY 
                array_position($1, md.med_id),
                type_priority ASC,
                md.med_brand_name ASC
            LIMIT $${paramIndex}
        `;

        queryParams.push(medicineLimit);

        const result = await client.query(popularMedicinesQuery, queryParams);

        res.locals = {
            status: STATUS.SUCCESS,
            message: `Retrieved top ${result.rows.length} popular medicines`,
            data: {
                medicines: result.rows,
                count: result.rows.length,
                limit: medicineLimit,
                filter: type ? { type } : null
            }
        };

    } catch (error) {
        console.error('❌ Get popular medicines error:', error);

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to retrieve popular medicines'
        };
    } finally {
        client.release();
    }

    next();
};
