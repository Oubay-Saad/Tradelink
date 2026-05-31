const express = require("express")

const User = require("../models/User")
const Post = require("../models/Post")
const Service = require("../models/Service")
const Request = require("../models/Request")
const Review = require("../models/Review")

const { auth, isAdmin } = require("../middleware/auth")

const router = express.Router()

// protect everything
router.use(auth)
router.use(isAdmin)


// Users

// Get all users
router.get("/admin/users", async (req, res) => {
    const users = await User.find().select("-password")
    res.json(users)
})

// Get one user
router.get("/admin/users/:id", async (req, res) => {
    const user = await User.findById(req.params.id).select("-password")
    if (!user) return res.status(404).json({ error: "User not found" })
    res.json(user)
})

// Create user
router.post("/admin/users", async (req, res) => {
    const user = await User.create(req.body)
    res.json(user)
})

// Update user
router.patch("/admin/users/:id", async (req, res) => {
    const user = await User.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
    ).select("-password")

    if (!user) return res.status(404).json({ error: "User not found" })

    res.json(user)
})

// Delete user
router.delete("/admin/users/:id", async (req, res) => {
    await User.findByIdAndDelete(req.params.id)
    res.json({ message: "User deleted" })
})


// Posts

// Get all posts
router.get("/admin/posts", async (req, res) => {
    const posts = await Post.find().populate("postedBy", "name email")
    res.json(posts)
})

// Get one post
router.get("/admin/posts/:id", async (req, res) => {
    const post = await Post.findById(req.params.id)
    if (!post) return res.status(404).json({ error: "Post not found" })
    res.json(post)
})

// Create post
router.post("/admin/posts", async (req, res) => {
    const post = await Post.create(req.body)
    res.json(post)
})

// Update post
router.patch("/admin/posts/:id", async (req, res) => {
    const post = await Post.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
    )

    if (!post) return res.status(404).json({ error: "Post not found" })

    res.json(post)
})

// Delete post
router.delete("/admin/posts/:id", async (req, res) => {
    await Post.findByIdAndDelete(req.params.id)
    res.json({ message: "Post deleted" })
})


// Services

// Get all services
router.get("/admin/services", async (req, res) => {
    const services = await Service.find().populate("createdBy", "name email")
    res.json(services)
})

// Get one service
router.get("/admin/services/:id", async (req, res) => {
    const service = await Service.findById(req.params.id)
    if (!service) return res.status(404).json({ error: "Service not found" })
    res.json(service)
})

// Create service
router.post("/admin/services", async (req, res) => {
    const service = await Service.create(req.body)
    res.json(service)
})

// Update service
router.patch("/admin/services/:id", async (req, res) => {
    const service = await Service.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
    )

    if (!service) return res.status(404).json({ error: "Service not found" })

    res.json(service)
})

// Delete service
router.delete("/admin/services/:id", async (req, res) => {
    await Service.findByIdAndDelete(req.params.id)
    res.json({ message: "Service deleted" })
})


// Requests

// Get all requests
router.get("/admin/requests", async (req, res) => {
    const requests = await Request.find()
        .populate("service")
        .populate("requestedBy", "name email")

    res.json(requests)
})

// Update status
router.patch("/admin/requests/:id/status", async (req, res) => {
    const { status } = req.body

    const request = await Request.findByIdAndUpdate(
        req.params.id,
        { status },
        { new: true }
    )

    if (!request) return res.status(404).json({ error: "Request not found" })

    res.json(request)
})

// Delete request
router.delete("/admin/requests/:id", async (req, res) => {
    await Request.findByIdAndDelete(req.params.id)
    res.json({ message: "Request deleted" })
})


// Reviews

// Get all reviews
router.get("/admin/reviews", async (req, res) => {
    const reviews = await Review.find()
        .populate("tradesman", "name")
        .populate("customer", "name")

    res.json(reviews)
})

// Delete review
router.delete("/admin/reviews/:id", async (req, res) => {
    await Review.findByIdAndDelete(req.params.id)
    res.json({ message: "Review deleted" })
})


// Global override

router.delete("/admin/:model/:id", async (req, res) => {
    const { model, id } = req.params

    const models = {
        user: User,
        post: Post,
        service: Service,
        request: Request,
        review: Review
    }

    const Model = models[model]

    if (!Model) return res.status(400).json({ error: "Invalid model" })

    await Model.findByIdAndDelete(id)

    res.json({ message: `${model} deleted` })
})



module.exports = router