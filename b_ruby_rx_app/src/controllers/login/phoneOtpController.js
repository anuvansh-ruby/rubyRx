const STATUS = require('../../utils/constants').STATUS;
const jwt = require('jsonwebtoken');
const crypto = require("crypto");
const redisRouter = require("../../utils/redisRouter");
const patientService = require('../patient/patientService');

// Generate 4-digit OTP
function generateOTP() {
    // For testing, use a fixed OTP
    return "1234"; // Fixed OTP for testing
    // return crypto.randomInt(1000, 9999).toString();
}

// Utility to generate JWT token
function generateToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "7d" });
}

// Send WhatsApp message via WasenderAPI
async function sendWhatsAppOTP(phoneNumber, otp) {
    try {
        // For development/testing - use mock mode if API key is not set or trial expired
        if (!process.env.WASENDER_API_KEY || process.env.WASENDER_API_KEY === 'your_api_key_here' || true) { // Force mock mode for testing
            console.log(`🧪 MOCK MODE: Would send OTP ${otp} to ${phoneNumber} via WhatsApp`);
            console.log(`Message: Your Ruby AI verification code is: ${otp}\n\nThis code will expire in 5 minutes.\n\nDo not share this code with anyone.`);
            return {
                success: true,
                data: {
                    message: 'Mock message sent successfully',
                    mock: true
                }
            };
        }

        const response = await fetch('https://wasenderapi.com/api/send-message', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.WASENDER_API_KEY}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                to: phoneNumber,
                text: `Your Ruby AI verification code is: ${otp}\n\nThis code will expire in 5 minutes.\n\nDo not share this code with anyone.`
            })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(`WhatsApp API Error: ${data.message || 'Failed to send message'}`);
        }

        return { success: true, data };
    } catch (error) {
        console.error('WhatsApp API Error:', error);
        throw new Error(`Failed to send OTP via WhatsApp: ${error.message}`);
    }
}

// Send OTP to phone number
exports.sendPhoneOTP = async (req, res, next) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number is required"
            };
            return next();
        }

        // Validate phone number format (basic validation)
        const phoneRegex = /^\+\d{10,15}$/;
        if (!phoneRegex.test(phoneNumber)) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Invalid phone number format. Please include country code (e.g., +91xxxxxxxxxx)"
            };
            return next();
        }

        // Generate 4-digit OTP
        const otp = generateOTP();

        // Store OTP in Redis with 5 minute expiry
        const otpKey = `phone_otp:${phoneNumber}`;
        await redisRouter.setToRedis(otpKey, otp, 300); // 5 minutes TTL

        // Store attempt count to prevent spam
        const attemptKey = `otp_attempts:${phoneNumber}`;
        const attempts = await redisRouter.getFromRedis(attemptKey) || 0;

        if (attempts >= 3) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Too many OTP requests. Please try again after 5 minutes."
            };
            return next();
        }

        // Increment attempt count
        await redisRouter.setToRedis(attemptKey, parseInt(attempts) + 1, 300);

        // Send OTP via WhatsApp
        await sendWhatsAppOTP(phoneNumber, otp);

        res.locals = {
            status: STATUS.SUCCESS,
            message: "OTP sent successfully to your WhatsApp",
            data: { phoneNumber: phoneNumber.replace(/(\+\d{2})\d{6}(\d{4})/, '$1******$2') } // Mask phone number
        };
        next();

    } catch (error) {
        console.error('Send OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: error.message || "Failed to send OTP"
        };
        next();
    }
};

