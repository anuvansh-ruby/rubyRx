/**
 * Anuvansh Medicine Database Integration Utility
 * Handles linking between patient medicines and Anuvansh medicine database
 * Enhanced with fuzzy matching for OCR-extracted prescriptions
 */

const { medicinePool } = require('../config/multiDbConnection');
const { fuzzySearchMedicine } = require('./fuzzyMedicineMatcher');

/**
 * Search medicine in Anuvansh database by name with fuzzy matching
 * Queries the med_details table using advanced matching strategies
 * @param {string} medicineName - Medicine name to search
 * @param {Object} options - Search options
 * @returns {Object} - Medicine data from medicine DB or null
 */
const searchAnuvanshMedicine = async (medicineName, options = {}) => {
    try {
        console.log(`🔍 Searching Medicine DB for: "${medicineName}"`);

        if (!medicineName || medicineName.trim() === '') {
            return {
                success: false,
                data: null,
                message: 'Medicine name is required'
            };
        }

        const {
            useFuzzyMatch = true,
            minSimilarity = 0.7,
            includeSalt = null
        } = options;

        // Use fuzzy matching for better OCR results
        if (useFuzzyMatch) {
            const fuzzyResult = await fuzzySearchMedicine(medicineName, {
                minSimilarity: minSimilarity,
                includeSalt: includeSalt,
                preferExactMatch: true
            });

            if (fuzzyResult.success) {
                console.log(`✅ Found in Medicine DB (${fuzzyResult.matchType}): ${fuzzyResult.match.name} (ID: ${fuzzyResult.match.id})`);
                console.log(`   Confidence: ${(fuzzyResult.confidence * 100).toFixed(1)}%`);

                return {
                    success: true,
                    data: fuzzyResult.match,
                    confidence: fuzzyResult.confidence,
                    matchType: fuzzyResult.matchType,
                    alternativeMatches: fuzzyResult.alternativeMatches
                };
            } else {
                console.log(`❌ Not found in Medicine DB: "${medicineName}"`);
                return {
                    success: false,
                    data: null,
                    message: fuzzyResult.message || 'Medicine not found in database',
                    suggestion: fuzzyResult.suggestion
                };
            }
        }

        // Fallback to basic search (kept for backward compatibility)
        const cleanName = medicineName.trim();

        const query = `
            SELECT 
                md.med_id as med_drug_id,
                md.med_brand_name as drug_name,
                md.med_generic_id,
                md.med_composition_id_1 as composition1_id,
                md.med_composition_name_1 as composition1_name,
                md.med_composition_strength_1 as composition1_strength,
                md.med_composition_unit_1 as composition1_unit,
                md.med_composition_id_2 as composition2_id,
                md.med_composition_name_2 as composition2_name,
                md.med_composition_strength_2 as composition2_strength,
                md.med_composition_unit_2 as composition2_unit,
                md.med_price as mrp,
                md.med_manufacturer_name as manufacturer_name,
                md.med_pack_size as pack_size,
                md.med_type,
                md.med_weightage
            FROM med_details md
            WHERE md.is_active = 1 
                AND md.is_deactivated = 0
                AND (LOWER(md.med_brand_name) = LOWER($1) OR LOWER(md.med_brand_name) LIKE LOWER($2))
            ORDER BY md.med_weightage DESC NULLS LAST
            LIMIT 1
        `;

        const result = await medicinePool.query(query, [cleanName, `%${cleanName}%`]);

        if (result.rows.length > 0) {
            const medicine = result.rows[0];
            console.log(`✅ Found in Medicine DB: ${medicine.drug_name} (ID: ${medicine.med_drug_id})`);

            const composition1_dose = (medicine.composition1_strength && medicine.composition1_unit)
                ? `${medicine.composition1_strength}${medicine.composition1_unit}`
                : null;
            const composition2_dose = (medicine.composition2_strength && medicine.composition2_unit)
                ? `${medicine.composition2_strength}${medicine.composition2_unit}`
                : null;

            return {
                success: true,
                data: {
                    id: medicine.med_drug_id,
                    name: medicine.drug_name,
                    generic_id: medicine.med_generic_id,
                    composition1_id: medicine.composition1_id,
                    composition1_name: medicine.composition1_name,
                    composition1_strength: medicine.composition1_strength,
                    composition1_unit: medicine.composition1_unit,
                    composition1_dose: composition1_dose,
                    composition2_id: medicine.composition2_id,
                    composition2_name: medicine.composition2_name,
                    composition2_strength: medicine.composition2_strength,
                    composition2_unit: medicine.composition2_unit,
                    composition2_dose: composition2_dose,
                    mrp: medicine.mrp,
                    manufacturer: medicine.manufacturer_name,
                    pack_size: medicine.pack_size,
                    med_type: medicine.med_type,
                    med_weightage: medicine.med_weightage
                }
            };
        } else {
            console.log(`❌ Not found in Medicine DB: "${medicineName}"`);
            return {
                success: false,
                data: null,
                message: 'Medicine not found in database'
            };
        }

    } catch (error) {
        console.error('❌ Error searching medicine database:', error);
        return {
            success: false,
            data: null,
            error: error.message
        };
    }
};

