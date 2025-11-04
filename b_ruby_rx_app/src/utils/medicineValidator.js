/**
 * Medicine Validation Utility
 * Provides comprehensive validation and sanitization for medicine data
 */

/**
 * Validate and sanitize medicine data for database insertion
 * @param {Object} medicine - Raw medicine object
 * @param {number} index - Medicine index for error reporting
 * @returns {Object} - Validated medicine data or error
 */
const validateMedicine = (medicine, index = 0) => {
    const errors = [];
    const sanitizedMedicine = {};

    // 1. Validate medicine name (required)
    const medicineName = medicine.medicine_name || medicine.name || medicine.medicineName;
    if (!medicineName || typeof medicineName !== 'string' || medicineName.trim().length === 0) {
        errors.push(`Medicine name is required for medicine ${index + 1}`);
    } else {
        const trimmedName = medicineName.trim();
        if (trimmedName.length > 255) {
            errors.push(`Medicine name too long for medicine ${index + 1} (max 255 characters, got ${trimmedName.length})`);
        } else {
            sanitizedMedicine.medicine_name = trimmedName;
        }
    }

    // 2. Validate and sanitize medicine frequency
    const medicineFrequency = medicine.medicine_frequency || medicine.frequency || medicine.dosage || '1-0-1';
    if (medicineFrequency && typeof medicineFrequency === 'string') {
        const trimmedFrequency = medicineFrequency.trim();
        if (trimmedFrequency.length > 255) {
            sanitizedMedicine.medicine_frequency = trimmedFrequency.substring(0, 255);
        } else {
            sanitizedMedicine.medicine_frequency = trimmedFrequency;
        }
    } else {
        sanitizedMedicine.medicine_frequency = '1-0-1'; // Default frequency
    }

    // 3. Validate and sanitize medicine salt/composition
    const medicineSalt = medicine.medicine_salt || medicine.salt || medicine.generic_name || medicine.composition;
    if (medicineSalt && typeof medicineSalt === 'string') {
        const trimmedSalt = medicineSalt.trim();
        if (trimmedSalt.length > 500) {
            sanitizedMedicine.medicine_salt = trimmedSalt.substring(0, 500);
        } else {
            sanitizedMedicine.medicine_salt = trimmedSalt;
        }
    } else {
        sanitizedMedicine.medicine_salt = null;
    }

    // 4. Validate med_drug_id (Anuvansh medicine database ID)
    const medDrugId = medicine.med_drug_id || medicine.drug_id || medicine.anuvansh_id || medicine.medicine_id;
    if (medDrugId) {
        const parsedMedDrugId = parseInt(medDrugId);
        if (isNaN(parsedMedDrugId) || parsedMedDrugId <= 0) {
            errors.push(`Invalid med_drug_id for medicine ${index + 1}: must be a positive integer`);
        } else {
            sanitizedMedicine.med_drug_id = parsedMedDrugId;
        }
    } else {
        sanitizedMedicine.med_drug_id = null;
    }

    // 5. Additional fields (not stored in current schema but validated for future use)
    sanitizedMedicine.dosage = medicine.dosage || medicine.strength || null;
    sanitizedMedicine.duration = medicine.duration || medicine.course_duration || null;
    sanitizedMedicine.instructions = medicine.instructions || medicine.special_instructions || null;

    // Return validation result
    return {
        isValid: errors.length === 0,
        errors: errors,
        sanitized: sanitizedMedicine,
        original: medicine
    };
};

/**
 * Validate an array of medicines
 * @param {Array} medicines - Array of medicine objects
 * @returns {Object} - Validation results
 */
