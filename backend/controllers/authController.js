import User from "../models/userModel.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { created, badRequest, notFound, serverError } from "../utils/responseMessages.js";

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
        const {email, password} = req.body;

        //Check if user alreday exists
        const user = await User.findOne({ where: {email} });
        if(!user){
            return notFound(res, "User not found");
        }

        //Compare password
        const isMatch = await bcrypt.compare(password, user.password);
        if(!isMatch){
            return badRequest(res, "Invalid credentials");
        }

        //Generate JWT token
        const token = jwt.sign(
            {id: user.id, email: user.email, userRole: user.userRole}, 
            process.env.JWT_SECRET,
            {expiresIn: "1h"},

        );
    res.status(200).json({success: true, data: {token, user:{
        id: user.id, 
        email: user.email,
        name: user.name,
        phone: user.phone,
        userRole: user.userRole
    }}, message: `Login successful`});

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
            {expiresIn: "1h"},

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