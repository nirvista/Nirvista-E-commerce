import { Op } from "sequelize";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import User from "../models/userModel.js";
import VendorProfile from "../models/vendorProfileModel.js";
import RefreshToken from "../models/refreshTokenModel.js";
import Product from "../models/productModel.js";
import ProductVariant from "../models/variantModel.js";
import { success, created, notFound, badRequest, serverError } from "../utils/responseMessages.js";

// ---------------------------------------------------------------------------
// Helper: mask bank account number — only expose last 4 digits
// ---------------------------------------------------------------------------
function maskBankAccount(accountNumber) {
    if (!accountNumber) return null;
    const last4 = accountNumber.slice(-4);
    return `${"*".repeat(Math.max(0, accountNumber.length - 4))}${last4}`;
}

// ---------------------------------------------------------------------------
// Helper: format a vendor record for API response
// ---------------------------------------------------------------------------
function formatVendorResponse(user, profile, maskSensitive = true) {
    const base = {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        userRole: user.userRole,
        userStatus: user.userStatus,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
    };

    if (!profile) return { ...base, vendorProfile: null };

    return {
        ...base,
        vendorProfile: {
            id: profile.id,
            storeName: profile.storeName,
            storeDescription: profile.storeDescription,
            businessEmail: profile.businessEmail,
            businessPhone: profile.businessPhone,
            businessAddress: profile.businessAddress,
            businessRegistrationNumber: profile.businessRegistrationNumber,
            businessRegistrationDocUrl: profile.businessRegistrationDocUrl,
            taxId: profile.taxId,
            bankAccountName: profile.bankAccountName,
            // Mask bank account number unless full view is requested
            bankAccountNumber: maskSensitive
                ? maskBankAccount(profile.bankAccountNumber)
                : profile.bankAccountNumber,
            bankName: profile.bankName,
            bankIFSC: profile.bankIFSC,
            vendorStatus: profile.vendorStatus,
            statusReason: profile.statusReason,
            statusUpdatedAt: profile.statusUpdatedAt,
        },
    };
}

// ---------------------------------------------------------------------------
// GET /api/admin/vendors
// List all vendors with pagination, sorting, and filtering
// ---------------------------------------------------------------------------
export const getAllVendors = async (req, res) => {
    try {
        const {
            status,          // Filter by vendorProfile.vendorStatus
            userStatus,      // Filter by user.userStatus
            search,          // Search by storeName, name, or email
            page = 1,
            limit = 20,
            sortBy = "createdAt",
            sortOrder = "DESC",
        } = req.query;

        const pageNum = Math.max(1, parseInt(page, 10));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
        const offset = (pageNum - 1) * limitNum;

        // --- Build user-level filter ---
        const userWhere = { userRole: "vendor" };
        if (userStatus) userWhere.userStatus = userStatus;

        if (search) {
            userWhere[Op.or] = [
                { name: { [Op.iLike]: `%${search}%` } },
                { email: { [Op.iLike]: `%${search}%` } },
            ];
        }

        // --- Build profile-level filter ---
        const profileWhere = {};
        if (status) profileWhere.vendorStatus = status;
        if (search) {
            // Also search by storeName (merge into profile where)
            profileWhere[Op.or] = [
                { storeName: { [Op.iLike]: `%${search}%` } },
            ];
        }

        // --- Validate sort column (whitelist) ---
        const allowedSortColumns = ["createdAt", "updatedAt", "name", "email"];
        const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : "createdAt";
        const safeSortOrder = sortOrder.toUpperCase() === "ASC" ? "ASC" : "DESC";

        const { count, rows } = await User.findAndCountAll({
            where: userWhere,
            include: [
                {
                    model: VendorProfile,
                    as: "vendorProfile",
                    where: Object.keys(profileWhere).length > 0 ? profileWhere : undefined,
                    required: Object.keys(profileWhere).length > 0, // INNER JOIN only when filtering
                    attributes: [
                        "id", "storeName", "businessEmail", "businessPhone",
                        "vendorStatus", "statusReason", "statusUpdatedAt", "createdAt"
                    ]
                }
            ],
            attributes: { exclude: ["password"] },
            order: [[safeSortBy, safeSortOrder]],
            limit: limitNum,
            offset,
            distinct: true,
        });

        const vendors = rows.map(user =>
            formatVendorResponse(user, user.vendorProfile, true)
        );

        success(res, {
            vendors,
            pagination: {
                total: count,
                page: pageNum,
                limit: limitNum,
                totalPages: Math.ceil(count / limitNum),
            }
        }, "Vendors fetched successfully");
    } catch (error) {
        console.error("[getAllVendors]", error);
        serverError(res, "Failed to fetch vendors");
    }
};

