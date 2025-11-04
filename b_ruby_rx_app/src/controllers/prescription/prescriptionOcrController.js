const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');

// Import medical data mapper for standardizing OCR values
const { mapPrescriptionData, getAvailableOptions } = require('../../utils/medicalDataMapper');

// Google Vision API for OCR
let visionClient = null;
let visionApiAvailable = false;

// Gemini AI for intelligent data parsing
let geminiModel = null;
let geminiApiAvailable = false;

try {
    const vision = require('@google-cloud/vision');

    // Configure Google Vision client
    visionClient = new vision.ImageAnnotatorClient({
        // Add your Google Cloud credentials here
        keyFilename: process.env.GOOGLE_CLOUD_KEYFILE_PATH,
        // projectId: process.env.GOOGLE_CLOUD_PROJECT_ID,
    });

    visionApiAvailable = true;
    console.log('✅ Google Vision API client initialized');
} catch (error) {
    console.warn('⚠️ Google Vision API not available:', error.message);
    console.warn('🔄 Falling back to mock OCR processing');
    visionApiAvailable = false;
}

// Initialize Gemini AI
try {
    const { GoogleGenerativeAI } = require('@google/generative-ai');

    if (process.env.GEMINI_API_KEY) {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

        // Use the correct model name based on the current Gemini API
        // As of 2024, the stable model is "gemini-1.5-flash"
        try {
            geminiModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
            geminiApiAvailable = true;
            console.log(`✅ Gemini AI client initialized with model: gemini-2.5-flash`);
        } catch (modelError) {
            console.log(`⚠️ Primary model gemini-2.5-flash not available: ${modelError.message}`);

            // Try fallback model
            try {
                geminiModel = genAI.getGenerativeModel({ model: "gemini-2.5-pro" });
                geminiApiAvailable = true;
                console.log(`✅ Gemini AI client initialized with fallback model: gemini-1.5-pro`);
            } catch (fallbackError) {
                console.warn('⚠️ All Gemini models unavailable, falling back to manual parsing');
                console.warn('Fallback error:', fallbackError.message);
                geminiApiAvailable = false;
            }
        }
    } else {
        console.warn('⚠️ GEMINI_API_KEY not found in environment variables');
        geminiApiAvailable = false;
    }
} catch (error) {
    console.warn('⚠️ Gemini AI not available:', error.message);
    console.warn('🔄 Falling back to manual parsing');
    geminiApiAvailable = false;
}

// Enhanced file validation
function validateUploadFile(file) {
    const errors = [];

    // Check file type
    const allowedMimeTypes = [
        'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
        'image/bmp', 'image/webp', 'image/tiff', 'image/tif'
    ];

    if (!allowedMimeTypes.includes(file.mimetype)) {
        errors.push(`Unsupported file type: ${file.mimetype}. Allowed types: ${allowedMimeTypes.join(', ')}`);
    }

    // Check file size (10MB limit)
    if (file.size > 10 * 1024 * 1024) {
        errors.push(`File size ${(file.size / 1024 / 1024).toFixed(2)}MB exceeds 10MB limit`);
    }

    if (file.size === 0) {
        errors.push('File is empty');
    }

    // Check filename
    if (!file.originalname || file.originalname.length > 255) {
        errors.push('Invalid filename');
    }

    // Check for potentially malicious file extensions in disguised files
    const suspiciousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.com', '.pif'];
    const originalLower = file.originalname.toLowerCase();
    if (suspiciousExtensions.some(ext => originalLower.includes(ext))) {
        errors.push('Suspicious file detected');
    }

    return errors;
}

// Enhanced storage configuration with error handling
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadPath = path.join(__dirname, '../../../uploads/prescriptions');

        try {
            // Create directory if it doesn't exist
            if (!fs.existsSync(uploadPath)) {
                fs.mkdirSync(uploadPath, { recursive: true });
                console.log(`📁 Created upload directory: ${uploadPath}`);
            }

            // Check if directory is writable
            fs.accessSync(uploadPath, fs.constants.W_OK);

            // Check available disk space (basic check)
            const stats = fs.statSync(uploadPath);

            cb(null, uploadPath);
        } catch (error) {
            console.error('❌ Storage configuration error:', error);
            cb(new Error(`Storage error: ${error.message}`), null);
        }
    },
    filename: function (req, file, cb) {
        try {
            // Sanitize filename
            const sanitizedOriginalName = file.originalname
                .replace(/[^a-zA-Z0-9._-]/g, '_')
                .substring(0, 100);

            // Generate unique filename
            const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
            const extension = path.extname(sanitizedOriginalName);
            const filename = `prescription_${uniqueSuffix}${extension}`;

            cb(null, filename);
        } catch (error) {
            console.error('❌ Filename generation error:', error);
            cb(new Error(`Filename error: ${error.message}`), null);
        }
    }
});

// Enhanced file filter with detailed validation
const fileFilter = (req, file, cb) => {
    try {
        const validationErrors = validateUploadFile(file);

        if (validationErrors.length > 0) {
            const error = new Error(`File validation failed: ${validationErrors.join(', ')}`);
            error.code = 'FILE_VALIDATION_ERROR';
            cb(error, false);
            return;
        }

        cb(null, true);
    } catch (error) {
        console.error('❌ File filter error:', error);
        cb(new Error(`File validation error: ${error.message}`), false);
    }
};

// Enhanced multer configuration with single image restriction
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit per file
        files: 1, // RESTRICTED: Only 1 file allowed
        fields: 10, // Reduced field limit
        parts: 15 // Reduced parts limit
    },
    onError: function (err, next) {
        console.error('❌ Multer error:', err);
        next(err);
    }
});

