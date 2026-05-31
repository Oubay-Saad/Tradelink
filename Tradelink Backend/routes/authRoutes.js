const express = require("express")
const bcrypt = require("bcrypt")
const jwt = require("jsonwebtoken")
const User = require("../models/User")

const router = express.Router()

router.post("/auth/register", async (req,res) => {
    try{
        const { name, phone, email, role, password } = req.body
        
        const hashedPass = await bcrypt.hash(password, 10)

        const newUser = new User()

        newUser.name = name
        newUser.phone = phone
        newUser.email = email
        newUser.role = role
        newUser.password = hashedPass
        
        await newUser.save()

        res.status(201).json({
            message: "Account created",
            user: newUser
        })
    } catch (err) {
        console.error(err)

        if (err.code === 11000) {
            return res.status(400).json({error: "User already exists"})
        }

        res.status(500).json({error: "Server error"})
    }
})

router.post("/auth/login", async (req,res) => {
    try{
        const { phone, identifier, password } = req.body
        const loginPhone = phone || identifier

        const user = await User.findOne({ phone: loginPhone })
        if(!user){
            return res.status(400).json({error: "User not found"})
        }

        const isMatch = await bcrypt.compare(password, user.password)
        if(!isMatch){
            return res.status(400).json({error: "Invalid password"})
        }

        const token = jwt.sign({id: user._id, role: user.role}, "SECRET_KEY", {expiresIn: "7d"})

        res.json({message: "Login successful", token , user})
    }catch (err){
        res.status(500).json({error: "Server error"})
    }
})

// Get current user from token
const { auth } = require("../middleware/auth")
router.get("/auth/me", auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select("-password")
        if (!user) return res.status(404).json({ error: "User not found" })
        res.json({ user })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

module.exports = router