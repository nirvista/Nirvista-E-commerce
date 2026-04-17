import sequelize from "../config/db.js";
import User from "../models/userModel.js";
import crypto from "crypto";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { created, badRequest, notFound, serverError, unauthorized } from "../utils/responseMessages.js";
import UserAddress from "../models/userAddresses.js";
import RefreshToken from "../models/refreshTokenModel.js";

// Helper: Generate Access Token (JWT)
function generateAccessToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, userRole: user.userRole },
    process.env.JWT_SECRET,
    { expiresIn: "15m" }
  );
}

// Helper: Generate Refresh Token (cryptographically secure random string)
function generateRefreshToken() {
  return crypto.randomBytes(64).toString("hex");
}

// Helper: Hash Refresh Token
async function hashToken(token) {
  return await bcrypt.hash(token, 12);
}

// Helper: Set Refresh Token Cookie (for web)
function setRefreshTokenCookie(res, token, expires) {
  res.cookie("refreshToken", token, {
    httpOnly: true,
    secure: true,
    sameSite: "strict",
    expires,
  });
}

// Helper: Clear Refresh Token Cookie (for web)
function clearRefreshTokenCookie(res) {
  res.clearCookie("refreshToken", {
    httpOnly: true,
    secure: true,
    sameSite: "strict",
  });
}


export const userSignup = async (req, res) => {
    try {
        const {name, email, phone, password, confirmPassword, userRole} = req.body;

        if (!name || !email || !phone || !password || !confirmPassword || !userRole) {
            return badRequest(res, "All fields are required");
        }

        if (password !== confirmPassword) {
            return badRequest(res, "Passwords do not match");
        }

        //Check if user alreday exists
        const userExists = await User.findOne({ where: {email} });
        if(userExists){
            return badRequest(res, "User already exists");
        } 

        //hash password
        const hashPassword = await bcrypt.hash(password, 10);

        //Create new user
        await User.create({
            name,
            email,
            phone,
            password: hashPassword,
            userRole
        });

        created(res, null, "User created successfully");

    } catch (error) {
        serverError(res, "Server error");
    }
};

export const userLogin = async (req, res) => {
    try {
    const { email, password } = req.body;
    const clientType = req.headers["x-client-type"];
    const deviceInfo = req.headers["user-agent"] || "Unknown";

    if (!email || !password || !clientType || !["web", "mobile"].includes(clientType)) {
      return badRequest(res, "Missing credentials or invalid client type");
    }

    const user = await User.findOne({ where: { email } });
    if (!user) return notFound(res, "User not found");

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return unauthorized(res, "Invalid credentials");

    // Generate tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken();
    const tokenHash = await hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    // Store refresh token in DB
    await RefreshToken.create({
      userId: user.id,
      token_hash: tokenHash,
      client_type: clientType,
      device_info: deviceInfo,
      expires_at: expiresAt,
    });

    // Prepare response
    const responseData = {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        userRole: user.userRole,
      },
    };

    // Conditional delivery of refresh token
    if (clientType === "web") {
      // Web: Set HttpOnly cookie
      setRefreshTokenCookie(res, refreshToken, expiresAt);
    } else {
      // Mobile: Return in JSON body
      responseData.refreshToken = refreshToken;
    }

    return res.status(200).json({ success: true, data: responseData, message: "Login successful" });
  } catch (error) {
    serverError(res, "Server error");
  }
}

export const refresh = async (req, res) => {
  try {
    const clientType = req.headers["x-client-type"];
    let refreshToken;

    // Extract refresh token based on client type
    if (clientType === "web") {
      refreshToken = req.cookies?.refreshToken;
    } else if (clientType === "mobile") {
      refreshToken = req.body.refreshToken;
    } else {
      return badRequest(res, "Invalid client type");
    }

    if (!refreshToken) return unauthorized(res, "No refresh token provided");

    // Find matching token in DB
    const tokens = await RefreshToken.findAll({ where: { client_type: clientType } });
    let tokenRecord = null;
    for (const t of tokens) {
      if (await bcrypt.compare(refreshToken, t.token_hash)) {
        tokenRecord = t;
        break;
      }
    }
    if (!tokenRecord) return unauthorized(res, "Invalid refresh token");

    if (new Date(tokenRecord.expires_at) < new Date()) {
      await tokenRecord.destroy();
      return unauthorized(res, "Refresh token expired");
    }

    // Get user
    const user = await User.findByPk(tokenRecord.userId);
    if (!user) return unauthorized(res, "User not found");

    // Rotate refresh token
    const newRefreshToken = generateRefreshToken();
    const newTokenHash = await hashToken(newRefreshToken);
    const newExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    // Update DB
    tokenRecord.token_hash = newTokenHash;
    tokenRecord.expires_at = newExpiresAt;
    await tokenRecord.save();

    // Generate new access token
    const accessToken = generateAccessToken(user);

    // Prepare response
    const responseData = { accessToken };

    // Conditional delivery of new refresh token
    if (clientType === "web") {
      setRefreshTokenCookie(res, newRefreshToken, newExpiresAt);
    } else {
      responseData.refreshToken = newRefreshToken;
    }

    return res.status(200).json({ success: true, data: responseData, message: "Token refreshed" });
  } catch (error) {
    serverError(res, "Server error");
  }
}

