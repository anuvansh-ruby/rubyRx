const STATUS = require('../../utils/constants').STATUS;
const jwt = require('jsonwebtoken');
const crypto = require("crypto");
const axios = require('axios');
const redisRouter = require("../../utils/redisRouter");
const patientService = require('./patientService');

/**
 * Patient Authentication Controller
 * Handles login, registration, and forgot PIN functionality for patients
 * Uses patient_records table schema as per database instructions
 */

// Generate 4-digit OTP
function generateOTP() {
    return crypto.randomInt(1000, 9999).toString();
}

// Utility to generate JWT token for patients
function generatePatientToken(payload) {
    const tokenPayload = {
        ...payload,
        type: 'patient', // Distinguish from other user types
        iat: Math.floor(Date.now() / 1000)
    };
    return jwt.sign(tokenPayload, process.env.JWT_SECRET, { expiresIn: "30d" });
}

// Send WhatsApp message via WasenderAPI with fallback handling
async function sendWhatsAppOTP(phoneNumber, otp, customMessage = null) {
    try {
        // Skip WhatsApp API for now - development mode
        console.log(`📱 SKIPPING WHATSAPP API - OTP for ${phoneNumber}: ${otp}`);
        if (customMessage) {
            console.log(`� Message: ${customMessage}`);
        }

        return { success: true, data: { message: 'WhatsApp API skipped - OTP logged to console', messageId: 'dev_' + Date.now() } };

        // WhatsApp API code commented out for now
        /*
        const url = 'https://api.wasender.io/v1/messages';
        const message = customMessage || `🏥 Ruby AI Healthcare\n\nYour OTP for login is: ${otp}\n\nThis OTP will expire in 5 minutes.\n\nDo not share this OTP with anyone.`;

        const requestData = {
            phone: phoneNumber,
            message: message
        };

        const config = {
            method: 'POST',
            url: url,
            headers: {
                'Authorization': `Bearer ${process.env.WASENDER_API_KEY}`,
                'Content-Type': 'application/json'
            },
            data: requestData,
            timeout: 10000 // 10 second timeout
        };

        const response = await axios(config);
        return { success: true, data: response.data };
        */
    } catch (error) {
        console.error('WhatsApp API Error:', error);

        // Always log OTP for development/testing purposes
        console.log(`❌ WhatsApp failed - OTP for ${phoneNumber}: ${otp}`);

        throw error;
    }
}/**
 * Send OTP to patient's phone number for login
 */
