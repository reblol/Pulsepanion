# Pulsepanion

**Smart Summary** is a web-based R Shiny dashboard that enables caregivers to upload patient data and automatically generate clean, human-readable health summaries across selected timeframes. Built using **R Shiny** for the UI and **Python** for backend processing, this tool supports streamlined healthcare communication through automated data analysis, de-identification, LLM-powered summarization, and export-ready PDF reports.

---

## Features

- Upload patient CSV data
- Select and filter by timeframe 
- **De-identify** sensitive information
- Generate summaries using **LLMs (e.g., OpenAI GPT)**
- Export summaries as formatted **PDF reports**
- Visualize health metrics using interactive charts

---

## Tech Stack

- **Frontend**: [R Shiny](https://shiny.posit.co/)
- **Backend**: Python (via `reticulate`)
- **LLM API**: OpenAI GPT
- **Visualization**: `ggplot2`, `Chart.js`
- **PDF Generation**: `rmarkdown`, `pagedown`

---

## Team Contributions

**Amine Ouaddi (Programmer)**  
- Designed a user-friendly interface through use of R Shiny
-  Designed and implemented backend scripts for:
    - .csv file upload
    - Data text summary generation
    - Full Chart.js functionality through Interactive charts
    - Real-time data processing and data validation
    - Multi-session support for file uploads
    - Memory Navigation
    - Multilingual support
---

## 📂 How to Run Locally

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/smart-summary.git
   cd smart-summary