// Enhanced image processing and validation
async function validateAndProcessImage(imagePath) {
    try {
        // Check if file exists
        if (!fs.existsSync(imagePath)) {
            throw new Error('Uploaded file not found on server');
        }

        // Get file stats
        const stats = fs.statSync(imagePath);
        if (stats.size === 0) {
            throw new Error('Uploaded file is empty');
        }

        // Validate image using Sharp
        const metadata = await sharp(imagePath).metadata();

        // Check image properties
        if (!metadata.width || !metadata.height) {
            throw new Error('Invalid image dimensions');
        }

        if (metadata.width < 100 || metadata.height < 100) {
            throw new Error('Image too small for OCR processing (minimum 100x100 pixels)');
        }

        if (metadata.width > 10000 || metadata.height > 10000) {
            throw new Error('Image too large for processing (maximum 10000x10000 pixels)');
        }

        // Check for corruption by attempting to read the image
        await sharp(imagePath).toBuffer();

        console.log(`📸 Image validated: ${metadata.width}x${metadata.height}, ${metadata.format}, ${(stats.size / 1024).toFixed(1)}KB`);

        return {
            width: metadata.width,
            height: metadata.height,
            format: metadata.format,
            size: stats.size,
            isValid: true
        };
    } catch (error) {
        console.error('❌ Image validation error:', error);
        throw new Error(`Image validation failed: ${error.message}`);
    }
}

/**
 * Extract text from prescription image using Google Vision API
 * @param {string} imagePath - Path to the prescription image
 * @returns {Promise<Object>} Extracted prescription data
 */
async function extractPrescriptionData(imagePath) {
    try {
        if (!visionApiAvailable) {
            // Mock OCR processing when Vision API is not available
            console.log('🔄 Using mock OCR processing for:', imagePath);
            return generateMockOcrData(imagePath);
        }

        // Perform OCR using Google Vision API
        const [result] = await visionClient.textDetection(imagePath);
        const detections = result.textAnnotations;

        if (!detections || detections.length === 0) {
            throw new Error('No text detected in the image');
        }

        const extractedText = detections[0].description;
        console.log('📄 OCR extracted text length:', extractedText.length);

        // Process the extracted text using AI-powered parsing
        const prescriptionData = await parsePrescriptionTextWithAI(extractedText);

        // Calculate overall confidence score
        const confidence = calculateOverallConfidence(detections);

        return {
            ...prescriptionData,
            confidence_score: confidence,
            extracted_text: extractedText,
            requires_manual_review: confidence < 0.7 || prescriptionData.extraction_warnings.length > 0
        };

    } catch (error) {
        console.error('OCR Processing Error:', error);

        if (!visionApiAvailable) {
            // If Vision API is not available, return mock data instead of throwing error
            console.log('🔄 Falling back to mock OCR data due to Vision API unavailability');
            return generateMockOcrData(imagePath);
        }

        throw new Error(`Failed to extract text from prescription: ${error.message}`);
    }
}

/**
 * Generate mock OCR data for testing when Vision API is not available
 */
function generateMockOcrData(imagePath) {
    const fileName = imagePath.split('/').pop() || 'prescription';

    const mockData = {
        doctor_name: 'Dr. Sample Physician',
        doctor_specialty: 'General Medicine',
        doctor_license_number: null,
        clinic_name: 'Sample Medical Center',
        patient_name: 'John Doe',
        patient_age: '35',
        patient_gender: 'Male',
        medical_conditions: null,
        blood_pressure: '120/80',
        pulse: '72 bpm',
        temperature: null,
        weight: null,
        height: null,
        prescription_date: new Date().toISOString().split('T')[0],
        diagnosis: 'Sample diagnosis from mock data',
        additional_notes: `Mock OCR data generated for ${fileName}`,
        medications: [
            {
                name: 'Paracetamol',
                generic_name: 'Acetaminophen',
                dosage: '500mg',
                frequency: 'Twice a day', // Using standardized format
                duration: '1 Week', // Using standardized format
                instructions: 'Take after meals',
                salt: 'Paracetamol',
                confidence: 0.85
            },
            {
                name: 'Ibuprofen',
                generic_name: 'Ibuprofen',
                dosage: '200mg',
                frequency: 'Thrice a day', // Using standardized format
                duration: '3 Days', // Using standardized format
                instructions: 'Take with food',
                salt: 'Ibuprofen',
                confidence: 0.90
            }
        ],
        confidence_score: 0.88,
        extracted_text: `MOCK PRESCRIPTION DATA\nDoctor: Dr. Sample Physician\nPatient: John Doe\nAge: 35\nRx:\n1. Paracetamol 500mg - Twice daily for 5 days\n2. Ibuprofen 200mg - Three times daily for 3 days`,
        requires_manual_review: false,
        extraction_warnings: ['This is mock data - Vision API not configured']
    };

    // Apply medical data mapping to ensure consistency
    return mapPrescriptionData(mockData);
}

/**
 * Parse extracted text using Gemini AI to identify prescription components
 * @param {string} text - Raw OCR extracted text
 * @returns {Object} Structured prescription data matching frontend PrescriptionOcrData model
 */
