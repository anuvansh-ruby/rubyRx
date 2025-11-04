/**
 * Fuzzy Medicine Matcher Utility
 * Advanced medicine name matching with multiple strategies for OCR-extracted prescriptions
 * Handles variations, typos, and different naming conventions
 */

const { medicinePool } = require('../config/multiDbConnection');

/**
 * Extract strength/dosage from medicine name
 * @param {string} medicineName - Medicine name that may contain dosage
 * @returns {Object} - Object with name and strength extracted
 */
function extractStrengthFromName(medicineName) {
    if (!medicineName) return { name: '', strength: null, unit: null };

    // Pattern to match dosage like "500mg", "10ml", "2.5mg", etc.
    const strengthPattern = /(\d+(?:\.\d+)?)\s*(mg|gm|ml|mcg|g|l|iu|%)/i;
    const match = medicineName.match(strengthPattern);

    if (match) {
        const strength = match[1];
        const unit = match[2].toLowerCase();
        const nameWithoutStrength = medicineName.replace(strengthPattern, '').trim();

        return {
            name: nameWithoutStrength,
            strength: strength,
            unit: unit,
            fullDose: `${strength}${unit}`
        };
    }

    return { name: medicineName.trim(), strength: null, unit: null, fullDose: null };
}

/**
 * Generate medicine name variations for fuzzy matching
 * Handles common OCR errors, abbreviations, and formatting differences
 * @param {string} medicineName - Original medicine name from OCR
 * @returns {Array<string>} - Array of name variations to try
 */
function generateMedicineNameVariations(medicineName) {
    if (!medicineName || typeof medicineName !== 'string') {
        return [];
    }

    const variations = new Set();
    const cleanName = medicineName.trim();

    // Add original name
    variations.add(cleanName);
    variations.add(cleanName.toLowerCase());

    // 1. Remove common suffixes (tablet forms, dosage indicators)
    const suffixPatterns = [
        /\s+(tablet|tab|capsule|cap|syrup|injection|inj|suspension|drops?|cream|ointment|gel|powder|sachet)s?$/i,
        /\s+\d+\s*(mg|gm|ml|mcg|g|l)$/i, // Remove dosages like "500mg", "10ml"
        /\s+\d+$/i, // Remove trailing numbers
        /\s+[A-Z]+$/i, // Remove trailing abbreviations like "DS", "SR", "XR"
    ];

    suffixPatterns.forEach(pattern => {
        const withoutSuffix = cleanName.replace(pattern, '').trim();
        if (withoutSuffix && withoutSuffix !== cleanName) {
            variations.add(withoutSuffix);
            variations.add(withoutSuffix.toLowerCase());
        }
    });

    // 2. Remove special characters and normalize spacing
    const normalized = cleanName
        .replace(/[^\w\s-]/g, ' ') // Replace special chars with space
        .replace(/\s+/g, ' ') // Normalize multiple spaces
        .trim();

    if (normalized !== cleanName) {
        variations.add(normalized);
        variations.add(normalized.toLowerCase());
    }

    // 3. Handle common brand name patterns (e.g., "Paracetamol-500" -> "Paracetamol")
    const withoutDash = cleanName.split(/[-_]/)[0].trim();
    if (withoutDash && withoutDash !== cleanName) {
        variations.add(withoutDash);
        variations.add(withoutDash.toLowerCase());
    }

    // 4. Handle parentheses and brackets (e.g., "Aspirin (Bayer)" -> "Aspirin")
    const withoutParens = cleanName.replace(/\s*[\(\[\{].*?[\)\]\}]\s*/g, ' ').trim();
    if (withoutParens && withoutParens !== cleanName) {
        variations.add(withoutParens);
        variations.add(withoutParens.toLowerCase());
    }

    // 5. Replace common OCR character confusions
    const ocrFixes = [
        { from: /0/g, to: 'O' }, // Zero to letter O
        { from: /O/g, to: '0' }, // Letter O to zero
        { from: /1/g, to: 'I' }, // One to letter I
        { from: /I/g, to: '1' }, // Letter I to one
        { from: /5/g, to: 'S' }, // Five to letter S
        { from: /S/g, to: '5' }, // Letter S to five
    ];

    // Apply OCR fixes selectively (only add a few key variations to avoid explosion)
    const firstOcrFix = cleanName.replace(ocrFixes[0].from, ocrFixes[0].to);
    if (firstOcrFix !== cleanName) {
        variations.add(firstOcrFix);
        variations.add(firstOcrFix.toLowerCase());
    }

    // 6. Single word extraction (for compound names)
    const words = cleanName.split(/\s+/);
    if (words.length > 1) {
        // Add longest word (usually the main drug name)
        const longestWord = words.reduce((a, b) => a.length > b.length ? a : b);
        if (longestWord.length > 3) {
            variations.add(longestWord);
            variations.add(longestWord.toLowerCase());
        }

        // Add first word if significant
        if (words[0].length > 3) {
            variations.add(words[0]);
            variations.add(words[0].toLowerCase());
        }
    }

    // 7. Remove "MR", "SR", "XR", "ER" (modified/sustained/extended release) suffixes
    const releaseTypes = ['MR', 'SR', 'XR', 'ER', 'CR', 'LA', 'XL', 'DS'];
    releaseTypes.forEach(type => {
        const pattern = new RegExp(`\\s+${type}$`, 'i');
        const withoutRelease = cleanName.replace(pattern, '').trim();
        if (withoutRelease !== cleanName) {
            variations.add(withoutRelease);
            variations.add(withoutRelease.toLowerCase());
        }
    });

    return Array.from(variations).filter(v => v && v.length >= 3); // Minimum 3 chars
}

