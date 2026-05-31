const JOB_TYPES = [
    // Construction and structure
    { value: "plumber",                   en: "Plumber",                      fr: "Plombier",                         ar: "سبّاك" },
    { value: "electrician",               en: "Electrician",                  fr: "Électricien",                      ar: "كهربائي" },
    { value: "carpenter",                 en: "Carpenter",                    fr: "Charpentier",                      ar: "نجار" },
    { value: "mason",                     en: "Mason",                        fr: "Maçon",                            ar: "بنّاء" },
    { value: "painter",                   en: "Painter",                      fr: "Peintre",                          ar: "دهّان" },
    { value: "tiler",                     en: "Tiler",                        fr: "Carreleur",                        ar: "مبلّط" },
    { value: "welder",                    en: "Welder",                       fr: "Soudeur",                          ar: "لحّام" },
    { value: "roofer",                    en: "Roofer",                       fr: "Couvreur",                         ar: "عامل أسقف" },
    { value: "scaffolder",                en: "Scaffolder",                   fr: "Échafaudeur",                      ar: "عامل سقالات" },
    { value: "plasterer",                 en: "Plasterer",                    fr: "Plâtrier",                         ar: "جبّاص" },
    { value: "insulation_worker",         en: "Insulation Worker",            fr: "Isoleur",                          ar: "عازل" },
    { value: "flooring_installer",        en: "Flooring Installer",           fr: "Poseur de revêtements de sol",     ar: "عامل أرضيات" },
    { value: "glazier",                   en: "Glazier",                      fr: "Vitrier",                          ar: "زجّاج" },
    { value: "ironworker",                en: "Ironworker",                   fr: "Ferrailleur",                      ar: "حدّاد" },

    // Home systems
    { value: "hvac_technician",           en: "HVAC Technician",              fr: "Technicien CVC",                   ar: "تقني تكييف وتدفئة" },
    { value: "gas_installer",             en: "Gas Installer",                fr: "Installateur de gaz",              ar: "فنّي غاز" },
    { value: "solar_panel_installer",     en: "Solar Panel Installer",        fr: "Installateur de panneaux solaires",ar: "مركّب ألواح شمسية" },
    { value: "water_pump_technician",     en: "Water Pump Technician",        fr: "Technicien en pompes à eau",       ar: "تقني مضخات مياه" },
    { value: "generator_technician",      en: "Generator Technician",         fr: "Technicien en générateurs",        ar: "تقني مولدات كهرباء" },
    { value: "satellite_installer",       en: "Satellite & Antenna Installer",fr: "Installateur satellite & antenne", ar: "مركّب أطباق وهوائيات" },

    // Finishing and interior
    { value: "interior_designer",         en: "Interior Designer",            fr: "Designer d'intérieur",             ar: "مصمم داخلي" },
    { value: "decorator",                 en: "Decorator",                    fr: "Décorateur",                       ar: "مزيّن / ديكور" },
    { value: "cabinet_maker",             en: "Cabinet Maker",                fr: "Ébéniste",                         ar: "صانع خزائن" },
    { value: "furniture_assembler",       en: "Furniture Assembler",          fr: "Monteur de meubles",               ar: "مجمّع أثاث" },
    { value: "curtain_installer",         en: "Curtain & Blind Installer",    fr: "Poseur de rideaux et stores",      ar: "مركّب ستائر" },
    { value: "false_ceiling_installer",   en: "False Ceiling Installer",      fr: "Poseur de faux plafonds",          ar: "مركّب أسقف مستعارة" },
    { value: "kitchen_fitter",            en: "Kitchen Fitter",               fr: "Installateur de cuisines",         ar: "مركّب مطابخ" },

    // Maintenance and repair
    { value: "handyman",                  en: "Handyman",                     fr: "Homme à tout faire",               ar: "عامل صيانة عامة" },
    { value: "appliance_repair",          en: "Appliance Repair Technician",  fr: "Technicien en électroménager",     ar: "تقني إصلاح أجهزة" },
    { value: "lock_door_specialist",      en: "Lock & Door Specialist",       fr: "Spécialiste serrures et portes",   ar: "متخصص أقفال وأبواب" },
    { value: "waterproofing_specialist",  en: "Waterproofing Specialist",     fr: "Spécialiste en étanchéité",        ar: "متخصص عزل مائي" },
    { value: "pest_control",              en: "Pest Control",                 fr: "Dératisation / Désinsectisation",  ar: "مكافحة الحشرات والقوارض" },
    { value: "cleaning_service",          en: "Cleaning Service",             fr: "Service de nettoyage",             ar: "خدمة تنظيف" },

    // Outdoor and heavy
    { value: "landscaper",               en: "Landscaper",                   fr: "Paysagiste",                       ar: "مزيّن حدائق" },
    { value: "well_digger",              en: "Well Digger",                  fr: "Puisatier",                        ar: "حفّار آبار" },
    { value: "demolition_worker",        en: "Demolition Worker",            fr: "Démolisseur",                      ar: "عامل هدم" },
    { value: "excavation_worker",        en: "Excavation & Earthworks",      fr: "Terrassier",                       ar: "عامل حفر وترابية" },
    { value: "fence_gate_installer",     en: "Fence & Gate Installer",       fr: "Poseur de clôtures et portails",   ar: "مركّب أسوار وبوابات" },

    // Vehicles
    { value: "auto_mechanic",            en: "Auto Mechanic",                fr: "Mécanicien auto",                  ar: "ميكانيكي سيارات" },
    { value: "motorcycle_mechanic",      en: "Motorcycle Mechanic",          fr: "Mécanicien moto",                  ar: "ميكانيكي دراجات" },
    { value: "auto_electrician",         en: "Auto Electrician",             fr: "Électricien auto",                 ar: "كهربائي سيارات" },
    { value: "car_body_repair",          en: "Car Body Repair",              fr: "Carrossier",                       ar: "ميكانيكي هياكل سيارات" },
    { value: "tire_specialist",          en: "Tire Specialist",              fr: "Spécialiste en pneus",             ar: "متخصص إطارات" },

    // Other
    { value: "mover",                    en: "Mover & Transporter",          fr: "Déménageur / Transporteur",        ar: "ناقل وشاحن" },
    { value: "security_installer",       en: "Security System Installer",    fr: "Installateur de sécurité",         ar: "مركّب أنظمة أمان" },
    { value: "network_technician",       en: "Network & Cable Technician",   fr: "Technicien réseau et câblage",     ar: "تقني شبكات وكابلات" },
    { value: "marble_worker",            en: "Marble & Stone Worker",        fr: "Marbrier",                         ar: "رخّام" },
]

module.exports = JOB_TYPES