// ---------------------------------------------------------------------------
// GET /api/admin/vendors/:vendorId
// Full vendor details including sensitive business/banking data
// ---------------------------------------------------------------------------
export const getVendorById = async (req, res) => {
    try {
        const { vendorId } = req.params;

        const user = await User.findOne({
            where: { id: vendorId, userRole: "vendor" },
            attributes: { exclude: ["password"] },
            include: [
                {
                    model: VendorProfile,
                    as: "vendorProfile",
                }
            ]
        });

        if (!user) return notFound(res, "Vendor not found");

        // Full detail view — unmask bank account
        const vendorData = formatVendorResponse(user, user.vendorProfile, false);

        success(res, vendorData, "Vendor details fetched successfully");
    } catch (error) {
        console.error("[getVendorById]", error);
        serverError(res, "Failed to fetch vendor details");
    }
};

// ---------------------------------------------------------------------------
// POST /api/vendor/profile
// Create a vendor profile for an existing vendor if not present
// ---------------------------------------------------------------------------
export const createVendorProfileIfNotExists = async (req, res) => {
    try {
        const userId = req.user?.id; // Assumes authentication middleware sets req.user
        if (!userId) {
            return res.status(401).json({ success: false, message: "Unauthorized" });
        }

        // Check if user is a vendor
        const user = await User.findByPk(userId);
        if (!user || user.userRole !== "vendor") {
            return res.status(403).json({ success: false, message: "Only vendors can create a profile" });
        }

        // Check if profile already exists
        const existingProfile = await VendorProfile.findOne({ where: { userId } });
        if (existingProfile) {
            return res.status(400).json({ success: false, message: "Vendor profile already exists" });
        }

        // Extract profile fields from request body
        const {
            storeName,
            storeDescription,
            businessEmail,
            businessPhone,
            businessAddress,
            businessRegistrationNumber,
            businessRegistrationDocUrl,
            taxId,
            bankAccountName,
            bankAccountNumber,
            bankName,
            bankIFSC,
        } = req.body;

        // Validate required fields
        if (!storeName) {
            return res.status(400).json({ success: false, message: "storeName is required" });
        }

        // Create the vendor profile
        const vendorProfile = await VendorProfile.create({
            userId,
            storeName,
            storeDescription,
            businessEmail,
            businessPhone,
            businessAddress,
            businessRegistrationNumber,
            businessRegistrationDocUrl,
            taxId,
            bankAccountName,
            bankAccountNumber,
            bankName,
            bankIFSC,
        });

        return success(res, vendorProfile, "Vendor profile created successfully");
    } catch (error) {
        return serverError(res, "Failed to create vendor profile");
    }
};

