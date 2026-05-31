const mongoose = require("mongoose")
const JOB_TYPES = require("../config/jobTypes")
const JOB_TYPE_VALUES = JOB_TYPES.map(j => j.value)

const Schema = mongoose.Schema

const userSchema = new Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },

    phone: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        minLength: 10,
        maxLength: 10
    },

    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true        
    },

    role: {
        type: String,
        enum: ["customer", "tradesman", "admin"],
        default: "customer",
        required: true
    },

    password: {
        type: String,
        required: true,
    },

    // Other information

    profilePic: {
        type: String,
        default: null
    },

    bio: {
        type: String,
        maxlength: 500,
        default: null
    },

    location: {
        type: String,
        default: null
    },

    tradesmanInfo: {
        jobTypes: {
            type: [String],
            enum: JOB_TYPE_VALUES,
            default: []
        },
        skills: {
            type: [String], 
            default: []
        },
        experience: {
            type: Number, 
            default: null
        },
        gallery: {
            type: [Schema.Types.ObjectId],
            ref: "Post",
            default: []
        }
    }
},{ timestamps: true })

const User = mongoose.model("User", userSchema)

module.exports = User