// Verify OTP and login user
exports.verifyPhoneOTP = async (req, res, next) => {
    try {
        const { phoneNumber, otp } = req.body;

        if (!phoneNumber || !otp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number and OTP are required"
            };
            return next();
        }

        // Get stored OTP from Redis (matching patient auth controller key pattern)
        const otpKey = `patient_login_otp:${phoneNumber}`;
        const storedOtp = await redisRouter.getFromRedis(otpKey);

        if (!storedOtp) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "OTP has expired. Please request a new one."
            };
            return next();
        }

        if (storedOtp !== otp) {
            // Track failed verification attempts
            const failKey = `otp_fails:${phoneNumber}`;
            const fails = await redisRouter.getFromRedis(failKey) || 0;

            if (fails >= 2) {
                // Delete OTP after 3 failed attempts
                await redisRouter.delFromRedis(otpKey);
                await redisRouter.delFromRedis(failKey);

                res.locals = {
                    status: STATUS.FAILURE,
                    message: "Too many incorrect attempts. Please request a new OTP."
                };
                return next();
            }

            await redisRouter.setToRedis(failKey, parseInt(fails) + 1, 300);

            res.locals = {
                status: STATUS.FAILURE,
                message: `Invalid OTP. ${2 - fails} attempts remaining.`
            };
            return next();
        }

        // OTP is valid - clean up Redis keys
        await redisRouter.delFromRedis(otpKey);
        await redisRouter.delFromRedis(`otp_attempts:${phoneNumber}`);
        await redisRouter.delFromRedis(`otp_fails:${phoneNumber}`);

        // Check if patient exists in database
        const patientCheck = await patientService.checkPhoneExists(phoneNumber);

        if (patientCheck.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Error checking user records. Please try again."
            };
            return next();
        }

        // If patient exists and is active, return token
        if (patientCheck.exists && patientCheck.isActive) {
            const patientResult = await patientService.getPatientByPhone(phoneNumber);

            if (patientResult.status === STATUS.SUCCESS && patientResult.data) {
                const patient = patientResult.data;

                // Generate JWT token for existing user
                const tokenPayload = {
                    patientId: patient.patient_id,
                    phone: patient.patient_phone_number,
                    email: patient.patient_email,
                    firstName: patient.patient_first_name,
                    lastName: patient.patient_last_name,
                    loginMethod: 'phone',
                    verified: true,
                    loginTime: new Date().toISOString()
                };

                const token = generateToken(tokenPayload);

                // Store user session in Redis
                const sessionKey = `user_session:${phoneNumber}`;
                const sessionData = {
                    ...tokenPayload,
                    token,
                    lastActive: new Date().toISOString()
                };

                await redisRouter.setToRedis(sessionKey, sessionData, 7 * 24 * 60 * 60); // 7 days

                res.locals = {
                    status: STATUS.SUCCESS,
                    message: "OTP verified successfully",
                    data: {
                        token,
                        isExistingUser: true,
                        user: {
                            id: patient.patient_id,
                            phoneNumber: patient.patient_phone_number,
                            firstName: patient.patient_first_name,
                            lastName: patient.patient_last_name,
                            email: patient.patient_email,
                            dateOfBirth: patient.patient_date_of_birth,
                            address: patient.patient_address,
                            hasPinSetup: patient.patient_pin ? true : false,
                            verified: true
                        }
                    }
                };
                return next();
            }
        }

        // If patient doesn't exist or is inactive, return success but no token (new user)
        res.locals = {
            status: STATUS.SUCCESS,
            message: "OTP verified successfully. Please complete your registration.",
            data: {
                isExistingUser: false,
                phoneNumber: phoneNumber,
                verified: true
            }
        };
        next();

    } catch (error) {
        console.error('Verify OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: error.message || "Failed to verify OTP"
        };
        next();
    }
};

// Register new user with full details
exports.registerUser = async (req, res, next) => {
    try {
        const {
            phoneNumber,
            firstName,
            lastName,
            email,
            dateOfBirth,
            address,
            nationalIdType,
            nationalIdNumber
        } = req.body;

        // Input validation
        const requiredFields = { phoneNumber, firstName, lastName, email, dateOfBirth };
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

        // Check email uniqueness
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
            created_by: 'user_registration',
            updated_by: 'user_registration'
        };

        // Create patient record (without PIN)
        const createResult = await patientService.createPatientInDB(patientData);

        if (createResult.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: createResult.message || "Failed to register user"
            };
            return next();
        }

        const newPatient = createResult.data;

        // Store temporary registration session (no token yet - user needs to set PIN)
        const tempSessionKey = `temp_registration:${phoneNumber}`;
        const tempSessionData = {
            patientId: newPatient.patient_id,
            phoneNumber: newPatient.patient_phone_number,
            registrationComplete: true,
            pinRequired: true,
            createdAt: new Date().toISOString()
        };

        await redisRouter.setToRedis(tempSessionKey, JSON.stringify(tempSessionData), 300); // 5 minutes to set PIN

        res.locals = {
            status: STATUS.SUCCESS,
            message: "Registration successful. Please setup your PIN to complete the process.",
            data: {
                patientId: newPatient.patient_id,
                phoneNumber: newPatient.patient_phone_number,
                firstName: newPatient.patient_first_name,
                lastName: newPatient.patient_last_name,
                email: newPatient.patient_email,
                registrationComplete: true,
                pinRequired: true
            }
        };
        next();

    } catch (error) {
        console.error('User Registration Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: error.message || "Registration failed. Please try again."
        };
        next();
    }
};

