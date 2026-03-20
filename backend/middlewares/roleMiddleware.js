import { forbidden } from "../utils/responseMessages.js";

const authorizeRoles = (...allowedRoles) => {
    return (req, res, next) => {
        if(!allowedRoles.includes(req.user.userRole)){
            return forbidden(res);
        }
        next();
    }
};

export default authorizeRoles;