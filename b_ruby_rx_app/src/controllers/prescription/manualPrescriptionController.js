const STATUS = require('../../utils/constants').STATUS;
const pool = require('../../config/dbConnection');
const { medicinePool } = require('../../config/multiDbConnection');

exports.createPrescription = async function (req, res, next) {

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        let userId = req.user?.patientId || 0; // Default to 0 if not authenticated

        // Validate and sanitize doctor information
        const doctorName = (req.body.doctor_name || 'System Doctor').replace(/'/g, "''");
        const doctorPhoneNumber = (req.body.doctor_phone_number || '0000000000').replace(/'/g, "''");
        const appointmentName = (req.body.appointment_name || 'General Consultation').replace(/'/g, "''");
        const clinicAddress = (req.body.clinic_address || req.body.clinic_name || 'City').replace(/'/g, "''");

        // Parse appointment date from request (format: DD/MM/YYYY) or use current date
        let appointmentDate = new Date();
        if (req.body.appointment_date) {
            try {
                // Parse DD/MM/YYYY format
                const dateParts = req.body.appointment_date.split('/');
                if (dateParts.length === 3) {
                    const day = parseInt(dateParts[0]);
                    const month = parseInt(dateParts[1]) - 1; // Month is 0-indexed
                    const year = parseInt(dateParts[2]);
                    appointmentDate = new Date(year, month, day);
                    console.log(`📅 Appointment date parsed: ${appointmentDate.toISOString()}`);
                }
            } catch (dateError) {
                console.warn('⚠️ Failed to parse appointment date, using current date:', dateError.message);
                appointmentDate = new Date();
            }
        }

        // Support legacy fields for backward compatibility
        const doctorSpecialty = (req.body.doctor_specialty || 'General Practitioner').replace(/'/g, "''");
        const doctorEmail = `${doctorName.replace(/\s+/g, '_').toLowerCase()}@example.com`;

        let insertDoctorObj = {
            dr_name: doctorName,
            dr_email: doctorEmail,
            dr_phone_number: doctorPhoneNumber,
            dr_highest_designation: appointmentName, // Store appointment name in designation field
            dr_licence_type: 'MD',
            dr_practice_start_date: new Date('2000-01-01'),
            dr_licence_id: req.body.doctor_license_number || 'SYS-' + Date.now().toString(),
            dr_dob: new Date('1970-01-01'),
            dr_specialization: doctorSpecialty,
            last_login: new Date(),
            created_at: new Date(),
            updated_at: new Date(),
            dr_city: clinicAddress, // Store clinic address in city field
            dr_state: 'State',
            dr_country: 'Country',
            dr_pin: '000000'
        };

        let insertDoctorQuery = `
            INSERT INTO public.doctors_records (
                dr_name,
                dr_email,
                dr_phone_number,
                dr_highest_designation,
                dr_licence_type,
                dr_practice_start_date,
                dr_licence_id,
                dr_dob,
                dr_specialization,
                last_login,
                created_at,
                updated_at,
                dr_city,
                dr_state,
                dr_country,
                dr_pin
            ) VALUES (
                '${insertDoctorObj.dr_name}',
                '${insertDoctorObj.dr_email}',
                '${insertDoctorObj.dr_phone_number}',
                '${insertDoctorObj.dr_highest_designation}',
                '${insertDoctorObj.dr_licence_type}',
                '${insertDoctorObj.dr_practice_start_date.toISOString()}',
                '${insertDoctorObj.dr_licence_id}',
                '${insertDoctorObj.dr_dob.toISOString()}',
                '${insertDoctorObj.dr_specialization}',
                '${insertDoctorObj.last_login.toISOString()}',
                '${insertDoctorObj.created_at.toISOString()}',
                '${insertDoctorObj.updated_at.toISOString()}',
                '${insertDoctorObj.dr_city}',
                '${insertDoctorObj.dr_state}',
                '${insertDoctorObj.dr_country}',
                '${insertDoctorObj.dr_pin}'
            )
            RETURNING dr_id;
        `;
        console.log('Insert Doctor Query:', insertDoctorQuery);
        let doctorRows = await client.query(insertDoctorQuery);
        let doctorId = doctorRows.rows[0]?.dr_id || 1; // Default to 1 if insertion fails

        // Sanitize prescription data (support both new and legacy fields)
        const bloodPressure = (req.body.patient_blood_pressure || '').replace(/'/g, "''");
        const pulse = (req.body.patient_pulse || '').replace(/'/g, "''");
        const temperature = (req.body.patient_temperature || '').replace(/'/g, "''");
        const weight = (req.body.patient_weight || '').replace(/'/g, "''");
        const medicalConditions = (req.body.medical_conditions || '').replace(/'/g, "''");

        console.log('📋 Prescription data received:', {
            doctor_name: doctorName,
            doctor_phone_number: doctorPhoneNumber,
            appointment_name: appointmentName,
            appointment_date: appointmentDate.toISOString(),
            clinic_address: clinicAddress,
            medicines_count: req.body.medicines?.length || 0
        });

        let insertPrescriptionObj = {
            patient_id: userId,
            prescription_raw_url: req.body.original_image_path || '',
            compiled_prescription_url: '',
            created_at: appointmentDate, // Use appointment date as created_at
            updated_at: new Date(),
            created_by: userId,
            updated_by: userId,
            dr_id: doctorId,
            patient_blood_pressure: bloodPressure,
            patient_pulse: pulse,
            patient_temprature: temperature,
            patient_weight: weight,
            medical_conditions: medicalConditions
        };

        let insertPrescriptionQuery = `
            INSERT INTO public.patient_prescription (
                patient_id,
                prescription_raw_url,
                compiled_prescription_url,
                created_at,
                updated_at,
                created_by,
                updated_by,
                dr_id,
                patient_blood_pressure,
                patient_pulse,
                patient_temprature,
                patient_weight,
                medical_conditions
            ) VALUES (
                ${userId},
                '${insertPrescriptionObj.prescription_raw_url}',
                '${insertPrescriptionObj.compiled_prescription_url}',
                '${insertPrescriptionObj.created_at.toISOString()}',
                '${insertPrescriptionObj.updated_at.toISOString()}',
                ${insertPrescriptionObj.created_by},
                ${insertPrescriptionObj.updated_by},
                ${insertPrescriptionObj.dr_id},
                '${insertPrescriptionObj.patient_blood_pressure}',
                '${insertPrescriptionObj.patient_pulse}',
                '${insertPrescriptionObj.patient_temprature}',
                '${insertPrescriptionObj.patient_weight}',
                '${insertPrescriptionObj.medical_conditions}'
            )
            RETURNING prescription_id;
        `;
        console.log('Insert Prescription Query:', insertPrescriptionQuery);
        let prescriptionRows = await client.query(insertPrescriptionQuery);
        let prescriptionId = prescriptionRows.rows[0]?.prescription_id || 1; // Default to 1 if insertion fails

        // Process medicines with database matching support
        let medicineList = [];
        const { processAnuvanshLinking } = require('../../utils/anuvanshMedicineIntegration');

        console.log(`\n📋 ═══════════════════════════════════════════════════`);
        console.log(`📋 Processing ${req.body.medicines.length} medicines for prescription ${prescriptionId}`);
        console.log(`📋 Using enhanced fuzzy matching for database linking`);
        console.log(`📋 ═══════════════════════════════════════════════════\n`);

        for (let i = 0; i < req.body.medicines.length; i++) {
            let med = req.body.medicines[i];

            // Sanitize medicine data
            const medicineName = (med.medicine_name || med.name || '').replace(/'/g, "''").trim();
            const medicineSalt = (med.medicine_salt || med.salt || '').replace(/'/g, "''").trim();
            const medicineFrequency = (med.medicine_frequency || med.frequency || '').replace(/'/g, "''").trim();

            if (!medicineName) {
                console.warn(`⚠️ Skipping medicine ${i + 1}: No medicine name provided`);
                continue;
            }

            // Determine medicine database ID with enhanced fuzzy matching
            // Priority: 1. Explicit id field, 2. med_drug_id, 3. Fuzzy auto-match, 4. Default to 0
            let medDrugId = 0;
            let matchingInfo = '';

            if (med.id && parseInt(med.id) > 0) {
                medDrugId = parseInt(med.id);
                matchingInfo = `Manually provided ID`;
                console.log(`✅ [${i + 1}/${req.body.medicines.length}] "${medicineName}" - Manual ID: ${medDrugId}`);
            } else if (med.med_drug_id && parseInt(med.med_drug_id) > 0) {
                medDrugId = parseInt(med.med_drug_id);
                matchingInfo = `Pre-matched ID`;
                console.log(`✅ [${i + 1}/${req.body.medicines.length}] "${medicineName}" - Pre-matched ID: ${medDrugId}`);
            } else {
                // Try fuzzy auto-match with database if no ID provided
                console.log(`🔍 [${i + 1}/${req.body.medicines.length}] Auto-matching: "${medicineName}"${medicineSalt ? ` (salt: ${medicineSalt})` : ''}`);

                try {
                    const linkingResult = await processAnuvanshLinking([{
                        medicine_name: medicineName,
                        medicine_salt: medicineSalt,
                        medicine_frequency: medicineFrequency
                    }], {
                        autoLink: true,
                        requireAnuvanshId: false,
                        useFuzzyMatch: true,    // Enable fuzzy matching
                        minSimilarity: 0.7      // 70% similarity threshold
                    });

                    if (linkingResult.success &&
                        linkingResult.medicines[0]?.anuvansh_linked &&
                        linkingResult.medicines[0]?.med_drug_id) {

                        medDrugId = linkingResult.medicines[0].med_drug_id;
                        const method = linkingResult.medicines[0].linking_method || 'auto';
                        const confidence = linkingResult.medicines[0].linking_confidence || 1.0;
                        const dbName = linkingResult.medicines[0].anuvansh_data?.name || medicineName;

                        matchingInfo = `${method} match (${(confidence * 100).toFixed(1)}% confidence)`;

                        console.log(`🔗 [${i + 1}/${req.body.medicines.length}] Match found!`);
                        console.log(`   OCR name: "${medicineName}"`);
                        console.log(`   DB name:  "${dbName}"`);
                        console.log(`   Method:   ${method}`);
                        console.log(`   Confidence: ${(confidence * 100).toFixed(1)}%`);
                        console.log(`   ID: ${medDrugId}`);
                    } else {
                        matchingInfo = `Not found in database (manual entry)`;
                        console.log(`⚠️ [${i + 1}/${req.body.medicines.length}] "${medicineName}" - Not found in database, saving as manual entry (ID: 0)`);
                    }
                } catch (linkingError) {
                    matchingInfo = `Matching error: ${linkingError.message}`;
                    console.error(`❌ [${i + 1}/${req.body.medicines.length}] Error matching "${medicineName}":`, linkingError.message);
                }
            }

            let insertMedicinesObj = {
                prescription_id: prescriptionId,
                medicine_name: medicineName,
                medicine_salt: medicineSalt,
                medicine_frequency: medicineFrequency,
                created_by: userId,
                created_at: new Date(),
                updated_by: userId,
                updated_at: new Date(),
                med_drug_id: medDrugId
            };

            medicineList.push(`
                (
                    ${insertMedicinesObj.prescription_id},
                    '${insertMedicinesObj.medicine_name}',
                    '${insertMedicinesObj.medicine_salt}',
                    '${insertMedicinesObj.medicine_frequency}',
                    ${insertMedicinesObj.created_by},
                    '${insertMedicinesObj.created_at.toISOString()}',
                    ${insertMedicinesObj.updated_by},
                    '${insertMedicinesObj.updated_at.toISOString()}',
                    ${insertMedicinesObj.med_drug_id}
                )
            `);
        }

        if (medicineList.length > 0) {
            let insertMedicinesQuery = `
                INSERT INTO public.patient_medicine (
                    prescription_id,
                    medicine_name,
                    medicine_salt,
                    medicine_frequency,
                    created_by,
                    created_at,
                    updated_by,
                    updated_at,
                    med_drug_id
                ) VALUES ${medicineList.join(',')};
            `;
            console.log('Insert Medicines Query:', insertMedicinesQuery);
            await client.query(insertMedicinesQuery);

            const linkedCount = medicineList.filter((_, idx) =>
                req.body.medicines[idx] &&
                (req.body.medicines[idx].med_drug_id > 0 || req.body.medicines[idx].id > 0)
            ).length;

            console.log(`\n✅ ═══════════════════════════════════════════════════`);
            console.log(`✅ Medicine Insertion Completed`);
            console.log(`✅ ═══════════════════════════════════════════════════`);
            console.log(`   Total medicines: ${medicineList.length}`);
            console.log(`   Database linked: ${linkedCount}`);
            console.log(`   Manual entries: ${medicineList.length - linkedCount}`);
            console.log(`✅ ═══════════════════════════════════════════════════\n`);
        } else {
            console.warn(`⚠️ No valid medicines to insert for prescription ${prescriptionId}`);
        }

        await client.query('COMMIT');

        res.locals = {
            status: STATUS.SUCCESS,
            message: 'Prescription created successfully with medicine database matching.',
            data: {
                prescription_id: prescriptionId,
                doctor_id: doctorId,
                medicines_count: medicineList.length
            }
        };
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Error in createPrescription:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: 'Error creating prescription',
            error: error.message
        };
    } finally {
        client.release();
    }

    next();
};


exports.getMyPrescriptionList = async (req, res, next) => {
    const client = await pool.connect();

    try {
        // Get patient ID from JWT token (populated by middleware)
        if (!req.user || !req.user.patientId) {
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Patient authentication required'
            };
            return next();
        }

        const patientId = req.user.patientId;
        const { page = 1, limit = 10 } = req.query;

        const offset = (parseInt(page) - 1) * parseInt(limit);

        console.log(`🔍 Getting prescriptions for authenticated patient ID: ${patientId}`);

        const prescriptionsQuery = `
            SELECT 
                pp.prescription_id,
                pp.patient_id::int,
                pp.prescription_raw_url,
                pp.compiled_prescription_url,
                pp.is_active,
                pp.created_at,
                pp.updated_at,
                pp.created_by::int,
                pp.updated_by::int,
                da.appointment_id::int,
                dr.dr_name,
                dr.dr_phone_number,
                dr.dr_specialization,
                dr.dr_highest_designation as appointment_name,
                dr.dr_city as clinic_address,
                pp.created_at as appointment_date,
                COUNT(pm.medicin_id) as medicine_count
            FROM patient_prescription pp
            LEFT JOIN dr_appointment da ON (
                da.patient_id = pp.patient_id 
                AND ABS(EXTRACT(EPOCH FROM (da.created_at - pp.created_at))) < 3600
            )
            LEFT JOIN doctors_records dr ON dr.dr_id = da.dr_id  or dr.dr_id = pp.dr_id
            LEFT JOIN patient_medicine pm ON pm.prescription_id = pp.prescription_id
            WHERE pp.patient_id = $1 AND pp.is_active = 1
            GROUP BY pp.prescription_id, pp.patient_id, pp.prescription_raw_url, 
                     pp.compiled_prescription_url, pp.is_active, pp.created_at, 
                     pp.updated_at, pp.created_by, pp.updated_by, da.appointment_id, 
                     dr.dr_name, dr.dr_phone_number, dr.dr_specialization, 
                     dr.dr_highest_designation, dr.dr_city
            ORDER BY pp.created_at DESC
            LIMIT $2 OFFSET $3
        `;

        const result = await client.query(prescriptionsQuery, [patientId, parseInt(limit), offset]);

        console.log(`✅ Found ${result.rows.length} prescriptions for patient ${patientId}`);

        // Get total count
        const countResult = await client.query(
            'SELECT COUNT(*) as total FROM patient_prescription WHERE patient_id = $1 AND is_active = 1',
            [patientId]
        );

        const total = parseInt(countResult.rows[0].total);
        const totalPages = Math.ceil(total / parseInt(limit));

        res.locals = {
            status: STATUS.SUCCESS,
            data: {
                prescriptions: result.rows,
                patient_info: {
                    patient_id: Number(req.user.patientId),
                    patient_name: req.user.fullName,
                    patient_email: req.user.email
                },
                pagination: {
                    current_page: parseInt(page),
                    total_pages: totalPages,
                    total_records: total,
                    limit: parseInt(limit)
                }
            }
        };

    } catch (error) {
        console.error('❌ Get my prescriptions error:', error);

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to retrieve prescription history'
        };
    } finally {
        client.release();
    }

    next();
};


exports.getPrescriptionDetail = async (req, res, next) => {
    const client = await pool.connect();

    try {
        // Get prescription ID from URL parameters
        const prescriptionId = req.params.id;

        if (!prescriptionId) {
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Prescription ID is required'
            };
            return next();
        }

        // Get patient ID from JWT token (populated by middleware)
        if (!req.user || !req.user.patientId) {
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Patient authentication required'
            };
            return next();
        }

        const patientId = req.user.patientId;

        console.log(`🔍 Getting prescription detail for ID: ${prescriptionId}, Patient: ${patientId}`);

        // Main query to get prescription details with doctor and patient info
        const prescriptionDetailQuery = `
            SELECT 
                pp.prescription_id::int,
                pp.patient_id::int,
                pp.prescription_raw_url,
                pp.compiled_prescription_url,
                pp.is_active,
                pp.created_at,
                pp.updated_at,
                pp.created_by::int,
                pp.updated_by::int,
                pp.dr_id::int,
                pp.patient_blood_pressure,
                pp.patient_pulse,
                pp.patient_temprature,
                pp.patient_weight,
                pp.medical_conditions,
                
                -- Doctor information
                dr.dr_name,
                dr.dr_email,
                dr.dr_phone_number,
                dr.dr_specialization,
                dr.dr_highest_designation,
                dr.dr_licence_id,
                dr.dr_city,
                dr.dr_state,
                dr.dr_country,
                
                -- Patient information
                pr.patient_first_name,
                pr.patient_last_name,
                pr.patient_email,
                pr.patient_phone_number,
                pr.patient_date_of_birth,
                pr.patient_address,
                pr.national_id_type,
                pr.national_id_number,
                
                -- Appointment information if available
                da.appointment_id::int,
                da.patient_height,
                pp.created_at as appointment_date,
                dad.appointment_summary,
                dad.appointemnt_transcription
                
            FROM patient_prescription pp
            LEFT JOIN doctors_records dr ON dr.dr_id = pp.dr_id
            LEFT JOIN patients_records pr ON pr.patient_id = pp.patient_id
            LEFT JOIN dr_appointment da ON (
                da.patient_id = pp.patient_id 
                AND da.dr_id = pp.dr_id
                AND ABS(EXTRACT(EPOCH FROM (da.created_at - pp.created_at))) < 3600
            )
            LEFT JOIN dr_appointment_details dad ON dad.appointment_id = da.appointment_id
            WHERE pp.prescription_id = $1 
                AND pp.patient_id = $2 
                AND pp.is_active = 1
        `;

        const prescriptionResult = await client.query(prescriptionDetailQuery, [prescriptionId, patientId]);

        if (prescriptionResult.rows.length === 0) {
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Prescription not found or access denied'
            };
            return next();
        }

        const prescriptionData = prescriptionResult.rows[0];

        // Get all medicines for this prescription
        const medicinesQuery = `
            SELECT 
                medicin_id::int,
                prescription_id::int,
                medicine_name,
                medicine_salt,
                medicine_frequency,
                created_at,
                updated_at,
                created_by::int,
                updated_by::int,
                med_drug_id::int
            FROM patient_medicine
            WHERE prescription_id = $1 AND is_active = 1
            ORDER BY created_at ASC
        `;

        const medicinesResult = await client.query(medicinesQuery, [prescriptionId]);

        // Get composition data from medicine database for medicines with med_drug_id
        const medicineClient = await medicinePool.connect();
        try {
            // Extract all med_drug_ids that are not null/0
            const medDrugIds = medicinesResult.rows
                .filter(m => m.med_drug_id && m.med_drug_id > 0)
                .map(m => m.med_drug_id);

            let compositionData = {};

            if (medDrugIds.length > 0) {
                console.log(`🔍 Fetching composition data for ${medDrugIds.length} medicines with med_drug_ids:`, medDrugIds);

                // Query medicine database for composition data
                const compositionQuery = `
                    SELECT 
                        md.med_id,
                        md.med_composition_id_1 as short_composition_1,
                        CONCAT(md.med_composition_strength_1, md.med_composition_unit_1) as short_composition_1_dose,
                        md.med_composition_id_2 as short_composition_2,
                        CONCAT(md.med_composition_strength_2, md.med_composition_unit_2) as short_composition_2_dose,
                        md.med_composition_name_1 as composition_1_name,
                        md.med_composition_name_2 as composition_2_name,
                        md.med_composition_id_3,
                        md.med_composition_name_3 as composition_3_name,
                        CONCAT(md.med_composition_strength_3, md.med_composition_unit_3) as composition_3_dose,
                        md.med_composition_id_4,
                        md.med_composition_name_4 as composition_4_name,
                        CONCAT(md.med_composition_strength_4, md.med_composition_unit_4) as composition_4_dose,
                        md.med_composition_id_5,
                        md.med_composition_name_5 as composition_5_name,
                        CONCAT(md.med_composition_strength_5, md.med_composition_unit_5) as composition_5_dose
                    FROM med_details md
                    WHERE md.is_active = 1 
                        AND md.is_deactivated = 0
                        AND md.med_id = ANY($1::int[])
                `;

                const compositionResult = await medicineClient.query(compositionQuery, [medDrugIds]);

                console.log(`✅ Found composition data for ${compositionResult.rows.length} medicines`);
                if (compositionResult.rows.length > 0) {
                    console.log('Sample composition data:', {
                        med_id: compositionResult.rows[0].med_id,
                        composition_1_id: compositionResult.rows[0].short_composition_1,
                        composition_1_name: compositionResult.rows[0].composition_1_name
                    });
                }

                // Create a map of med_id to composition data
                compositionResult.rows.forEach(row => {
                    compositionData[row.med_id] = {
                        composition_1_id: row.short_composition_1,
                        composition_1_name: row.composition_1_name,
                        composition_1_dose: row.short_composition_1_dose,
                        composition_2_id: row.short_composition_2,
                        composition_2_name: row.composition_2_name,
                        composition_2_dose: row.short_composition_2_dose,
                        composition_3_id: row.med_composition_id_3,
                        composition_3_name: row.composition_3_name,
                        composition_3_dose: row.composition_3_dose,
                        composition_4_id: row.med_composition_id_4,
                        composition_4_name: row.composition_4_name,
                        composition_4_dose: row.composition_4_dose,
                        composition_5_id: row.med_composition_id_5,
                        composition_5_name: row.composition_5_name,
                        composition_5_dose: row.composition_5_dose
                    };
                });
            }

            // Merge composition data with medicines
            medicinesResult.rows.forEach(medicine => {
                if (medicine.med_drug_id && compositionData[medicine.med_drug_id]) {
                    Object.assign(medicine, compositionData[medicine.med_drug_id]);
                    console.log(`✅ Merged composition data for medicine: ${medicine.medicine_name}, composition_1_id: ${medicine.composition_1_id}`);
                } else {
                    console.log(`⚠️ No composition data for medicine: ${medicine.medicine_name}, med_drug_id: ${medicine.med_drug_id}`);
                }
            });

        } finally {
            medicineClient.release();
        }

        // Calculate patient age if date of birth is available
        let patientAge = null;
        if (prescriptionData.patient_date_of_birth) {
            const birthDate = new Date(prescriptionData.patient_date_of_birth);
            const today = new Date();
            patientAge = today.getFullYear() - birthDate.getFullYear();
            const monthDiff = today.getMonth() - birthDate.getMonth();
            if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
                patientAge--;
            }
        }

        // Format vitals information
        const vitals = [];
        if (prescriptionData.patient_weight) vitals.push(`Weight: ${prescriptionData.patient_weight}`);
        if (prescriptionData.patient_height) vitals.push(`Height: ${prescriptionData.patient_height}`);
        if (prescriptionData.patient_blood_pressure) vitals.push(`BP: ${prescriptionData.patient_blood_pressure}`);
        if (prescriptionData.patient_pulse) vitals.push(`Pulse: ${prescriptionData.patient_pulse}`);
        if (prescriptionData.patient_temprature) vitals.push(`Temperature: ${prescriptionData.patient_temprature}`);

        // Structure the response according to the Flutter model expectations
        const responseData = {
            prescription_id: prescriptionData.prescription_id,
            patient_id: prescriptionData.patient_id,

            // Patient information
            patient_name: `${prescriptionData.patient_first_name || ''} ${prescriptionData.patient_last_name || ''}`.trim() || 'Patient',
            patient_age: patientAge,
            patient_gender: 'M', // Default value - can be enhanced later
            patient_weight: prescriptionData.patient_weight,
            vitals: vitals.join(', ') || 'Not recorded',

            // Doctor information
            doctor: prescriptionData.dr_name ? {
                doctor_id: prescriptionData.dr_id,
                doctor_name: prescriptionData.dr_name,
                doctor_email: prescriptionData.dr_email,
                doctor_phone_number: prescriptionData.dr_phone_number,
                doctor_specialization: prescriptionData.dr_specialization,
                doctor_designation: prescriptionData.dr_highest_designation,
                doctor_license_id: prescriptionData.dr_licence_id,
                doctor_city: prescriptionData.dr_city,
                doctor_state: prescriptionData.dr_state,
                doctor_country: prescriptionData.dr_country,
                // New fields mapping
                appointment_name: prescriptionData.dr_highest_designation, // Appointment name stored in designation
                clinic_address: prescriptionData.dr_city // Clinic address stored in city field
            } : null,

            // Prescription URLs
            prescription_raw_url: prescriptionData.prescription_raw_url,
            compiled_prescription_url: prescriptionData.compiled_prescription_url,

            // Medical information
            diagnosis: prescriptionData.medical_conditions,
            appointment_summary: prescriptionData.appointment_summary,
            appointment_transcription: prescriptionData.appointemnt_transcription,

            // Medicines list with composition data
            medicines: medicinesResult.rows.map(medicine => {
                const mappedMedicine = {
                    medicine_id: medicine.medicin_id,
                    medicine_name: medicine.medicine_name,
                    medicine_salt: medicine.medicine_salt,
                    medicine_frequency: medicine.medicine_frequency,
                    med_drug_id: medicine.med_drug_id,
                    composition_1_id: medicine.composition_1_id || medicine.short_composition_1,
                    composition_1_name: medicine.composition_1_name,
                    composition_1_dose: medicine.composition_1_dose || medicine.short_composition_1_dose,
                    composition_2_id: medicine.composition_2_id || medicine.short_composition_2,
                    composition_2_name: medicine.composition_2_name,
                    composition_2_dose: medicine.composition_2_dose || medicine.short_composition_2_dose,
                    composition_3_id: medicine.composition_3_id,
                    composition_3_name: medicine.composition_3_name,
                    composition_3_dose: medicine.composition_3_dose,
                    composition_4_id: medicine.composition_4_id,
                    composition_4_name: medicine.composition_4_name,
                    composition_4_dose: medicine.composition_4_dose,
                    composition_5_id: medicine.composition_5_id,
                    composition_5_name: medicine.composition_5_name,
                    composition_5_dose: medicine.composition_5_dose
                };

                console.log(`📋 Medicine in response: ${mappedMedicine.medicine_name}`, {
                    med_drug_id: mappedMedicine.med_drug_id,
                    composition_1_id: mappedMedicine.composition_1_id,
                    composition_1_name: mappedMedicine.composition_1_name
                });

                return mappedMedicine;
            }),

            // Vitals as separate fields for Flutter
            patient_blood_pressure: prescriptionData.patient_blood_pressure,
            patient_pulse: prescriptionData.patient_pulse,
            patient_temperature: prescriptionData.patient_temprature,
            patient_height: prescriptionData.patient_height,

            // Metadata
            created_at: prescriptionData.created_at,
            updated_at: prescriptionData.updated_at,
            appointment_date: prescriptionData.appointment_date
        };

        console.log(`✅ Successfully retrieved prescription detail for ID: ${prescriptionId}`);

        res.locals = {
            status: STATUS.SUCCESS,
            data: responseData,
            message: 'Prescription detail retrieved successfully'
        };

    } catch (error) {
        console.error('❌ Get prescription detail error:', error);

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to retrieve prescription detail',
            error: error.message
        };
    } finally {
        client.release();
    }

    next();
};