export const logout = async (req, res) => {
  try {
    const clientType = req.headers["x-client-type"];
    let refreshToken;

    if (clientType === "web") {
      refreshToken = req.cookies?.refreshToken;
    } else if (clientType === "mobile") {
      refreshToken = req.body.refreshToken;
    } else {
      return badRequest(res, "Invalid client type");
    }

    if (!refreshToken) return unauthorized(res, "No refresh token provided");

    // Find and delete the token
    const tokens = await RefreshToken.findAll({ where: { client_type: clientType } });
    let tokenRecord = null;
    for (const t of tokens) {
      if (await bcrypt.compare(refreshToken, t.token_hash)) {
        tokenRecord = t;
        break;
      }
    }
    if (tokenRecord) await tokenRecord.destroy();

    // For web, clear the cookie
    if (clientType === "web") {
      clearRefreshTokenCookie(res);
    }

    return res.status(200).json({ success: true, message: "Logged out successfully" });
  } catch (error) {
    serverError(res, "Server error");
  }
}

export const logoutAll = async (req, res) => {
  try {
    // You should authenticate the user and get userId from req.user (set by auth middleware)
    const userId = req.user?.id;
    const clientType = req.headers["x-client-type"];

    if (!userId) return unauthorized(res, "Unauthorized");

    // Delete all refresh tokens for this user
    await RefreshToken.destroy({ where: { userId } });

    // For web, clear the cookie
    if (clientType === "web") {
      clearRefreshTokenCookie(res);
    }

    return res.status(200).json({ success: true, message: "Logged out from all devices" });
  } catch (error) {
    serverError(res, "Server error");
  }
}


export const adminSignUp = async (req, res) => {
    try {
        const {name, email, phone, password, confirmPassword} = req.body;

        if (!name || !email || !phone || !password || !confirmPassword) {
            return badRequest(res, "All fields are required");
        }

        //Check if admin already exists
        const adminExists = await User.findOne({ where: {email} });
        if(adminExists){
            return badRequest(res, "Admin already exists");
        } 

        //hash password
        const hashPassword = await bcrypt.hash(password, 10);

        //Create new admin
        await User.create({
            name,
            email,
            phone,
            password: hashPassword,
            userRole: "admin"
        });

        created(res, null, "Admin created successfully");


    } catch (error) {
        serverError(res, "Server error");
    }
}

export const adminLogin = async (req, res) => {
    try {
        const {email, password} = req.body;

        //Check if admin alreday exists
        const admin = await User.findOne({ where: {email} });
        if(!admin){
            return notFound(res, "Admin not found");
        }

        //Compare password
        const isMatch = await bcrypt.compare(password, admin.password);
        if(!isMatch){
            return badRequest(res, "Invalid credentials");
        }

        //Generate JWT token
        const token = jwt.sign(
            {id: admin.id, email: admin.email, userRole: admin.userRole}, 
            process.env.JWT_SECRET,
            {expiresIn: "10h"},

        );
    res.status(200).json({success: true, data: {token, user:{
        id: admin.id, 
        email: admin.email,
        name: admin.name,
        phone: admin.phone,
        userRole: admin.userRole
    }}, message: `Login successful`});
    } catch (error) {
        serverError(res, "Server error");
    }
}

export const getCurrentUserProfile = async (req, res) => {
    try {
        // Get token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];

        // Verify token
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET);
        } catch (err) {
            return res.status(401).json({ success: false, message: "Invalid token" });
        }

        // Fetch user by ID
        const user = await User.findByPk(decoded.id, {
            attributes: { exclude: ['password'] },
            include: [
                {
                    model: UserAddress,
                    as: 'UserAddresses'
                }
            ]
        });
        if (!user) {
            return notFound(res, "User not found");
        }

        res.status(200).json({ success: true, data: user, message: "User profile fetched successfully" });
    } catch (error) {
        serverError(res, "Server error");
    }
};