const validateMedicines = (medicines) => {
    if (!Array.isArray(medicines)) {
        return {
            isValid: false,
            errors: ['Medicines must be an array'],
            sanitized: [],
            allErrors: []
        };
    }

    if (medicines.length === 0) {
        return {
            isValid: false,
            errors: ['At least one medicine is required'],
            sanitized: [],
            allErrors: []
        };
    }

    const sanitizedMedicines = [];
    const allErrors = [];
    let hasErrors = false;

    medicines.forEach((medicine, index) => {
        const validation = validateMedicine(medicine, index);

        if (validation.isValid) {
            sanitizedMedicines.push(validation.sanitized);
        } else {
            hasErrors = true;
            allErrors.push(...validation.errors);
        }
    });

    return {
        isValid: !hasErrors,
        errors: allErrors,
        sanitized: sanitizedMedicines,
        allErrors: allErrors
    };
};

/**
 * Validate prescription ID
 * @param {*} prescriptionId - Prescription ID to validate
 * @returns {Object} - Validation result
 */
const validatePrescriptionId = (prescriptionId) => {
    const parsedId = parseInt(prescriptionId);

    if (isNaN(parsedId) || parsedId <= 0) {
        return {
            isValid: false,
            error: 'Invalid prescription ID',
            sanitized: null
        };
    }

    return {
        isValid: true,
        error: null,
        sanitized: parsedId
    };
};

/**
 * Create medicine frequency validation regex patterns
 */
const FREQUENCY_PATTERNS = {
    // Pattern: digit-digit-digit (e.g., 1-0-1, 2-1-2)
    STANDARD: /^\d+-\d+-\d+$/,
    // Pattern: once/twice/thrice daily
    DESCRIPTIVE: /^(once|twice|thrice|daily|morning|afternoon|evening|night|bedtime)$/i,
    // Pattern: every X hours
    HOURLY: /^every\s+\d+\s+hours?$/i,
    // Pattern: X times a day
    DAILY_COUNT: /^\d+\s+times?\s+(a\s+)?day$/i
};

/**
 * Validate medicine frequency pattern
 * @param {string} frequency - Frequency string to validate
 * @returns {Object} - Validation result
 */
const validateFrequency = (frequency) => {
    if (!frequency || typeof frequency !== 'string') {
        return {
            isValid: false,
            error: 'Frequency is required',
            pattern: null
        };
    }

    const trimmedFrequency = frequency.trim();

    for (const [patternName, pattern] of Object.entries(FREQUENCY_PATTERNS)) {
        if (pattern.test(trimmedFrequency)) {
            return {
                isValid: true,
                error: null,
                pattern: patternName,
                sanitized: trimmedFrequency
            };
        }
    }

    // If no pattern matches, still accept but flag as custom
    return {
        isValid: true,
        error: null,
        pattern: 'CUSTOM',
        sanitized: trimmedFrequency,
        warning: 'Custom frequency pattern - please verify'
    };
};

/**
 * Sanitize and validate full medicine creation request
 * @param {Object} requestBody - Full request body
 * @returns {Object} - Validation result
 */
const validateMedicineCreationRequest = (requestBody) => {
    const errors = [];
    const sanitized = {};

    // Validate prescription ID
    const prescriptionValidation = validatePrescriptionId(requestBody.prescription_id);
    if (!prescriptionValidation.isValid) {
        errors.push(prescriptionValidation.error);
    } else {
        sanitized.prescription_id = prescriptionValidation.sanitized;
    }

    // Validate medicines array
    const medicinesValidation = validateMedicines(requestBody.medicines || []);
    if (!medicinesValidation.isValid) {
        errors.push(...medicinesValidation.errors);
    } else {
        sanitized.medicines = medicinesValidation.sanitized;
    }

    // Validate created_by
    const createdBy = parseInt(requestBody.created_by || requestBody.user_id || 1);
    if (isNaN(createdBy) || createdBy <= 0) {
        errors.push('Invalid created_by user ID');
    } else {
        sanitized.created_by = createdBy;
    }

    return {
        isValid: errors.length === 0,
        errors: errors,
        sanitized: sanitized
    };
};

module.exports = {
    validateMedicine,
    validateMedicines,
    validatePrescriptionId,
    validateFrequency,
    validateMedicineCreationRequest,
    FREQUENCY_PATTERNS
};