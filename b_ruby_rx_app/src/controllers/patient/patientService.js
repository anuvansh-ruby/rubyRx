const pool = require('../../config/dbConnection');
const STATUS = require('../../utils/constants').STATUS;

/**
 * Patient Service - Handles all patient database operations
 * Following database schema instructions for patient_records table
 */

/**
 * Update patient PIN
 * @param {number} patientId - Patient ID
 * @param {string} hashedPin - Hashed PIN
 * @returns {Object} - Update result
 */
exports.updatePatientPIN = async function (patientId, hashedPin) {
    try {
        const query = `
            UPDATE patients_records 
            SET patient_pin = $2, updated_at = CURRENT_TIMESTAMP 
            WHERE patient_id = $1 AND is_active = 1
            RETURNING patient_id, patient_first_name, patient_last_name, patient_pin
        `;

        const { rows } = await pool.query(query, [patientId, hashedPin]);

        if (rows.length === 0) {
            return {
                status: STATUS.FAILURE,
                message: 'Patient not found or inactive'
            };
        }

        return {
            status: STATUS.SUCCESS,
            data: rows[0],
            message: 'PIN updated successfully'
        };
    } catch (error) {
        console.error('Error updating patient PIN:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database update error for PIN',
            error: error.message
        };
    }
};

/**
 * Check if patient exists by phone number and get active status
 * @param {string} phoneNumber - Patient's phone number
 * @returns {Object} - Existence and status info
 */
exports.getPatientByPhone = async function (phoneNumber) {
    try {
        const query = `
            SELECT 
                patient_id, 
                patient_first_name, 
                patient_last_name, 
                patient_email, 
                patient_phone_number,
                patient_date_of_birth,
                patient_address,
                national_id_type,
                national_id_number,
                patient_last_visit_date,
                patient_pin,
                is_active,
                created_at,
                updated_at
            FROM patients_records 
            WHERE patient_phone_number = $1 AND is_active = 1
        `;

        const { rows } = await pool.query(query, [phoneNumber]);
        return { status: STATUS.SUCCESS, data: rows[0] || null };
    } catch (error) {
        console.error('Error fetching patient by phone:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database query error while fetching patient',
            error: error.message
        };
    }
};

/**
 * Get patient data by email
 * @param {string} email - Patient's email
 * @returns {Object} - Patient data or null if not found
 */
exports.getPatientByEmail = async function (email) {
    try {
        const query = `
            SELECT 
                patient_id, 
                patient_first_name, 
                patient_last_name, 
                patient_email, 
                patient_phone_number,
                patient_date_of_birth,
                patient_address,
                national_id_type,
                national_id_number,
                patient_last_visit_date,
                is_active,
                created_at,
                updated_at
            FROM patients_records 
            WHERE patient_email = $1 AND is_active = 1
        `;

        const { rows } = await pool.query(query, [email]);
        return { status: STATUS.SUCCESS, data: rows[0] || null };
    } catch (error) {
        console.error('Error fetching patient by email:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database query error while fetching patient',
            error: error.message
        };
    }
};

/**
 * Create new patient in database
 * @param {Object} patientData - Patient information
 * @returns {Object} - Created patient data
 */
exports.createPatientInDB = async function (patientData) {
    try {
        // Validate required fields according to schema
        const requiredFields = [
            'patient_first_name',
            'patient_last_name',
            'patient_phone_number',
            'patient_email',
            'patient_date_of_birth'
        ];

        for (const field of requiredFields) {
            if (!patientData[field]) {
                return {
                    status: STATUS.FAILURE,
                    message: `Missing required field: ${field}`
                };
            }
        }

        // Set default values for system fields
        const currentTime = new Date().toISOString();
        const patientRecord = {
            ...patientData,
            created_by: patientData.created_by || 'system',
            updated_by: patientData.updated_by || 'system',
            created_at: currentTime,
            updated_at: currentTime,
            patient_last_visit_date: currentTime,
            is_active: 1
        };

        // Build dynamic query
        const columns = Object.keys(patientRecord).join(', ');
        const values = Object.values(patientRecord);
        const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

        const query = `
            INSERT INTO patients_records (${columns}) 
            VALUES (${placeholders}) 
            RETURNING 
                patient_id, 
                patient_first_name, 
                patient_last_name, 
                patient_email, 
                patient_phone_number,
                patient_date_of_birth,
                patient_address,
                national_id_type,
                national_id_number,
                created_at,
                updated_at
        `;

        const { rows } = await pool.query(query, values);

        if (rows && rows.length > 0) {
            return {
                status: STATUS.SUCCESS,
                data: rows[0],
                message: 'Patient created successfully'
            };
        } else {
            return {
                status: STATUS.FAILURE,
                message: 'Failed to create patient record'
            };
        }
    } catch (error) {
        console.error('Error creating patient:', error);

        // Handle unique constraint violations
        if (error.code === '23505') {
            if (error.constraint && error.constraint.includes('email')) {
                return {
                    status: STATUS.FAILURE,
                    message: 'Email already exists. Please use a different email address.'
                };
            } else if (error.constraint && error.constraint.includes('phone')) {
                return {
                    status: STATUS.FAILURE,
                    message: 'Phone number already exists. Please use a different phone number.'
                };
            } else {
                return {
                    status: STATUS.FAILURE,
                    message: 'Patient with this information already exists.'
                };
            }
        }

        return {
            status: STATUS.FAILURE,
            message: 'Database error while creating patient',
            error: error.message
        };
    }
};