async function parsePrescriptionTextWithAI(text) {
    if (!geminiApiAvailable) {
        console.log('🔄 Falling back to manual parsing - Gemini AI not available');
        return await parsePrescriptionText(text);
    }

    try {
        console.log('🤖 Using Gemini AI for intelligent prescription parsing');

        const prompt = `
            You are an expert medical prescription parser with deep knowledge of medical terminology and prescription formats. Your task is to parse OCR-extracted prescription text and return a JSON object with standardized medical values.

            ⚠️ CRITICAL: You MUST use ONLY the exact standardized values below. Do NOT use any other variations.

            📋 FREQUENCY OPTIONS (Choose EXACTLY one of these):
            - "Once a day"     ← Use for: daily, od, qd, once daily, 1x daily, once per day, every 24 hours
            - "Twice a day"    ← Use for: bid, bd, twice daily, 2x daily, every 12 hours, twice per day
            - "Thrice a day"   ← Use for: tid, tds, three times daily, 3x daily, every 8 hours, thrice daily
            - "Once weekly"    ← Use for: weekly, once per week, qw, every week, 1x weekly
            - "Twice weekly"   ← Use for: twice per week, 2x weekly, biweekly
            - "Once a month"   ← Use for: monthly, once per month, every month, 1x monthly

            ⏰ DURATION OPTIONS (Choose EXACTLY one of these):
            - "1 Day"      ← Use for: 1 day, one day, single day
            - "2 Days"     ← Use for: 2 days, two days, couple of days
            - "3 Days"     ← Use for: 3 days, three days, 4-5 days (round to closest)
            - "1 Week"     ← Use for: 1 week, one week, 7 days, 6-8 days, a week
            - "2 Weeks"    ← Use for: 2 weeks, two weeks, 14 days, 10-15 days, fortnight
            - "3 Weeks"    ← Use for: 3 weeks, three weeks, 21 days, 18-23 days
            - "1 Month"    ← Use for: 1 month, one month, 30 days, 28-35 days, a month
            - "2 Months"   ← Use for: 2 months, two months, 60 days, 8 weeks
            - "3 Months"   ← Use for: 3 months, three months, 90 days, quarterly

            👤 GENDER OPTIONS (Choose EXACTLY one of these):
            - "Male"       ← Use for: male, man, boy, m, masculine
            - "Female"     ← Use for: female, woman, girl, f, feminine  
            - "Other"      ← Use for: other, transgender, non-binary, prefer not to say

            📝 JSON STRUCTURE (Follow exactly):
            {
            "doctor_name": "string or null",
            "doctor_specialty": "string or null", 
            "doctor_license_number": "string or null",
            "clinic_name": "string or null",
            "patient_name": "string or null",
            "patient_age": "string or null",
            "patient_gender": "Male|Female|Other|null",
            "medical_conditions": "string or null",
            "blood_pressure": "string or null (format: 120/80)",
            "pulse": "string or null (format: 72 bpm)",
            "temperature": "string or null (format: 98.6°F)",
            "weight": "string or null (format: 70 kg)",
            "height": "string or null (format: 5'8\")",
            "prescription_date": "string or null (YYYY-MM-DD format)",
            "diagnosis": "string or null",
            "additional_notes": "string or null",
            "medications": [
                {
                "name": "string (medication name)",
                "generic_name": "string or null",
                "dosage": "string or null (e.g., 500mg, 10ml, 1 tablet)",
                "frequency": "EXACT frequency option from above list or null",
                "duration": "EXACT duration option from above list or null", 
                "instructions": "string or null (special instructions)",
                "salt": "string or null (active ingredient)",
                "confidence": 0.8
                }
            ],
            "extraction_warnings": ["array of warning strings"]
            }

            🎯 PARSING RULES:
            1. ACCURACY FIRST: Only extract clearly visible information
            2. STANDARDIZATION: Always map to exact dropdown values listed above
            3. MEDICATION FOCUS: Separate name, dosage, frequency, duration carefully
            4. CONFIDENCE SCORING: Rate 0.1-1.0 based on text clarity
            5. WARNING SYSTEM: Flag unclear or missing critical data
            6. NULL HANDLING: Use null for missing/unclear fields
            7. JSON ONLY: Return valid JSON without markdown or extra text

            🔍 DETAILED MAPPING EXAMPLES:

            Frequency Conversions:
            "Take twice daily" → "Twice a day"
            "BID" → "Twice a day"  
            "Every 8 hours" → "Thrice a day"
            "TID" → "Thrice a day"
            "Once per day" → "Once a day"
            "QD" → "Once a day"
            "Weekly dosing" → "Once weekly"
            "Every week" → "Once weekly"
            "Monthly" → "Once a month"

            Duration Conversions:
            "For 5 days" → "3 Days" (closest available)
            "Continue for one week" → "1 Week"
            "Take for 10 days" → "1 Week" (closest available)
            "For 2 weeks" → "2 Weeks"
            "For a month" → "1 Month"
            "For 45 days" → "1 Month" (closest available)
            "For 3 months" → "3 Months"

            Complex Examples:
            "Take Paracetamol 500mg twice daily for 5 days"
            → name: "Paracetamol", dosage: "500mg", frequency: "Twice a day", duration: "3 Days"

            "Amoxicillin 250mg TID x 7 days"  
            → name: "Amoxicillin", dosage: "250mg", frequency: "Thrice a day", duration: "1 Week"

            ⚠️ VALIDATION CHECKS:
            - Frequency MUST be one of the 6 exact options or null
            - Duration MUST be one of the 9 exact options or null
            - Gender MUST be Male, Female, Other, or null
            - Confidence MUST be 0.1-1.0
            - If mapping is unclear, use null and add warning

            Here is the OCR text to parse:

            ${text}
            `;

        const result = await geminiModel.generateContent(prompt);
        const response = await result.response;
        const geminiOutput = response.text().trim();

        // Clean up the response to ensure it's valid JSON
        let cleanedOutput = geminiOutput;
        if (cleanedOutput.startsWith('```json')) {
            cleanedOutput = cleanedOutput.replace(/```json\n?/, '').replace(/```$/, '');
        } else if (cleanedOutput.startsWith('```')) {
            cleanedOutput = cleanedOutput.replace(/```\n?/, '').replace(/```$/, '');
        }

        try {
            const parsedData = JSON.parse(cleanedOutput);

            // Pre-validate AI output to catch invalid dropdown values
            const preValidatedData = preValidateAIOutput(parsedData);

            // Validate the structure
            const validatedData = validateAndCleanParsedData(preValidatedData);

            // Apply medical data mapping to standardize values
            const mappedData = mapPrescriptionData(validatedData);

            console.log('✅ Gemini AI parsing successful');
            console.log(`📋 Extracted ${mappedData.medications?.length || 0} medications`);

            // Log mapping results
            if (preValidatedData.extraction_warnings?.length > validatedData.extraction_warnings?.length) {
                console.log('🔧 Applied medical data mapping corrections');
            }

            return mappedData;

        } catch (jsonError) {
            console.warn('⚠️ Gemini returned invalid JSON, falling back to manual parsing');
            console.warn('Gemini response:', cleanedOutput);
            return await parsePrescriptionText(text);
        }

    } catch (error) {
        console.error('❌ Gemini AI parsing error:', error.message);

        // Log specific error details for debugging
        if (error.message.includes('models/') && error.message.includes('not found')) {
            console.error('📋 Model not found - this might be due to API version or model availability');
            console.error('🔧 Consider checking available models or updating the model name');
        } else if (error.message.includes('API key')) {
            console.error('🔑 API key issue - verify GEMINI_API_KEY in environment variables');
        } else if (error.message.includes('quota') || error.message.includes('limit')) {
            console.error('📊 Rate limit or quota exceeded - consider implementing retry logic');
        }

        console.log('🔄 Falling back to manual parsing');
        return await parsePrescriptionText(text);
    }
}

