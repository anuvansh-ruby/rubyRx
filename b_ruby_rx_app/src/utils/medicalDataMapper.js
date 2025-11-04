/**
 * Medical Data Mapper Utility
 * Maps raw OCR extracted text to standardized medical dropdown values
 * that match the frontend predefined options
 */

// Predefined dropdown options matching frontend MedicalDropdownOptions
const MEDICAL_DROPDOWN_OPTIONS = {
    frequency: [
        'Once a day',
        'Twice a day',
        'Thrice a day',
        'Once weekly',
        'Twice weekly',
        'Once a month',
    ],
    duration: [
        '1 Day',
        '2 Days',
        '3 Days',
        '1 Week',
        '2 Weeks',
        '3 Weeks',
        '1 Month',
        '2 Months',
        '3 Months',
    ],
    gender: [
        'Male',
        'Female',
        'Other',
    ]
};

// Frequency mapping patterns
const FREQUENCY_MAPPING = {
    // Once daily patterns
    'once a day': 'Once a day',
    'once daily': 'Once a day',
    'once per day': 'Once a day',
    '1x daily': 'Once a day',
    '1 time daily': 'Once a day',
    '1 time a day': 'Once a day',
    'od': 'Once a day', // Medical abbreviation
    'qd': 'Once a day', // Medical abbreviation
    'daily': 'Once a day',
    'everyday': 'Once a day',
    'one time daily': 'Once a day',

    // Twice daily patterns
    'twice a day': 'Twice a day',
    'twice daily': 'Twice a day',
    'twice per day': 'Twice a day',
    '2x daily': 'Twice a day',
    '2 times daily': 'Twice a day',
    '2 times a day': 'Twice a day',
    'bd': 'Twice a day', // Medical abbreviation
    'bid': 'Twice a day', // Medical abbreviation
    'two times daily': 'Twice a day',
    'two times a day': 'Twice a day',

    // Thrice daily patterns
    'thrice a day': 'Thrice a day',
    'thrice daily': 'Thrice a day',
    'three times a day': 'Thrice a day',
    'three times daily': 'Thrice a day',
    '3x daily': 'Thrice a day',
    '3 times daily': 'Thrice a day',
    '3 times a day': 'Thrice a day',
    'tid': 'Thrice a day', // Medical abbreviation
    'tds': 'Thrice a day', // Medical abbreviation

    // Weekly patterns
    'once a week': 'Once weekly',
    'once weekly': 'Once weekly',
    'weekly': 'Once weekly',
    '1x weekly': 'Once weekly',
    'once per week': 'Once weekly',
    'one time weekly': 'Once weekly',

    'twice a week': 'Twice weekly',
    'twice weekly': 'Twice weekly',
    '2x weekly': 'Twice weekly',
    'two times weekly': 'Twice weekly',
    'twice per week': 'Twice weekly',

    // Monthly patterns
    'once a month': 'Once a month',
    'once monthly': 'Once a month',
    'monthly': 'Once a month',
    '1x monthly': 'Once a month',
    'once per month': 'Once a month',
};

// Duration mapping patterns  
const DURATION_MAPPING = {
    // Day patterns
    '1 day': '1 Day',
    'one day': '1 Day',
    'single day': '1 Day',
    'for 1 day': '1 Day',

    '2 days': '2 Days',
    'two days': '2 Days',
    'for 2 days': '2 Days',

    '3 days': '3 Days',
    'three days': '3 Days',
    'for 3 days': '3 Days',

    // Week patterns
    '1 week': '1 Week',
    'one week': '1 Week',
    'a week': '1 Week',
    'for 1 week': '1 Week',
    'for a week': '1 Week',
    '7 days': '1 Week',
    'seven days': '1 Week',

    '2 weeks': '2 Weeks',
    'two weeks': '2 Weeks',
    'for 2 weeks': '2 Weeks',
    '14 days': '2 Weeks',
    'fourteen days': '2 Weeks',

    '3 weeks': '3 Weeks',
    'three weeks': '3 Weeks',
    'for 3 weeks': '3 Weeks',
    '21 days': '3 Weeks',

    // Month patterns
    '1 month': '1 Month',
    'one month': '1 Month',
    'a month': '1 Month',
    'for 1 month': '1 Month',
    'for a month': '1 Month',
    '30 days': '1 Month',

    '2 months': '2 Months',
    'two months': '2 Months',
    'for 2 months': '2 Months',
    '60 days': '2 Months',

    '3 months': '3 Months',
    'three months': '3 Months',
    'for 3 months': '3 Months',
    '90 days': '3 Months',
};

// Gender mapping patterns
const GENDER_MAPPING = {
    'male': 'Male',
    'man': 'Male',
    'm': 'Male',
    'boy': 'Male',

    'female': 'Female',
    'woman': 'Female',
    'f': 'Female',
    'girl': 'Female',

    'other': 'Other',
    'transgender': 'Other',
    'non-binary': 'Other',
    'prefer not to say': 'Other',
};