/**
 * Update patient's last visit date
 * @param {number} patientId - Patient ID
 * @returns {Object} - Update result
 */
exports.updateLastVisitDate = async function (patientId) {
    try {
        const currentTime = new Date().toISOString();
        const query = `
            UPDATE patients_records 
            SET patient_last_visit_date = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
            WHERE patient_id = $1
            RETURNING patient_id, patient_last_visit_date
        `;

        const { rows } = await pool.query(query, [patientId]);

        if (rows && rows.length > 0) {
            return {
                status: STATUS.SUCCESS,
                data: rows[0],
                message: 'Last visit date updated successfully'
            };
        } else {
            return {
                status: STATUS.FAILURE,
                message: 'Patient not found or inactive'
            };
        }
    } catch (error) {
        console.error('Error updating last visit date:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database error while updating last visit date',
            error: error.message
        };
    }
};

/**
 * Update patient information
 * @param {number} patientId - Patient ID
 * @param {Object} updateData - Data to update
 * @returns {Object} - Update result
 */
exports.updatePatientInfo = async function (patientId, updateData) {
    try {
        if (!updateData || Object.keys(updateData).length === 0) {
            return {
                status: STATUS.FAILURE,
                message: 'No data provided for update'
            };
        }

        // Add system fields
        updateData.updated_at = new Date().toISOString();
        updateData.updated_by = updateData.updated_by || 'system';

        // Build dynamic update query
        const updateFields = Object.keys(updateData);
        const setClause = updateFields.map((field, index) => `${field} = $${index + 1}`).join(', ');
        const values = Object.values(updateData);
        values.push(patientId); // Add patient_id as last parameter

        const query = `
            UPDATE patients_records 
            SET ${setClause}
            WHERE patient_id = $${values.length} AND is_active = 1
            RETURNING patient_id, patient_first_name, patient_last_name, 
                     patient_email, patient_phone_number, updated_at
        `;

        const { rows } = await pool.query(query, values);

        if (rows && rows.length > 0) {
            return {
                status: STATUS.SUCCESS,
                data: rows[0],
                message: 'Patient information updated successfully'
            };
        } else {
            return {
                status: STATUS.FAILURE,
                message: 'Patient not found or inactive'
            };
        }
    } catch (error) {
        console.error('Error updating patient info:', error);

        // Handle unique constraint violations
        if (error.code === '23505') {
            if (error.constraint && error.constraint.includes('email')) {
                return {
                    status: STATUS.FAILURE,
                    message: 'Email already exists. Please use a different email address.'
                };
            } else if (error.constraint && error.constraint.includes('phone')) {
                return {
                    status: STATUS.FAILURE,
                    message: 'Phone number already exists. Please use a different phone number.'
                };
            }
        }

        return {
            status: STATUS.FAILURE,
            message: 'Database error while updating patient information',
            error: error.message
        };
    }
};

/**
 * Deactivate patient (soft delete)
 * @param {number} patientId - Patient ID
 * @returns {Object} - Deactivation result
 */
exports.deactivatePatient = async function (patientId) {
    try {
        const currentTime = new Date().toISOString();
        const query = `
            UPDATE patients_records 
            SET is_active = 0, updated_at = $1, updated_by = 'system'
            WHERE patient_id = $2
            RETURNING patient_id, is_active
        `;

        const { rows } = await pool.query(query, [currentTime, patientId]);

        if (rows && rows.length > 0) {
            return {
                status: STATUS.SUCCESS,
                data: rows[0],
                message: 'Patient deactivated successfully'
            };
        } else {
            return {
                status: STATUS.FAILURE,
                message: 'Patient not found'
            };
        }
    } catch (error) {
        console.error('Error deactivating patient:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database error while deactivating patient',
            error: error.message
        };
    }
};