exports.sendPatientLoginOTP = async (req, res, next) => {
    try {
        const { phoneNumber } = req.body;

        // Input validation
        if (!phoneNumber) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number is required"
            };
            return next();
        }

        // Validate phone number format
        const phoneRegex = /^\+\d{10,15}$/;
        if (!phoneRegex.test(phoneNumber)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid phone number format. Please include country code (e.g., +91xxxxxxxxxx)"
            };
            return next();
        }

        // Check if patient exists (but don't reject if they don't)
        const patientCheck = await patientService.checkPhoneExists(phoneNumber);
        if (patientCheck.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Error checking patient records. Please try again."
            };
            return next();
        }

        // If patient exists but is inactive, reject
        if (patientCheck.exists && !patientCheck.isActive) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Your account is inactive. Please contact support."
            };
            return next();
        }

        // Generate and store OTP for both existing and new users
        const otp = generateOTP();
        const otpKey = `patient_login_otp:${phoneNumber}`;

        // Store OTP with 5-minute expiry
        await redisRouter.setToRedis(otpKey, otp, 300);

        // Store attempt count to prevent spam
        const attemptKey = `patient_otp_attempts:${phoneNumber}`;
        const attempts = await redisRouter.getFromRedis(attemptKey) || 0;

        // if (parseInt(attempts) >= 3) {
        //     res.locals = {
        //         status: STATUS.FAILURE,
        //         message: "Too many OTP requests. Please try again after 15 minutes."
        //     };
        //     return next();
        // }

        await redisRouter.setToRedis(attemptKey, parseInt(attempts) + 1, 900); // 15 min TTL

        // Send WhatsApp OTP
        let whatsappSent = false;
        let otpDeliveryMethod = 'console'; // fallback method

        try {
            const whatsappResult = await sendWhatsAppOTP(phoneNumber, otp);
            whatsappSent = whatsappResult.success;
            otpDeliveryMethod = 'whatsapp';
        } catch (whatsappError) {
            console.error('WhatsApp sending failed:', whatsappError);
            // OTP is logged to console for development/testing when WhatsApp fails
            otpDeliveryMethod = 'console';
        }

        // Prepare response message based on delivery method
        let responseMessage = "OTP sent successfully to your WhatsApp";
        if (!whatsappSent && process.env.NODE_ENV === 'development') {
            responseMessage = "OTP generated successfully (check console for development OTP)";
        } else if (!whatsappSent) {
            responseMessage = "OTP generated successfully (delivery pending - please contact support if not received)";
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: responseMessage,
            data: {
                phoneNumber: phoneNumber.replace(/(\+\d{2})\d{6}(\d{4})/, '$1******$2'),
                expiresIn: 300, // 5 minutes in seconds
                deliveryMethod: otpDeliveryMethod,
                whatsappSent: whatsappSent
            }
        };
        next();

    } catch (error) {
        console.error('Send Patient Login OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Failed to send OTP. Please try again."
        };
        next();
    }
};

/**
 * Verify OTP and login patient
 */
exports.verifyPatientLoginOTP = async (req, res, next) => {
    try {
        const { phoneNumber, otp } = req.body;

        // Input validation
        if (!phoneNumber || !otp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number and OTP are required"
            };
            return next();
        }

        // Get stored OTP from Redis
        const otpKey = `patient_login_otp:${phoneNumber}`;
        const storedOtp = await redisRouter.getFromRedis(otpKey);

        if (!storedOtp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "OTP expired or invalid. Please request a new OTP."
            };
            return next();
        }

        if (storedOtp !== otp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid OTP. Please check and try again."
            };
            return next();
        }

        // Get patient data
        const patientResult = await patientService.getPatientByPhone(phoneNumber);

        let patient;
        let isNewUser = false;
        let responseData = {};

        if (patientResult.status === STATUS.FAILURE || !patientResult.data) {
            responseData = {
                isNewUser: true
            };
        } else {
            patient = patientResult.data;
            await patientService.updateLastVisitDate(patient.patient_id);
            await redisRouter.delFromRedis(otpKey);
            await redisRouter.delFromRedis(`patient_otp_attempts:${phoneNumber}`);
            const tokenPayload = {
                patientId: patient.patient_id,
                phone: patient.patient_phone_number,
                email: patient.patient_email,
                firstName: patient.patient_first_name,
                lastName: patient.patient_last_name
            };

            const token = generatePatientToken(tokenPayload);

            // Store patient session in Redis
            const sessionKey = `patient_session:${patient.patient_id}`;
            const sessionData = {
                ...patient,
                loginTime: new Date().toISOString(),
                lastActivity: new Date().toISOString()
            };

            await redisRouter.setToRedis(sessionKey, JSON.stringify(sessionData), 2592000); // 30 days
            responseData = {
                token,
                isNewUser: isNewUser,
                patient: {
                    id: patient.patient_id,
                    firstName: patient.patient_first_name,
                    lastName: patient.patient_last_name,
                    email: patient.patient_email,
                    phone: patient.patient_phone_number,
                    dateOfBirth: patient.patient_date_of_birth,
                    address: patient.patient_address,
                    lastVisitDate: patient.patient_last_visit_date,
                    pin: patient.patient_pin,
                    hasPinSetup: patient.patient_pin ? true : false
                }
            };
        }
        res.locals = {
            status: STATUS.SUCCESS,
            message: isNewUser ? "Verified now lets register!!" : "Login successful!!",
            data: responseData
        };
        next();

    } catch (error) {
        console.error('Verify Patient Login OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Login verification failed. Please try again."
        };
        next();
    }
};

