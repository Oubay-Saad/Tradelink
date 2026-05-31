const express = require("express")
const sharp = require("sharp")
const Service = require("../models/Service")
const { auth, isCustomer } = require("../middleware/auth")
const upload = require("../config/upload")

const router = express.Router()

const toBase64 = async (buffer) => {
    const compressed = await sharp(buffer)
        .resize(720, 720, { fit: "cover", position: "center" })
        .jpeg({ quality: 70 })
        .toBuffer()
    return `data:image/jpeg;base64,${compressed.toString("base64")}`
}

// Create service
router.post("/services", auth, isCustomer, upload.array("images", 3), async (req, res) => {
    try {
        const { title, description, budget } = req.body

        // Images are optional for services
        const images = req.files && req.files.length > 0
            ? await Promise.all(req.files.map(f => toBase64(f.buffer)))
            : []

        const service = await Service.create({
            title,
            description,
            budget,
            images,
            createdBy: req.user.id
        })

        res.status(201).json({ message: "Service created successfully!", service })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

// Get all services
router.get("/services", auth, async (req, res) => {
    try {
        const { jobType, minBudget, maxBudget } = req.query

        const filter = {}

        if (jobType) {
            filter.jobTypes = jobType
        }

        if (minBudget || maxBudget) {
            filter.budget = {}
            if (minBudget) filter.budget.$gte = parseInt(minBudget)
            if (maxBudget) filter.budget.$lte = parseInt(maxBudget)
        }

        const services = await Service.find(filter)
            .populate("createdBy", "name")

        res.status(200).json({ services })

    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

// Get single service
router.get("/services/:id", auth, async (req, res) => {
    try {
        const service = await Service.findById(req.params.id).populate("createdBy", "name")

        if (!service) return res.status(404).json({ error: "Service not found" })

        res.status(200).json({ service })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})



// Edit service
router.patch("/services/:id", auth, isCustomer, upload.array("images", 3), async (req, res) => {
    try {
        const service = await Service.findById(req.params.id)
        if (!service) return res.status(404).json({ error: "Service not found" })

        if (service.createdBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "Not authorized" })
        }

        const { title, description, budget } = req.body
        if (title) service.title = title
        if (description) service.description = description
        if (budget) service.budget = budget

        if (req.files && req.files.length > 0) {
            if (service.images.length + req.files.length > 3) {
                return res.status(400).json({ error: `Can only add ${3 - service.images.length} more image(s)` })
            }
            const newImages = await Promise.all(req.files.map(f => toBase64(f.buffer)))
            service.images.push(...newImages)
        }

        await service.save()

        res.status(200).json({ message: "Service updated successfully!", service })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

// Delete service
router.delete("/services/:id", auth, isCustomer, async (req, res) => {
    try {
        const service = await Service.findById(req.params.id)

        if (!service) return res.status(404).json({ error: "Service not found" })

        if (service.createdBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "You can only delete your own services" })
        }

        await Service.findByIdAndDelete(req.params.id)
        res.status(200).json({ message: "Service deleted successfully!" })

    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

// DELETE /api/services/:id/images/:index
router.delete("/services/:id/images/:index", auth, isCustomer, async (req, res) => {
    try {
        const service = await Service.findById(req.params.id)
        if (!service) return res.status(404).json({ error: "Service not found" })

        if (service.createdBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "Not authorized" })
        }

        const index = parseInt(req.params.index)

        if (index < 0 || index >= service.images.length) {
            return res.status(400).json({ error: "Invalid image index" })
        }

        service.images.splice(index, 1)
        await service.save()

        res.status(200).json({ message: "Image deleted successfully!", service })

    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})

module.exports = router