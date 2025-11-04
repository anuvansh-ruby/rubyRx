const puppeteer = require("puppeteer");
const fs = require("fs");
const path = require("path");
const pool = require("../../config/dbConnection");
const { STATUS } = require("../../utils/constants");

exports.getPrescriptionPDF = async (req, res, next) => {
    const client = await pool.connect();

    try {
        const prescriptionId = req.params.id;

        if (!req.user || !req.user.patientId) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Patient authentication required"
            };
            return next();
        }

        const patientId = req.user.patientId;

        // ✅ Query prescription details with patient, appointment, and vitals info
        const detailQuery = `
            SELECT 
                pp.prescription_id::int,
                pp.patient_id::int,
                pr.patient_first_name,
                pr.patient_last_name,
                pr.patient_date_of_birth,
                pp.created_at,
                pp.created_at as appointment_date,
                pp.updated_at,
                da.patient_weight,
                da.patient_height,
                da.patient_blood_pressure,
                da.patient_pulse,
                da.patient_temprature,
                dad.appointment_summary,
                dr.dr_name,
                dr.dr_specialization
            FROM patient_prescription pp
            LEFT JOIN patients_records pr ON pr.patient_id = pp.patient_id
            LEFT JOIN dr_appointment_details dad ON dad.prescription_id = pp.prescription_id
            LEFT JOIN dr_appointment da ON da.appointment_id = dad.appointment_id
            LEFT JOIN doctors_records dr ON dr.dr_id = da.dr_id
            WHERE pp.prescription_id = $1 AND pp.patient_id = $2 AND pp.is_active = 1
        `;

        const result = await client.query(detailQuery, [prescriptionId, patientId]);

        if (result.rows.length === 0) {
            res.locals = {
                status: STATUS.FAILURE,
                message: "Prescription not found or access denied"
            };
            return next();
        }

        const data = result.rows[0];

        // ✅ Fetch medicines for the same prescription
        const medResult = await client.query(
            `SELECT medicine_name, medicine_salt, medicine_frequency 
             FROM patient_medicine 
             WHERE prescription_id = $1 AND is_active = 1`,
            [prescriptionId]
        );

        data.medicines = medResult.rows;

        // ✅ Calculate patient age if DOB is available
        let patientAge = '-';
        let patientGender = '-';
        if (data.patient_date_of_birth) {
            const dob = new Date(data.patient_date_of_birth);
            const today = new Date();
            const age = today.getFullYear() - dob.getFullYear();
            const monthDiff = today.getMonth() - dob.getMonth();
            if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
                patientAge = age - 1;
            } else {
                patientAge = age;
            }
        }

        // ✅ Format vitals
        const vitals = [];
        if (data.patient_weight) vitals.push(`Weight: ${data.patient_weight} kg`);
        if (data.patient_height) vitals.push(`Height: ${data.patient_height} cm`);
        if (data.patient_blood_pressure) vitals.push(`BP: ${data.patient_blood_pressure} mmHg`);
        if (data.patient_pulse) vitals.push(`Pulse: ${data.patient_pulse} bpm`);
        if (data.patient_temprature) vitals.push(`Temp: ${data.patient_temprature}°F`);
        const vitalsText = vitals.length > 0 ? vitals.join(', ') : 'Not recorded';

        // ✅ Diagnosis text
        const diagnosisText = data.appointment_summary || 'As per consultation';

        // ✅ Doctor details
        const doctorName = data.dr_name || 'Consulting Doctor';
        const doctorSpecialization = data.dr_specialization || 'General Medicine';

        // ✅ HTML Template for PDF - Professional Prescription Format
        const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body { 
                    font-family: 'Arial', 'Helvetica', sans-serif; 
                    font-size: 11pt;
                    line-height: 1.4;
                    padding: 20px;
                    color: #000;
                }
                
                .header {
                    border: 2px solid #000;
                    padding: 15px;
                    margin-bottom: 15px;
                    background: linear-gradient(to right, #f8f9fa 0%, #e9ecef 100%);
                }
                
                .clinic-name {
                    font-size: 18pt;
                    font-weight: bold;
                    color: #2c3e50;
                    text-transform: uppercase;
                    margin-bottom: 5px;
                }
                
                .header-details {
                    font-size: 9pt;
                    line-height: 1.3;
                    margin-top: 8px;
                }
                
                .header-details p {
                    margin: 2px 0;
                }
                
                .patient-info {
                    display: table;
                    width: 100%;
                    margin: 15px 0;
                    border: 1px solid #dee2e6;
                    background: #fff;
                }
                
                .patient-row {
                    display: table-row;
                }
                
                .patient-cell {
                    display: table-cell;
                    padding: 8px;
                    border-bottom: 1px solid #dee2e6;
                }
                
                .patient-cell:first-child {
                    width: 50%;
                    border-right: 1px solid #dee2e6;
                }
                
                .label {
                    font-weight: bold;
                    color: #495057;
                }
                
                .vitals-section {
                    margin: 15px 0;
                    padding: 10px;
                    background: #f8f9fa;
                    border-left: 4px solid #007bff;
                }
                
                .vitals-section .label {
                    color: #007bff;
                }
                
                .diagnosis-section {
                    margin: 15px 0;
                    padding: 10px;
                    background: #fff3cd;
                    border-left: 4px solid #ffc107;
                }
                
                .diagnosis-section .label {
                    color: #856404;
                }
                
                .rx-header {
                    background: #000;
                    color: #fff;
                    padding: 8px 12px;
                    font-weight: bold;
                    font-size: 14pt;
                    margin: 20px 0 10px 0;
                }
                
                .medicines-table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 10px 0 20px 0;
                    border: 1px solid #000;
                }
                
                .medicines-table th {
                    background: #e9ecef;
                    border: 1px solid #000;
                    padding: 8px;
                    text-align: left;
                    font-weight: bold;
                    font-size: 10pt;
                }
                
                .medicines-table td {
                    border: 1px solid #000;
                    padding: 8px;
                    font-size: 10pt;
                    vertical-align: top;
                }
                
                .medicines-table td:first-child {
                    width: 40px;
                    text-align: center;
                    font-weight: bold;
                }
                
                .medicine-name {
                    font-weight: bold;
                    color: #000;
                    margin-bottom: 3px;
                }
                
                .medicine-composition {
                    font-size: 9pt;
                    color: #6c757d;
                    font-style: italic;
                }
                
                .instructions-section {
                    margin: 20px 0;
                    padding: 12px;
                    background: #e7f3ff;
                    border-left: 4px solid #0056b3;
                }
                
                .instructions-section .label {
                    color: #0056b3;
                    font-size: 11pt;
                    margin-bottom: 8px;
                    display: block;
                }
                
                .instructions-section ul {
                    margin-left: 20px;
                    margin-top: 5px;
                }
                
                .instructions-section li {
                    margin: 4px 0;
                }
                
                .signature-section {
                    margin-top: 40px;
                    display: table;
                    width: 100%;
                }
                
                .signature-left {
                    display: table-cell;
                    width: 50%;
                    padding-right: 20px;
                }
                
                .signature-right {
                    display: table-cell;
                    width: 50%;
                    text-align: right;
                }
                
                .signature-line {
                    margin-top: 50px;
                    border-top: 2px solid #000;
                    padding-top: 5px;
                    font-weight: bold;
                }
                
                .footer {
                    margin-top: 30px;
                    padding-top: 15px;
                    border-top: 2px dashed #dee2e6;
                    text-align: center;
                    font-size: 9pt;
                    color: #6c757d;
                }
                
                .watermark {
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%) rotate(-45deg);
                    font-size: 80pt;
                    color: rgba(0, 123, 255, 0.05);
                    font-weight: bold;
                    z-index: -1;
                    white-space: nowrap;
                }
            </style>
        </head>
        <body>
            <div class="watermark">RUBY RX</div>
            
            <!-- Header -->
            <div class="header">
                <div class="clinic-name">Ruby RX - Digital Prescription</div>
                <div class="header-details">
                    <p><strong>Digital Healthcare Platform</strong></p>
                    <p><strong>Doctor:</strong> ${doctorName} ${doctorSpecialization ? `(${doctorSpecialization})` : ''}</p>
                    <p>Prescription ID: <strong>#${data.prescription_id}</strong></p>
                    <p>Date: <strong>${new Date(data.appointment_date || data.created_at).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        })}</strong></p>
                </div>
            </div>
            
            <!-- Patient Information -->
            <div class="patient-info">
                <div class="patient-row">
                    <div class="patient-cell">
                        <span class="label">Name:</span> ${data.patient_first_name || ""} ${data.patient_last_name || ""}
                    </div>
                    <div class="patient-cell">
                        <span class="label">Date:</span> ${new Date(data.appointment_date || data.created_at).toLocaleDateString('en-US')}
                    </div>
                </div>
                <div class="patient-row">
                    <div class="patient-cell">
                        <span class="label">Age/Sex:</span> ${patientAge} / ${patientGender}
                    </div>
                    <div class="patient-cell">
                        <span class="label">Patient ID:</span> ${data.patient_id}
                    </div>
                </div>
            </div>
            
            <!-- Vitals Section -->
            <div class="vitals-section">
                <span class="label">Vitals:</span> ${vitalsText}
            </div>
            
            <!-- Diagnosis Section -->
            <div class="diagnosis-section">
                <span class="label">Diagnosis:</span> ${diagnosisText}
            </div>
            
            <!-- Prescription Header -->
            <div class="rx-header">℞ PRESCRIPTION</div>
            
            <!-- Medicines Table -->
            <table class="medicines-table">
                <thead>
                    <tr>
                        <th>Sr.</th>
                        <th>Name</th>
                        <th>Frequency</th>
                        <th>Duration</th>
                        <th>Notes</th>
                    </tr>
                </thead>
                <tbody>
                    ${data.medicines.length > 0 ? data.medicines.map((m, i) => `
                    <tr>
                        <td>${i + 1}</td>
                        <td>
                            <div class="medicine-name">${m.medicine_name || 'N/A'}</div>
                            ${m.medicine_salt ? `<div class="medicine-composition">${m.medicine_salt}</div>` : ''}
                        </td>
                        <td>${m.medicine_frequency || '-'}</td>
                        <td>As prescribed</td>
                        <td>-</td>
                    </tr>
                    `).join('') : `
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 20px; color: #6c757d;">
                            No medicines prescribed
                        </td>
                    </tr>
                    `}
                </tbody>
            </table>
            
            <!-- Instructions Section -->
            <div class="instructions-section">
                <span class="label">Instructions:</span>
                <ul>
                    <li>Take medicines as prescribed by your healthcare provider</li>
                    <li>Complete the full course of medication</li>
                    <li>Consult your doctor if you experience any side effects</li>
                    <li>Store medicines in a cool, dry place</li>
                </ul>
            </div>
            
            <!-- Signature Section -->
            <div class="signature-section">
                <div class="signature-left">
                    <p><strong>Follow-up:</strong> As advised</p>
                    <p style="margin-top: 10px; font-size: 9pt; color: #6c757d;">
                        Prescribed by: <strong>${doctorName}</strong>
                    </p>
                </div>
                <div class="signature-right">
                    <div class="signature-line">
                        ${doctorName}
                        <br>
                        <span style="font-size: 10pt; font-weight: normal;">${doctorSpecialization}</span>
                        <br>
                        <span style="font-size: 9pt; font-weight: normal; color: #6c757d;">Digital Signature</span>
                    </div>
                </div>
            </div>
            
            <!-- Footer -->
            <div class="footer">
                <p><strong>Ruby RX - Digital Prescription Management Platform</strong></p>
                <p>Generated on ${new Date().toLocaleString('en-US', {
            dateStyle: 'full',
            timeStyle: 'short'
        })}</p>
                <p style="margin-top: 8px; font-size: 8pt;">
                    This is a digitally generated prescription. Please verify medicine details with your healthcare provider.
                    <br>Keep this prescription for your medical records.
                </p>
            </div>
        </body>
        </html>
        `;

        // ✅ Generate PDF with Puppeteer
        const browser = await puppeteer.launch({
            headless: true,
            args: ["--no-sandbox", "--disable-setuid-sandbox"]
        });
        const page = await browser.newPage();
        await page.setContent(html, { waitUntil: "networkidle0" });

        const pdfBuffer = await page.pdf({
            format: "A4",
            printBackground: true
        });

        await browser.close();

        // ✅ Convert PDF buffer to base64 string
        const base64String = Buffer.from(pdfBuffer).toString("base64");

        console.log(`✅ Generated PDF: ${pdfBuffer.length} bytes`);
        console.log(`✅ Base64 length: ${base64String.length} characters`);
        console.log(`✅ Base64 preview: ${base64String.substring(0, 50)}...`);

        // ✅ Return PDF as base64 in JSON response
        res.locals = {
            status: STATUS.SUCCESS,
            message: "Prescription PDF generated successfully",
            data: {
                prescription_id: prescriptionId,
                pdf_base64: base64String
            }
        };

    } catch (error) {
        console.error("❌ PDF generation error:", error);
        res.locals = {
            status: STATUS.FAILURE,
            message: "Failed to generate prescription PDF",
            error: error.message
        };
    } finally {
        client.release();
    }

    next();
};
