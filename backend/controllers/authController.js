import User from "../models/userModel.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { created, badRequest, notFound, serverError } from "../utils/responseMessages.js";

export const userSignup = async (req, res) => {
    try {
        const {email, password, confirmPassword} = req.body;

        if (!email || !password || !confirmPassword) {
            return badRequest(res, "Email, password and confirmPassword are required");
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
            email,
            password: hashPassword
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
            {id: user.id, email: user.email}, 
            process.env.JWT_SECRET,
            {expiresIn: "1h"},

        );
    res.status(200).json({success: true, data: {token, user:{
        id: user.id, 
        email: user.email,
    }}, message: `Login successful`});

    } catch (error) {
        serverError(res, "Server error");
    }
}