// Setup PIN after registration and generate final token
exports.setupPinAfterRegistration = async (req, res, next) => {
    try {
        const { phoneNumber, pin } = req.body;

        if (!phoneNumber || !pin) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number and PIN are required"
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

        // Get temporary registration session
        const tempSessionKey = `temp_registration:${phoneNumber}`;
        const tempSessionData = await redisRouter.getFromRedis(tempSessionKey);

        if (!tempSessionData) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Registration session expired. Please register again."
            };
            return next();
        }

        const sessionInfo = JSON.parse(tempSessionData);

        // Hash the PIN before storing
        const hashedPin = crypto.createHash('sha256').update(pin).digest('hex');

        // Update patient record with PIN
        const updateResult = await patientService.updatePatientPIN(sessionInfo.patientId, hashedPin);

        if (updateResult.status === STATUS.FAILURE) {
            res.locals = {
                status: STATUS.FAILURE,
                message: updateResult.message || "Failed to set PIN"
            };
            return next();
        }

        // Get complete patient data
        const patientResult = await patientService.getPatientByPhone(phoneNumber);

        if (patientResult.status === STATUS.SUCCESS && patientResult.data) {
            const patient = patientResult.data;

            // Generate final JWT token
            const tokenPayload = {
                patientId: patient.patient_id,
                phone: patient.patient_phone_number,
                email: patient.patient_email,
                firstName: patient.patient_first_name,
                lastName: patient.patient_last_name,
                loginMethod: 'registration',
                verified: true,
                loginTime: new Date().toISOString()
            };

            const token = generateToken(tokenPayload);

            // Store user session in Redis
            const sessionKey = `user_session:${phoneNumber}`;
            const sessionData = {
                ...tokenPayload,
                token,
                lastActive: new Date().toISOString()
            };

            await redisRouter.setToRedis(sessionKey, sessionData, 7 * 24 * 60 * 60); // 7 days

            // Clean up temporary registration session
            await redisRouter.delFromRedis(tempSessionKey);

            res.locals = {
                status: STATUS.SUCCESS,
                message: "PIN setup successful. Registration complete!",
                data: {
                    token,
                    user: {
                        id: patient.patient_id,
                        phoneNumber: patient.patient_phone_number,
                        firstName: patient.patient_first_name,
                        lastName: patient.patient_last_name,
                        email: patient.patient_email,
                        dateOfBirth: patient.patient_date_of_birth,
                        address: patient.patient_address,
                        hasPinSetup: true,
                        verified: true
                    }
                }
            };
            return next();
        }

        res.locals = {
            status: STATUS.FAILURE,
            message: "Failed to retrieve user data after PIN setup"
        };
        next();

    } catch (error) {
        console.error('Setup PIN After Registration Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: error.message || "Failed to setup PIN. Please try again."
        };
        next();
    }
};

// Resend OTP (with rate limiting)
exports.resendPhoneOTP = async (req, res, next) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Phone number is required"
            };
            return next();
        }

        // Check if user can resend (wait at least 60 seconds)
        const resendKey = `otp_resend:${phoneNumber}`;
        const lastResend = await redisRouter.getFromRedis(resendKey);

        if (lastResend) {
            const timeDiff = Date.now() - parseInt(lastResend);
            const waitTime = 60000 - timeDiff; // 60 seconds

            if (waitTime > 0) {
                res.locals = {
                    status: STATUS.FAILURE,
                    message: `Please wait ${Math.ceil(waitTime / 1000)} seconds before requesting another OTP`
                };
                return next();
            }
        }

        // Set resend timestamp
        await redisRouter.setToRedis(resendKey, Date.now().toString(), 60);

        // Use the existing sendPhoneOTP logic
        req.body = { phoneNumber };
        return exports.sendPhoneOTP(req, res, next);

    } catch (error) {
        console.error('Resend OTP Error:', error);
        res.locals = {
            status: STATUS.FAILURE,
            message: error.message || "Failed to resend OTP"
        };
        next();
    }
};