/**
 * Register new patient
 */
exports.registerPatient = async (req, res, next) => {
    try {
        const {
            phoneNumber,
            email,
            firstName,
            lastName,
            dateOfBirth,
            address,
            nationalIdType,
            nationalIdNumber
        } = req.body;

        // Input validation
        const requiredFields = { phoneNumber, email, firstName, lastName, dateOfBirth };
        const missingFields = Object.entries(requiredFields)
            .filter(([key, value]) => !value)
            .map(([key]) => key);

        if (missingFields.length > 0) {
            res.locals = {
                status: STATUS.FAILURE,
                message: `Missing required fields: ${missingFields.join(', ')}`
            };
            return next();
        }

        // Validate phone number format
        const phoneRegex = /^\+\d{10,15}$/;
        if (!phoneRegex.test(phoneNumber)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid phone number format. Please include country code."
            };
            return next();
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid email format."
            };
            return next();
        }

        // Validate date of birth
        const birthDate = new Date(dateOfBirth);
        if (isNaN(birthDate.getTime()) || birthDate > new Date()) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid date of birth."
            };
            return next();
        }

        // Check if patient already exists
        const phoneCheck = await patientService.checkPhoneExists(phoneNumber);
        if (phoneCheck.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Error checking existing records. Please try again."
            };
            return next();
        }

        if (phoneCheck.exists) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number already registered. Please login instead.",
                code: "PHONE_EXISTS"
            };
            return next();
        }

        const emailCheck = await patientService.checkEmailExists(email);
        if (emailCheck.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Error checking existing records. Please try again."
            };
            return next();
        }

        if (emailCheck.exists) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Email already registered. Please login instead.",
                code: "EMAIL_EXISTS"
            };
            return next();
        }

        // Prepare patient data
        const patientData = {
            patient_first_name: firstName.trim(),
            patient_last_name: lastName.trim(),
            patient_phone_number: phoneNumber,
            patient_email: email.toLowerCase().trim(),
            patient_date_of_birth: birthDate.toISOString(),
            patient_address: address?.trim() || null,
            national_id_type: nationalIdType?.trim() || null,
            national_id_number: nationalIdNumber?.trim() || null,
            created_by: 'patient_registration',
            updated_by: 'patient_registration'
        };

        // Create patient record
        const createResult = await patientService.createPatientInDB(patientData);

        if (createResult.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: createResult.message || "Failed to register patient"
            };
            return next();
        }

        const newPatient = createResult.data;

        // Generate JWT token for the new patient
        const tokenPayload = {
            patientId: newPatient.patient_id,
            phone: newPatient.patient_phone_number,
            email: newPatient.patient_email,
            firstName: newPatient.patient_first_name,
            lastName: newPatient.patient_last_name
        };

        const token = generatePatientToken(tokenPayload);

        // Store patient session in Redis
        const sessionKey = `patient_session:${newPatient.patient_id}`;
        const sessionData = {
            ...newPatient,
            loginTime: new Date().toISOString(),
            lastActivity: new Date().toISOString()
        };

        await redisRouter.setToRedis(sessionKey, JSON.stringify(sessionData), 2592000); // 30 days

        res.locals = {
            status: STATUS.SUCCESS,
            message: "Registration successful",
            data: {
                token,
                patient: {
                    id: newPatient.patient_id,
                    firstName: newPatient.patient_first_name,
                    lastName: newPatient.patient_last_name,
                    email: newPatient.patient_email,
                    phone: newPatient.patient_phone_number,
                    dateOfBirth: newPatient.patient_date_of_birth
                }
            }
        };
        next();

    } catch (error) {
        console.error('Patient Registration Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Registration failed. Please try again."
        };
        next();
    }
};