/**
 * Auto-link medicine with Anuvansh database using fuzzy matching
 * Enhanced for OCR-extracted prescriptions with typos and variations
 * @param {Object} medicine - Medicine object from prescription
 * @param {Object} options - Linking options
 * @returns {Object} - Enhanced medicine object with Anuvansh linking
 */
const autoLinkAnuvanshMedicine = async (medicine, options = {}) => {
    try {
        const {
            useFuzzyMatch = true,
            minSimilarity = 0.7
        } = options;

        // If med_drug_id is already provided, use it
        if (medicine.med_drug_id || medicine.drug_id || medicine.anuvansh_id) {
            const existingId = medicine.med_drug_id || medicine.drug_id || medicine.anuvansh_id;
            console.log(`💊 Medicine already has Anuvansh ID: ${existingId}`);
            return {
                ...medicine,
                med_drug_id: parseInt(existingId),
                anuvansh_linked: true,
                linking_method: 'manual'
            };
        }

        // Extract medicine name and salt for searching
        const medicineName = medicine.medicine_name || medicine.name || medicine.medicineName;
        const medicineSalt = medicine.medicine_salt || medicine.salt || medicine.generic_name;

        if (!medicineName) {
            return {
                ...medicine,
                med_drug_id: null,
                anuvansh_linked: false,
                linking_error: 'No medicine name provided'
            };
        }

        console.log(`🔗 Auto-linking medicine: "${medicineName}"${medicineSalt ? ` (salt: ${medicineSalt})` : ''}`);

        // Search in Anuvansh database with fuzzy matching
        const searchResult = await searchAnuvanshMedicine(medicineName, {
            useFuzzyMatch: useFuzzyMatch,
            minSimilarity: minSimilarity,
            includeSalt: medicineSalt
        });

        if (searchResult.success && searchResult.data) {
            console.log(`🔗 Auto-linked "${medicineName}" with Anuvansh ID: ${searchResult.data.id}`);
            console.log(`   Match type: ${searchResult.matchType || 'exact'}`);
            console.log(`   Confidence: ${((searchResult.confidence || 1.0) * 100).toFixed(1)}%`);
            console.log(`   Database name: "${searchResult.data.name}"`);

            return {
                ...medicine,
                med_drug_id: searchResult.data.id,
                anuvansh_linked: true,
                anuvansh_data: searchResult.data,
                linking_method: searchResult.matchType || 'auto',
                linking_confidence: searchResult.confidence || 1.0,
                alternative_matches: searchResult.alternativeMatches,
                // Enhance with Anuvansh data if not already present
                medicine_name: searchResult.data.name, // Use database name for consistency
                medicine_salt: medicine.medicine_salt || medicine.salt ||
                    (searchResult.data.composition1_name ?
                        `${searchResult.data.composition1_name}${searchResult.data.composition1_dose ? ' ' + searchResult.data.composition1_dose : ''}` :
                        null),
                medicine_strength: medicine.dosage || medicine.strength || null
            };
        } else {
            console.log(`⚠️ Could not auto-link "${medicineName}" with Anuvansh DB`);
            if (searchResult.suggestion) {
                console.log(`   Low confidence suggestion: ${searchResult.suggestion.name} (ID: ${searchResult.suggestion.id})`);
            }

            return {
                ...medicine,
                med_drug_id: null,
                anuvansh_linked: false,
                linking_method: 'failed',
                linking_error: searchResult.message || 'Medicine not found in Anuvansh database',
                suggestion: searchResult.suggestion
            };
        }

    } catch (error) {
        console.error('❌ Error in auto-linking with Anuvansh:', error);
        return {
            ...medicine,
            med_drug_id: null,
            anuvansh_linked: false,
            linking_error: error.message
        };
    }
};

/**
 * Process and enhance medicines array with Anuvansh linking
 * Enhanced with fuzzy matching for better OCR results
 * @param {Array} medicines - Array of medicine objects
 * @param {Object} options - Processing options
 * @returns {Object} - Enhanced medicines with linking results
 */
