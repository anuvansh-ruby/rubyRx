const { medicinePool } = require('../../config/multiDbConnection');
const { STATUS } = require('../../utils/constants');

exports.getMedicineSubstitutes = async (req, res, next) => {
    const client = await medicinePool.connect();

    try {
        const { compositionId1, compositionId2 } = req.params;
        const {
            limit = 20,
            excludeMedId = '',
            sortBy = 'price' // 'price', 'name', 'manufacturer'
        } = req.query;

        console.log('🔍 [SUBSTITUTES] Request received:');
        console.log(`   Composition 1: ${compositionId1}`);
        console.log(`   Composition 2: ${compositionId2 || '(none)'}`);
        console.log(`   Exclude Med ID: ${excludeMedId || '(none)'}`);
        console.log(`   Sort By: ${sortBy}`);
        console.log(`   Limit: ${limit}`);

        // Validate composition ID
        if (!compositionId1 || compositionId1 === '0' || compositionId1 === 'null' || compositionId1 === 'undefined') {
            console.log('❌ [SUBSTITUTES] Invalid composition ID provided');
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Invalid composition ID provided'
            };
            return next();
        }

        // Validate composition ID is a number
        const comp1 = parseInt(compositionId1);
        if (isNaN(comp1) || comp1 <= 0) {
            console.log(`❌ [SUBSTITUTES] Invalid composition ID format: ${compositionId1}`);
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Composition ID must be a positive integer'
            };
            return next();
        }

        let whereClause = 'WHERE md.is_active = 1 AND md.is_deactivated = 0';
        let queryParams = [comp1];
        let paramIndex = 2;

        // Add primary composition filter
        whereClause += ` AND md.med_composition_id_1 = $1`;
        console.log(`✓ [SUBSTITUTES] Filtering by composition 1: ${comp1}`);

        // Add secondary composition filter if provided
        if (compositionId2 && compositionId2 !== '0' && compositionId2 !== 'null' && compositionId2 !== 'undefined') {
            const comp2 = parseInt(compositionId2);
            if (!isNaN(comp2) && comp2 > 0) {
                whereClause += ` AND md.med_composition_id_2 = $${paramIndex}`;
                queryParams.push(comp2);
                paramIndex++;
                console.log(`✓ [SUBSTITUTES] Filtering by composition 2: ${comp2}`);
            }
        } else {
            // If no second composition, filter for medicines with only one composition
            whereClause += ` AND (md.med_composition_id_2 IS NULL OR md.med_composition_id_2 = 0)`;
            console.log('✓ [SUBSTITUTES] Filtering for single-composition medicines only');
        }

        // Exclude the original medicine from results
        if (excludeMedId && excludeMedId !== '0' && excludeMedId !== 'null') {
            const excludeId = parseInt(excludeMedId);
            if (!isNaN(excludeId) && excludeId > 0) {
                whereClause += ` AND md.med_id != $${paramIndex}`;
                queryParams.push(excludeId);
                paramIndex++;
                console.log(`✓ [SUBSTITUTES] Excluding medicine ID: ${excludeId}`);
            }
        }

        // Determine sort order
        let orderByClause = 'md.med_type desc, md.med_weightage asc';
        if (sortBy === 'name') {
            orderByClause = 'md.med_name ASC';
        } else if (sortBy === 'manufacturer') {
            orderByClause = 'md.med_manufacturer_name ASC, md.med_price ASC';
        }
        console.log(`✓ [SUBSTITUTES] Sort order: ${sortBy} (${orderByClause})`);

        const substitutesQuery = `
            SELECT 
                md.med_id,
                md.med_brand_name as med_name,
                md.med_composition_id_1 as short_composition_1,
                CONCAT(md.med_composition_strength_1, md.med_composition_unit_1) as short_composition_1_dose,
                md.med_composition_id_2 as short_composition_2,
                CONCAT(md.med_composition_strength_2, md.med_composition_unit_2) as short_composition_2_dose,
                md.med_pack_size as pack_size_label,
                md.med_price as price,
                md.med_manufacturer_name as manufacturer_name,
                md.med_type as medicin_type,
                md.med_composition_name_1 as composition_1_name,
                md.med_composition_name_2 as composition_2_name,
                md.med_weightage
            FROM med_details md
            ${whereClause}
            ORDER BY ${orderByClause}
            LIMIT $${paramIndex}
        `;

        queryParams.push(parseInt(limit));

        console.log('🔍 [SUBSTITUTES] Executing query...');
        console.log(`   Query params: [${queryParams.join(', ')}]`);

        const result = await client.query(substitutesQuery, queryParams);

        console.log(`✅ [SUBSTITUTES] Found ${result.rows.length} substitute medicines`);

        // Get composition names for response
        let compositionInfo = null;
        if (result.rows.length > 0) {
            compositionInfo = {
                composition_1_id: comp1,
                composition_1_name: result.rows[0].composition_1_name,
                composition_1_dose: result.rows[0].short_composition_1_dose,
            };

            if (compositionId2 && compositionId2 !== '0' && compositionId2 !== 'null' && compositionId2 !== 'undefined') {
                const comp2 = parseInt(compositionId2);
                if (!isNaN(comp2) && comp2 > 0) {
                    compositionInfo.composition_2_id = comp2;
                    compositionInfo.composition_2_name = result.rows[0].composition_2_name;
                    compositionInfo.composition_2_dose = result.rows[0].short_composition_2_dose;
                }
            }

            console.log('📋 [SUBSTITUTES] Composition info:');
            console.log(`   ${compositionInfo.composition_1_name} (${compositionInfo.composition_1_dose})`);
            if (compositionInfo.composition_2_name) {
                console.log(`   + ${compositionInfo.composition_2_name} (${compositionInfo.composition_2_dose})`);
            }
        } else {
            console.log('⚠️ [SUBSTITUTES] No substitutes found - returning empty list');
        }

        res.locals = {
            status: STATUS.SUCCESS,
            data: {
                substitutes: result.rows,
                composition_info: compositionInfo,
                total_found: result.rows.length,
                sort_by: sortBy
            }
        };

    } catch (error) {
        console.error('❌ [SUBSTITUTES] Error:', error.message);
        console.error('📚 [SUBSTITUTES] Stack:', error.stack);

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to retrieve medicine substitutes',
            error: error.message
        };
    } finally {
        client.release();
    }

    next();
};

