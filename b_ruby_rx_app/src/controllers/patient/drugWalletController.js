/**
 * Drug Wallet Controller
 * Manages patient's medicine wallet - all medicines from all prescriptions
 * Provides comprehensive medicine history and details
 */

const { STATUS } = require('../../utils/constants');
const pool = require('../../config/dbConnection');
const { medicinePool } = require('../../config/multiDbConnection');

/**
 * Get all medicines for a patient across all prescriptions
 * Groups medicines with prescription and doctor details
 * 
 * Query Parameters:
 * - page (optional): Page number for pagination (default: 1)
 * - limit (optional): Number of medicines per page (default: 20)
 * - sort_by (optional): Sort field - 'date', 'name', 'doctor' (default: 'date')
 * - order (optional): Sort order - 'asc' or 'desc' (default: 'desc')
 * - filter (optional): Filter by medicine name (partial match)
 * 
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware
 */
async function getPatientDrugWallet(req, res, next) {
    let client;

    try {
        console.log('\n========================================');
        console.log('💊 DRUG WALLET - Get All Patient Medicines');
        console.log('========================================');

        // Get database client from pool
        client = await pool.connect();
        console.log('🔐 Database client acquired');

        // Get patient ID from authenticated user
        const patientId = req.user?.patientId;

        if (!patientId) {
            console.log('❌ No patient ID found in request');
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Patient authentication required',
                error: 'Missing patient ID'
            };
            return next();
        }

        console.log(`👤 Patient ID: ${patientId}`);

        // Parse query parameters
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        const sortBy = req.query.sort_by || 'date';
        const order = (req.query.order || 'desc').toUpperCase();
        const filter = req.query.filter || '';

        console.log(`📄 Pagination: Page ${page}, Limit ${limit}, Offset ${offset}`);
        console.log(`🔍 Sort: ${sortBy} ${order}`);
        console.log(`🔎 Filter: ${filter || 'None'}`);

        // Build ORDER BY clause based on sort parameter
        let orderByClause = 'pp.created_at DESC';
        switch (sortBy) {
            case 'name':
                orderByClause = `pm.medicine_name ${order}, pp.created_at DESC`;
                break;
            case 'doctor':
                orderByClause = `dr.dr_name ${order}, pp.created_at DESC`;
                break;
            case 'date':
            default:
                orderByClause = `pp.created_at ${order}`;
                break;
        }

        // Build filter clause
        const filterClause = filter ?
            `AND pm.medicine_name ILIKE $4` : '';
        const queryParams = filter ?
            [patientId, limit, offset, `%${filter}%`] :
            [patientId, limit, offset];

        // Main query to get all medicines with prescription, doctor details, and composition IDs
        const medicinesQuery = `
            SELECT 
                pm.medicin_id as medicine_id,
                pm.medicine_name,
                pm.medicine_salt,
                pm.medicine_frequency,
                pm.med_drug_id,
                pm.created_at as medicine_added_date,
                pp.prescription_id,
                pp.compiled_prescription_url,
                pp.prescription_raw_url,
                pp.created_at as prescription_date,
                dr.dr_id,
                dr.dr_name as doctor_name,
                dr.dr_specialization as doctor_specialization,
                dr.dr_phone_number as doctor_phone,
                dr.dr_email as doctor_email,
                dr.dr_city as doctor_city,
                da.appointment_id,
                da.patient_blood_pressure,
                da.patient_pulse,
                da.patient_temprature,
                da.patient_weight,
                da.patient_height
            FROM patient_medicine pm
            INNER JOIN patient_prescription pp ON pm.prescription_id = pp.prescription_id
            LEFT JOIN dr_appointment da ON (
                da.patient_id = pp.patient_id 
                AND ABS(EXTRACT(EPOCH FROM (da.created_at - pp.created_at))) < 3600
            )
            LEFT JOIN doctors_records dr ON dr.dr_id = da.dr_id OR dr.dr_id = pp.dr_id
            WHERE pm.prescription_id IN (
                SELECT prescription_id 
                FROM patient_prescription 
                WHERE patient_id = $1 AND is_active = 1
            )
            AND pm.is_active = 1
            ${filterClause}
            ORDER BY ${orderByClause}
            LIMIT $2 OFFSET $3
        `;

        console.log('🔄 Executing medicines query...');
        const result = await client.query(medicinesQuery, queryParams);

        console.log(`✅ Found ${result.rows.length} medicines`);

        // Fetch composition data from medicine database if medicines have med_drug_id
        const medicineIdsWithDrugId = result.rows
            .filter(m => m.med_drug_id)
            .map(m => m.med_drug_id);

        let compositionMap = new Map();

        if (medicineIdsWithDrugId.length > 0 && medicinePool) {
            try {
                console.log(`🔍 Fetching composition data for ${medicineIdsWithDrugId.length} medicines...`);
                const medicineClient = await medicinePool.connect();
                try {
                    const compositionQuery = `
                        SELECT 
                            med_id AS med_drug_id,
                            med_composition_id_1,
                            med_composition_id_2,
                            med_composition_id_3,
                            med_composition_id_4,
                            med_composition_id_5
                        FROM med_details
                        WHERE med_id = ANY($1)
                    `;
                    const compositionResult = await medicineClient.query(compositionQuery, [medicineIdsWithDrugId]);

                    console.log(`✅ Found composition data for ${compositionResult.rows.length} medicines`);

                    // Create a map of med_drug_id to composition IDs
                    // Convert med_drug_id to number for consistent Map key type
                    compositionResult.rows.forEach(row => {
                        const drugIdKey = parseInt(row.med_drug_id);
                        compositionMap.set(drugIdKey, {
                            med_composition_id_1: row.med_composition_id_1,
                            med_composition_id_2: row.med_composition_id_2,
                            med_composition_id_3: row.med_composition_id_3,
                            med_composition_id_4: row.med_composition_id_4,
                            med_composition_id_5: row.med_composition_id_5
                        });
                    });
                } finally {
                    medicineClient.release();
                }
            } catch (medicineError) {
                console.error('⚠️ Error fetching composition data:', medicineError);
                // Continue without composition data
            }
        }

        // Merge composition data with result rows
        // Convert med_drug_id to number for Map lookup
        result.rows.forEach(row => {
            const drugIdKey = parseInt(row.med_drug_id);
            if (row.med_drug_id && compositionMap.has(drugIdKey)) {
                const compositionData = compositionMap.get(drugIdKey);
                row.med_composition_id_1 = compositionData.med_composition_id_1;
                row.med_composition_id_2 = compositionData.med_composition_id_2;
                row.med_composition_id_3 = compositionData.med_composition_id_3;
                row.med_composition_id_4 = compositionData.med_composition_id_4;
                row.med_composition_id_5 = compositionData.med_composition_id_5;
            } else {
                // Set null composition IDs if not found
                row.med_composition_id_1 = null;
                row.med_composition_id_2 = null;
                row.med_composition_id_3 = null;
                row.med_composition_id_4 = null;
                row.med_composition_id_5 = null;
            }
        });

        // Get total count for pagination
        const countQuery = `
            SELECT COUNT(*) as total
            FROM patient_medicine pm
            WHERE pm.prescription_id IN (
                SELECT prescription_id 
                FROM patient_prescription 
                WHERE patient_id = $1 AND is_active = 1
            )
            AND pm.is_active = 1
            ${filter ? `AND pm.medicine_name ILIKE $2` : ''}
        `;

        const countParams = filter ? [patientId, `%${filter}%`] : [patientId];
        const countResult = await client.query(countQuery, countParams);
        const total = parseInt(countResult.rows[0].total);
        const totalPages = Math.ceil(total / limit);

        console.log(`📊 Total medicines in wallet: ${total}`);
        console.log(`📄 Total pages: ${totalPages}`);

        // Get unique medicine count (distinct medicine names)
        const uniqueCountQuery = `
            SELECT COUNT(DISTINCT pm.medicine_name) as unique_count
            FROM patient_medicine pm
            WHERE pm.prescription_id IN (
                SELECT prescription_id 
                FROM patient_prescription 
                WHERE patient_id = $1 AND is_active = 1
            )
            AND pm.is_active = 1
        `;

        const uniqueResult = await client.query(uniqueCountQuery, [patientId]);
        const uniqueMedicineCount = parseInt(uniqueResult.rows[0].unique_count);

        console.log(`🔢 Unique medicines: ${uniqueMedicineCount}`);

        // Get medicine statistics
        const statsQuery = `
            SELECT 
                COUNT(DISTINCT pp.prescription_id) as total_prescriptions,
                COUNT(DISTINCT dr.dr_id) as total_doctors,
                MIN(pp.created_at) as first_prescription_date,
                MAX(pp.created_at) as latest_prescription_date
            FROM patient_medicine pm
            INNER JOIN patient_prescription pp ON pm.prescription_id = pp.prescription_id
            LEFT JOIN dr_appointment da ON (
                da.patient_id = pp.patient_id 
                AND ABS(EXTRACT(EPOCH FROM (da.created_at - pp.created_at))) < 3600
            )
            LEFT JOIN doctors_records dr ON dr.dr_id = da.dr_id OR dr.dr_id = pp.dr_id
            WHERE pp.patient_id = $1 AND pp.is_active = 1 AND pm.is_active = 1
        `;

        const statsResult = await client.query(statsQuery, [patientId]);
        const stats = statsResult.rows[0];

        console.log('📈 Statistics:');
        console.log(`   - Total Prescriptions: ${stats.total_prescriptions}`);
        console.log(`   - Total Doctors: ${stats.total_doctors}`);
        console.log(`   - First Prescription: ${stats.first_prescription_date}`);
        console.log(`   - Latest Prescription: ${stats.latest_prescription_date}`);

        // Helper function to safely parse integer IDs
        const parseIntId = (value) => {
            if (value == null || value === '') return null;
            const parsed = parseInt(value);
            return isNaN(parsed) || parsed === 0 ? null : parsed;
        };

        // Format response with composition IDs
        const medicines = result.rows.map(row => ({
            medicine_id: row.medicine_id,
            medicine_name: row.medicine_name,
            medicine_salt: row.medicine_salt,
            medicine_frequency: row.medicine_frequency,
            medicine_added_date: row.medicine_added_date,
            med_drug_id: parseIntId(row.med_drug_id),
            compositions: {
                composition_id_1: parseIntId(row.med_composition_id_1),
                composition_id_2: parseIntId(row.med_composition_id_2),
                composition_id_3: parseIntId(row.med_composition_id_3),
                composition_id_4: parseIntId(row.med_composition_id_4),
                composition_id_5: parseIntId(row.med_composition_id_5)
            },
            prescription: {
                prescription_id: row.prescription_id,
                prescription_date: row.prescription_date,
                prescription_url: row.compiled_prescription_url || row.prescription_raw_url,
                appointment_id: row.appointment_id,
                vitals: {
                    blood_pressure: row.patient_blood_pressure,
                    pulse: row.patient_pulse,
                    temperature: row.patient_temprature,
                    weight: row.patient_weight,
                    height: row.patient_height
                }
            },
            doctor: row.dr_id ? {
                doctor_id: row.dr_id,
                doctor_name: row.doctor_name,
                doctor_specialization: row.doctor_specialization,
                doctor_phone: row.doctor_phone,
                doctor_email: row.doctor_email,
                doctor_city: row.doctor_city
            } : null
        }));

        // Check for composition overlaps and mark medicines with shared compositions
        const medicinesWithWarnings = medicines.map((medicine, index) => {
            const hasCompositionOverlap = medicines.some((otherMedicine, otherIndex) => {
                if (index === otherIndex) return false; // Don't compare with itself

                // Get all composition IDs for current medicine
                const currentCompositions = [
                    medicine.compositions.composition_id_1,
                    medicine.compositions.composition_id_2,
                    medicine.compositions.composition_id_3,
                    medicine.compositions.composition_id_4,
                    medicine.compositions.composition_id_5
                ].filter(id => id != null && id !== 0);

                // Get all composition IDs for other medicine
                const otherCompositions = [
                    otherMedicine.compositions.composition_id_1,
                    otherMedicine.compositions.composition_id_2,
                    otherMedicine.compositions.composition_id_3,
                    otherMedicine.compositions.composition_id_4,
                    otherMedicine.compositions.composition_id_5
                ].filter(id => id != null && id !== 0);

                // Check if any composition IDs match
                return currentCompositions.some(compId => otherCompositions.includes(compId));
            });

            return {
                ...medicine,
                has_composition_overlap: hasCompositionOverlap,
                warning_level: hasCompositionOverlap ? 'high' : 'none'
            };
        });

        // Count medicines with composition overlaps
        const overlappingMedicinesCount = medicinesWithWarnings.filter(m => m.has_composition_overlap).length;

        console.log(`⚠️ Found ${overlappingMedicinesCount} medicines with composition overlaps`);

        res.locals = {
            status: STATUS.SUCCESS,
            message: `Retrieved ${medicines.length} medicines from drug wallet`,
            data: {
                medicines: medicinesWithWarnings,
                statistics: {
                    total_medicines: total,
                    unique_medicines: uniqueMedicineCount,
                    total_prescriptions: parseInt(stats.total_prescriptions) || 0,
                    total_doctors: parseInt(stats.total_doctors) || 0,
                    first_prescription_date: stats.first_prescription_date,
                    latest_prescription_date: stats.latest_prescription_date,
                    medicines_with_overlaps: overlappingMedicinesCount
                },
                pagination: {
                    current_page: page,
                    total_pages: totalPages,
                    total_records: total,
                    limit: limit,
                    has_next: page < totalPages,
                    has_previous: page > 1
                },
                filters: {
                    sort_by: sortBy,
                    order: order,
                    filter: filter || null
                }
            }
        };

        console.log('✅ Drug wallet data prepared successfully');
        console.log('========================================\n');

        next();

    } catch (error) {
        console.error('❌ Error in getPatientDrugWallet:', error);
        console.error('Stack trace:', error.stack);
        console.log('========================================\n');

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to retrieve drug wallet',
            error: error.message
        };
        next();
    } finally {
        // Release database client back to pool
        if (client) {
            client.release();
            console.log('🔓 Database client released');
        }
    }
}

module.exports = {
    getPatientDrugWallet
};
