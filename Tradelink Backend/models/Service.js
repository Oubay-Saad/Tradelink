const mongoose = require("mongoose")
const JOB_TYPES = require("../config/jobTypes")
const JOB_TYPE_VALUES = JOB_TYPES.map(j => j.value)

const Schema = mongoose.Schema


const serviceSchema = new Schema({
    title: {
        type: String,
        required: true,
        maxlength: 100,
    },
    jobTypes: {
        type: [String],
        enum: JOB_TYPE_VALUES,
        required: true,
    },
    description: {
        type: String,
        required: true,
        maxlength: 800,
    },
    budget: {
        type: Number,
        required: true,
    },
    images: {
        type: [String],
        default: [],
        validate: {
            validator: (arr) => arr.length <= 3,
            message: "You can't upload more than 3 images"
        }
    },
    createdBy: {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true
    }
}, { timestamps: true })


const Service = mongoose.model("Service", serviceSchema)

module.exports = Service