const processAnuvanshLinking = async (medicines, options = {}) => {
    const {
        autoLink = true,
        requireAnuvanshId = false,
        skipAutoLinkForManual = false,
        useFuzzyMatch = true,
        minSimilarity = 0.7
    } = options;

    console.log(`\n🔗 Processing Anuvansh linking for ${medicines.length} medicines`);
    console.log('Options:', { autoLink, requireAnuvanshId, skipAutoLinkForManual, useFuzzyMatch, minSimilarity });

    const processedMedicines = [];
    const linkingStats = {
        total: medicines.length,
        manual_linked: 0,
        exact_match: 0,
        fuzzy_match: 0,
        composition_match: 0,
        not_linked: 0,
        failed_linking: 0,
        high_confidence: 0, // >= 0.9
        medium_confidence: 0, // 0.7-0.89
        low_confidence: 0 // < 0.7
    };

    for (let i = 0; i < medicines.length; i++) {
        const medicine = medicines[i];
        const medicineName = medicine.medicine_name || medicine.name || `Medicine ${i + 1}`;
        console.log(`\n🔗 [${i + 1}/${medicines.length}] Processing: "${medicineName}"`);

        let processedMedicine;

        if (autoLink) {
            processedMedicine = await autoLinkAnuvanshMedicine(medicine, {
                useFuzzyMatch,
                minSimilarity
            });
        } else {
            processedMedicine = {
                ...medicine,
                med_drug_id: medicine.med_drug_id || medicine.drug_id || medicine.anuvansh_id || null,
                anuvansh_linked: !!(medicine.med_drug_id || medicine.drug_id || medicine.anuvansh_id),
                linking_method: 'disabled'
            };
        }

        // Update stats based on linking result
        if (processedMedicine.anuvansh_linked) {
            const method = processedMedicine.linking_method || 'unknown';
            const confidence = processedMedicine.linking_confidence || 1.0;

            if (method === 'manual') {
                linkingStats.manual_linked++;
            } else if (method === 'exact') {
                linkingStats.exact_match++;
            } else if (method === 'fuzzy') {
                linkingStats.fuzzy_match++;
            } else if (method === 'composition') {
                linkingStats.composition_match++;
            }

            // Track confidence levels
            if (confidence >= 0.9) {
                linkingStats.high_confidence++;
            } else if (confidence >= 0.7) {
                linkingStats.medium_confidence++;
            } else {
                linkingStats.low_confidence++;
            }
        } else if (processedMedicine.linking_method === 'failed') {
            linkingStats.failed_linking++;
        } else {
            linkingStats.not_linked++;
        }

        // Check if Anuvansh ID is required but missing
        if (requireAnuvanshId && !processedMedicine.anuvansh_linked) {
            throw new Error(
                `Medicine ${i + 1} "${medicineName}" requires Anuvansh database linking but could not be linked. ` +
                `Error: ${processedMedicine.linking_error || 'Unknown error'}`
            );
        }

        processedMedicines.push(processedMedicine);
    }

    const totalLinked = linkingStats.manual_linked + linkingStats.exact_match +
        linkingStats.fuzzy_match + linkingStats.composition_match;

    console.log('\n📊 ═══════════════════════════════════════════════════');
    console.log('📊 Anuvansh Linking Statistics:');
    console.log('📊 ═══════════════════════════════════════════════════');
    console.log(`   📦 Total medicines: ${linkingStats.total}`);
    console.log(`   ✅ Successfully linked: ${totalLinked} (${((totalLinked / linkingStats.total) * 100).toFixed(1)}%)`);
    console.log(`      ├─ 👤 Manual linked: ${linkingStats.manual_linked}`);
    console.log(`      ├─ 🎯 Exact match: ${linkingStats.exact_match}`);
    console.log(`      ├─ 🔍 Fuzzy match: ${linkingStats.fuzzy_match}`);
    console.log(`      └─ 🧪 Composition match: ${linkingStats.composition_match}`);
    console.log(`   ❌ Not linked: ${linkingStats.not_linked}`);
    console.log(`   ⚠️  Failed linking: ${linkingStats.failed_linking}`);
    console.log(`   `);
    console.log(`   Confidence Breakdown:`);
    console.log(`      🟢 High (≥90%): ${linkingStats.high_confidence}`);
    console.log(`      🟡 Medium (70-89%): ${linkingStats.medium_confidence}`);
    console.log(`      🔴 Low (<70%): ${linkingStats.low_confidence}`);
    console.log('📊 ═══════════════════════════════════════════════════\n');

    return {
        medicines: processedMedicines,
        stats: linkingStats,
        success: true,
        summary: {
            total: linkingStats.total,
            linked: totalLinked,
            linkingRate: ((totalLinked / linkingStats.total) * 100).toFixed(1) + '%'
        }
    };
};

/**
 * Get medicine details from medicine database by ID
 * @param {number} medDrugId - Medicine database ID
 * @returns {Object} - Medicine details or null
 */