/**
 * Update patient profile after auto-registration
 */
exports.updatePatientProfile = async (req, res, next) => {
    try {
        const {
            email,
            firstName,
            lastName,
            dateOfBirth,
            address,
            nationalIdType,
            nationalIdNumber
        } = req.body;

        const userData = req.user; // From JWT middleware (validateRequest)

        // Check if user data exists and has patientId
        if (!userData || !userData.patientId) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Authentication required. Please login again."
            };
            return next();
        }

        // Input validation
        const requiredFields = { email, firstName, lastName, dateOfBirth };
        const missingFields = Object.entries(requiredFields)
            .filter(([key, value]) => !value)
            .map(([key]) => key);

        if (missingFields.length > 0) {
            res.locals = {
                status: STATUS.FAILURE,
                message: `Missing required fields: ${missingFields.join(', ')}`
            };
            return next();
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid email format."
            };
            return next();
        }

        // Validate date of birth
        const birthDate = new Date(dateOfBirth);
        if (isNaN(birthDate.getTime()) || birthDate > new Date()) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid date of birth."
            };
            return next();
        }

        // Check if email is already used by another patient
        const emailCheck = await patientService.checkEmailExists(email);
        if (emailCheck.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Error checking existing records. Please try again."
            };
            return next();
        }

        // Allow if email doesn't exist or belongs to current patient
        if (emailCheck.exists) {
            const currentPatient = await patientService.getPatientById(userData.patientId);
            if (currentPatient.status === STATUS.SUCCESS &&
                currentPatient.data.patient_email !== email) {
                res.locals = {
                    status: STATUS.FAILURE,
                    message: "Email already registered by another user."
                };
                return next();
            }
        }

        // Prepare update data
        const updateData = {
            patient_first_name: firstName.trim(),
            patient_last_name: lastName.trim(),
            patient_email: email.toLowerCase().trim(),
            patient_date_of_birth: birthDate.toISOString(),
            patient_address: address?.trim() || null,
            national_id_type: nationalIdType?.trim() || null,
            national_id_number: nationalIdNumber?.trim() || null,
            updated_by: 'profile_update'
        };

        // Update patient record
        const updateResult = await patientService.updatePatientProfile(userData.patientId, updateData);

        if (updateResult.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: updateResult.message || "Failed to update profile"
            };
            return next();
        }

        const updatedPatient = updateResult.data;

        res.locals = {
            status: STATUS.SUCCESS,
            message: "Profile updated successfully",
            data: {
                patient: {
                    id: updatedPatient.patient_id,
                    firstName: updatedPatient.patient_first_name,
                    lastName: updatedPatient.patient_last_name,
                    email: updatedPatient.patient_email,
                    phone: updatedPatient.patient_phone_number,
                    dateOfBirth: updatedPatient.patient_date_of_birth,
                    address: updatedPatient.patient_address,
                    lastVisitDate: updatedPatient.patient_last_visit_date
                }
            }
        };
        next();

    } catch (error) {
        console.error('Update Patient Profile Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Profile update failed. Please try again."
        };
        next();
    }
};

/**
 * Send OTP for forgot PIN
 */