/**
 * Calculate similarity score between two strings (Levenshtein-based)
 * @param {string} str1 - First string
 * @param {string} str2 - Second string
 * @returns {number} - Similarity score (0-1, higher is more similar)
 */
function calculateSimilarity(str1, str2) {
    if (!str1 || !str2) return 0;

    const s1 = str1.toLowerCase();
    const s2 = str2.toLowerCase();

    // Exact match
    if (s1 === s2) return 1.0;

    // Contains match (partial credit)
    if (s1.includes(s2) || s2.includes(s1)) {
        const minLen = Math.min(s1.length, s2.length);
        const maxLen = Math.max(s1.length, s2.length);
        return 0.8 * (minLen / maxLen);
    }

    // Levenshtein distance
    const len1 = s1.length;
    const len2 = s2.length;
    const matrix = Array(len1 + 1).fill(null).map(() => Array(len2 + 1).fill(0));

    for (let i = 0; i <= len1; i++) matrix[i][0] = i;
    for (let j = 0; j <= len2; j++) matrix[0][j] = j;

    for (let i = 1; i <= len1; i++) {
        for (let j = 1; j <= len2; j++) {
            const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
            matrix[i][j] = Math.min(
                matrix[i - 1][j] + 1,      // deletion
                matrix[i][j - 1] + 1,      // insertion
                matrix[i - 1][j - 1] + cost // substitution
            );
        }
    }

    const distance = matrix[len1][len2];
    const maxLen = Math.max(len1, len2);

    return Math.max(0, 1 - (distance / maxLen));
}

/**
 * Search medicine using multiple strategies with fuzzy matching
 * @param {string} medicineName - Medicine name from OCR
 * @param {Object} options - Search options
 * @returns {Promise<Object>} - Best matching medicine or null
 */