/**
 * Pre-validate AI output to check if values match dropdown options
 * This helps catch AI errors before applying the medical mapper
 * @param {Object} data - Raw data from Gemini AI
 * @returns {Object} Data with validation warnings added
 */
function preValidateAIOutput(data) {
    const validatedData = { ...data };
    const warnings = Array.isArray(data.extraction_warnings) ? [...data.extraction_warnings] : [];

    const { isValidDropdownValue } = require('../../utils/medicalDataMapper');

    // Validate gender
    if (data.patient_gender && !isValidDropdownValue(data.patient_gender, 'gender')) {
        warnings.push(`AI returned invalid gender: "${data.patient_gender}" - will be remapped`);
    }

    // Validate medications
    if (Array.isArray(data.medications)) {
        data.medications.forEach((med, index) => {
            if (med.frequency && !isValidDropdownValue(med.frequency, 'frequency')) {
                warnings.push(`AI returned invalid frequency for medication ${index + 1}: "${med.frequency}" - will be remapped`);
            }
            if (med.duration && !isValidDropdownValue(med.duration, 'duration')) {
                warnings.push(`AI returned invalid duration for medication ${index + 1}: "${med.duration}" - will be remapped`);
            }
        });
    }

    validatedData.extraction_warnings = warnings;
    return validatedData;
}

/**
 * Validate and clean the data parsed by Gemini AI
 * @param {Object} data - Raw data from Gemini
 * @returns {Object} Validated and cleaned data
 */
function validateAndCleanParsedData(data) {
    const cleanedData = {
        doctor_name: data.doctor_name || null,
        doctor_specialty: data.doctor_specialty || null,
        doctor_license_number: data.doctor_license_number || null,
        clinic_name: data.clinic_name || null,
        patient_name: data.patient_name || null,
        patient_age: data.patient_age || null,
        patient_gender: data.patient_gender || null,
        medical_conditions: data.medical_conditions || null,
        blood_pressure: data.blood_pressure || null,
        pulse: data.pulse || null,
        temperature: data.temperature || null,
        weight: data.weight || null,
        height: data.height || null,
        prescription_date: data.prescription_date || null,
        diagnosis: data.diagnosis || null,
        additional_notes: data.additional_notes || null,
        medications: [],
        extraction_warnings: Array.isArray(data.extraction_warnings) ? data.extraction_warnings : []
    };

    // Validate and clean medications array
    if (Array.isArray(data.medications)) {
        cleanedData.medications = data.medications.map((med, index) => {
            if (!med.name) {
                cleanedData.extraction_warnings.push(`Medication ${index + 1} missing name`);
                return null;
            }

            return {
                name: String(med.name).trim(),
                generic_name: med.generic_name ? String(med.generic_name).trim() : null,
                dosage: med.dosage ? String(med.dosage).trim() : null,
                frequency: med.frequency ? String(med.frequency).trim() : null,
                duration: med.duration ? String(med.duration).trim() : null,
                instructions: med.instructions ? String(med.instructions).trim() : null,
                salt: med.salt ? String(med.salt).trim() : null,
                confidence: typeof med.confidence === 'number' ?
                    Math.max(0.1, Math.min(1.0, med.confidence)) : 0.7
            };
        }).filter(med => med !== null);
    }

    // Add automatic warnings for missing critical data
    if (!cleanedData.doctor_name) {
        cleanedData.extraction_warnings.push('Doctor name not detected');
    }
    if (!cleanedData.patient_name) {
        cleanedData.extraction_warnings.push('Patient name not detected');
    }
    if (cleanedData.medications.length === 0) {
        cleanedData.extraction_warnings.push('No medications detected');
    }

    return cleanedData;
}

