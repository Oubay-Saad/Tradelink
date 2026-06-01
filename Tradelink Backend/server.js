require('dotenv').config()
const express = require("express")
const mongoose = require("mongoose")
const cors = require("cors")

const authRoutes = require("./routes/authRoutes")
const userRoutes = require("./routes/userRoutes")
const serviceRoutes = require("./routes/serviceRoutes")
const requestRoutes = require("./routes/requestRoutes")
const postRoutes = require("./routes/postRoutes")
const reviewRoutes = require("./routes/reviewRoutes")
const adminRoutes = require("./routes/adminRoutes")


const app = express()
const PORT = process.env.PORT

app.use(express.json())
app.use(cors());

mongoose.connect(process.env.MONGODB_URI)
    .then(() => {
        console.log("Connected to data base")
    }).catch((err) => {
        console.log("Failed to connect to data base: ", err)
    })

// Get job types, no auth needed, public
app.get("/job-types", (req, res) => {
    const JOB_TYPES = require("./config/jobTypes")
    res.status(200).json({ jobTypes: JOB_TYPES })
})

// Get wilayas list
const WILAYAS = [
    { code: "01", name: "Adrar" }, { code: "02", name: "Chlef" },
    { code: "03", name: "Laghouat" }, { code: "04", name: "Oum El Bouaghi" },
    { code: "05", name: "Batna" }, { code: "06", name: "Bejaia" },
    { code: "07", name: "Biskra" }, { code: "08", name: "Bechar" },
    { code: "09", name: "Blida" }, { code: "10", name: "Bouira" },
    { code: "11", name: "Tamanrasset" }, { code: "12", name: "Tebessa" },
    { code: "13", name: "Tlemcen" }, { code: "14", name: "Tiaret" },
    { code: "15", name: "Tizi Ouzou" }, { code: "16", name: "Algiers" },
    { code: "17", name: "Djelfa" }, { code: "18", name: "Jijel" },
    { code: "19", name: "Setif" }, { code: "20", name: "Saida" },
    { code: "21", name: "Skikda" }, { code: "22", name: "Sidi Bel Abbes" },
    { code: "23", name: "Annaba" }, { code: "24", name: "Guelma" },
    { code: "25", name: "Constantine" }, { code: "26", name: "Medea" },
    { code: "27", name: "Mostaganem" }, { code: "28", name: "M'Sila" },
    { code: "29", name: "Mascara" }, { code: "30", name: "Ouargla" },
    { code: "31", name: "Oran" }, { code: "32", name: "El Bayadh" },
    { code: "33", name: "Illizi" }, { code: "34", name: "Bordj Bou Arreridj" },
    { code: "35", name: "Boumerdes" }, { code: "36", name: "El Tarf" },
    { code: "37", name: "Tindouf" }, { code: "38", name: "Tissemsilt" },
    { code: "39", name: "El Oued" }, { code: "40", name: "Khenchela" },
    { code: "41", name: "Souk Ahras" }, { code: "42", name: "Tipaza" },
    { code: "43", name: "Mila" }, { code: "44", name: "Ain Defla" },
    { code: "45", name: "Naama" }, { code: "46", name: "Ain Temouchent" },
    { code: "47", name: "Ghardaia" }, { code: "48", name: "Relizane" },
    { code: "49", name: "Timimoun" }, { code: "50", name: "Bordj Badji Mokhtar" },
    { code: "51", name: "Ouled Djellal" }, { code: "52", name: "Beni Abbes" },
    { code: "53", name: "In Salah" }, { code: "54", name: "In Guezzam" },
    { code: "55", name: "Touggourt" }, { code: "56", name: "Djanet" },
    { code: "57", name: "El M'Ghair" }, { code: "58", name: "El Meniaa" },
]
app.get("/wilayas", (req, res) => {
    res.status(200).json({ wilayas: WILAYAS })
})

// Admin only for testing

const path = require('path');

app.get('/admin-panel', (req, res) => {
    res.sendFile(path.join(__dirname, 'admin.html'));
});

app.use(authRoutes)
app.use(userRoutes)
app.use(serviceRoutes)
app.use(requestRoutes)
app.use(postRoutes)
app.use(reviewRoutes)
app.use(adminRoutes)


app.listen(PORT, () => console.log(`The server is runing on port ${PORT}`))