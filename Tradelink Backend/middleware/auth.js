const jwt = require("jsonwebtoken")

const auth = (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(" ")[1]

        if (!token) {
            return res.status(401).json({ error: "No token provided" })
        }

        const decoded = jwt.verify(token, "SECRET_KEY")
        req.user = decoded
        next()

    } catch (err) {
        res.status(401).json("Invalid or expired token")
    }
}

const isCustomer = (req, res, next) => {
    if (req.user.role !== "customer") {
        return res.status(403).json({ error: "Only customers can do this action!" })
    }
    next()
}

const isTradesman = (req, res, next) => {
    if (req.user.role !== "tradesman") {
        console.log(`isTradesman failed: user role is '${req.user.role}'`)
        return res.status(403).json({ error: "Only tradesman can do this action!" })
    }
    next()
}

const isAdmin = (req, res, next) => {
    if (req.user.role !== "admin") {
        return res.status(403).json({ error: "Admin access required" })
    }
    next()
}

module.exports = { auth, isCustomer, isTradesman, isAdmin }