exports.sendForgotPinOTP = async (req, res, next) => {
    try {
        const { phoneNumber } = req.body;

        // Input validation
        if (!phoneNumber) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number is required"
            };
            return next();
        }

        // Validate phone number format
        const phoneRegex = /^\+\d{10,15}$/;
        if (!phoneRegex.test(phoneNumber)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid phone number format. Please include country code."
            };
            return next();
        }

        // Check if patient exists
        const patientCheck = await patientService.checkPhoneExists(phoneNumber);
        if (patientCheck.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Error checking patient records. Please try again."
            };
            return next();
        }

        if (!patientCheck.exists || !patientCheck.isActive) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number not found or account inactive."
            };
            return next();
        }

        // Generate and store OTP
        const otp = generateOTP();
        const otpKey = `patient_forgot_pin_otp:${phoneNumber}`;

        // Store OTP with 10-minute expiry for forgot PIN (longer than login)
        await redisRouter.setToRedis(otpKey, otp, 300);

        // Check attempt limit
        const attemptKey = `patient_forgot_pin_attempts:${phoneNumber}`;
        const attempts = await redisRouter.getFromRedis(attemptKey) || 0;

        if (parseInt(attempts) >= 3) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Too many reset requests. Please try again after 1 hour."
            };
            return next();
        }

        await redisRouter.setToRedis(attemptKey, parseInt(attempts) + 1, 3600); // 1 hour TTL

        // Send WhatsApp OTP with improved error handling
        let whatsappSent = false;
        let otpDeliveryMethod = 'console';

        try {
            const message = `🏥 Ruby AI Healthcare\n\nYour PIN reset OTP is: ${otp}\n\nThis OTP will expire in 10 minutes.\n\nIf you didn't request this, please ignore this message.`;
            const whatsappResult = await sendWhatsAppOTP(phoneNumber, otp, message);
            whatsappSent = whatsappResult.success;
            otpDeliveryMethod = 'whatsapp';
        } catch (whatsappError) {
            console.error('WhatsApp sending failed for forgot PIN:', whatsappError);
            otpDeliveryMethod = 'console';
        }

        // Prepare response message based on delivery method
        let responseMessage = "PIN reset OTP sent successfully to your WhatsApp";
        if (!whatsappSent && process.env.NODE_ENV === 'development') {
            responseMessage = "PIN reset OTP generated successfully (check console for development OTP)";
        } else if (!whatsappSent) {
            responseMessage = "PIN reset OTP generated successfully (delivery pending - please contact support if not received)";
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: responseMessage,
            data: {
                phoneNumber: phoneNumber.replace(/(\+\d{2})\d{6}(\d{4})/, '$1******$2'),
                expiresIn: 600, // 10 minutes in seconds
                deliveryMethod: otpDeliveryMethod,
                whatsappSent: whatsappSent
            }
        };
        next();

    } catch (error) {
        console.error('Send Forgot PIN OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Failed to send PIN reset OTP. Please try again."
        };
        next();
    }
};

/**
 * Verify forgot PIN OTP
 */
exports.verifyForgotPinOTP = async (req, res, next) => {
    try {
        const { phoneNumber, otp } = req.body;

        // Input validation
        if (!phoneNumber || !otp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number and OTP are required"
            };
            return next();
        }

        // Get stored OTP from Redis
        const otpKey = `patient_forgot_pin_otp:${phoneNumber}`;
        const storedOtp = await redisRouter.getFromRedis(otpKey);

        if (!storedOtp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "OTP expired or invalid. Please request a new OTP."
            };
            return next();
        }

        if (storedOtp !== otp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid OTP. Please check and try again."
            };
            return next();
        }

        // Get patient data to ensure they still exist and are active
        const patientResult = await patientService.getPatientByPhone(phoneNumber);

        if (patientResult.status === STATUS.FAILURE || !patientResult.data) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Patient not found."
            };
            return next();
        }

        // Clear OTP and attempt count after successful verification
        await redisRouter.delFromRedis(otpKey);
        await redisRouter.delFromRedis(`patient_forgot_pin_attempts:${phoneNumber}`);

        // Generate a temporary token for PIN reset
        const resetTokenPayload = {
            patientId: patientResult.data.patient_id,
            phone: phoneNumber,
            purpose: 'pin_reset',
            iat: Math.floor(Date.now() / 1000)
        };

        const resetToken = jwt.sign(resetTokenPayload, process.env.JWT_SECRET, { expiresIn: "15m" });

        res.locals = {
            status: STATUS.SUCCESS,
            message: "OTP verified successfully. You can now reset your PIN.",
            data: {
                resetToken,
                expiresIn: 900 // 15 minutes in seconds
            }
        };
        next();

    } catch (error) {
        console.error('Verify Forgot PIN OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "OTP verification failed. Please try again."
        };
        next();
    }
};

