const STATUS = require('../../utils/constants').STATUS;
const pool = require('../../config/dbConnection');
const jwt = require('jsonwebtoken');
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const redisRouter = require("../../utils/redisRouter");
const loginService = require('./loginService');


function generateOTP() {
    return crypto.randomInt(100000, 999999).toString();
}

// Nodemailer transporter
const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.GOOGLE_EMAIL_USER,
        pass: process.env.GOOGLE_APP_PASSWORD,
    },
});

// Utility to generate JWT token
function generateToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "7d" });
}

// ===== EMAIL OTP LOGIN =====
exports.login = async (req, res, next) => {
    try {
        const { email } = req.body;
        if (!email) {
            res.locals = { status: STATUS.FAILURE, message: "Email is required" };
            return next();
        }

        const otp = generateOTP();
        await redisRouter.setToRedis(`otp:${email}`, otp, 300); // 5 min TTL

        await transporter.sendMail({
            from: process.env.EMAIL_USER,
            to: email,
            subject: "Your OTP Code",
            text: `Your OTP is ${otp}. It will expire in 5 minutes.`,
        });

        res.locals = { status: STATUS.SUCCESS, message: "OTP sent successfully" };
        next();
    } catch (error) {
        res.locals = { status: STATUS.FAILURE, message: error.message };
        next();
    }
};

exports.verifyOtp = async (req, res, next) => {
    try {
        const { name, email, otp } = req.body;
        if (!name || !email || !otp) {
            res.locals = { status: STATUS.FAILURE, message: "Name, email, and OTP are required" };
            return next();
        }

        const storedOtp = await redisRouter.getFromRedis(`otp:${email}`);
        if (!storedOtp || storedOtp !== otp) {
            res.locals = { status: STATUS.FAILURE, message: "Invalid or expired OTP" };
            return next();
        }

        await redisRouter.delFromRedis(`otp:${email}`); // delete after verification

        const token = generateToken({ name, email });
        res.locals = { status: STATUS.SUCCESS, message: "OTP verified successfully", token };
        next();
    } catch (error) {
        res.locals = { status: STATUS.FAILURE, message: error.message };
        next();
    }
};

// ===== GOOGLE OAUTH =====
exports.googleLogin = (req, res) => {
    const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${process.env.GOOGLE_CLIENT_ID}&redirect_uri=${process.env.GOOGLE_REDIRECT_URI}&response_type=code&scope=profile email`;
    res.redirect(authUrl);
};

exports.googleLoginCallback = async (req, res) => {
    const { code } = req.query;
    try {
        const tokenUrl = "https://oauth2.googleapis.com/token";
        const body = new URLSearchParams({
            code,
            client_id: process.env.GOOGLE_CLIENT_ID,
            client_secret: process.env.GOOGLE_CLIENT_SECRET,
            redirect_uri: process.env.GOOGLE_REDIRECT_URI,
            grant_type: "authorization_code",
        });

        const response = await fetch(tokenUrl, { method: "POST", body });
        const data = await response.json();
        if (data.error) throw new Error(data.error_description || "Failed to get tokens");

        const decoded = jwt.decode(data.id_token);
        const token = generateToken({ name: decoded.name, email: decoded.email, picture: decoded.picture, source_id: decoded.sub });

        res.redirect(`http://localhost:3000/?token=${encodeURIComponent(token)}`);
    } catch (err) {
        res.redirect(`http://localhost:3000/?error=${encodeURIComponent(err.message)}`);
    }
};

// ===== LINKEDIN OAUTH =====
exports.linkedinLogin = (req, res) => {
    const authUrl = `https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=${process.env.LINKEDIN_CLIENT_ID}&redirect_uri=${process.env.LINKEDIN_REDIRECT_URI}&scope=openid%20profile%20email`;
    res.redirect(authUrl);
};

exports.linkedinLoginCallback = async (req, res) => {
    const { code } = req.query;
    try {
        const tokenUrl = "https://www.linkedin.com/oauth/v2/accessToken";
        const body = new URLSearchParams({
            grant_type: "authorization_code",
            code,
            redirect_uri: process.env.LINKEDIN_REDIRECT_URI,
            client_id: process.env.LINKEDIN_CLIENT_ID,
            client_secret: process.env.LINKEDIN_CLIENT_SECRET,
        });

        const response = await fetch(tokenUrl, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body,
        });

        const data = await response.json();
        if (data.error) throw new Error(data.error_description || "Failed to get tokens");

        const profileRes = await fetch("https://api.linkedin.com/v2/userinfo", {
            headers: { Authorization: `${data.access_token}` },
        });
        const profile = await profileRes.json();

        const token = generateToken({ name: profile.name, email: profile.email, picture: profile.picture, source_id: profile.sub });
        res.redirect(`http://localhost:3000/?token=${encodeURIComponent(token)}`);
    } catch (err) {
        res.redirect(`http://localhost:3000/?error=${encodeURIComponent(err.message)}`);
    }
};



exports.getUserData = async (req, res, next) => {
    try {
        if (!req.user || !req.user.email) {
            res.locals = { status: STATUS.FAILURE, message: "User not authenticated" };
            return next();
        }

        const email = req.user.email;

        // Try Redis first
        let userData = await redisRouter.getFromRedis(`user:${email}`);
        if (!userData) {
            // Not in Redis, check DB
            userData = await loginService.getUserDataFromDB(email);
            if (userData.status === STATUS.FAILURE) {
                // Handle DB error
                res.locals = { status: STATUS.FAILURE, message: userData.message };
                return next();
            } else if (userData && userData.status == STATUS.SUCCESS && !userData.data) {
                {
                    // Not in DB, create new user
                    const newUser = {
                        email,
                        full_name: req.user.name || "New User",
                        created_at: new Date().toISOString(),
                        picture: req.user.picture || "",
                        source_id: req.user.source_id || "",
                        user_type: req.user.user_type || "PLANNER"
                    };
                    userData = await loginService.createUserInDB(newUser);
                    if (userData.status === STATUS.FAILURE) {
                        res.locals = { status: STATUS.FAILURE, message: userData.message };
                        return next();
                    }
                }
            }
            // Store in Redis
            await redisRouter.setToRedis(`user:${email}`, userData);
        }

        res.locals = {
            status: STATUS.SUCCESS,
            message: "User data retrieved successfully",
            data: { token: req.user.token, ...userData },
        };
        next();
    } catch (error) {
        res.locals = { status: STATUS.FAILURE, message: error.message };
        next();
    }
};