namespace F1Info_Tickets.Services.Seed
{
    // All sovereign countries (plus Kosovo, Palestine and Taiwan) with ISO 3166-1 alpha-3 codes,
    // so any driver nationality or team base can be selected.
    public static class WorldCountries
    {
        public static readonly (string Code, string Name, string Continent)[] All =
        {
            // Europe
            ("ALB", "Albania", "Europe"), ("AND", "Andorra", "Europe"), ("AUT", "Austria", "Europe"), ("BLR", "Belarus", "Europe"),
            ("BEL", "Belgium", "Europe"), ("BIH", "Bosnia and Herzegovina", "Europe"), ("BGR", "Bulgaria", "Europe"),
            ("HRV", "Croatia", "Europe"), ("CYP", "Cyprus", "Europe"), ("CZE", "Czech Republic", "Europe"), ("DNK", "Denmark", "Europe"),
            ("EST", "Estonia", "Europe"), ("FIN", "Finland", "Europe"), ("FRA", "France", "Europe"), ("DEU", "Germany", "Europe"),
            ("GRC", "Greece", "Europe"), ("HUN", "Hungary", "Europe"), ("ISL", "Iceland", "Europe"), ("IRL", "Ireland", "Europe"),
            ("ITA", "Italy", "Europe"), ("XKX", "Kosovo", "Europe"), ("LVA", "Latvia", "Europe"), ("LIE", "Liechtenstein", "Europe"),
            ("LTU", "Lithuania", "Europe"), ("LUX", "Luxembourg", "Europe"), ("MLT", "Malta", "Europe"), ("MDA", "Moldova", "Europe"),
            ("MCO", "Monaco", "Europe"), ("MNE", "Montenegro", "Europe"), ("NLD", "Netherlands", "Europe"),
            ("MKD", "North Macedonia", "Europe"), ("NOR", "Norway", "Europe"), ("POL", "Poland", "Europe"), ("PRT", "Portugal", "Europe"),
            ("ROU", "Romania", "Europe"), ("RUS", "Russia", "Europe"), ("SMR", "San Marino", "Europe"), ("SRB", "Serbia", "Europe"),
            ("SVK", "Slovakia", "Europe"), ("SVN", "Slovenia", "Europe"), ("ESP", "Spain", "Europe"), ("SWE", "Sweden", "Europe"),
            ("CHE", "Switzerland", "Europe"), ("UKR", "Ukraine", "Europe"), ("GBR", "United Kingdom", "Europe"),
            ("VAT", "Vatican City", "Europe"),

            // Asia
            ("AFG", "Afghanistan", "Asia"), ("ARM", "Armenia", "Asia"), ("AZE", "Azerbaijan", "Asia"), ("BHR", "Bahrain", "Asia"),
            ("BGD", "Bangladesh", "Asia"), ("BTN", "Bhutan", "Asia"), ("BRN", "Brunei", "Asia"), ("KHM", "Cambodia", "Asia"),
            ("CHN", "China", "Asia"), ("GEO", "Georgia", "Asia"), ("IND", "India", "Asia"), ("IDN", "Indonesia", "Asia"),
            ("IRN", "Iran", "Asia"), ("IRQ", "Iraq", "Asia"), ("ISR", "Israel", "Asia"), ("JPN", "Japan", "Asia"),
            ("JOR", "Jordan", "Asia"), ("KAZ", "Kazakhstan", "Asia"), ("KWT", "Kuwait", "Asia"), ("KGZ", "Kyrgyzstan", "Asia"),
            ("LAO", "Laos", "Asia"), ("LBN", "Lebanon", "Asia"), ("MYS", "Malaysia", "Asia"), ("MDV", "Maldives", "Asia"),
            ("MNG", "Mongolia", "Asia"), ("MMR", "Myanmar", "Asia"), ("NPL", "Nepal", "Asia"), ("PRK", "North Korea", "Asia"),
            ("OMN", "Oman", "Asia"), ("PAK", "Pakistan", "Asia"), ("PSE", "Palestine", "Asia"), ("PHL", "Philippines", "Asia"),
            ("QAT", "Qatar", "Asia"), ("SAU", "Saudi Arabia", "Asia"), ("SGP", "Singapore", "Asia"), ("KOR", "South Korea", "Asia"),
            ("LKA", "Sri Lanka", "Asia"), ("SYR", "Syria", "Asia"), ("TWN", "Taiwan", "Asia"), ("TJK", "Tajikistan", "Asia"),
            ("THA", "Thailand", "Asia"), ("TLS", "Timor-Leste", "Asia"), ("TUR", "Turkey", "Asia"), ("TKM", "Turkmenistan", "Asia"),
            ("ARE", "United Arab Emirates", "Asia"), ("UZB", "Uzbekistan", "Asia"), ("VNM", "Vietnam", "Asia"), ("YEM", "Yemen", "Asia"),

            // North America (including Central America and the Caribbean)
            ("ATG", "Antigua and Barbuda", "North America"), ("BHS", "Bahamas", "North America"), ("BRB", "Barbados", "North America"),
            ("BLZ", "Belize", "North America"), ("CAN", "Canada", "North America"), ("CRI", "Costa Rica", "North America"),
            ("CUB", "Cuba", "North America"), ("DMA", "Dominica", "North America"), ("DOM", "Dominican Republic", "North America"),
            ("SLV", "El Salvador", "North America"), ("GRD", "Grenada", "North America"), ("GTM", "Guatemala", "North America"),
            ("HTI", "Haiti", "North America"), ("HND", "Honduras", "North America"), ("JAM", "Jamaica", "North America"),
            ("MEX", "Mexico", "North America"), ("NIC", "Nicaragua", "North America"), ("PAN", "Panama", "North America"),
            ("KNA", "Saint Kitts and Nevis", "North America"), ("LCA", "Saint Lucia", "North America"),
            ("VCT", "Saint Vincent and the Grenadines", "North America"), ("TTO", "Trinidad and Tobago", "North America"),
            ("USA", "United States", "North America"),

            // South America
            ("ARG", "Argentina", "South America"), ("BOL", "Bolivia", "South America"), ("BRA", "Brazil", "South America"),
            ("CHL", "Chile", "South America"), ("COL", "Colombia", "South America"), ("ECU", "Ecuador", "South America"),
            ("GUY", "Guyana", "South America"), ("PRY", "Paraguay", "South America"), ("PER", "Peru", "South America"),
            ("SUR", "Suriname", "South America"), ("URY", "Uruguay", "South America"), ("VEN", "Venezuela", "South America"),

            // Oceania
            ("AUS", "Australia", "Oceania"), ("FJI", "Fiji", "Oceania"), ("KIR", "Kiribati", "Oceania"),
            ("MHL", "Marshall Islands", "Oceania"), ("FSM", "Micronesia", "Oceania"), ("NRU", "Nauru", "Oceania"),
            ("NZL", "New Zealand", "Oceania"), ("PLW", "Palau", "Oceania"), ("PNG", "Papua New Guinea", "Oceania"),
            ("WSM", "Samoa", "Oceania"), ("SLB", "Solomon Islands", "Oceania"), ("TON", "Tonga", "Oceania"),
            ("TUV", "Tuvalu", "Oceania"), ("VUT", "Vanuatu", "Oceania"),

            // Africa
            ("DZA", "Algeria", "Africa"), ("AGO", "Angola", "Africa"), ("BEN", "Benin", "Africa"), ("BWA", "Botswana", "Africa"),
            ("BFA", "Burkina Faso", "Africa"), ("BDI", "Burundi", "Africa"), ("CPV", "Cape Verde", "Africa"), ("CMR", "Cameroon", "Africa"),
            ("CAF", "Central African Republic", "Africa"), ("TCD", "Chad", "Africa"), ("COM", "Comoros", "Africa"),
            ("COG", "Congo", "Africa"), ("COD", "DR Congo", "Africa"), ("CIV", "Côte d'Ivoire", "Africa"), ("DJI", "Djibouti", "Africa"),
            ("EGY", "Egypt", "Africa"), ("GNQ", "Equatorial Guinea", "Africa"), ("ERI", "Eritrea", "Africa"), ("SWZ", "Eswatini", "Africa"),
            ("ETH", "Ethiopia", "Africa"), ("GAB", "Gabon", "Africa"), ("GMB", "Gambia", "Africa"), ("GHA", "Ghana", "Africa"),
            ("GIN", "Guinea", "Africa"), ("GNB", "Guinea-Bissau", "Africa"), ("KEN", "Kenya", "Africa"), ("LSO", "Lesotho", "Africa"),
            ("LBR", "Liberia", "Africa"), ("LBY", "Libya", "Africa"), ("MDG", "Madagascar", "Africa"), ("MWI", "Malawi", "Africa"),
            ("MLI", "Mali", "Africa"), ("MRT", "Mauritania", "Africa"), ("MUS", "Mauritius", "Africa"), ("MAR", "Morocco", "Africa"),
            ("MOZ", "Mozambique", "Africa"), ("NAM", "Namibia", "Africa"), ("NER", "Niger", "Africa"), ("NGA", "Nigeria", "Africa"),
            ("RWA", "Rwanda", "Africa"), ("STP", "São Tomé and Príncipe", "Africa"), ("SEN", "Senegal", "Africa"),
            ("SYC", "Seychelles", "Africa"), ("SLE", "Sierra Leone", "Africa"), ("SOM", "Somalia", "Africa"),
            ("ZAF", "South Africa", "Africa"), ("SSD", "South Sudan", "Africa"), ("SDN", "Sudan", "Africa"), ("TZA", "Tanzania", "Africa"),
            ("TGO", "Togo", "Africa"), ("TUN", "Tunisia", "Africa"), ("UGA", "Uganda", "Africa"), ("ZMB", "Zambia", "Africa"),
            ("ZWE", "Zimbabwe", "Africa"),
        };
    }
}