async function fuzzySearchMedicine(medicineName, options = {}) {
    const {
        minSimilarity = 0.7,        // Minimum similarity threshold (0-1)
        maxResults = 5,              // Maximum results to consider
        includeSalt = null,          // Optional salt/composition for better matching
        preferExactMatch = true      // Prefer exact matches over fuzzy
    } = options;

    try {
        console.log(`\n🔍 Fuzzy searching for medicine: "${medicineName}"`);

        if (!medicineName || medicineName.trim() === '') {
            return {
                success: false,
                match: null,
                confidence: 0,
                message: 'Medicine name is required'
            };
        }

        // Step 1: Generate name variations
        const variations = generateMedicineNameVariations(medicineName);
        console.log(`📝 Generated ${variations.length} name variations:`, variations.slice(0, 5));

        // Step 2: Try exact match first (fastest and most accurate)
        if (preferExactMatch) {
            for (const variant of variations) {
                const exactQuery = `
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
                        AND LOWER(md.med_brand_name) = LOWER($1)
                    ORDER BY md.med_weightage DESC NULLS LAST
                    LIMIT 1
                `;

                const result = await medicinePool.query(exactQuery, [variant]);

                if (result.rows.length > 0) {
                    const medicine = result.rows[0];
                    console.log(`✅ EXACT MATCH found: "${medicine.drug_name}" (ID: ${medicine.med_drug_id})`);

                    return {
                        success: true,
                        match: formatMedicineResult(medicine),
                        confidence: 1.0,
                        matchType: 'exact',
                        searchTerm: variant
                    };
                }
            }
        }

        // Step 3: Try fuzzy match with LIKE operator
        console.log('🔄 No exact match, trying fuzzy matching...');

        const fuzzyResults = [];

        for (const variant of variations) {
            // Skip very short variants to avoid too many false positives
            if (variant.length < 3) continue;

            const fuzzyQuery = `
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
                    md.med_weightage,
                    CASE
                        WHEN LOWER(md.med_brand_name) = LOWER($1) THEN 100
                        WHEN LOWER(md.med_brand_name) LIKE LOWER($1) || '%' THEN 90
                        WHEN LOWER(md.med_brand_name) LIKE '%' || LOWER($1) || '%' THEN 80
                        ELSE 70
                    END as match_score
                FROM med_details md
                WHERE md.is_active = 1 
                    AND md.is_deactivated = 0
                    AND LOWER(md.med_brand_name) LIKE '%' || LOWER($1) || '%'
                ORDER BY match_score DESC, md.med_weightage DESC NULLS LAST, LENGTH(md.med_brand_name) ASC
                LIMIT $2
            `;

            const result = await medicinePool.query(fuzzyQuery, [variant, maxResults]);

            if (result.rows.length > 0) {
                result.rows.forEach(row => {
                    // Calculate similarity between original name and database name
                    const similarity = calculateSimilarity(medicineName, row.drug_name);

                    fuzzyResults.push({
                        medicine: row,
                        similarity: similarity,
                        dbMatchScore: row.match_score,
                        searchTerm: variant
                    });
                });
            }
        }

        // Step 4: If salt/composition provided, try matching by composition
        // NOW ENHANCED WITH pg_trgm FUZZY MATCHING
        if (includeSalt && fuzzyResults.length === 0) {
            console.log(`🧪 Trying composition-based FUZZY search with salt: "${includeSalt}"`);

            // Extract strength from salt if present (e.g., "Paracetamol 500mg")
            const saltExtracted = extractStrengthFromName(includeSalt);
            const saltVariations = generateMedicineNameVariations(saltExtracted.name || includeSalt);

            for (const saltVariant of saltVariations) {
                // Build query with optional strength matching
                let compositionQuery;
                let queryParams;

                if (saltExtracted.strength && saltExtracted.unit) {
                    // Search with strength matching + fuzzy similarity for better accuracy
                    console.log(`   🎯 Searching with fuzzy + strength: ${saltExtracted.strength}${saltExtracted.unit}`);

                    compositionQuery = `
                        SELECT DISTINCT
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
                            md.med_weightage,
                            GREATEST(
                                similarity(LOWER(COALESCE(md.med_composition_name_1, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_2, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_3, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_4, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_5, '')), LOWER($1))
                            ) as comp_similarity,
                            CASE
                                WHEN (LOWER(md.med_composition_name_1) % LOWER($1)
                                      AND md.med_composition_strength_1 = $2 
                                      AND LOWER(md.med_composition_unit_1) = LOWER($3)) THEN 100
                                WHEN (LOWER(md.med_composition_name_2) % LOWER($1)
                                      AND md.med_composition_strength_2 = $2 
                                      AND LOWER(md.med_composition_unit_2) = LOWER($3)) THEN 100
                                WHEN (LOWER(md.med_composition_name_3) % LOWER($1)
                                      AND md.med_composition_strength_3 = $2 
                                      AND LOWER(md.med_composition_unit_3) = LOWER($3)) THEN 100
                                WHEN LOWER(md.med_composition_name_1) % LOWER($1) THEN 80
                                WHEN LOWER(md.med_composition_name_2) % LOWER($1) THEN 80
                                WHEN LOWER(md.med_composition_name_3) % LOWER($1) THEN 80
                                ELSE 70
                            END as comp_match_score
                        FROM med_details md
                        WHERE md.is_active = 1 
                            AND md.is_deactivated = 0
                            AND (
                                LOWER(md.med_composition_name_1) % LOWER($1)
                                OR LOWER(md.med_composition_name_2) % LOWER($1)
                                OR LOWER(md.med_composition_name_3) % LOWER($1)
                                OR LOWER(md.med_composition_name_4) % LOWER($1)
                                OR LOWER(md.med_composition_name_5) % LOWER($1)
                            )
                        ORDER BY comp_match_score DESC, comp_similarity DESC, md.med_weightage DESC NULLS LAST, LENGTH(md.med_brand_name) ASC
                        LIMIT $4
                    `;
                    queryParams = [saltVariant, saltExtracted.strength, saltExtracted.unit, maxResults];
                } else {
                    // Search without strength using fuzzy matching (ENHANCED WITH pg_trgm)
                    compositionQuery = `
                        SELECT DISTINCT
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
                            md.med_weightage,
                            GREATEST(
                                similarity(LOWER(COALESCE(md.med_composition_name_1, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_2, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_3, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_4, '')), LOWER($1)),
                                similarity(LOWER(COALESCE(md.med_composition_name_5, '')), LOWER($1))
                            ) as comp_similarity
                        FROM med_details md
                        WHERE md.is_active = 1 
                            AND md.is_deactivated = 0
                            AND (
                                LOWER(md.med_composition_name_1) % LOWER($1)
                                OR LOWER(md.med_composition_name_2) % LOWER($1)
                                OR LOWER(md.med_composition_name_3) % LOWER($1)
                                OR LOWER(md.med_composition_name_4) % LOWER($1)
                                OR LOWER(md.med_composition_name_5) % LOWER($1)
                            )
                        ORDER BY comp_similarity DESC, md.med_weightage DESC NULLS LAST, LENGTH(md.med_brand_name) ASC
                        LIMIT $2
                    `;
                    queryParams = [saltVariant, maxResults];
                }

                const result = await medicinePool.query(compositionQuery, queryParams);

                if (result.rows.length > 0) {
                    result.rows.forEach(row => {
                        // Use pg_trgm similarity score from database (0-1 scale)
                        let bestCompSimilarity = row.comp_similarity || 0;

                        // Boost similarity if strength also matches
                        let strengthBonus = 1.0;
                        if (saltExtracted.strength && saltExtracted.unit) {
                            if ((row.composition1_strength === saltExtracted.strength &&
                                row.composition1_unit?.toLowerCase() === saltExtracted.unit?.toLowerCase()) ||
                                (row.composition2_strength === saltExtracted.strength &&
                                    row.composition2_unit?.toLowerCase() === saltExtracted.unit?.toLowerCase()) ||
                                (row.composition3_strength === saltExtracted.strength &&
                                    row.composition3_unit?.toLowerCase() === saltExtracted.unit?.toLowerCase())) {
                                strengthBonus = 1.15; // 15% boost for exact strength match
                                console.log(`   ✅ Strength match found for ${row.drug_name}`);
                            }
                        }

                        // Use database similarity score directly (already calculated by pg_trgm)
                        const finalSimilarity = Math.min(bestCompSimilarity * strengthBonus * 0.9, 1.0);

                        console.log(`   📊 ${row.drug_name}: comp_sim=${bestCompSimilarity.toFixed(3)}, final=${finalSimilarity.toFixed(3)}`);

                        fuzzyResults.push({
                            medicine: row,
                            similarity: finalSimilarity,
                            dbMatchScore: row.comp_match_score || 85,
                            searchTerm: `${saltVariant}${saltExtracted.fullDose ? ` ${saltExtracted.fullDose}` : ''} (composition)`,
                            matchType: 'composition'
                        });
                    });
                }
            }
        }

        // Step 5: Rank and select best match
        if (fuzzyResults.length === 0) {
            console.log(`❌ No fuzzy matches found for "${medicineName}"`);
            return {
                success: false,
                match: null,
                confidence: 0,
                message: 'Medicine not found in database'
            };
        }

        // Sort by similarity score (higher is better)
        fuzzyResults.sort((a, b) => b.similarity - a.similarity);

        const bestMatch = fuzzyResults[0];

        // Check if best match meets minimum threshold
        if (bestMatch.similarity < minSimilarity) {
            console.log(`⚠️ Best match similarity (${bestMatch.similarity.toFixed(2)}) below threshold (${minSimilarity})`);
            console.log(`   Found: "${bestMatch.medicine.drug_name}" but not confident enough`);

            return {
                success: false,
                match: null,
                confidence: bestMatch.similarity,
                suggestion: formatMedicineResult(bestMatch.medicine),
                message: `Low confidence match. Suggested: ${bestMatch.medicine.drug_name}`
            };
        }

        console.log(`✅ FUZZY MATCH found: "${bestMatch.medicine.drug_name}" (ID: ${bestMatch.medicine.med_drug_id})`);
        console.log(`   Confidence: ${(bestMatch.similarity * 100).toFixed(1)}% | Search term: "${bestMatch.searchTerm}"`);

        return {
            success: true,
            match: formatMedicineResult(bestMatch.medicine),
            confidence: bestMatch.similarity,
            matchType: bestMatch.matchType || 'fuzzy',
            searchTerm: bestMatch.searchTerm,
            alternativeMatches: fuzzyResults.slice(1, 3).map(r => ({
                name: r.medicine.drug_name,
                id: r.medicine.med_drug_id,
                confidence: r.similarity
            }))
        };

    } catch (error) {
        console.error('❌ Error in fuzzy medicine search:', error);
        return {
            success: false,
            match: null,
            confidence: 0,
            error: error.message
        };
    }
}

