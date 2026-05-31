const express = require("express")
const sharp = require("sharp")
const Post = require("../models/Post")
const User = require("../models/User")
const { auth, isTradesman } = require("../middleware/auth")
const upload = require("../config/upload")


const toBase64 = async (buffer) => {
    const compressed = await sharp(buffer)
        .resize(720, 720, { fit: "cover", position: "center" })
        .jpeg({ quality: 70 })
        .toBuffer()
    return `data:image/jpeg;base64,${compressed.toString("base64")}`
}

const router = express.Router()


router.post("/posts", auth, isTradesman, upload.array("images", 5), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ error: "At least one image is required" })
        }

        const { title, description } = req.body

        // Process all images in parallel
        const images = await Promise.all(req.files.map(f => toBase64(f.buffer)))

        const post = await Post.create({
            title,
            description: description || null,
            images,
            postedBy: req.user.id
        })

        await User.findByIdAndUpdate(req.user.id, {
            $push: { "tradesmanInfo.gallery": post._id }
        })

        res.status(201).json({ message: "Post created successfully!", post })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

router.get("/posts/:id", auth, async(req, res) => {
    try {
        const post = await Post.findById(req.params.id).populate("postedBy", "name profilePic")
        
        if (!post) {
            return res.status(404).json({ error: "Post not found" })
        }

        res.status(200).json({ post })

    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

// Get all posts
router.get("/posts", auth, async(req, res) => {
    try {
        const { name } = req.query
        let filter = {}

        if (name) {
            const users = await User.find({ name: { $regex: name, $options: "i" } }).select('_id')
            const userIds = users.map(u => u._id)
            filter.postedBy = { $in: userIds }
        }

        const posts = await Post.find(filter)
            .populate("postedBy", "name profilePic")
            .sort({ createdAt: -1 })

        res.status(200).json({ posts })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

router.delete("/posts/:id", auth, isTradesman, async(req, res) => {
    try {
        const post = await Post.findById(req.params.id)

        if (!post) {
            return res.status(404).json({ error: "Post not found" })
        }

        if (post.postedBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "You can only delete your own posts" })
        }

        await Post.findByIdAndDelete(req.params.id)
        res.status(200).json({ message: "Post deleted successfully!" })

    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

// DELETE /api/posts/:id/images/:index
router.delete("/posts/:id/images/:index", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id)
        if (!post) return res.status(404).json({ error: "Post not found" })

        if (post.postedBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "Not authorized" })
        }

        const index = parseInt(req.params.index)

        if (index < 0 || index >= post.images.length) {
            return res.status(400).json({ error: "Invalid image index" })
        }

        if (post.images.length === 1) {
            return res.status(400).json({ error: "A post must have at least one image" })
        }

        post.images.splice(index, 1)
        await post.save()

        res.status(200).json({ message: "Image deleted successfully!", post })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

router.patch("/posts/:id", auth, upload.array("images", 5), async (req, res) => {
    try {
        const post = await Post.findById(req.params.id)
        if (!post) return res.status(404).json({ error: "Post not found" })

        if (post.postedBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "Not authorized" })
        }

        const { title, description } = req.body
        if (title) post.title = title
        if (description) post.description = description

        // Handle images if provided
        if (req.files && req.files.length > 0) {
            if (post.images.length + req.files.length > 5) {
                return res.status(400).json({ error: `Can only add ${5 - post.images.length} more image(s)` })
            }

            const newImages = await Promise.all(req.files.map(f => toBase64(f.buffer)))
            post.images.push(...newImages)
        }

        await post.save()

        res.status(200).json({ message: "Post updated successfully!", post })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

module.exports = router