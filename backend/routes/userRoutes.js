import express from 'express';
import verifyToken from '../middlewares/authMiddleware.js';
import authorizeRoles from '../middlewares/roleMiddleware.js';

const router = express.Router();

router.get("/customer", verifyToken, authorizeRoles("customer"), (req, res) => {
    res.json({message: "Welcome Customer!"});
});

router.get("/vendor", verifyToken, authorizeRoles("vendor"), (req, res) => {
    res.json({message: "Welcome Vendor!"});
});

router.get("/admin", verifyToken, authorizeRoles("admin"), (req, res) => {
    res.json({message: "Welcome Admin!"});
});

export default router;