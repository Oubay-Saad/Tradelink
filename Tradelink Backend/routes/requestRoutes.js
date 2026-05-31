const express = require("express")
const Service = require("../models/Service")
const Request = require("../models/Request")
const { auth, isCustomer, isTradesman } = require("../middleware/auth")

const router = express.Router()


router.post("/services/:serviceId/requests", auth, isTradesman, async (req, res) => {
    try {
        const service = await Service.findById(req.params.serviceId)
        if (!service) {
            return res.status(404).json({ error: "Service not found" })
        }

        const { estimatedPrice, message } = req.body

        const newRequest = new Request()

        newRequest.service = req.params.serviceId
        newRequest.estimatedPrice = estimatedPrice
        newRequest.message = message
        newRequest.requestedBy = req.user.id

        await newRequest.save()

        res.status(201).json({ message: "Request sent successfuly!", request: newRequest })
    } catch (err) {
        if (err.name === "ValidationError") {
            return res.status(400).json({ error: err.message })
        }

        res.status(500).json({ error: "Server error" })
    }
})

router.get("/services/:serviceId/requests", auth, async (req, res) => {
    try {
        const requests = await Request.find({ service: req.params.serviceId })
        res.status(200).json({ requests: requests })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

router.patch("/requests/:requestId/status", auth, isCustomer, async (req, res) => {
    try {
        const { status } = req.body

        const request = await Request.findByIdAndUpdate(
            req.params.requestId,
            { status },
            { new: true }
        )

        if (!request) {
            return res.status(404).json({ error: "Request not found" })
        }

        res.status(200).json({ message: "Request status updated!", request })

    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})


router.get("/requests/me", auth, async (req, res) => {
    try {
        const requests = await Request.find({ requestedBy: req.user.id })
            .populate("service")
            .sort({ createdAt: -1 })
            
        res.status(200).json({ requests })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

// Edit a request
router.patch("/requests/:requestId", auth, async (req, res) => {
    try {
        const { estimatedPrice, message } = req.body
        const updateData = {}
        if (estimatedPrice !== undefined) updateData.estimatedPrice = estimatedPrice
        if (message !== undefined) updateData.message = message

        const request = await Request.findByIdAndUpdate(
            req.params.requestId,
            updateData,
            { new: true }
        )

        if (!request) {
            return res.status(404).json({ error: "Request not found" })
        }

        res.status(200).json({ message: "Request updated!", request })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

// Delete/withdraw a request
router.delete("/requests/:requestId", auth, async (req, res) => {
    try {
        const request = await Request.findById(req.params.requestId)
        if (!request) {
            return res.status(404).json({ error: "Request not found" })
        }

        if (request.requestedBy.toString() !== req.user.id) {
            return res.status(403).json({ error: "Not authorized" })
        }

        await Request.findByIdAndDelete(req.params.requestId)
        res.status(200).json({ message: "Request deleted!" })
    } catch (err) {
        res.status(500).json({ error: "Server error" })
    }
})

module.exports = router