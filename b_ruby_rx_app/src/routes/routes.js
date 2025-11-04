// ===== MIDDLEWARE IMPORTS =====
const { setResponse } = require('../middleware/setResponse');
const { validateRequest } = require('../middleware/validateRequests');

// ===== AUTHENTICATION CONTROLLERS =====
const loginRouter = require('../controllers/login/loginRouter');
const phoneOtpController = require('../controllers/login/phoneOtpController');
const patientAuthController = require('../controllers/patient/patientAuthController');

// ===== PATIENT SERVICES =====
const drugWalletController = require('../controllers/patient/drugWalletController');

// ===== PRESCRIPTION CONTROLLERS =====
const prescriptionOcrController = require('../controllers/prescription/prescriptionOcrController');
const manualPrescriptionController = require('../controllers/prescription/manualPrescriptionController');


// ===== MEDICINE CONTROLLERS =====
const medicineController = require('../controllers/medicine/medicineController');
const medicineDataController = require('../controllers/medicine/medicineDataController');
const medicineSubstituteController = require('../controllers/medicine/medicineSubstituteController');

const downloadPrescriptionPDF = require('../controllers/download-PDF/download-PDF-controller');


module.exports = function (app) {
    app.get('/', (req, res) => {
        res.send('API is running...');
    });

    // New registration flow routes
    app.post('/api/register-user', phoneOtpController.registerUser, setResponse);
    app.post('/api/setup-pin-after-registration', phoneOtpController.setupPinAfterRegistration, setResponse);

    // ===== PATIENT AUTHENTICATION ROUTES =====
    // Patient login routes
    app.post('/api/patient/send-login-otp', patientAuthController.sendPatientLoginOTP, setResponse);
    app.post('/api/patient/verify-login-otp', patientAuthController.verifyPatientLoginOTP, setResponse);
    app.post('/api/patient/resend-login-otp', patientAuthController.resendPatientLoginOTP, setResponse);

    // Patient registration
    app.post('/api/patient/register', patientAuthController.registerPatient, setResponse);

    // Patient PIN management
    app.post('/api/v1/patient/setup-pin', patientAuthController.setupPatientPIN, setResponse);
    app.post('/api/v1/patient/verify-pin', patientAuthController.verifyPatientPIN, setResponse);
    app.post('/api/v1/patient/reset-pin', patientAuthController.resetPatientPIN, setResponse);

    // Patient forgot PIN routes
    app.post('/api/patient/forgot-pin/send-otp', patientAuthController.sendForgotPinOTP, setResponse);
    app.post('/api/patient/forgot-pin/verify-otp', patientAuthController.verifyForgotPinOTP, setResponse);

    // Patient logout (requires authentication)
    app.post('/api/v1/patient/logout', validateRequest, patientAuthController.logoutPatient, setResponse);

    // Patient profile management (requires authentication)
    app.put('/api/v1/patient/profile', validateRequest, patientAuthController.updatePatientProfile, setResponse);

    // ===== DRUG WALLET ROUTES (requires authentication) =====
    // Get all patient medicines across all prescriptions
    app.get('/api/v1/patient/drug-wallet', validateRequest, drugWalletController.getPatientDrugWallet, setResponse);

    // ===== PRESCRIPTION PROCESSING ROUTES (SINGLE IMAGE ONLY) =====
    // Upload single prescription image with OCR processing
    app.post('/api/v1/prescription/upload',
        prescriptionOcrController.upload.single('prescription_image'),
        prescriptionOcrController.uploadPrescriptionImage,
        setResponse
    );

    // Create prescription (manual entry)
    app.post('/api/v1/prescriptions/createPrescription',
        manualPrescriptionController.createPrescription,
        setResponse
    );

    // Get prescription list
    app.get('/api/v1/prescriptions/getMyPrescriptionList',
        manualPrescriptionController.getMyPrescriptionList,
        setResponse
    );

    // Get prescription detail
    app.get('/api/v1/prescriptions/getPrescriptionDetail/:id',
        manualPrescriptionController.getPrescriptionDetail,
        setResponse
    );

    // Search medicines (requires authentication)
    app.get('/api/v1/medicines/search',
        medicineController.searchMedicines,
        setResponse
    );



    // ===== MEDICINE DATABASE SEARCH ROUTES =====

    // Get top 10 popular medicines (no authentication required for browsing)
    app.get('/api/medicine-data/popular',
        medicineDataController.getPopularMedicines,
        setResponse
    );

    // Get medicine substitutes by composition (requires authentication)
    // Dual composition: /api/v1/medicine-data/substitutes/:compositionId1/:compositionId2
    app.get('/api/v1/medicine-data/substitutes/:compositionId1/:compositionId2',
        validateRequest,
        medicineSubstituteController.getMedicineSubstitutes,
        setResponse
    );

    // Single composition: /api/v1/medicine-data/substitutes/:compositionId1
    // Note: This must come AFTER the dual composition route to avoid route conflicts
    app.get('/api/v1/medicine-data/substitutes/:compositionId1',
        validateRequest,
        medicineSubstituteController.getMedicineSubstitutes,
        setResponse
    );

    // Get medicine details with substitutes (requires authentication)
    app.get('/api/v1/medicine-data/:id/details',
        validateRequest,
        medicineSubstituteController.getMedicineWithSubstitutes,
        setResponse
    );

    app.post('/api/v1/get-user-data', loginRouter.getUserData, setResponse);

    // Download prescription PDF (requires authentication)
    app.get('/api/v1/download-prescription-pdf/:id', validateRequest, downloadPrescriptionPDF.getPrescriptionPDF, setResponse);
};