/**
 * Set up PIN for patient after registration
 */
exports.setupPatientPIN = async (req, res, next) => {
    try {
        const { pin } = req.body;
        const patientData = req.user;

        // Input validation
        if (!pin || !patientData || !patientData.patientId) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "PIN is required"
            };
            return next();
        }

        // Validate PIN format (4 digits)
        if (!/^\d{4}$/.test(pin)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "PIN must be exactly 4 digits"
            };
            return next();
        }

        // Hash the PIN before storing
        const hashedPin = crypto.createHash('sha256').update(pin).digest('hex');

        // Update patient record with PIN
        const updateResult = await patientService.updatePatientPIN(patientData.patientId, hashedPin);

        if (updateResult.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: updateResult.message || "Failed to set PIN"
            };
            return next();
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: "PIN set successfully",
            data: {
                pinSetup: true
            }
        };
        next();

    } catch (error) {
        console.error('Setup Patient PIN Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Failed to set PIN. Please try again."
        };
        next();
    }
};

/**
 * Verify patient PIN for app access
 */
exports.verifyPatientPIN = async (req, res, next) => {
    try {
        const { phoneNumber, pin } = req.body;

        // Input validation
        if (!phoneNumber || !pin) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number and PIN are required"
            };
            return next();
        }

        // Validate PIN format
        if (!/^\d{4}$/.test(pin)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid PIN format"
            };
            return next();
        }

        // Get patient data
        const patientResult = await patientService.getPatientByPhone(phoneNumber);

        if (patientResult.status === STATUS.FAILURE || !patientResult.data) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Patient not found"
            };
            return next();
        }

        const patient = patientResult.data;

        // Check if PIN is set
        if (!patient.patient_pin) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "PIN not set. Please set up your PIN first.",
                code: "PIN_NOT_SET"
            };
            return next();
        }

        // Hash the provided PIN and compare
        const hashedPin = crypto.createHash('sha256').update(pin).digest('hex');

        if (patient.patient_pin !== hashedPin) {
            // Implement PIN attempt tracking
            const attemptKey = `pin_attempts:${phoneNumber}`;
            const attempts = await redisRouter.getFromRedis(attemptKey) || 0;
            const newAttempts = parseInt(attempts) + 1;

            await redisRouter.setToRedis(attemptKey, newAttempts, 300); // 5 minutes

            if (newAttempts >= 5) {
                res.locals = {
                    status: STATUS.FAILURE,
                    message: "Too many failed attempts. Please try again later.",
                    code: "TOO_MANY_ATTEMPTS"
                };
            } else {
                res.locals = {
                    status: STATUS.FAILURE,
                    message: `Invalid PIN. ${5 - newAttempts} attempts remaining.`,
                    code: "INVALID_PIN"
                };
            }
            return next();
        }

        // Clear PIN attempt count on successful verification
        await redisRouter.delFromRedis(`pin_attempts:${phoneNumber}`);

        // Update last visit date
        await patientService.updateLastVisitDate(patient.patient_id);

        // Generate JWT token
        const tokenPayload = {
            patientId: patient.patient_id,
            phoneNumber: patient.patient_phone_number,
            name: `${patient.patient_first_name} ${patient.patient_last_name}`,
            loginMethod: 'pin',
            verified: true,
            loginTime: new Date().toISOString()
        };

        const token = generatePatientToken(tokenPayload);

        res.locals = {
            status: STATUS.SUCCESS,
            message: "PIN verified successfully",
            data: {
                token,
                patientInfo: {
                    id: patient.patient_id,
                    firstName: patient.patient_first_name,
                    lastName: patient.patient_last_name,
                    fullName: `${patient.patient_first_name} ${patient.patient_last_name}`,
                    email: patient.patient_email,
                    phone: patient.patient_phone_number,
                    dateOfBirth: patient.patient_date_of_birth,
                    address: patient.patient_address,
                    lastVisitDate: patient.patient_last_visit_date
                }
            }
        };
        next();

    } catch (error) {
        console.error('Verify Patient PIN Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "PIN verification failed. Please try again."
        };
        next();
    }
};