/**
 * Check if phone number exists
 * @param {string} phoneNumber - Phone number to check
 * @returns {Object} - Existence check result
 */
exports.checkPhoneExists = async function (phoneNumber) {
    try {
        const query = `
            SELECT patient_id, is_active 
            FROM patients_records 
            WHERE patient_phone_number = $1 and is_active = 1
        `;

        const { rows } = await pool.query(query, [phoneNumber]);
        return {
            status: STATUS.SUCCESS,
            exists: rows.length > 0,
            isActive: rows.length > 0 ? rows[0].is_active === 1 : false,
            patientId: rows.length > 0 ? rows[0].patient_id : null
        };
    } catch (error) {
        console.error('Error checking phone existence:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database error while checking phone number',
            error: error.message
        };
    }
};

/**
 * Check if email exists
 * @param {string} email - Email to check
 * @returns {Object} - Existence check result
 */
exports.checkEmailExists = async function (email) {
    try {
        const query = `
            SELECT patient_id, is_active 
            FROM patients_records 
            WHERE patient_email = $1
        `;

        const { rows } = await pool.query(query, [email]);
        return {
            status: STATUS.SUCCESS,
            exists: rows.length > 0,
            isActive: rows.length > 0 ? rows[0].is_active === 1 : false,
            patientId: rows.length > 0 ? rows[0].patient_id : null
        };
    } catch (error) {
        console.error('Error checking email existence:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database error while checking email',
            error: error.message
        };
    }
};

/**
 * Get patient by ID
 * @param {number} patientId - Patient ID
 * @returns {Object} - Patient data
 */
exports.getPatientById = async function (patientId) {
    try {
        const query = `
            SELECT 
                patient_id, 
                patient_first_name, 
                patient_last_name, 
                patient_email, 
                patient_phone_number,
                patient_date_of_birth,
                patient_address,
                national_id_type,
                national_id_number,
                patient_last_visit_date,
                is_active,
                created_at,
                updated_at
            FROM patients_records 
            WHERE patient_id = $1 AND is_active = 1
        `;

        const { rows } = await pool.query(query, [patientId]);

        if (rows.length === 0) {
            return {
                status: STATUS.FAILURE,
                message: 'Patient not found or inactive'
            };
        }

        return {
            status: STATUS.SUCCESS,
            data: rows[0]
        };
    } catch (error) {
        console.error('Error fetching patient by ID:', error);
        return {
            status: STATUS.FAILURE,
            message: 'Database error while fetching patient',
            error: error.message
        };
    }
};

/**
 * Update patient profile with validation
 * @param {number} patientId - Patient ID
 * @param {Object} updateData - Profile data to update
 * @returns {Object} - Update result
 */
exports.updatePatientProfile = async function (patientId, updateData) {
    try {
        if (!updateData || Object.keys(updateData).length === 0) {
            return {
                status: STATUS.FAILURE,
                message: 'No data provided for update'
            };
        }

        // Add system fields
        updateData.updated_at = new Date().toISOString();

        // Build dynamic update query
        const updateFields = Object.keys(updateData);
        const setClause = updateFields.map((field, index) => `${field} = $${index + 1}`).join(', ');
        const values = Object.values(updateData);
        values.push(patientId); // Add patient_id as last parameter

        const query = `
            UPDATE patients_records 
            SET ${setClause}
            WHERE patient_id = $${values.length} AND is_active = 1
            RETURNING 
                patient_id, 
                patient_first_name, 
                patient_last_name, 
                patient_email, 
                patient_phone_number,
                patient_date_of_birth,
                patient_address,
                national_id_type,
                national_id_number,
                patient_last_visit_date,
                updated_at
        `;

        const { rows } = await pool.query(query, values);

        if (rows && rows.length > 0) {
            return {
                status: STATUS.SUCCESS,
                data: rows[0],
                message: 'Patient profile updated successfully'
            };
        } else {
            return {
                status: STATUS.FAILURE,
                message: 'Patient not found or inactive'
            };
        }
    } catch (error) {
        console.error('Error updating patient profile:', error);

        // Handle unique constraint violations
        if (error.code === '23505') {
            if (error.constraint && error.constraint.includes('email')) {
                return {
                    status: STATUS.FAILURE,
                    message: 'Email already exists. Please use a different email address.'
                };
            } else if (error.constraint && error.constraint.includes('phone')) {
                return {
                    status: STATUS.FAILURE,
                    message: 'Phone number already exists. Please use a different phone number.'
                };
            }
        }

        return {
            status: STATUS.FAILURE,
            message: 'Database error while updating patient profile',
            error: error.message
        };
    }
};