
const { STATUS } = require('../../utils/constants');
const medSearchService = require('./med_search_service');


exports.searchMedicines = async (req, res, next) => {
    try {
        const {
            q: query,
            limit = 20,
        } = req.query;

        if (!query || query.trim().length < 2) {
            res.locals = {
                status: STATUS.FAILURE,
                message: 'Search query must be at least 2 characters long'
            };
            return next();
        }
        let result = await medSearchService.searchMedicines(query.toLowerCase(), parseInt(limit));
        if (!result || result.status !== STATUS.SUCCESS) {
            throw new Error('Medicine search failed');
        }
        res.locals = {
            status: STATUS.SUCCESS,
            data: {
                medicines: result.data,
                search_query: query,
                results_count: result.data.length,
            }
        };

    } catch (error) {
        console.error('❌ Search medicines error:', error);

        res.locals = {
            status: STATUS.FAILURE,
            message: 'Failed to search medicines'
        };
    }

    next();
};
