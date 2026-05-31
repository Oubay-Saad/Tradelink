const express = require("express")
const sharp = require("sharp")
const User = require("../models/User")
const Post = require("../models/Post")
const Service = require("../models/Service")
const Review = require("../models/Review")
const { auth } = require("../middleware/auth")
const upload = require("../config/upload")


const router = express.Router()


// Search and filter tradesmen
router.get("/users/search", auth, async (req, res) => {
    try {
        const { name, location, jobType, experience } = req.query

        const filter = {}

        if (name) {
            filter.name = { $regex: name, $options: "i" }
        }

        if (location) {
            filter.location = { $regex: location, $options: "i" }
        }

        if (jobType) {
            filter["tradesmanInfo.jobTypes"] = jobType
        }

        if (experience) {
            filter["tradesmanInfo.experience"] = { $gte: parseInt(experience) }
        }

        const users = await User.find(filter).select("-password -tradesmanInfo.gallery")

        res.status(200).json({ results: users })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

// Get top tradesmen ranked by average review rating
router.get("/users/top-tradesmen", auth, async (req, res) => {
    try {
        const { jobType, limit } = req.query
        const limitNum = parseInt(limit) || 5

        const filter = { role: "tradesman" }
        if (jobType) {
            filter["tradesmanInfo.jobTypes"] = jobType
        }

        const tradesmen = await User.find(filter).select("-password").lean()

        const results = await Promise.all(tradesmen.map(async (t) => {
            const reviews = await Review.find({ tradesman: t._id })
            let avgRating = 0
            if (reviews.length > 0) {
                const total = reviews.reduce((sum, r) => sum + r.rating, 0)
                avgRating = total / reviews.length
            }
            return { ...t, avgRating, totalReviews: reviews.length }
        }))

        results.sort((a, b) => b.avgRating - a.avgRating || b.totalReviews - a.totalReviews)

        res.status(200).json({ topTradesmen: results.slice(0, limitNum) })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

// Get nearby tradesmen based on current users location
router.get("/users/nearby", auth, async (req, res) => {
    try {
        const { limit } = req.query
        const limitNum = parseInt(limit) || 10

        const currentUser = await User.findById(req.user.id)
        if (!currentUser || !currentUser.location) {
            return res.status(200).json({ nearbyTradesmen: [] })
        }

        const tradesmen = await User.find({
            role: "tradesman",
            location: { $regex: currentUser.location, $options: "i" },
            _id: { $ne: req.user.id }
        }).select("-password").limit(limitNum).lean()

        const results = await Promise.all(tradesmen.map(async (t) => {
            const reviews = await Review.find({ tradesman: t._id })
            let avgRating = 0
            if (reviews.length > 0) {
                const total = reviews.reduce((sum, r) => sum + r.rating, 0)
                avgRating = total / reviews.length
            }
            return { ...t, avgRating, totalReviews: reviews.length }
        }))

        res.status(200).json({ nearbyTradesmen: results })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

// Update current user profile
router.patch("/users/me", auth, upload.single("profilePic"), async (req, res) => {
    try {
        const { bio, location, skills, experience } = req.body
        const updatedData = {}
        if (bio !== undefined) updatedData.bio = bio
        if (location !== undefined) updatedData.location = location

        // Handle profile pic if provided
        if (req.file) {
            const compressedBuffer = await sharp(req.file.buffer)
                .resize(300, 300)
                .jpeg({ quality: 60 })
                .toBuffer()
            updatedData.profilePic = `data:image/jpeg;base64,${compressedBuffer.toString("base64")}`
        }

        // Handle tradesman-specific fields
        if (req.user.role === "tradesman") {
            if (skills !== undefined) updatedData["tradesmanInfo.skills"] = skills
            if (experience !== undefined) updatedData["tradesmanInfo.experience"] = experience
        }

        const updated = await User.findByIdAndUpdate(
            req.user.id,
            updatedData,
            { returnDocument: "after" }
        ).select("-password")

        res.status(200).json({ message: "Updated successfully!", user: updated })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

// Get user by ID (must be last because :id matches anything)
router.get("/users/:id", auth, async (req, res) => {
    try {
        const user = await User.findById(req.params.id).select("-password")

        if(!user){
            return res.status(404).json({ error: "User not found" })
        }

        const response = { user }

        if(user.role === "tradesman"){
            response.posts = await Post.find({ postedBy: req.params.id })
        }

        if(user.role === "customer"){
            response.services = await Service.find({createdBy: req.params.id})
        }

        res.status(200).json(response)

    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})


module.exports = router