/**
 * Map raw frequency text to standardized dropdown value
 * @param {string} rawFrequency - Raw frequency text from OCR
 * @returns {string|null} Standardized frequency value or null if no match
 */
function mapFrequency(rawFrequency) {
    if (!rawFrequency || typeof rawFrequency !== 'string') {
        return null;
    }

    const normalized = rawFrequency.toLowerCase().trim();

    // Direct mapping first
    if (FREQUENCY_MAPPING[normalized]) {
        return FREQUENCY_MAPPING[normalized];
    }

    // Pattern matching for complex cases
    // Check for patterns like "2 times per day", "every 8 hours", etc.

    // Every X hours patterns
    if (normalized.match(/every\s*(\d+)\s*hours?/)) {
        const hours = parseInt(normalized.match(/every\s*(\d+)\s*hours?/)[1]);
        if (hours <= 8) return 'Thrice a day';
        if (hours <= 12) return 'Twice a day';
        if (hours <= 24) return 'Once a day';
    }

    // Once patterns
    if (normalized.match(/\b(once|1)\s*(time|times)?\s*(a\s*)?(day|daily)\b/)) {
        return 'Once a day';
    }

    // Handle "daily" without "once" explicitly
    if (normalized.match(/\bdaily\b/) && !normalized.match(/\b(twice|2|two|thrice|3|three)\b/)) {
        return 'Once a day';
    }

    // Handle "per day" patterns
    if (normalized.match(/once\s*(per|a)\s*day/)) {
        return 'Once a day';
    }

    // Twice patterns
    if (normalized.match(/\b(twice|2)\s*(times)?\s*(a\s*)?(day|daily)\b/)) {
        return 'Twice a day';
    }

    // Thrice patterns
    if (normalized.match(/\b(thrice|three|3)\s*(times)?\s*(a\s*)?(day|daily)\b/)) {
        return 'Thrice a day';
    }

    // Weekly patterns
    if (normalized.match(/\b(once|1)\s*(time|times)?\s*(a\s*)?(week|weekly)\b/)) {
        return 'Once weekly';
    }

    if (normalized.match(/\b(twice|2)\s*(times)?\s*(a\s*)?(week|weekly)\b/)) {
        return 'Twice weekly';
    }

    // Monthly patterns
    if (normalized.match(/\b(once|1)\s*(time|times)?\s*(a\s*)?(month|monthly)\b/)) {
        return 'Once a month';
    }

    // If no match found, return the closest available option based on content
    if (normalized.includes('day') || normalized.includes('daily')) {
        return 'Once a day'; // Default daily assumption
    }

    if (normalized.includes('week')) {
        return 'Once weekly';
    }

    if (normalized.includes('month')) {
        return 'Once a month';
    }

    // Return null if no pattern matches
    return null;
}

/**
 * Map raw duration text to standardized dropdown value
 * @param {string} rawDuration - Raw duration text from OCR
 * @returns {string|null} Standardized duration value or null if no match
 */