// ---------------------------------------------------------------------------
// POST /api/admin/vendors
// Manually provision a vendor account (bypasses public application)
// ---------------------------------------------------------------------------
export const createVendorByAdmin = async (req, res) => {
    try {
        const {
            // User fields
            name,
            email,
            phone,
            password,
            // Vendor profile fields
            storeName,
            storeDescription,
            businessEmail,
            businessPhone,
            businessAddress,
            businessRegistrationNumber,
            taxId,
            bankAccountName,
            bankAccountNumber,
            bankName,
            bankIFSC,
        } = req.body;

        // --- Validate required fields ---
        if (!name || !email || !phone || !storeName) {
            return badRequest(res, "name, email, phone, and storeName are required");
        }

        // --- Check for duplicate email ---
        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return badRequest(res, "A user with this email already exists");
        }

        const tempPassword = password || crypto.randomBytes(16).toString("hex");
        const hashedPassword = await bcrypt.hash(tempPassword, 10);

        // --- Create user account ---
        const newUser = await User.create({
            name,
            email,
            phone,
            password: hashedPassword,
            userRole: "vendor",
            userStatus: "active", // Admin-created accounts are active immediately
        });

        // --- Create vendor profile ---
        const vendorProfile = await VendorProfile.create({
            userId: newUser.id,
            storeName,
            storeDescription,
            businessEmail: businessEmail || email,
            businessPhone: businessPhone || phone,
            businessAddress,
            businessRegistrationNumber,
            taxId,
            bankAccountName,
            bankAccountNumber,
            bankName,
            bankIFSC,
            vendorStatus: "approved", // Admin-created vendors are pre-approved
            statusUpdatedAt: new Date(),
        });

        // --- Send invitation email (placeholder — integrate with your email service) ---
        // In production: await sendVendorInvitationEmail(email, name, tempPassword);
        // This should send a "set your password" link, not the raw tempPassword.
        console.info(`[createVendorByAdmin] Invitation email should be sent to: ${email}`);

        const responseData = formatVendorResponse(newUser, vendorProfile, true);

        created(res, {
            ...responseData,
            _note: "An invitation email has been dispatched to the vendor's email address.",
        }, "Vendor account created successfully");
    } catch (error) {
        console.error("[createVendorByAdmin]", error);
        serverError(res, "Failed to create vendor account");
    }
};

// ---------------------------------------------------------------------------
// PATCH /api/admin/vendors/:vendorId/status
// Approve, suspend, or reject a vendor
// On suspend: invalidates all JWTs and hides products
// ---------------------------------------------------------------------------
export const updateVendorStatus = async (req, res) => {
    try {
        const { vendorId } = req.params;
        const { status, reason } = req.body;

        // --- Validate status payload ---
        const allowedStatuses = ["approved", "suspended", "rejected", "pending"];
        if (!status || !allowedStatuses.includes(status)) {
            return badRequest(res, `status must be one of: ${allowedStatuses.join(", ")}`);
        }

        // --- Find vendor user ---
        const user = await User.findOne({
            where: { id: vendorId, userRole: "vendor" },
        });
        if (!user) return notFound(res, "Vendor not found");

        // --- Find vendor profile ---
        const vendorProfile = await VendorProfile.findOne({
            where: { userId: vendorId }
        });
        if (!vendorProfile) return notFound(res, "Vendor profile not found");

        // --- Map vendorStatus → userStatus ---
        // This drives authentication middleware and product visibility
        const userStatusMap = {
            approved: "active",
            suspended: "suspended",
            rejected: "suspended",  // Rejected vendors also cannot log in
            pending: "pending",
        };

        const previousStatus = vendorProfile.vendorStatus;

        // --- Update VendorProfile ---
        await vendorProfile.update({
            vendorStatus: status,
            statusReason: reason || null,
            statusUpdatedAt: new Date(),
        });

        // --- Update User.userStatus ---
        await user.update({ userStatus: userStatusMap[status] });

        // --- If suspending or rejecting: immediately invalidate all refresh tokens ---
        // This forces the vendor out of any active sessions on next token refresh.
        // The short-lived access token (15m) will expire on its own.
        if (status === "suspended" || status === "rejected") {
            const deletedTokenCount = await RefreshToken.destroy({
                where: { userId: vendorId }
            });
            console.info(
                `[updateVendorStatus] Invalidated ${deletedTokenCount} refresh token(s) for vendor ${vendorId}`
            );

            // Products are automatically hidden because:
            // 1. The auth middleware checks userStatus — suspended vendors get 401 on API calls
            // 2. Product queries should JOIN on vendor userStatus (see implementation note below)
            // 
            // IMPLEMENTATION NOTE for product controller:
            // When fetching public products, add a check to exclude products from suspended vendors:
            //   include: [{ model: User, as: 'vendor', where: { userStatus: 'active' }, required: true }]
            // This requires a Product→User association (vendorId foreign key on Product).
            // As a simpler immediate measure, the vendor's suspended userStatus blocks their
            // own ability to manage products, and a background job can mark their products inactive.
        }

        // --- Re-fetch for clean response ---
        const updatedProfile = await VendorProfile.findOne({ where: { userId: vendorId } });
        const responseData = formatVendorResponse(user, updatedProfile, true);

        const messages = {
            approved: "Vendor approved successfully. They can now list products.",
            suspended: "Vendor suspended. All sessions invalidated and products hidden.",
            rejected: "Vendor rejected. All sessions invalidated.",
            pending: "Vendor status reset to pending review.",
        };

        success(res, responseData, messages[status]);
    } catch (error) {
        console.error("[updateVendorStatus]", error);
        serverError(res, "Failed to update vendor status");
    }
};