/**
 * Format medicine database result into standard structure
 * @param {Object} medicine - Raw medicine data from database
 * @returns {Object} - Formatted medicine object
 */
function formatMedicineResult(medicine) {
    return {
        id: medicine.med_drug_id,
        med_drug_id: medicine.med_drug_id,
        name: medicine.drug_name,
        brand_name: medicine.drug_name,
        generic_id: medicine.med_generic_id,
        // Composition 1
        composition1_id: medicine.composition1_id,
        composition1_name: medicine.composition1_name,
        composition1_strength: medicine.composition1_strength,
        composition1_unit: medicine.composition1_unit,
        composition1_dose: medicine.composition1_strength && medicine.composition1_unit
            ? `${medicine.composition1_strength}${medicine.composition1_unit}`
            : null,
        // Composition 2
        composition2_id: medicine.composition2_id,
        composition2_name: medicine.composition2_name,
        composition2_strength: medicine.composition2_strength,
        composition2_unit: medicine.composition2_unit,
        composition2_dose: medicine.composition2_strength && medicine.composition2_unit
            ? `${medicine.composition2_strength}${medicine.composition2_unit}`
            : null,
        // Composition 3
        composition3_id: medicine.composition3_id,
        composition3_name: medicine.composition3_name,
        composition3_strength: medicine.composition3_strength,
        composition3_unit: medicine.composition3_unit,
        composition3_dose: medicine.composition3_strength && medicine.composition3_unit
            ? `${medicine.composition3_strength}${medicine.composition3_unit}`
            : null,
        // Composition 4
        composition4_id: medicine.composition4_id,
        composition4_name: medicine.composition4_name,
        composition4_strength: medicine.composition4_strength,
        composition4_unit: medicine.composition4_unit,
        composition4_dose: medicine.composition4_strength && medicine.composition4_unit
            ? `${medicine.composition4_strength}${medicine.composition4_unit}`
            : null,
        // Composition 5
        composition5_id: medicine.composition5_id,
        composition5_name: medicine.composition5_name,
        composition5_strength: medicine.composition5_strength,
        composition5_unit: medicine.composition5_unit,
        composition5_dose: medicine.composition5_strength && medicine.composition5_unit
            ? `${medicine.composition5_strength}${medicine.composition5_unit}`
            : null,
        // Full composition string
        composition: buildCompositionString(medicine),
        // Other details
        mrp: medicine.mrp,
        manufacturer: medicine.manufacturer_name,
        pack_size: medicine.pack_size,
        med_type: medicine.med_type,
        med_weightage: medicine.med_weightage
    };
}

