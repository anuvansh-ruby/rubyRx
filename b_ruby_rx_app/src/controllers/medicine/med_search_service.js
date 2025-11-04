const { medicinePool } = require('../../config/multiDbConnection');
const { STATUS } = require('../../utils/constants');



exports.searchMedicines = function (parametersList, limit = 20) {

    let searchQuery = `SELECT
                        md.*,
                        ud.drug_name,
                        (
                            ${generatematchCountCondition(parametersList)}
                        ) AS match_count
                    FROM
                        med_details md
                    LEFT JOIN unique_drugs ud 
                        ON ud.id IN (
                            md.med_composition_id_1, 
                            md.med_composition_id_2, 
                            md.med_composition_id_3, 
                            md.med_composition_id_4, 
                            md.med_composition_id_5
                        )
                    WHERE
                        md.is_active = 1
                        AND (
                            ${generateWhereClause(parametersList)}
                        )
                    ORDER BY
                        match_count DESC,
                        md.med_type DESC,
                        md.med_weightage ASC
                        LIMIT ${limit};
                    `;

    console.log('Generated Search Query:', searchQuery);

    return new Promise((resolve, reject) => {
        medicinePool.query(searchQuery, (error, results) => {
            if (error) {
                console.error('Error executing search query:', error);
                return reject({
                    status: STATUS.ERROR,
                    message: 'Database query error',
                    error: error
                });
            }
            return resolve({
                status: STATUS.SUCCESS,
                data: results.rows
            });
        });
    });
};

function generatematchCountCondition(searchTerm) {
    for (let term of searchTerm.split(' ')) {
        let conditionParts = [];
        conditionParts.push(`CASE WHEN LOWER(md.med_brand_name) LIKE '${term}%' THEN 1 ELSE 0 END`);
        for (let i = 1; i <= 5; i++) {
            conditionParts.push(`CASE WHEN md.med_composition_strength_${i} LIKE '%${term}%' THEN 1 ELSE 0 END`);
            conditionParts.push(`CASE WHEN LOWER(md.med_composition_unit_${i}) LIKE '%${term}%' THEN 1 ELSE 0 END`);
        }
        conditionParts.push(`CASE WHEN LOWER(md.med_type) LIKE '%${term}%' THEN 1 ELSE 0 END`);
        conditionParts.push(`CASE WHEN LOWER(ud.drug_name) LIKE '%${term}%' THEN 1 ELSE 0 END`);

        let condition = conditionParts.join(' + ');
        return condition;
    }
}

function generateWhereClause(searchTerm) {
    let whereParts = [];
    for (let term of searchTerm.split(' ')) {
        whereParts.push(`LOWER(md.med_brand_name) LIKE '${term}%'`);
        for (let i = 1; i <= 5; i++) {
            whereParts.push(`md.med_composition_strength_${i} LIKE '%${term}%'`);
            whereParts.push(`LOWER(md.med_composition_unit_${i}) LIKE '%${term}%'`);
        }
        whereParts.push(`LOWER(md.med_type) LIKE '%${term}%'`);
        whereParts.push(`LOWER(ud.drug_name) LIKE '%${term}%'`);
    }
    return whereParts.join(' OR ');
}