/**
 * Extract doctor name from prescription text
 */
function extractDoctorName(lines) {
    for (const line of lines) {
        // Look for patterns like "Dr.", "Doctor", "Dr "
        if (line.match(/^(Dr\.?|Doctor)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/i)) {
            return line.replace(/^(Dr\.?|Doctor)\s+/i, '').trim();
        }
        // Look for lines that might contain doctor names
        if (line.match(/^[A-Z][a-z]+\s+[A-Z][a-z]+.*(?:MD|MBBS|MS|MD|DM)/i)) {
            return line.replace(/\s*(?:MD|MBBS|MS|DM).*$/i, '').trim();
        }
    }
    return null;
}

/**
 * Extract doctor specialty
 */
function extractDoctorSpecialty(lines) {
    const specialties = [
        'Cardiologist', 'Dermatologist', 'Endocrinologist', 'Gastroenterologist',
        'Neurologist', 'Oncologist', 'Orthopedist', 'Pediatrician', 'Psychiatrist',
        'General Physician', 'Internal Medicine', 'Family Medicine'
    ];

    for (const line of lines) {
        for (const specialty of specialties) {
            if (line.toLowerCase().includes(specialty.toLowerCase())) {
                return specialty;
            }
        }
    }
    return null;
}

/**
 * Extract license number
 */
function extractLicenseNumber(lines) {
    for (const line of lines) {
        // Look for license patterns
        const licenseMatch = line.match(/(?:license|reg|registration)[\s\.]*(no\.?|number)?[\s\.]*:?\s*([A-Z0-9]+)/i);
        if (licenseMatch) {
            return licenseMatch[2];
        }
    }
    return null;
}

/**
 * Extract clinic/hospital name
 */
function extractClinicName(lines) {
    const clinicKeywords = ['clinic', 'hospital', 'medical center', 'healthcare'];

    for (const line of lines) {
        for (const keyword of clinicKeywords) {
            if (line.toLowerCase().includes(keyword)) {
                return line.trim();
            }
        }
    }
    return null;
}

/**
 * Extract patient name
 */
function extractPatientName(lines) {
    for (const line of lines) {
        // Look for patient name patterns
        if (line.match(/^(?:patient|name)[\s:]*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/i)) {
            return line.replace(/^(?:patient|name)[\s:]*/i, '').trim();
        }
    }
    return null;
}

/**
 * Extract age
 */
function extractAge(lines) {
    for (const line of lines) {
        const ageMatch = line.match(/(?:age|yrs?|years?)[\s:]*(\d{1,3})/i);
        if (ageMatch) {
            return ageMatch[1];
        }
    }
    return null;
}

/**
 * Extract gender
 */
function extractGender(lines) {
    for (const line of lines) {
        if (line.match(/\b(male|female|m|f)\b/i)) {
            const gender = line.match(/\b(male|female|m|f)\b/i)[1].toLowerCase();
            return gender === 'm' ? 'Male' : gender === 'f' ? 'Female' :
                gender.charAt(0).toUpperCase() + gender.slice(1);
        }
    }
    return null;
}

/**
 * Extract prescription date
 */
function extractPrescriptionDate(lines) {
    for (const line of lines) {
        // Look for various date patterns
        const datePatterns = [
            /(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/,
            /(\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4})/i
        ];

        for (const pattern of datePatterns) {
            const match = line.match(pattern);
            if (match) {
                return match[1];
            }
        }
    }
    return null;
}

/**
 * Extract vital signs
 */
function extractBloodPressure(lines) {
    for (const line of lines) {
        const bpMatch = line.match(/(?:bp|blood pressure)[\s:]*(\d{2,3}\/\d{2,3})/i);
        if (bpMatch) {
            return bpMatch[1];
        }
    }
    return null;
}

function extractPulse(lines) {
    for (const line of lines) {
        const pulseMatch = line.match(/(?:pulse|hr|heart rate)[\s:]*(\d{2,3})\s*(?:bpm)?/i);
        if (pulseMatch) {
            return pulseMatch[1] + ' bpm';
        }
    }
    return null;
}

function extractTemperature(lines) {
    for (const line of lines) {
        const tempMatch = line.match(/(?:temp|temperature)[\s:]*(\d{2,3}(?:\.\d)?)\s*[°]?[fc]?/i);
        if (tempMatch) {
            return tempMatch[1] + '°F';
        }
    }
    return null;
}

function extractWeight(lines) {
    for (const line of lines) {
        const weightMatch = line.match(/(?:weight|wt)[\s:]*(\d{2,3}(?:\.\d)?)\s*(?:kg|lbs?)?/i);
        if (weightMatch) {
            return weightMatch[1] + ' kg';
        }
    }
    return null;
}

/**
 * Parse extracted text to identify prescription components (Fallback manual parsing)
 * @param {string} text - Raw OCR extracted text
 * @returns {Object} Structured prescription data
 */
