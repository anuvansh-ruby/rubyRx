const jwt = require('jsonwebtoken');
const STATUS = require('../utils/constants').STATUS;

exports.validateRequest = (req, res, next) => {
    try {
        const authHeader = req.headers["authorization"];
        if (!authHeader) {
            res.locals = { status: STATUS.FAILURE, message: "Authorization header missing" };
            return next();
        }

        const token = authHeader;

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            if (!decoded) {
                res.locals = { status: STATUS.FAILURE, message: "Invalid token payload" };
                return next();
            }
            req.user = { token: token, ...decoded };
            next();
        } catch (err) {
            res.locals = { status: STATUS.FAILURE, message: "Invalid token" };
            next();
        }
    } catch (err) {
        res.locals = { status: STATUS.FAILURE, message: err.message };
        next();
    }
};