function mapDuration(rawDuration) {
    if (!rawDuration || typeof rawDuration !== 'string') {
        return null;
    }

    const normalized = rawDuration.toLowerCase().trim();

    // Direct mapping first
    if (DURATION_MAPPING[normalized]) {
        return DURATION_MAPPING[normalized];
    }

    // Pattern matching for complex cases

    // Day patterns
    const dayMatch = normalized.match(/(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s*days?/);
    if (dayMatch) {
        const dayNumber = convertWordToNumber(dayMatch[1]);
        if (dayNumber === 1) return '1 Day';
        if (dayNumber === 2) return '2 Days';
        if (dayNumber === 3) return '3 Days';
        if (dayNumber === 7) return '1 Week';
        if (dayNumber === 14) return '2 Weeks';
        if (dayNumber === 21) return '3 Weeks';
        if (dayNumber === 30) return '1 Month';
        if (dayNumber === 60) return '2 Months';
        if (dayNumber === 90) return '3 Months';
    }

    // Week patterns
    const weekMatch = normalized.match(/(\d+|one|two|three|four)\s*weeks?/);
    if (weekMatch) {
        const weekNumber = convertWordToNumber(weekMatch[1]);
        if (weekNumber === 1) return '1 Week';
        if (weekNumber === 2) return '2 Weeks';
        if (weekNumber === 3) return '3 Weeks';
    }

    // Month patterns
    const monthMatch = normalized.match(/(\d+|one|two|three)\s*months?/);
    if (monthMatch) {
        const monthNumber = convertWordToNumber(monthMatch[1]);
        if (monthNumber === 1) return '1 Month';
        if (monthNumber === 2) return '2 Months';
        if (monthNumber === 3) return '3 Months';
    }

    // Default fallbacks based on content
    if (normalized.includes('day')) {
        return '3 Days'; // Common short-term treatment default
    }

    if (normalized.includes('week')) {
        return '1 Week';
    }

    if (normalized.includes('month')) {
        return '1 Month';
    }

    // Return null if no pattern matches
    return null;
}

/**
 * Map raw gender text to standardized dropdown value
 * @param {string} rawGender - Raw gender text from OCR
 * @returns {string|null} Standardized gender value or null if no match
 */
function mapGender(rawGender) {
    if (!rawGender || typeof rawGender !== 'string') {
        return null;
    }

    const normalized = rawGender.toLowerCase().trim();

    // Direct mapping
    if (GENDER_MAPPING[normalized]) {
        return GENDER_MAPPING[normalized];
    }

    // Pattern matching
    if (normalized.match(/\b(male|man|boy)\b/)) {
        return 'Male';
    }

    if (normalized.match(/\b(female|woman|girl)\b/)) {
        return 'Female';
    }

    // Default to null for ambiguous cases
    return null;
}

/**
 * Convert word numbers to integers
 * @param {string} word - Number word (e.g., "one", "two", "1", "2")
 * @returns {number} Numeric value
 */
function convertWordToNumber(word) {
    const wordMap = {
        'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
        'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
        'fourteen': 14, 'twenty-one': 21, 'thirty': 30,
        'sixty': 60, 'ninety': 90
    };

    return wordMap[word.toLowerCase()] || parseInt(word) || 0;
}

/**
 * Map a medication object's frequency and duration to standardized values
 * @param {Object} medication - Medication object with frequency and duration
 * @returns {Object} Medication object with mapped values
 */
function mapMedicationValues(medication) {
    if (!medication || typeof medication !== 'object') {
        return medication;
    }

    const mappedMedication = { ...medication };

    // Map frequency
    if (medication.frequency) {
        const mappedFrequency = mapFrequency(medication.frequency);
        if (mappedFrequency) {
            mappedMedication.frequency = mappedFrequency;
        }
    }

    // Map duration
    if (medication.duration) {
        const mappedDuration = mapDuration(medication.duration);
        if (mappedDuration) {
            mappedMedication.duration = mappedDuration;
        }
    }

    return mappedMedication;
}

/**
 * Map an entire prescription data object to standardized values
 * @param {Object} prescriptionData - Complete prescription data from OCR
 * @returns {Object} Prescription data with mapped values
 */
function mapPrescriptionData(prescriptionData) {
    if (!prescriptionData || typeof prescriptionData !== 'object') {
        return prescriptionData;
    }

    const mappedData = { ...prescriptionData };

    // Map patient gender
    if (prescriptionData.patient_gender) {
        const mappedGender = mapGender(prescriptionData.patient_gender);
        if (mappedGender) {
            mappedData.patient_gender = mappedGender;
        }
    }

    // Map medications
    if (Array.isArray(prescriptionData.medications)) {
        mappedData.medications = prescriptionData.medications.map(mapMedicationValues);
    }

    return mappedData;
}

/**
 * Get available dropdown options (for validation or display)
 * @returns {Object} Available medical dropdown options
 */
function getAvailableOptions() {
    return { ...MEDICAL_DROPDOWN_OPTIONS };
}

/**
 * Validate if a value exists in the corresponding dropdown options
 * @param {string} value - Value to validate
 * @param {string} type - Type of validation ('frequency', 'duration', 'gender')
 * @returns {boolean} True if value exists in options
 */
function isValidDropdownValue(value, type) {
    if (!value || !type || !MEDICAL_DROPDOWN_OPTIONS[type]) {
        return false;
    }

    return MEDICAL_DROPDOWN_OPTIONS[type].includes(value);
}

/**
 * Get the closest match from dropdown options using similarity
 * @param {string} value - Input value
 * @param {string} type - Type of dropdown ('frequency', 'duration', 'gender')
 * @returns {string|null} Closest matching option or null
 */
function getClosestMatch(value, type) {
    if (!value || !type || !MEDICAL_DROPDOWN_OPTIONS[type]) {
        return null;
    }

    const options = MEDICAL_DROPDOWN_OPTIONS[type];
    const normalized = value.toLowerCase();

    // Find exact substring matches first
    for (const option of options) {
        if (option.toLowerCase().includes(normalized) || normalized.includes(option.toLowerCase())) {
            return option;
        }
    }

    // Return first option as fallback for that type
    return options[0];
}

module.exports = {
    mapFrequency,
    mapDuration,
    mapGender,
    mapMedicationValues,
    mapPrescriptionData,
    getAvailableOptions,
    isValidDropdownValue,
    getClosestMatch,
    MEDICAL_DROPDOWN_OPTIONS
};