async function parsePrescriptionText(text) {
    console.log('🔧 Using manual parsing fallback');

    const lines = text.split('\n').map(line => line.trim()).filter(line => line.length > 0);

    const prescriptionData = {
        doctor_name: null,
        doctor_specialty: null,
        doctor_license_number: null,
        clinic_name: null,
        patient_name: null,
        patient_age: null,
        patient_gender: null,
        medical_conditions: null,
        blood_pressure: null,
        pulse: null,
        temperature: null,
        weight: null,
        height: null,
        prescription_date: null,
        diagnosis: null,
        additional_notes: null,
        medications: [],
        extraction_warnings: []
    };

    // Parse doctor information
    prescriptionData.doctor_name = extractDoctorName(lines);
    prescriptionData.doctor_specialty = extractDoctorSpecialty(lines);
    prescriptionData.doctor_license_number = extractLicenseNumber(lines);
    prescriptionData.clinic_name = extractClinicName(lines);

    // Parse patient information
    prescriptionData.patient_name = extractPatientName(lines);
    prescriptionData.patient_age = extractAge(lines);
    prescriptionData.patient_gender = extractGender(lines);

    // Parse prescription date
    prescriptionData.prescription_date = extractPrescriptionDate(lines);

    // Parse vital signs
    prescriptionData.blood_pressure = extractBloodPressure(lines);
    prescriptionData.pulse = extractPulse(lines);
    prescriptionData.temperature = extractTemperature(lines);
    prescriptionData.weight = extractWeight(lines);

    // Parse medications using simplified approach
    prescriptionData.medications = extractMedicationsSimplified(lines);

    // Extract diagnosis if present
    prescriptionData.diagnosis = extractDiagnosis(lines);

    // Generate warnings for low-confidence extractions
    prescriptionData.extraction_warnings = generateExtractionWarnings(prescriptionData);

    // Apply medical data mapping to standardize values
    const mappedData = mapPrescriptionData(prescriptionData);

    return mappedData;
}

/**
 * Simplified medication extraction for fallback parsing
 */
function extractMedicationsSimplified(lines) {
    const medications = [];
    const medicationKeywords = ['rx', 'prescription', 'medicines', 'drugs', 'tab', 'cap', 'syrup'];

    let inMedicationSection = false;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].toLowerCase();

        // Check if we've entered medication section
        if (medicationKeywords.some(keyword => line.includes(keyword))) {
            inMedicationSection = true;
            continue;
        }

        if (inMedicationSection && lines[i].length > 3) {
            // Simple medication extraction - just get basic info
            const medicationData = parseBasicMedicationLine(lines[i]);

            if (medicationData) {
                medications.push({
                    name: medicationData.name,
                    generic_name: null,
                    dosage: medicationData.dosage || null,
                    frequency: medicationData.frequency || null,
                    duration: medicationData.duration || null,
                    instructions: medicationData.instructions || null,
                    salt: null,
                    confidence: 0.6 // Lower confidence for manual parsing
                });
            }
        }
    }

    return medications;
}

/**
 * Basic medication line parsing (simplified version)
 */
function parseBasicMedicationLine(line) {
    // Very basic parsing - just extract what we can clearly identify
    const medicationPattern = /^(\d+[\.\)]?\s*)?([A-Za-z][A-Za-z\s]+?)(?:\s+(\d+(?:\.\d+)?(?:mg|gm|ml|mcg)?))?/i;
    const match = line.match(medicationPattern);

    if (match && match[2] && match[2].length > 2) {
        return {
            name: match[2].trim(),
            dosage: match[3] ? match[3].trim() : null,
            instructions: line // Keep full line as instructions
        };
    }

    return null;
}

/**
 * Extract frequency patterns
 */
function extractFrequencyFromText(text) {
    if (!text) return null;

    const frequencyPatterns = [
        /(\d+\s*times?\s*(?:a\s*)?day)/i,
        /(twice\s*(?:a\s*)?day)/i,
        /(once\s*(?:a\s*)?day)/i,
        /(every\s*\d+\s*hours?)/i,
        /(morning|evening|night)/i
    ];

    for (const pattern of frequencyPatterns) {
        const match = text.match(pattern);
        if (match) {
            return match[1];
        }
    }

    return null;
}

/**
 * Extract duration patterns
 */
function extractDurationFromText(text) {
    if (!text) return null;

    const durationPattern = /(\d+\s*(?:days?|weeks?|months?))/i;
    const match = text.match(durationPattern);

    return match ? match[1] : null;
}

/**
 * Extract diagnosis information
 */
function extractDiagnosis(lines) {
    const diagnosisKeywords = ['diagnosis', 'condition', 'complaint', 'problem'];

    for (const line of lines) {
        for (const keyword of diagnosisKeywords) {
            if (line.toLowerCase().includes(keyword)) {
                return line.replace(new RegExp(keyword, 'i'), '').replace(/[:]/g, '').trim();
            }
        }
    }
    return null;
}

/**
 * Calculate overall confidence score based on Vision API results
 */
function calculateOverallConfidence(detections) {
    if (!detections || detections.length === 0) return 0;

    // Use the confidence from the first detection (overall text)
    // Google Vision doesn't always provide confidence scores for text detection
    // So we'll estimate based on detected features

    let confidence = 0.8; // Base confidence

    // Reduce confidence if text is very short or fragmented
    const mainText = detections[0].description;
    if (mainText.length < 100) confidence -= 0.2;
    if (mainText.split('\n').length < 5) confidence -= 0.1;

    return Math.max(0.1, Math.min(1.0, confidence));
}

/**
 * Generate extraction warnings based on parsed data
 */
function generateExtractionWarnings(data) {
    const warnings = [];

    if (!data.doctor_name) warnings.push('Doctor name not detected');
    if (!data.patient_name) warnings.push('Patient name not detected');
    if (data.medications.length === 0) warnings.push('No medications detected');
    if (data.medications.some(med => !med.name)) warnings.push('Some medications may be incomplete');

    return warnings;
}

/**
 * Match medicine names with database and enrich with DB IDs
 * Enhanced with fuzzy matching for OCR-extracted names with typos
 * @param {Array} medications - Array of extracted medications
 * @returns {Promise<Array>} Enhanced medications with database IDs
 */
