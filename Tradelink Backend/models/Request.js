const mongoose = require("mongoose")
const Schema = mongoose.Schema


const requestSchema = new Schema({
    service: {
        type: Schema.Types.ObjectId,
        ref: "Service",
        required: true
    },
    estimatedPrice: {
        type: Number,
        required: true
    },
    message: {
        type: String,
        maxlength: 100,
    },
    requestedBy: {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    status: {
        type: String,
        enum: ["Pending", "Accepted", "Rejected"],
        default: "Pending"
    }
}, { timestamps: true })



const Request = mongoose.model("Request", requestSchema)

module.exports = Request