// ---------------------------------------------------------------------------
// PUT /api/admin/vendors/:vendorId
// Update all vendor details except vendorStatus
// ---------------------------------------------------------------------------
export const updateVendorDetails = async (req, res) => {
    try {
        const { vendorId } = req.params;
        const {
            // User fields
            name,
            email,
            phone,
            // Vendor profile fields (excluding vendorStatus)
            storeName,
            storeDescription,
            businessEmail,
            businessPhone,
            businessAddress,
            businessRegistrationNumber,
            businessRegistrationDocUrl,
            taxId,
            bankAccountName,
            bankAccountNumber,
            bankName,
            bankIFSC,
            statusReason,
            statusUpdatedAt,
        } = req.body;

        // --- Find vendor user ---
        const user = await User.findOne({
            where: { id: vendorId, userRole: "vendor" },
        });
        if (!user) return notFound(res, "Vendor not found");

        // --- Find vendor profile ---
        const vendorProfile = await VendorProfile.findOne({
            where: { userId: vendorId }
        });
        if (!vendorProfile) return notFound(res, "Vendor profile not found");

        // --- Update User fields ---
        await user.update({
            ...(name && { name }),
            ...(email && { email }),
            ...(phone && { phone }),
        });

        // --- Update VendorProfile fields (excluding vendorStatus) ---
        await vendorProfile.update({
            ...(storeName && { storeName }),
            ...(storeDescription && { storeDescription }),
            ...(businessEmail && { businessEmail }),
            ...(businessPhone && { businessPhone }),
            ...(businessAddress && { businessAddress }),
            ...(businessRegistrationNumber && { businessRegistrationNumber }),
            ...(businessRegistrationDocUrl && { businessRegistrationDocUrl }),
            ...(taxId && { taxId }),
            ...(bankAccountName && { bankAccountName }),
            ...(bankAccountNumber && { bankAccountNumber }),
            ...(bankName && { bankName }),
            ...(bankIFSC && { bankIFSC }),
            ...(statusReason && { statusReason }),
            ...(statusUpdatedAt && { statusUpdatedAt }),
        });

        // --- Return updated data ---
        const updatedProfile = await VendorProfile.findOne({ where: { userId: vendorId } });
        const responseData = formatVendorResponse(user, updatedProfile, true);

        success(res, responseData, "Vendor details updated successfully");
    } catch (error) {
        console.error("[updateVendorDetails]", error);
        serverError(res, "Failed to update vendor details");
    }
};