async function matchMedicinesWithDatabase(medications) {
    const { processAnuvanshLinking } = require('../../utils/anuvanshMedicineIntegration');

    try {
        console.log(`\n🔍 ═══════════════════════════════════════════════════`);
        console.log(`🔍 Starting Enhanced Medicine Database Matching`);
        console.log(`🔍 Processing ${medications.length} OCR-extracted medicines`);
        console.log(`🔍 ═══════════════════════════════════════════════════\n`);

        // Process Anuvansh linking with fuzzy matching enabled
        const linkingResult = await processAnuvanshLinking(medications, {
            autoLink: true,
            requireAnuvanshId: false,
            skipAutoLinkForManual: false,
            useFuzzyMatch: true,     // Enable fuzzy matching
            minSimilarity: 0.7       // 70% similarity threshold
        });

        if (!linkingResult.success) {
            console.warn('⚠️ Medicine database matching failed, proceeding with original data');
            return medications;
        }

        // Transform to format expected by manual entry form
        const enhancedMedications = linkingResult.medicines.map((med, index) => {
            const isLinked = med.anuvansh_linked || false;
            const linkingMethod = med.linking_method || 'not_linked';
            const confidence = med.linking_confidence || 0;

            return {
                // Core medication data (for manual entry form)
                name: med.medicine_name || med.name,
                generic_name: med.generic_name || med.anuvansh_data?.name || null,
                dosage: med.dosage || med.medicine_strength || null,
                frequency: med.frequency || med.medicine_frequency || null,
                duration: med.duration || null,
                instructions: med.instructions || null,
                salt: med.salt || med.medicine_salt || med.anuvansh_data?.composition || null,
                confidence: med.confidence || 0.7,

                // Database linking information
                id: med.med_drug_id || 0, // Medicine ID from database (0 if not found)
                med_drug_id: med.med_drug_id || 0,
                anuvansh_linked: isLinked,
                linking_method: linkingMethod,
                linking_confidence: confidence,

                // Detailed linking information
                linking_info: isLinked
                    ? `✅ Matched via ${linkingMethod} (ID: ${med.med_drug_id}, Confidence: ${(confidence * 100).toFixed(1)}%)`
                    : '⚠️ Not found in database - will be manual entry',

                // Alternative matches (if available from fuzzy matching)
                alternative_matches: med.alternative_matches || [],

                // Original OCR data preserved
                ocr_extracted_name: med.name || med.medicine_name,
                database_matched_name: isLinked ? med.anuvansh_data?.name : null,

                // Composition data from database
                composition1_id: med.anuvansh_data?.composition1_id || null,
                composition1_name: med.anuvansh_data?.composition1_name || null,
                composition1_dose: med.anuvansh_data?.composition1_dose || null,
                composition2_id: med.anuvansh_data?.composition2_id || null,
                composition2_name: med.anuvansh_data?.composition2_name || null,
                composition2_dose: med.anuvansh_data?.composition2_dose || null
            };
        });

        console.log(`\n✅ ═══════════════════════════════════════════════════`);
        console.log(`✅ Medicine Matching Completed Successfully`);
        console.log(`✅ ═══════════════════════════════════════════════════`);
        console.log(`   Total processed: ${enhancedMedications.length}`);
        console.log(`   Successfully matched: ${enhancedMedications.filter(m => m.anuvansh_linked).length}`);
        console.log(`   Manual entry needed: ${enhancedMedications.filter(m => !m.anuvansh_linked).length}`);
        console.log(`   `);
        console.log(`   Match breakdown:`);
        console.log(`      🎯 Exact matches: ${enhancedMedications.filter(m => m.linking_method === 'exact').length}`);
        console.log(`      🔍 Fuzzy matches: ${enhancedMedications.filter(m => m.linking_method === 'fuzzy').length}`);
        console.log(`      🧪 Composition matches: ${enhancedMedications.filter(m => m.linking_method === 'composition').length}`);
        console.log(`      👤 Manual entries: ${enhancedMedications.filter(m => m.linking_method === 'manual').length}`);
        console.log(`✅ ═══════════════════════════════════════════════════\n`);

        return enhancedMedications;

    } catch (error) {
        console.error('❌ Error matching medicines with database:', error);
        // Return original medications if matching fails
        return medications.map(med => ({
            ...med,
            id: 0,
            med_drug_id: 0,
            anuvansh_linked: false,
            linking_method: 'error',
            linking_info: 'Database matching failed: ' + error.message
        }));
    }
}

/**
 * Enhanced upload single prescription image with OCR
 */