/**
 * Build full composition string from components
 * @param {Object} medicine - Medicine data
 * @returns {string} - Formatted composition string
 */
function buildCompositionString(medicine) {
    const parts = [];

    // Composition 1
    if (medicine.composition1_name) {
        const dose1 = (medicine.composition1_strength && medicine.composition1_unit)
            ? ` ${medicine.composition1_strength}${medicine.composition1_unit}`
            : '';
        parts.push(`${medicine.composition1_name}${dose1}`);
    }

    // Composition 2
    if (medicine.composition2_name) {
        const dose2 = (medicine.composition2_strength && medicine.composition2_unit)
            ? ` ${medicine.composition2_strength}${medicine.composition2_unit}`
            : '';
        parts.push(`${medicine.composition2_name}${dose2}`);
    }

    // Composition 3
    if (medicine.composition3_name) {
        const dose3 = (medicine.composition3_strength && medicine.composition3_unit)
            ? ` ${medicine.composition3_strength}${medicine.composition3_unit}`
            : '';
        parts.push(`${medicine.composition3_name}${dose3}`);
    }

    // Composition 4
    if (medicine.composition4_name) {
        const dose4 = (medicine.composition4_strength && medicine.composition4_unit)
            ? ` ${medicine.composition4_strength}${medicine.composition4_unit}`
            : '';
        parts.push(`${medicine.composition4_name}${dose4}`);
    }

    // Composition 5
    if (medicine.composition5_name) {
        const dose5 = (medicine.composition5_strength && medicine.composition5_unit)
            ? ` ${medicine.composition5_strength}${medicine.composition5_unit}`
            : '';
        parts.push(`${medicine.composition5_name}${dose5}`);
    }

    return parts.length > 0 ? parts.join(' + ') : null;
}