/**
 * Get detailed medicine information with substitutes
 * GET /api/v1/medicine-data/:id/details
 * 
 * Returns medicine details along with available substitutes
 */
exports.getMedicineWithSubstitutes = async (req, res, next) => {
    const client = await medicinePool.connect();

    try {
        const { id } = req.params;
        const { limit = 20 } = req.query;

        // Get medicine details
        const medicineQuery = `
            SELECT 
                md.med_id,
                md.med_brand_name as med_name,
                md.med_composition_id_1 as short_composition_1,
                CONCAT(md.med_composition_strength_1, md.med_composition_unit_1) as short_composition_1_dose,
                md.med_composition_id_2 as short_composition_2,
                CONCAT(md.med_composition_strength_2, md.med_composition_unit_2) as short_composition_2_dose,
                md.med_pack_size as pack_size_label,
                md.med_price as price,
                md.med_manufacturer_name as manufacturer_name,
                md.med_type as medicin_type,
                md.is_deactivated as is_discontinued,
                md.med_composition_name_1 as composition_1_name,
                md.med_composition_name_2 as composition_2_name,
                md.med_weightage
            FROM med_details md
            WHERE md.med_id = $1 AND md.is_active = 1
        `;

        const medicineResult = await client.query(medicineQuery, [id]);

        if (medicineResult.rows.length === 0) {
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Medicine not found'
            };
            return next();
        }

        const medicine = medicineResult.rows[0];

        // Get substitutes if medicine has valid compositions
        let substitutes = [];
        if (medicine.short_composition_1 && medicine.short_composition_1 !== 0) {
            let substituteWhereClause = `WHERE md.is_active = 1 AND md.is_deactivated = 0 
                AND md.med_composition_id_1 = $1 
                AND md.med_id != $2`;

            let substituteParams = [medicine.short_composition_1, id];
            let paramIndex = 3;

            // Match second composition if present
            if (medicine.short_composition_2 && medicine.short_composition_2 !== 0) {
                substituteWhereClause += ` AND md.med_composition_id_2 = $${paramIndex}`;
                substituteParams.push(medicine.short_composition_2);
                paramIndex++;
            } else {
                substituteWhereClause += ` AND (md.med_composition_id_2 IS NULL OR md.med_composition_id_2 = 0)`;
            }

            const substitutesQuery = `
                SELECT 
                    md.med_id,
                    md.med_brand_name as med_name,
                    md.med_composition_id_1 as short_composition_1,
                    CONCAT(md.med_composition_strength_1, md.med_composition_unit_1) as short_composition_1_dose,
                    md.med_composition_id_2 as short_composition_2,
                    CONCAT(md.med_composition_strength_2, md.med_composition_unit_2) as short_composition_2_dose,
                    md.med_pack_size as pack_size_label,
                    md.med_price as price,
                    md.med_manufacturer_name as manufacturer_name,
                    md.med_type as medicin_type,
                    md.med_composition_name_1 as composition_1_name,
                    md.med_composition_name_2 as composition_2_name,
                    md.med_weightage
                FROM med_details md
                ${substituteWhereClause}
                ORDER BY md.med_price ASC, md.med_brand_name ASC
                LIMIT $${paramIndex}
            `;

            substituteParams.push(parseInt(limit));

            const substitutesResult = await client.query(substitutesQuery, substituteParams);
            substitutes = substitutesResult.rows;
        }

        res.locals = {
            status: STATUS.SUCCESS,
            data: {
                medicine: medicine,
                substitutes: substitutes,
                substitutes_count: substitutes.length
            }
        };

    } catch (error) {
        console.error('❌ Get medicine with substitutes error:', error);

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to retrieve medicine details with substitutes'
        };
    } finally {
        client.release();
    }

    next();
};
