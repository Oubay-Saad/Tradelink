const mongoose = require("mongoose")
const Schema = mongoose.Schema

const postSchema = new Schema({
    title: {
        type: String,
        maxlength: 50,
        required: true
    },

    description: {
        type: String,
        maxlength: 200
    },

    images: {
        type: [String],
        validate: {
            validator: (arr) => arr.length <= 5,
            message: "You can't upload more than 5 pictures"
        },
        required: true,
    },

    postedBy: {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true
    }
    
},{ timestamps: true })

const Post = mongoose.model("Post", postSchema)

module.exports = Post