export const updateUserProfile = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        // Get token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }
        const token = authHeader.split(" ")[1];
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET);
        } catch (err) {
            return res.status(401).json({ success: false, message: "Invalid token" });
        }

        const user = await User.findByPk(decoded.id, { transaction: t });
        if (!user) {
            await t.rollback();
            return notFound(res, "User not found");
        }

        // Update basic details
        const { name, email, phone, currentPassword, newPassword } = req.body;
        if (name) user.name = name;
        if (email) user.email = email;
        if (phone) user.phone = phone;

        // Change password logic
        if (currentPassword && newPassword) {
            const isMatch = await bcrypt.compare(currentPassword, user.password);
            if (!isMatch) {
                await t.rollback();
                return badRequest(res, "Current password is incorrect");
            }
            user.password = await bcrypt.hash(newPassword, 10);
        }

        await user.save({ transaction: t });
        await t.commit();

        // Fetch updated user with addresses
        const updatedUser = await User.findByPk(user.id, {
            attributes: { exclude: ['password'] },
        });

        res.status(200).json({ success: true, data: updatedUser, message: "Profile updated successfully" });
    } catch (error) {
        await t.rollback();
        serverError(res, "Server error");
    }
};

export const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        // Generic response to prevent email enumeration
        const genericMessage = "If an account with that email exists, a password reset link has been sent.";

        const user = await User.findOne({ where: { email } });
        
        // If user doesn't exist, exit quietly returning success true
        if (!user) {
            return res.status(200).json({ success: true, message: genericMessage });
        }

        // 1. Generate a secure 32-byte hex token
        const resetToken = crypto.randomBytes(32).toString("hex");

        // 2. Hash the token for database storage
        const resetPasswordToken = crypto.createHash("sha256").update(resetToken).digest("hex");
        const resetPasswordExpire = Date.now() + 15 * 60 * 1000; // 15 minutes

        // 3. Save hashed token and expiry to user record
        // NOTE: Ensure your User model has 'resetPasswordToken' and 'resetPasswordExpire' columns defined.
        user.resetPasswordToken = resetPasswordToken;
        user.resetPasswordExpire = new Date(resetPasswordExpire);
        await user.save();

        // 4. Send email with PLAIN token
        const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
        const resetUrl = `${frontendUrl}/reset-password/${resetToken}`;
        
        const message = `You are receiving this email because you (or someone else) requested a password reset. \n\nPlease click the link below to reset your password. This link will expire in 15 minutes: \n\n ${resetUrl}`;

        const transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT,
            auth: {
                user: process.env.SMTP_EMAIL,
                pass: process.env.SMTP_PASSWORD,
            }
        });

        await transporter.sendMail({
            from: `${process.env.FROM_NAME} <${process.env.FROM_EMAIL}>`,
            to: user.email,
            subject: "Password Reset Request",
            text: message,
        });

        return res.status(200).json({ success: true, message: genericMessage });

    } catch (error) {
        console.error("Forgot Password Error:", error);
        
        // If email fails, nullify the token in DB so it can't be exploited
        if (req.body.email) {
            const user = await User.findOne({ where: { email: req.body.email } });
            if (user) {
                user.resetPasswordToken = null;
                user.resetPasswordExpire = null;
                await user.save();
            }
        }
        return serverError(res, "Email could not be sent. Please try again later.");
    }
};

// ==========================================
// NEW: Reset Password Controller
// ==========================================
export const resetPassword = async (req, res) => {
    try {
        const { password } = req.body;
        const { token } = req.params;

        // 1. Hash the incoming URL token to compare with the database
        const resetPasswordToken = crypto.createHash("sha256").update(token).digest("hex");

        // 2. Find user by token AND ensure token hasn't expired
        const user = await User.findOne({
            where: {
                resetPasswordToken,
                resetPasswordExpire: { [Op.gt]: new Date() } // Expiry must be Greater Than Now
            }
        });

        if (!user) {
            return badRequest(res, "Invalid or expired reset token");
        }

        // 3. Hash the new password
        user.password = await bcrypt.hash(password, 10);
        
        // 4. One-Time Use: Clear the token and expiry fields
        user.resetPasswordToken = null;
        user.resetPasswordExpire = null;
        
        await user.save();

        return success(res, null, "Password reset successful. You can now log in.");
    } catch (error) {
        console.error("Reset Password Error:", error);
        return serverError(res, "Failed to reset password.");
    }
};