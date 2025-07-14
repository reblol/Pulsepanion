# NCHacks-Pulsepanion

**Smart Summary** is a web-based dashboard that enables caregivers to upload patient data and automatically generate clean, human-readable health summaries across selected timeframes. Built using **R Shiny** for the UI and **Python** for backend processing, this tool supports streamlined healthcare communication through automated data analysis, de-identification, LLM-powered summarization, and export-ready PDF reports.

---

## Features

- Upload patient CSV data
- Select and filter by timeframe (Today, Last 7 Days, Last 30 Days, Custom)
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

**Kyle Shiroma (Team Lead)**  
- Led project direction and coordinated team meetings  
- Designed and implemented the backend Python script for:  
  - De-identification of patient data  
  - Integration with OpenAI’s LLM for summary generation  
- Connected backend to the R Shiny UI using `reticulate`  
- Built the PDF export pipeline with `rmarkdown` and custom formatting

---

## 📂 How to Run Locally

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/smart-summary.git
   cd smart-summary