/**
 * Batch fuzzy search for multiple medicines
 * @param {Array} medicines - Array of medicine objects with name and optionally salt
 * @param {Object} options - Search options
 * @returns {Promise<Array>} - Array of search results
 */
async function batchFuzzySearch(medicines, options = {}) {
    console.log(`\n🔍 Starting batch fuzzy search for ${medicines.length} medicines`);

    const results = [];

    for (let i = 0; i < medicines.length; i++) {
        const medicine = medicines[i];
        const medicineName = medicine.medicine_name || medicine.name;
        const salt = medicine.medicine_salt || medicine.salt;

        console.log(`\n[${i + 1}/${medicines.length}] Processing: "${medicineName}"`);

        const searchResult = await fuzzySearchMedicine(medicineName, {
            ...options,
            includeSalt: salt
        });

        results.push({
            original: medicine,
            searchResult: searchResult,
            index: i
        });
    }

    const successCount = results.filter(r => r.searchResult.success).length;
    console.log(`\n✅ Batch search completed: ${successCount}/${medicines.length} medicines matched`);

    return results;
}

module.exports = {
    fuzzySearchMedicine,
    batchFuzzySearch,
    generateMedicineNameVariations,
    calculateSimilarity,
    formatMedicineResult,
    extractStrengthFromName
};