const getAnuvanshMedicineById = async (medDrugId) => {
    try {
        console.log(`🔍 Fetching medicine details for ID: ${medDrugId}`);

        if (!medDrugId) {
            return {
                success: false,
                data: null,
                message: 'Medicine ID is required'
            };
        }

        const query = `
            SELECT 
                md.med_id as med_drug_id,
                md.med_brand_name as drug_name,
                md.med_generic_id,
                md.med_composition_id_1 as composition1_id,
                md.med_composition_name_1 as composition1_name,
                md.med_composition_strength_1 as composition1_strength,
                md.med_composition_unit_1 as composition1_unit,
                md.med_composition_id_2 as composition2_id,
                md.med_composition_name_2 as composition2_name,
                md.med_composition_strength_2 as composition2_strength,
                md.med_composition_unit_2 as composition2_unit,
                md.med_composition_id_3 as composition3_id,
                md.med_composition_name_3 as composition3_name,
                md.med_composition_strength_3 as composition3_strength,
                md.med_composition_unit_3 as composition3_unit,
                md.med_composition_id_4 as composition4_id,
                md.med_composition_name_4 as composition4_name,
                md.med_composition_strength_4 as composition4_strength,
                md.med_composition_unit_4 as composition4_unit,
                md.med_composition_id_5 as composition5_id,
                md.med_composition_name_5 as composition5_name,
                md.med_composition_strength_5 as composition5_strength,
                md.med_composition_unit_5 as composition5_unit,
                md.med_price as mrp,
                md.med_manufacturer_name as manufacturer_name,
                md.med_pack_size as pack_size,
                md.med_type,
                md.med_weightage
            FROM med_details md
            WHERE md.is_active = 1 
                AND md.is_deactivated = 0
                AND md.med_id = $1
        `;

        const result = await medicinePool.query(query, [medDrugId]);

        if (result.rows.length > 0) {
            const medicine = result.rows[0];
            console.log(`✅ Found medicine: ${medicine.drug_name}`);

            const composition1_dose = (medicine.composition1_strength && medicine.composition1_unit)
                ? `${medicine.composition1_strength}${medicine.composition1_unit}`
                : null;
            const composition2_dose = (medicine.composition2_strength && medicine.composition2_unit)
                ? `${medicine.composition2_strength}${medicine.composition2_unit}`
                : null;
            const composition3_dose = (medicine.composition3_strength && medicine.composition3_unit)
                ? `${medicine.composition3_strength}${medicine.composition3_unit}`
                : null;
            const composition4_dose = (medicine.composition4_strength && medicine.composition4_unit)
                ? `${medicine.composition4_strength}${medicine.composition4_unit}`
                : null;
            const composition5_dose = (medicine.composition5_strength && medicine.composition5_unit)
                ? `${medicine.composition5_strength}${medicine.composition5_unit}`
                : null;

            return {
                success: true,
                data: {
                    id: medicine.med_drug_id,
                    name: medicine.drug_name,
                    generic_id: medicine.med_generic_id,
                    composition1_id: medicine.composition1_id,
                    composition1_name: medicine.composition1_name,
                    composition1_strength: medicine.composition1_strength,
                    composition1_unit: medicine.composition1_unit,
                    composition1_dose: composition1_dose,
                    composition2_id: medicine.composition2_id,
                    composition2_name: medicine.composition2_name,
                    composition2_strength: medicine.composition2_strength,
                    composition2_unit: medicine.composition2_unit,
                    composition2_dose: composition2_dose,
                    composition3_id: medicine.composition3_id,
                    composition3_name: medicine.composition3_name,
                    composition3_strength: medicine.composition3_strength,
                    composition3_unit: medicine.composition3_unit,
                    composition3_dose: composition3_dose,
                    composition4_id: medicine.composition4_id,
                    composition4_name: medicine.composition4_name,
                    composition4_strength: medicine.composition4_strength,
                    composition4_unit: medicine.composition4_unit,
                    composition4_dose: composition4_dose,
                    composition5_id: medicine.composition5_id,
                    composition5_name: medicine.composition5_name,
                    composition5_strength: medicine.composition5_strength,
                    composition5_unit: medicine.composition5_unit,
                    composition5_dose: composition5_dose,
                    mrp: medicine.mrp,
                    manufacturer: medicine.manufacturer_name,
                    pack_size: medicine.pack_size,
                    med_type: medicine.med_type,
                    med_weightage: medicine.med_weightage
                }
            };
        } else {
            console.log(`❌ Medicine not found for ID: ${medDrugId}`);
            return {
                success: false,
                data: null,
                message: 'Medicine not found in database'
            };
        }

    } catch (error) {
        console.error('❌ Error fetching medicine details:', error);
        return {
            success: false,
            data: null,
            error: error.message
        };
    }
};

module.exports = {
    searchAnuvanshMedicine,
    autoLinkAnuvanshMedicine,
    processAnuvanshLinking,
    getAnuvanshMedicineById
};