const uploadPrescriptionImage = async (req, res, next) => {
    console.log('\n========================================');
    console.log('🚀 [BACKEND] uploadPrescriptionImage called');
    console.log('========================================\n');

    try {
        const { notes, patient_id, upload_type, timestamp } = req.body;
        const uploadedFile = req.file;

        console.log('📦 [BACKEND] Request body:', {
            notes: notes ? 'present' : 'none',
            patient_id,
            upload_type,
            timestamp
        });

        if (!uploadedFile) {
            console.error('❌ [BACKEND] No file uploaded');
            return res.status(400).json({
                status: 'FAILURE',
                message: 'No prescription image uploaded',
                error: 'MISSING_FILE'
            });
        }

        console.log('� [BACKEND] File received:');
        console.log(`  - Filename: ${uploadedFile.filename}`);
        console.log(`  - Original: ${uploadedFile.originalname}`);
        console.log(`  - Size: ${(uploadedFile.size / 1024).toFixed(2)} KB`);
        console.log(`  - Mimetype: ${uploadedFile.mimetype}`);
        console.log(`  - Path: ${uploadedFile.path}`);

        console.log('\n🔄 [BACKEND] Starting OCR extraction...');

        // Step 1: Extract prescription data using Google Vision API + Gemini AI
        const ocrData = await extractPrescriptionData(uploadedFile.path);

        console.log('\n✅ [BACKEND] OCR extraction completed');
        console.log(`📊 [BACKEND] Confidence: ${(ocrData.confidence_score * 100).toFixed(1)}%`);
        console.log(`📋 [BACKEND] Medications extracted: ${ocrData.medications?.length || 0}`);
        console.log(`👨‍⚕️ [BACKEND] Doctor: ${ocrData.doctor_name || 'Not found'}`);
        console.log(`👤 [BACKEND] Patient: ${ocrData.patient_name || 'Not found'}`);

        // Step 2: Match extracted medicines with database
        let enhancedMedications = ocrData.medications || [];
        if (enhancedMedications.length > 0) {
            console.log('\n🔄 [BACKEND] Matching medicines with database...');
            enhancedMedications = await matchMedicinesWithDatabase(enhancedMedications);
            console.log(`✅ [BACKEND] Database matching completed for ${enhancedMedications.length} medicines`);
        }

        const prescriptionData = {
            prescription_id: `RX_${Date.now()}`,
            original_filename: uploadedFile.originalname,
            stored_filename: uploadedFile.filename,
            file_path: uploadedFile.path,
            file_size: uploadedFile.size,
            mime_type: uploadedFile.mimetype,
            upload_timestamp: new Date().toISOString(),
            notes: notes || null,
            patient_id: patient_id || null,
            upload_type: upload_type || 'camera_scan',
            processing_status: 'COMPLETED',
            original_image_path: `/uploads/prescriptions/${uploadedFile.filename}`,
            ...ocrData,
            medications: enhancedMedications // Use enhanced medications with DB matching
        };

        console.log('\n📤 [BACKEND] Preparing response...');
        console.log(`  - Prescription ID: ${prescriptionData.prescription_id}`);
        console.log(`  - Status: ${prescriptionData.processing_status}`);
        console.log(`  - Image path: ${prescriptionData.original_image_path}`);
        console.log(`  - Medications count: ${enhancedMedications.length}`);

        // Step 3: Return data ready for manual entry form
        const responseData = {
            status: 'SUCCESS',
            message: 'Prescription processed successfully with OCR and database matching',
            data: {
                prescription_id: prescriptionData.prescription_id,
                processing_status: prescriptionData.processing_status,
                original_image_path: prescriptionData.original_image_path,
                confidence_score: prescriptionData.confidence_score,
                requires_manual_review: prescriptionData.requires_manual_review,
                extraction_warnings: prescriptionData.extraction_warnings,

                // Fields for manual entry form pre-population
                doctor_name: prescriptionData.doctor_name,
                doctor_specialty: prescriptionData.doctor_specialty,
                doctor_license_number: prescriptionData.doctor_license_number,
                clinic_name: prescriptionData.clinic_name,
                patient_name: prescriptionData.patient_name,
                patient_age: prescriptionData.patient_age,
                patient_gender: prescriptionData.patient_gender,
                medical_conditions: prescriptionData.medical_conditions,
                blood_pressure: prescriptionData.blood_pressure,
                pulse: prescriptionData.pulse,
                temperature: prescriptionData.temperature,
                weight: prescriptionData.weight,
                height: prescriptionData.height,
                prescription_date: prescriptionData.prescription_date,
                diagnosis: prescriptionData.diagnosis,
                additional_notes: prescriptionData.additional_notes,

                // Enhanced medications with database IDs (ready for manual entry saving)
                medications: enhancedMedications
            }
        };

        console.log('\n✅ [BACKEND] Response ready - sending to client');
        console.log('📋 [BACKEND] Response data keys:', Object.keys(responseData.data));
        console.log('========================================\n');

        res.status(200).json(responseData);

        console.log(`✅ [BACKEND] Prescription OCR response sent successfully`);

    } catch (error) {
        console.error('\n❌❌❌ [BACKEND] CRITICAL ERROR ❌❌❌');
        console.error('💥 [BACKEND] Error type:', error.constructor.name);
        console.error('💥 [BACKEND] Error message:', error.message);
        console.error('📚 [BACKEND] Stack trace:', error.stack);
        console.error('========================================\n');

        res.status(500).json({
            status: 'FAILURE',
            message: 'Failed to process prescription image',
            error: error.message
        });
    }
};

/**
 * REMOVED: Multiple image upload functionality
 * The system now only supports single image upload and processing
 * to ensure better accuracy and reduce complexity.
 * 
 * To re-enable multiple uploads in the future:
 * 1. Update multer limits to allow multiple files
 * 2. Uncomment uploadMultiplePrescriptionImages function
 * 3. Add back the batch upload route in routes.js
 */

// Export single image upload function with AI-powered parsing
exports.upload = upload;
exports.uploadPrescriptionImage = uploadPrescriptionImage;
// Keep existing functions
exports.extractPrescriptionData = extractPrescriptionData;
exports.parsePrescriptionTextWithAI = parsePrescriptionTextWithAI;
exports.parsePrescriptionText = parsePrescriptionText; // Fallback manual parsing
// Medicine database matching
exports.matchMedicinesWithDatabase = matchMedicinesWithDatabase;
// Utility functions
exports.validateAndCleanParsedData = validateAndCleanParsedData;