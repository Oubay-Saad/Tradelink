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
    { value: "Adrar", en: "Adrar" }, { value: "Chlef", en: "Chlef" },
    { value: "Laghouat", en: "Laghouat" }, { value: "Oum El Bouaghi", en: "Oum El Bouaghi" },
    { value: "Batna", en: "Batna" }, { value: "Bejaia", en: "Bejaia" },
    { value: "Biskra", en: "Biskra" }, { value: "Bechar", en: "Bechar" },
    { value: "Blida", en: "Blida" }, { value: "Bouira", en: "Bouira" },
    { value: "Tamanrasset", en: "Tamanrasset" }, { value: "Tebessa", en: "Tebessa" },
    { value: "Tlemcen", en: "Tlemcen" }, { value: "Tiaret", en: "Tiaret" },
    { value: "Tizi Ouzou", en: "Tizi Ouzou" }, { value: "Algiers", en: "Algiers" },
    { value: "Djelfa", en: "Djelfa" }, { value: "Jijel", en: "Jijel" },
    { value: "Setif", en: "Setif" }, { value: "Saida", en: "Saida" },
    { value: "Skikda", en: "Skikda" }, { value: "Sidi Bel Abbes", en: "Sidi Bel Abbes" },
    { value: "Annaba", en: "Annaba" }, { value: "Guelma", en: "Guelma" },
    { value: "Constantine", en: "Constantine" }, { value: "Medea", en: "Medea" },
    { value: "Mostaganem", en: "Mostaganem" }, { value: "M'Sila", en: "M'Sila" },
    { value: "Mascara", en: "Mascara" }, { value: "Ouargla", en: "Ouargla" },
    { value: "Oran", en: "Oran" }, { value: "El Bayadh", en: "El Bayadh" },
    { value: "Illizi", en: "Illizi" }, { value: "Bordj Bou Arreridj", en: "Bordj Bou Arreridj" },
    { value: "Boumerdes", en: "Boumerdes" }, { value: "El Tarf", en: "El Tarf" },
    { value: "Tindouf", en: "Tindouf" }, { value: "Tissemsilt", en: "Tissemsilt" },
    { value: "El Oued", en: "El Oued" }, { value: "Khenchela", en: "Khenchela" },
    { value: "Souk Ahras", en: "Souk Ahras" }, { value: "Tipaza", en: "Tipaza" },
    { value: "Mila", en: "Mila" }, { value: "Ain Defla", en: "Ain Defla" },
    { value: "Naama", en: "Naama" }, { value: "Ain Temouchent", en: "Ain Temouchent" },
    { value: "Ghardaia", en: "Ghardaia" }, { value: "Relizane", en: "Relizane" },
    { value: "Timimoun", en: "Timimoun" }, { value: "Bordj Badji Mokhtar", en: "Bordj Badji Mokhtar" },
    { value: "Ouled Djellal", en: "Ouled Djellal" }, { value: "Beni Abbes", en: "Beni Abbes" },
    { value: "In Salah", en: "In Salah" }, { value: "In Guezzam", en: "In Guezzam" },
    { value: "Touggourt", en: "Touggourt" }, { value: "Djanet", en: "Djanet" },
    { value: "El M'Ghair", en: "El M'Ghair" }, { value: "El Meniaa", en: "El Meniaa" },
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