/**
 * Reset patient PIN (requires reset token from forgot PIN flow)
 */
exports.resetPatientPIN = async (req, res, next) => {
    try {
        const { newPin } = req.body;
        const resetData = req.resetData; // From reset token middleware

        // Input validation
        if (!newPin) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "New PIN is required"
            };
            return next();
        }

        // Validate PIN format
        if (!/^\d{4}$/.test(newPin)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "PIN must be exactly 4 digits"
            };
            return next();
        }

        // Hash the new PIN
        const hashedPin = crypto.createHash('sha256').update(newPin).digest('hex');

        // Update patient PIN
        const updateResult = await patientService.updatePatientPIN(resetData.patientId, hashedPin);

        if (updateResult.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: updateResult.message || "Failed to reset PIN"
            };
            return next();
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: "PIN reset successfully",
            data: {
                pinReset: true
            }
        };
        next();

    } catch (error) {
        console.error('Reset Patient PIN Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "PIN reset failed. Please try again."
        };
        next();
    }
};

/**
 * Resend OTP for login
 */
exports.resendPatientLoginOTP = async (req, res, next) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number is required"
            };
            return next();
        }

        // Check cooldown period (30 seconds between resends)
        const resendKey = `patient_login_resend:${phoneNumber}`;
        const lastResend = await redisRouter.getFromRedis(resendKey);

        if (lastResend) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Please wait 30 seconds before requesting another OTP"
            };
            return next();
        }


        // Generate new OTP
        const otp = generateOTP();
        const otpKey = `patient_login_otp:${phoneNumber}`;

        // Store OTP with 5-minute expiry
        await redisRouter.setToRedis(otpKey, otp, 300);

        // Set resend cooldown
        await redisRouter.setToRedis(resendKey, Date.now(), 30);

        // Send WhatsApp OTP with improved error handling
        let whatsappSent = false;
        let otpDeliveryMethod = 'console';

        try {
            const whatsappResult = await sendWhatsAppOTP(phoneNumber, otp);
            whatsappSent = whatsappResult.success;
            otpDeliveryMethod = 'whatsapp';
        } catch (whatsappError) {
            console.error('WhatsApp sending failed for resend login:', whatsappError);
            otpDeliveryMethod = 'console';
        }

        // Prepare response message based on delivery method
        let responseMessage = "OTP resent successfully to your WhatsApp";
        if (!whatsappSent && process.env.NODE_ENV === 'development') {
            responseMessage = "OTP resent successfully (check console for development OTP)";
        } else if (!whatsappSent) {
            responseMessage = "OTP resent successfully (delivery pending - please contact support if not received)";
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: responseMessage,
            data: {
                phoneNumber: phoneNumber.replace(/(\+\d{2})\d{6}(\d{4})/, '$1******$2'),
                expiresIn: 300,
                deliveryMethod: otpDeliveryMethod,
                whatsappSent: whatsappSent
            }
        };
        next();

    } catch (error) {
        console.error('Resend Patient Login OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Failed to resend OTP. Please try again."
        };
        next();
    }
};

/**
 * Logout patient
 */
exports.logoutPatient = async (req, res, next) => {
    try {
        const patientId = req.patient?.patientId;

        if (patientId) {
            // Clear session from Redis
            const sessionKey = `patient_session:${patientId}`;
            await redisRouter.delFromRedis(sessionKey);
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: "Logout successful"
        };
        next();

    } catch (error) {
        console.error('Patient Logout Error:', error);
        res.locals = {
            status: STATUS.SUCCESS, // Still return success for logout
            message: "Logout completed"
        };
        next();
    }
};