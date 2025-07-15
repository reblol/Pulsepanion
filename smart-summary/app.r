# Load required libraries
library(shiny)
library(shinyWidgets)
library(jsonlite)
library(ggplot2)
library(readr)
library(tidyr)
library(dplyr)
library(reticulate)
library(rmarkdown) 

# Set Python environment and load the summarization script
use_python("/opt/anaconda3/bin/python", required = TRUE)
source_python("~/Desktop/summarizer.py")

# Reactive value to store the latest summary
global_summary <- reactiveVal(NULL)

# ReactiveValues for storing uploaded dataset and metadata
reactive_store <- reactiveValues(
  full_data = NULL,
  original_data = NULL,
  date_col = NULL
)

ui <- fluidPage(
  tags$head(
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"),
    tags$style(HTML("
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
      
      * {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
        background-size: 400% 400%;
        animation: gradientShift 8s ease infinite;
        margin: 0;
        padding: 0;
        min-height: 100vh;
      }
      
      @keyframes gradientShift {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
      }
      
      .container-fluid {
        background: transparent;
        padding: 0;
      }
      
      .language-selector-container {
        position: absolute;
        top: 30px;
        right: 30px;
        z-index: 1000;
        animation: fadeIn 1s ease-out 0.3s both;
      }
      
      .language-selector {
        background: rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(20px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 15px;
        padding: 12px 20px;
        color: white;
        font-weight: 600;
        font-size: 14px;
        cursor: pointer;
        transition: all 0.3s ease;
        min-width: 120px;
        text-align: center;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
      }
      
      .language-selector:hover {
        background: rgba(255, 255, 255, 0.25);
        transform: translateY(-2px);
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
      }
      
      .main-title-container {
        background: transparent;
        padding: 60px 0 40px 0;
        margin: 0 0 40px 0;
        text-align: center;
        position: relative;
        overflow: hidden;
      }
      
      .main-title {
        color: white;
        font-size: 4.5em;
        font-weight: 700;
        margin: 0 0 60px 0;
        text-shadow: 0 4px 20px rgba(0,0,0,0.3);
        letter-spacing: -0.02em;
        position: relative;
        z-index: 1;
        background: linear-gradient(45deg, #ffffff, #f0f8ff, #ffffff);
        background-size: 200% 200%;
        animation: titleShimmer 3s ease infinite;
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
      }
      
      @keyframes titleShimmer {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
      }
      
      .features-container {
        max-width: 800px;
        margin: 0 auto 60px auto;
        padding: 0 40px;
      }
      
      .feature-item {
        display: flex;
        align-items: flex-start;
        margin-bottom: 25px;
        opacity: 0;
        transform: translateX(-30px);
        animation: slideInLeft 0.8s ease forwards;
        text-align: left;
        justify-content: flex-start;
      }
      
      .feature-item:nth-child(1) { animation-delay: 0.2s; }
      .feature-item:nth-child(2) { animation-delay: 0.4s; }
      .feature-item:nth-child(3) { animation-delay: 0.6s; }
      .feature-item:nth-child(4) { animation-delay: 0.8s; }
      .feature-item:nth-child(5) { animation-delay: 1.0s; }
      .feature-item:nth-child(6) { animation-delay: 1.2s; }
      
      @keyframes slideInLeft {
        to {
          opacity: 1;
          transform: translateX(0);
        }
      }
      
      .bullet-point {
        width: 12px;
        height: 12px;
        background: linear-gradient(45deg, #ffffff, #e3f2fd);
        border-radius: 50%;
        margin-right: 20px;
        margin-top: 6px;
        box-shadow: 0 2px 8px rgba(255, 255, 255, 0.3);
        animation: pulse 2s ease infinite;
        flex-shrink: 0;
        align-self: flex-start;
      }
      
      @keyframes pulse {
        0%, 100% { transform: scale(1); box-shadow: 0 2px 8px rgba(255, 255, 255, 0.3); }
        50% { transform: scale(1.1); box-shadow: 0 4px 15px rgba(255, 255, 255, 0.5); }
      }
      
      .feature-text {
        color: white;
        font-size: 18px;
        font-weight: 400;
        line-height: 1.6;
        text-shadow: 0 2px 8px rgba(0,0,0,0.2);
        letter-spacing: 0.3px;
        text-align: left;
        flex: 1;
      }
      
      .start-button-container {
        text-align: center;
        margin: 80px 0 60px 0;
      }
      
      .start-btn {
        min-width: 200px;
        height: 70px;
        font-size: 20px;
        font-weight: 700;
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        border: none;
        border-radius: 35px;
        color: white;
        cursor: pointer;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 30px rgba(79, 172, 254, 0.4);
        transform: translateY(0);
        letter-spacing: 1px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      .start-btn::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
        transition: left 0.6s;
      }
      
      .start-btn:hover {
        transform: translateY(-6px);
        box-shadow: 0 20px 40px rgba(79, 172, 254, 0.6);
        background: linear-gradient(135deg, #00f2fe 0%, #4facfe 100%);
      }
      
      .start-btn:hover::before {
        left: 100%;
      }
      
      .start-btn:active {
        transform: translateY(-3px);
        box-shadow: 0 15px 30px rgba(79, 172, 254, 0.5);
      }
      
      .page-title-container {
        background: transparent;
        padding: 60px 0 40px 0;
        margin: 0 0 40px 0;
        text-align: center;
        position: relative;
        overflow: hidden;
      }
      
      .page-title {
        color: white;
        font-size: 3.5em;
        font-weight: 700;
        margin: 0 0 20px 0;
        text-shadow: 0 4px 20px rgba(0,0,0,0.3);
        letter-spacing: -0.02em;
        position: relative;
        z-index: 1;
        background: linear-gradient(45deg, #ffffff, #e3f2fd, #ffffff);
        background-size: 200% 200%;
        animation: titleShimmer 3s ease infinite;
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        opacity: 0;
        transform: translateY(-30px);
        animation: fadeInTitle 1s ease forwards, titleShimmer 3s ease infinite;
      }
      
      @keyframes fadeInTitle {
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .main-title, .page-title {
        color: white;
        font-size: 3.5em;
        font-weight: 700;
        margin: 0;
        text-shadow: 0 4px 8px rgba(0,0,0,0.2);
        letter-spacing: -0.02em;
        position: relative;
        z-index: 1;
      }
      
      .content-card {
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(20px);
        border-radius: 25px;
        padding: 40px;
        margin: 20px;
        box-shadow: 0 25px 80px rgba(0, 0, 0, 0.15);
        border: 1px solid rgba(255, 255, 255, 0.3);
        animation: slideInUp 0.8s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
      }
      
      .content-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent);
        animation: cardShimmer 4s ease infinite;
      }
      
      @keyframes cardShimmer {
        0% { left: -100%; }
        100% { left: 100%; }
      }
      
      @keyframes slideInUp {
        from {
          opacity: 0;
          transform: translateY(50px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      @keyframes chartsSlideIn {
        from {
          opacity: 0;
          transform: translateY(40px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .chart-card {
        background: rgba(255, 255, 255, 0.95);
        border-radius: 20px;
        padding: 30px;
        box-shadow: 0 15px 40px rgba(0, 0, 0, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.4);
        transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
        opacity: 0;
        animation: chartCardReveal 0.8s ease-out forwards;
      }
      
      .chart-card:nth-child(1) { animation-delay: 1.0s; }
      .chart-card:nth-child(2) { animation-delay: 1.2s; }
      .chart-card:nth-child(3) { animation-delay: 1.4s; }
      .chart-card:nth-child(4) { animation-delay: 1.6s; }
      
      @keyframes chartCardReveal {
        to {
          opacity: 1;
        }
      }
      
      .chart-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(79, 172, 254, 0.1), transparent);
        animation: chartShimmer 3s ease infinite;
      }
      
      @keyframes chartShimmer {
        0% { left: -100%; }
        100% { left: 100%; }
      }
      
      .chart-card:hover {
        transform: translateY(-5px) scale(1.02);
        box-shadow: 0 25px 60px rgba(0, 0, 0, 0.15);
      }
      
      .chart-title {
        font-size: 18px;
        font-weight: 600;
        color: #2c3e50;
        margin-bottom: 15px;
        text-align: center;
        letter-spacing: 0.3px;
      }
      
      .chart-canvas {
        max-height: 300px;
        width: 100%;
      }
      
      .file-input-container {
        display: flex;
        justify-content: flex-start;
        margin: 30px 0;
        animation: fadeInLeft 1s ease-out 0.3s both;
      }
      
      @keyframes fadeInLeft {
        from {
          opacity: 0;
          transform: translateX(-30px);
        }
        to {
          opacity: 1;
          transform: translateX(0);
        }
      }
      
      .file-input-large {
        width: 100%;
        max-width: 500px;
        position: relative;
      }
      
      .file-input-large .form-group {
        margin-bottom: 0;
      }
      
      .file-input-large label {
        font-size: 18px;
        font-weight: 600;
        margin-bottom: 15px;
        display: block;
        color: #2c3e50;
        letter-spacing: 0.3px;
        animation: fadeIn 1.2s ease-out 0.5s both;
      }
      
      .file-input-large input[type='file'] {
        font-size: 16px;
        padding: 25px;
        height: 80px;
        width: 100%;
        border: 3px dashed #ddd;
        border-radius: 20px;
        background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
        cursor: pointer;
        transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        font-weight: 500;
        position: relative;
        overflow: hidden;
      }
      
      .file-input-large input[type='file']:hover {
        border-color: #4facfe;
        background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
        transform: translateY(-3px) scale(1.02);
        box-shadow: 0 15px 40px rgba(79, 172, 254, 0.3);
      }
      
      .file-input-large input[type='file']:focus {
        outline: none;
        border-color: #00f2fe;
        box-shadow: 0 0 0 6px rgba(79, 172, 254, 0.15);
      }
      
      .date-input-container {
        display: flex;
        align-items: center;
        gap: 25px;
        margin: 30px 0;
        flex-wrap: wrap;
        animation: fadeInUp 1s ease-out 0.6s both;
      }
      
      @keyframes fadeInUp {
        from {
          opacity: 0;
          transform: translateY(30px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .date-input-large {
        flex: 1;
        min-width: 200px;
        position: relative;
        overflow: hidden;
        border-radius: 15px;
        background: linear-gradient(135deg, rgba(255,255,255,0.8) 0%, rgba(240,248,255,0.9) 100%);
        padding: 20px;
        transition: all 0.3s ease;
      }
      
      .date-input-large:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 30px rgba(79, 172, 254, 0.2);
      }
      
      .date-input-large label {
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 10px;
        color: #2c3e50;
        letter-spacing: 0.3px;
        display: block;
      }
      
      .date-input-large input {
        font-size: 16px;
        padding: 15px;
        height: 55px;
        width: 100%;
        border: 2px solid rgba(79, 172, 254, 0.3);
        border-radius: 12px;
        background: white;
        font-weight: 500;
        transition: all 0.3s ease;
      }
      
      .date-input-large input:hover {
        border-color: #4facfe;
        box-shadow: 0 4px 15px rgba(79, 172, 254, 0.2);
      }
      
      .date-input-large input:focus {
        outline: none;
        border-color: #00f2fe;
        box-shadow: 0 0 0 4px rgba(79, 172, 254, 0.1);
      }
      
      .generate-summary-container {
        text-align: center;
        margin: 40px 0 20px 0;
        animation: fadeInScale 1s ease-out 1.2s both;
        display: flex;
        gap: 20px;
        justify-content: center;
        flex-wrap: wrap;
      }
      
      @keyframes fadeInScale {
        from {
          opacity: 0;
          transform: scale(0.8);
        }
        to {
          opacity: 1;
          transform: scale(1);
        }
      }
      
      .generate-summary-btn {
        min-width: 200px;
        height: 60px;
        font-size: 16px;
        font-weight: 600;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        border: none;
        border-radius: 30px;
        color: white;
        cursor: pointer;
        position: relative;
        overflow: hidden;
        box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
        transform: translateY(0);
        letter-spacing: 0.5px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      .generate-llm-btn {
        min-width: 200px;
        height: 60px;
        font-size: 16px;
        font-weight: 600;
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
        border: none;
        border-radius: 30px;
        color: white;
        cursor: pointer;
        position: relative;
        overflow: hidden;
        box-shadow: 0 8px 25px rgba(255, 107, 107, 0.4);
        transform: translateY(0);
        letter-spacing: 0.5px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      .generate-summary-btn::before,
      .generate-llm-btn::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
        transition: left 0.6s;
      }
      
      .generate-summary-btn:hover {
        transform: translateY(-4px);
        box-shadow: 0 15px 35px rgba(102, 126, 234, 0.6);
        background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
      }
      
      .generate-llm-btn:hover {
        transform: translateY(-4px);
        box-shadow: 0 15px 35px rgba(255, 107, 107, 0.6);
        background: linear-gradient(135deg, #ee5a24 0%, #ff6b6b 100%);
      }
      
      .generate-summary-btn:hover::before,
      .generate-llm-btn:hover::before {
        left: 100%;
      }
      
      .generate-summary-btn:active,
      .generate-llm-btn:active {
        transform: translateY(-2px);
      }
      
      .summary-output {
        background: linear-gradient(135deg, rgba(255,255,255,0.95) 0%, rgba(248,250,252,0.9) 100%);
        border-radius: 20px;
        padding: 30px;
        margin: 20px auto;
        max-width: 800px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.3);
        backdrop-filter: blur(10px);
        font-size: 16px;
        line-height: 1.6;
        color: #2c3e50;
        animation: summarySlideIn 0.6s ease-out;
        text-align: left;
      }
      
      @keyframes summarySlideIn {
        from {
          opacity: 0;
          transform: translateY(20px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .btn-secondary {
        background: linear-gradient(135deg, #6c757d 0%, #495057 100%);
        border: none;
        border-radius: 12px;
        padding: 12px 25px;
        color: white;
        font-weight: 600;
        font-size: 16px;
        cursor: pointer;
        transition: all 0.3s ease;
        letter-spacing: 0.3px;
      }
      
      .btn-secondary:hover {
        background: linear-gradient(135deg, #495057 0%, #6c757d 100%);
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(108, 117, 125, 0.3);
      }
      
      .btn-info {
        background: linear-gradient(135deg, #17a2b8 0%, #138496 100%);
        border: none;
        border-radius: 12px;
        padding: 12px 25px;
        color: white;
        font-weight: 600;
        font-size: 16px;
        cursor: pointer;
        transition: all 0.3s ease;
        letter-spacing: 0.3px;
      }
      
      .chart-canvas {
        max-height: 300px;
        width: 100%;
        position: relative;
        z-index: 1;
      }
      
      .text-data {
        background: linear-gradient(135deg, rgba(248,249,250,0.9) 0%, rgba(233,236,239,0.9) 100%);
        border-radius: 20px;
        padding: 30px;
        border: 1px solid rgba(255, 255, 255, 0.3);
        font-family: 'SF Mono', 'Monaco', 'Cascadia Code', monospace;
        font-size: 14px;
        line-height: 1.7;
        color: #2c3e50;
        box-shadow: inset 0 4px 12px rgba(0, 0, 0, 0.08);
        animation: textDataSlide 1s ease-out 0.9s both;
        max-height: 400px;
        overflow-y: auto;
        margin: 25px 0;
        position: relative;
        backdrop-filter: blur(10px);
      }
      
      .text-data::-webkit-scrollbar {
        width: 8px;
      }
      
      .text-data::-webkit-scrollbar-track {
        background: rgba(0, 0, 0, 0.05);
        border-radius: 4px;
      }
      
      .text-data::-webkit-scrollbar-thumb {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        border-radius: 4px;
      }
      
      .overview-container {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 25px;
        margin: 30px auto;
        max-width: 1200px;
        padding: 0 20px;
        animation: overviewSlideIn 1s ease-out 0.7s both;
      }
      
      .charts-container {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
        gap: 30px;
        margin: 40px auto;
        max-width: 1400px;
        padding: 0 20px;
        animation: chartsSlideIn 1s ease-out 0.8s both;
      }
      
      .show-all-data-container {
        text-align: center;
        margin: 30px auto;
        max-width: 600px;
        animation: fadeInScale 1s ease-out 0.6s both;
      }
      
      @keyframes overviewSlideIn {
        from {
          opacity: 0;
          transform: translateY(30px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .overview-card {
        background: linear-gradient(135deg, rgba(255,255,255,0.95) 0%, rgba(248,250,252,0.9) 100%);
        border-radius: 20px;
        padding: 30px;
        text-align: center;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.3);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
        backdrop-filter: blur(10px);
      }
      
      .overview-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(79, 172, 254, 0.1), transparent);
        animation: overviewShimmer 3s ease infinite;
      }
      
      @keyframes overviewShimmer {
        0% { left: -100%; }
        100% { left: 100%; }
      }
      
      .overview-card:hover {
        transform: translateY(-5px) scale(1.02);
        box-shadow: 0 20px 50px rgba(0, 0, 0, 0.15);
      }
      
      .overview-card .card-icon {
        font-size: 2.5em;
        margin-bottom: 15px;
        display: block;
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        position: relative;
        z-index: 1;
      }
      
      .overview-card .card-title {
        font-size: 16px;
        font-weight: 600;
        color: #64748b;
        margin-bottom: 10px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        position: relative;
        z-index: 1;
      }
      
      .overview-card .card-value {
        font-size: 2.2em;
        font-weight: 700;
        color: #1e293b;
        margin-bottom: 5px;
        position: relative;
        z-index: 1;
      }
      
      .overview-card .card-subtitle {
        font-size: 14px;
        color: #64748b;
        font-weight: 500;
        position: relative;
        z-index: 1;
      }
      
      .overview-header {
        text-align: center;
        margin: 30px 0 40px 0;
        animation: fadeInDown 1s ease-out 0.4s both;
      }
      
      @keyframes fadeInDown {
        from {
          opacity: 0;
          transform: translateY(-20px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .overview-header h2 {
        font-size: 2.2em;
        font-weight: 700;
        margin: 0 0 10px 0;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
      }
      
      .overview-header p {
        font-size: 16px;
        color: #64748b;
        margin: 0;
        font-weight: 500;
      }
      
      .date-range-badge {
        display: inline-block;
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        color: white;
        padding: 8px 20px;
        border-radius: 25px;
        font-size: 14px;
        font-weight: 600;
        margin: 10px 0;
        box-shadow: 0 4px 15px rgba(79, 172, 254, 0.3);
        animation: badgeFloat 2s ease-in-out infinite;
      }
      
      @keyframes badgeFloat {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-3px); }
      }
      
      @keyframes fadeIn {
        from {
          opacity: 0;
        }
        to {
          opacity: 1;
        }
      }
      
      .shiny-notification {
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(20px);
        border: none;
        border-radius: 15px;
        box-shadow: 0 15px 40px rgba(0, 0, 0, 0.2);
        font-weight: 500;
        letter-spacing: 0.3px;
        animation: notificationSlideIn 0.5s ease-out;
      }
      
      @keyframes notificationSlideIn {
        from {
          opacity: 0;
          transform: translateY(-20px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .shiny-notification-content {
        padding: 15px 20px;
      }
      
      .text-data {
        background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
        border-radius: 15px;
        padding: 25px;
        border: none;
        font-family: 'SF Mono', 'Monaco', 'Cascadia Code', monospace;
        font-size: 14px;
        line-height: 1.6;
        color: #2c3e50;
        box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.05);
        animation: fadeIn 0.8s ease-out 0.6s both;
        max-height: 400px;
        overflow-y: auto;
        margin: 20px 0;
      }
      
      .text-data::-webkit-scrollbar {
        width: 8px;
      }
      
      .text-data::-webkit-scrollbar-track {
        background: rgba(0, 0, 0, 0.05);
        border-radius: 4px;
      }
      
      .text-data::-webkit-scrollbar-thumb {
        background: rgba(52, 152, 219, 0.3);
        border-radius: 4px;
      }
      
      .text-data::-webkit-scrollbar-thumb:hover {
        background: rgba(52, 152, 219, 0.5);
      }
      
      .shiny-notification {
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(20px);
        border: none;
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        font-weight: 500;
        letter-spacing: 0.3px;
      }
      
      .shiny-notification-content {
        padding: 15px 20px;
      }
      
      @media (max-width: 768px) {
        .main-title {
          font-size: 3em;
        }
        
        .page-title {
          font-size: 2.5em;
        }
        
        .features-container {
          padding: 0 20px;
        }
        
        .feature-text {
          font-size: 16px;
        }
        
        .start-btn {
          min-width: 180px;
          height: 60px;
          font-size: 18px;
        }
        
        .generate-summary-btn,
        .generate-llm-btn {
          min-width: 180px;
          height: 55px;
          font-size: 14px;
        }
        
        .generate-summary-container {
          flex-direction: column;
          gap: 15px;
        }
        
        .content-card {
          margin: 10px;
          padding: 25px;
        }
        
        .date-input-container {
          flex-direction: column;
          gap: 15px;
        }
        
        .charts-container {
          grid-template-columns: 1fr;
          gap: 20px;
          padding: 0 10px;
        }
        
        .overview-container {
          grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
          gap: 20px;
          padding: 0 10px;
        }
        
        .overview-card {
          padding: 25px;
        }
        
        .overview-card .card-value {
          font-size: 1.8em;
        }
        
        .overview-header h2 {
          font-size: 1.8em;
        }
        
        .show-all-data-container {
          padding: 0 10px;
        }
        
        .language-selector-container {
          top: 20px;
          right: 20px;
        }
        
        .language-selector-container select {
          min-width: 120px;
          font-size: 13px;
          padding: 10px 15px;
        }
      }
    "))
  ),
  uiOutput("main_ui")
  
  
)

server <- function(input, output, session) {
  page <- reactiveVal("main")
  previous_page <- reactiveVal("main")
  selected_language <- reactiveVal("en")
  
  # Translation dictionary
  translations <- list(
    en = list(
      # Main page
      main_title = "NCHacks Pulspanion",
      feature_1 = "Track, analyze, and visualize heart rate and wellness data in real time",
      feature_2 = "Monitor daily vitals, manage conditions, or optimize fitness performance",
      feature_3 = "Intuitive dashboards and personalized insights",
      feature_4 = "Seamless integration with .csv health records",
      feature_5 = "Advanced trend tracking and customizable reports",
      feature_6 = "Empowers users to stay informed and take control of their health",
      start_button = "🚀 Start Analysis",
      language_selector = "🌐 Language",

      # Analysis page
      analysis_title = "Health Data Analysis",
      upload_label = "Upload CSV File:",
      start_date = "Start Date:",
      end_date = "End Date:",
      show_all_data = "📊 Show All Data",
      back_button = "← Back",
      
      # Overview
      overview_title = "Data Overview",
      overview_subtitle = "Summary of your health metrics for the selected period",
      total_records = "Total Records",
      heart_rate = "Heart Rate",
      sleep_average = "Sleep Average",
      activities = "Activities",
      breathing_rate = "Breathing Rate",
      data_span = "Data Span",
      
      # Summary
      generate_text_summary = "📝 Generate Text Summary",
      generate_llm_summary = "🤖 Generate LLM Summary",
      summary_title = "📋 Health Data Summary",
      
      # All data page
      complete_dataset_title = "Complete Dataset Overview",
      complete_analysis_title = "Complete Dataset Analysis",
      complete_summary_title = "📋 Complete Health Data Summary",
      comprehensive_subtitle = "Comprehensive summary of all health data in your dataset",
      back_to_analysis = "← Back to Analysis",
      
      # Units and descriptors
      data_points = "data points analyzed",
      per_night = "per night",
      unique_categories = "unique categories",
      average_bpm = "Average BPM",
      range_bpm = "Range: %s BPM",
      breaths_min = "breaths/min average",
      total_days = "days",
      total_time_period = "total time period",
      valid_dates_percent = "%s%% with valid dates",
      
      # Summary text components
      analysis_of = "Analysis of %s health records",
      from_period = "from %s",
      hr_averaged = "Heart rate averaged %s BPM, %s with readings ranging from %s to %s BPM.",
      hr_normal = "within normal range",
      hr_low = "below normal range (bradycardia)",
      hr_high = "above normal range (tachycardia)",
      sleep_averaged = "Sleep duration averaged %s hours per night, %s for healthy adults.",
      sleep_recommended = "meeting recommended guidelines",
      sleep_low = "below recommended 7-9 hours",
      sleep_high = "above typical range",
      deep_sleep = "Deep sleep accounted for %s hours (%s%%) of total sleep.",
      activities_engaged = "Patient engaged in %s different activity types, with %s being the most frequently recorded activity.",
      breathing_averaged = "Breathing rate averaged %s breaths per minute, %s for a healthy adult at rest.",
      breathing_normal = "within normal range",
      breathing_low = "below normal range",
      breathing_high = "above normal range",
      overall_indicates = "Overall, the data indicates %s during this period.",
      normal_heart_rate = "normal heart rate",
      adequate_sleep = "adequate sleep duration",
      normal_breathing = "normal breathing rate",
      no_data_available = "No data available for the selected time period.",
      no_data_found = "No Data Found",
      no_records_message = "No records available for the selected date range."
    ),
    es = list(
      # Main page
      main_title = "NCHacks Pulspanion",
      feature_1 = "Rastrea, analiza y visualiza datos de ritmo cardíaco y bienestar en tiempo real",
      feature_2 = "Monitorea signos vitales diarios, maneja condiciones u optimiza el rendimiento físico",
      feature_3 = "Paneles intuitivos e insights personalizados",
      feature_4 = "Integración perfecta con registros de salud .csv",
      feature_5 = "Seguimiento avanzado de tendencias e informes personalizables",
      feature_6 = "Empodera a los usuarios para mantenerse informados y tomar control de su salud",
      start_button = "🚀 Iniciar Análisis",
      language_selector = "🌐 Idioma",
      
      # Analysis page
      analysis_title = "Análisis de Datos de Salud",
      upload_label = "Subir Archivo CSV:",
      start_date = "Fecha de Inicio:",
      end_date = "Fecha de Fin:",
      show_all_data = "📊 Mostrar Todos los Datos",
      back_button = "← Atrás",
      
      # Overview
      overview_title = "Resumen de Datos",
      overview_subtitle = "Resumen de sus métricas de salud para el período seleccionado",
      total_records = "Registros Totales",
      heart_rate = "Ritmo Cardíaco",
      sleep_average = "Promedio de Sueño",
      activities = "Actividades",
      breathing_rate = "Frecuencia Respiratoria",
      data_span = "Período de Datos",
      
      # Summary
      generate_text_summary = "📝 Generar Resumen de Texto",
      generate_llm_summary = "🤖 Generar Resumen LLM",
      summary_title = "📋 Resumen de Datos de Salud",
      
      # All data page
      complete_dataset_title = "Resumen Completo del Dataset",
      complete_analysis_title = "Análisis Completo del Dataset",
      complete_summary_title = "📋 Resumen Completo de Datos de Salud",
      comprehensive_subtitle = "Resumen integral de todos los datos de salud en su dataset",
      back_to_analysis = "← Volver al Análisis",
      
      # Units and descriptors
      data_points = "puntos de datos analizados",
      per_night = "por noche",
      unique_categories = "categorías únicas",
      average_bpm = "LPM Promedio",
      range_bpm = "Rango: %s LPM",
      breaths_min = "respiraciones/min promedio",
      total_days = "días",
      total_time_period = "período total de tiempo",
      valid_dates_percent = "%s%% con fechas válidas",
      
      # Summary text components
      analysis_of = "Análisis de %s registros de salud",
      from_period = "desde %s",
      hr_averaged = "El ritmo cardíaco promedió %s LPM, %s con lecturas que van desde %s hasta %s LPM.",
      hr_normal = "dentro del rango normal",
      hr_low = "por debajo del rango normal (bradicardia)",
      hr_high = "por encima del rango normal (taquicardia)",
      sleep_averaged = "La duración del sueño promedió %s horas por noche, %s para adultos saludables.",
      sleep_recommended = "cumpliendo las recomendaciones",
      sleep_low = "por debajo de las 7-9 horas recomendadas",
      sleep_high = "por encima del rango típico",
      deep_sleep = "El sueño profundo representó %s horas (%s%%) del sueño total.",
      activities_engaged = "El paciente participó en %s tipos diferentes de actividades, siendo %s la actividad registrada con mayor frecuencia.",
      breathing_averaged = "La frecuencia respiratoria promedió %s respiraciones por minuto, %s para un adulto saludable en reposo.",
      breathing_normal = "dentro del rango normal",
      breathing_low = "por debajo del rango normal",
      breathing_high = "por encima del rango normal",
      overall_indicates = "En general, los datos indican %s durante este período.",
      normal_heart_rate = "ritmo cardíaco normal",
      adequate_sleep = "duración adecuada de sueño",
      normal_breathing = "frecuencia respiratoria normal",
      no_data_available = "No hay datos disponibles para el período de tiempo seleccionado.",
      no_data_found = "No se Encontraron Datos",
      no_records_message = "No hay registros disponibles para el rango de fechas seleccionado."
      
    )
  )
  
  # Helper function to get translated text
  t <- function(key, ...) {
    lang <- selected_language()
    text <- translations[[lang]][[key]]
    if(is.null(text)) {
      text <- translations[["en"]][[key]]  # Fallback to English
    }
    if(length(list(...)) > 0) {
      return(sprintf(text, ...))
    }
    return(text)
  }
  
  # Function to process uploaded CSV
  process_csv <- function(file_path) {
    tryCatch({
      # Read the CSV
      original_data <<- read.csv(file_path, stringsAsFactors = FALSE)
      full_data <<- original_data
      
      # Find date column
      date_col <<- NULL
      for(col in names(full_data)) {
        if(grepl("date|Date|DATE", col, ignore.case = TRUE)) {
          date_col <<- col
          break
        }
      }
      
      # If no date column found, check first column
      if(is.null(date_col)) {
        date_col <<- names(full_data)[1]
      }
      
      # Parse dates
      full_data$Date <<- tryCatch({
        # Try M/D/YYYY format first
        parsed <- as.Date(full_data[[date_col]], format = "%m/%d/%Y")
        if(all(is.na(parsed))) {
          # Try M/D/YY format
          parsed <- as.Date(full_data[[date_col]], format = "%m/%d/%y")
        }
        if(all(is.na(parsed))) {
          # Try YYYY-MM-DD format
          parsed <- as.Date(full_data[[date_col]], format = "%Y-%m-%d")
        }
        if(all(is.na(parsed))) {
          # Try automatic parsing
          parsed <- as.Date(full_data[[date_col]])
        }
        parsed
      }, error = function(e) {
        rep(NA, nrow(full_data))
      })
      
      return(TRUE)
    }, error = function(e) {
      showNotification(paste("Error reading CSV:", e$message), type = "error")
      return(FALSE)
    })
  }
  
  # Function to generate interactive charts for all data types
  generate_interactive_charts <- function(df, output_id) {
    if(nrow(df) == 0) return("")
    
    chart_id_hr <- paste0("heartRate_", output_id)
    chart_id_sleep <- paste0("sleep_", output_id) 
    chart_id_activity <- paste0("activity_", output_id)
    chart_id_breathing <- paste0("breathing_", output_id)
    
    charts_html <- '<div class="charts-container">'
    
    # Heart Rate Chart
    hr_cols_exist <- any(c("hr_avg", "hr_min", "hr_max") %in% names(df))
    if(hr_cols_exist && !all(is.na(df$hr_avg))) {
      charts_html <- paste0(charts_html,
                            '<div class="chart-card">',
                            '<div class="chart-title">💓 Heart Rate Trends</div>',
                            '<canvas id="', chart_id_hr, '" class="chart-canvas"></canvas>',
                            '</div>'
      )
    }
    
    # Sleep Chart
    sleep_cols <- c("sleep_total", "sleep_light", "sleep_deep", "sleep_rem")
    existing_sleep_cols <- sleep_cols[sleep_cols %in% names(df)]
    sleep_has_data <- FALSE
    
    if(length(existing_sleep_cols) > 0) {
      for(col in existing_sleep_cols) {
        if(!all(is.na(df[[col]]))) {
          sleep_has_data <- TRUE
          break
        }
      }
    }
    
    if(sleep_has_data) {
      charts_html <- paste0(charts_html,
                            '<div class="chart-card">',
                            '<div class="chart-title">😴 Sleep Analysis</div>',
                            '<canvas id="', chart_id_sleep, '" class="chart-canvas"></canvas>',
                            '</div>'
      )
    }
    
    # Activity Chart
    if("act_cat" %in% names(df) && !all(is.na(df$act_cat))) {
      charts_html <- paste0(charts_html,
                            '<div class="chart-card">',
                            '<div class="chart-title">📊 Activity Categories</div>',
                            '<canvas id="', chart_id_activity, '" class="chart-canvas"></canvas>',
                            '</div>'
      )
    }
    
    # Breathing Chart
    if("br_avg" %in% names(df) && !all(is.na(df$br_avg))) {
      charts_html <- paste0(charts_html,
                            '<div class="chart-card">',
                            '<div class="chart-title">🫁 Breathing Rate</div>',
                            '<canvas id="', chart_id_breathing, '" class="chart-canvas"></canvas>',
                            '</div>'
      )
    }
    
    charts_html <- paste0(charts_html, '</div>')
    
    # Add JavaScript for charts
    charts_html <- paste0(charts_html, '<script>')
    
    hr_cols_exist <- any(c("hr_avg", "hr_min", "hr_max") %in% names(df))
    if(hr_cols_exist && !all(is.na(df$hr_avg))) {
      charts_html <- paste0(charts_html, create_heart_rate_js(df, chart_id_hr))
    }
    
    # Check for sleep data more comprehensively
    sleep_cols <- c("sleep_total", "sleep_light", "sleep_deep", "sleep_rem")
    existing_sleep_cols <- sleep_cols[sleep_cols %in% names(df)]
    sleep_has_data <- FALSE
    
    if(length(existing_sleep_cols) > 0) {
      for(col in existing_sleep_cols) {
        if(!all(is.na(df[[col]]))) {
          sleep_has_data <- TRUE
          break
        }
      }
    }
    
    if(sleep_has_data) {
      charts_html <- paste0(charts_html, create_sleep_js(df, chart_id_sleep))
    }
    
    if("act_cat" %in% names(df) && !all(is.na(df$act_cat))) {
      charts_html <- paste0(charts_html, create_activity_js(df, chart_id_activity))
    }
    
    if("br_avg" %in% names(df) && !all(is.na(df$br_avg))) {
      charts_html <- paste0(charts_html, create_breathing_js(df, chart_id_breathing))
    }
    
    charts_html <- paste0(charts_html, '</script>')
    
    return(charts_html)
  }
  
  # Heart Rate Interactive Chart JavaScript
  create_heart_rate_js <- function(df, chart_id) {
    # Check if heart rate columns exist
    hr_cols_exist <- any(c("hr_avg", "hr_min", "hr_max") %in% names(df))
    if(!hr_cols_exist) return("")
    
    valid_data <- df[!is.na(df$hr_avg), ]
    if(nrow(valid_data) == 0) return("")
    
    # Sample data if too many points for better visualization
    if(nrow(valid_data) > 50) {
      # Take every nth point to reduce clutter
      sample_interval <- ceiling(nrow(valid_data) / 50)
      valid_data <- valid_data[seq(1, nrow(valid_data), by = sample_interval), ]
    }
    
    dates <- format(valid_data$Date, "%m-%d")
    
    # Handle missing HR columns with defaults
    hr_min <- if("hr_min" %in% names(valid_data)) valid_data$hr_min else valid_data$hr_avg
    hr_max <- if("hr_max" %in% names(valid_data)) valid_data$hr_max else valid_data$hr_avg
    hr_avg <- valid_data$hr_avg
    
    # Replace NAs with average where possible
    hr_min[is.na(hr_min)] <- hr_avg[is.na(hr_min)]
    hr_max[is.na(hr_max)] <- hr_avg[is.na(hr_max)]
    
    # Create safe JavaScript arrays
    labels_js <- paste0('["', paste(dates, collapse = '","'), '"]')
    min_js <- paste0('[', paste(hr_min, collapse = ','), ']')
    max_js <- paste0('[', paste(hr_max, collapse = ','), ']')
    avg_js <- paste0('[', paste(hr_avg, collapse = ','), ']')
    
    js_code <- paste0(
      'setTimeout(function() {
        var ctx = document.getElementById("', chart_id, '");
        if(ctx && typeof Chart !== "undefined") {
          new Chart(ctx, {
            type: "line",
            data: {
              labels: ', labels_js, ',
              datasets: [{
                label: "Min HR",
                data: ', min_js, ',
                borderColor: "#3498db",
                backgroundColor: "rgba(52, 152, 219, 0.1)",
                fill: false,
                tension: 0.4,
                borderWidth: 2,
                pointRadius: function(context) {
                  return context.chart.data.labels.length > 30 ? 0 : 3;
                },
                pointHoverRadius: 5
              }, {
                label: "Average HR", 
                data: ', avg_js, ',
                borderColor: "#e74c3c",
                backgroundColor: "rgba(231, 76, 60, 0.1)",
                fill: false,
                tension: 0.4,
                borderWidth: 3,
                pointRadius: function(context) {
                  return context.chart.data.labels.length > 30 ? 0 : 4;
                },
                pointHoverRadius: 6
              }, {
                label: "Max HR",
                data: ', max_js, ',
                borderColor: "#f39c12",
                backgroundColor: "rgba(243, 156, 18, 0.1)",
                fill: false,
                tension: 0.4,
                borderWidth: 2,
                pointRadius: function(context) {
                  return context.chart.data.labels.length > 30 ? 0 : 3;
                },
                pointHoverRadius: 5
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              interaction: {
                intersect: false,
                mode: "index"
              },
              plugins: {
                legend: {
                  position: "top"
                },
                tooltip: {
                  mode: "index",
                  intersect: false,
                  callbacks: {
                    title: function(context) {
                      return "Date: " + context[0].label;
                    },
                    label: function(context) {
                      return context.dataset.label + ": " + context.parsed.y + " BPM";
                    }
                  }
                }
              },
              scales: {
                x: {
                  display: true,
                  title: {
                    display: true,
                    text: "Date"
                  },
                  ticks: {
                    maxTicksLimit: 10,
                    autoSkip: true,
                    maxRotation: 45
                  }
                },
                y: {
                  display: true,
                  title: {
                    display: true,
                    text: "BPM"
                  },
                  beginAtZero: false
                }
              }
            }
          });
        }
      }, 500);'
    )
    
    return(js_code)
  }
  
  # Sleep Interactive Chart JavaScript
  create_sleep_js <- function(df, chart_id) {
    # Check if any sleep columns exist
    sleep_cols <- c("sleep_total", "sleep_light", "sleep_deep", "sleep_rem")
    existing_sleep_cols <- sleep_cols[sleep_cols %in% names(df)]
    
    if(length(existing_sleep_cols) == 0) return("")
    
    # If we have sleep_total but no breakdown, use sleep_total
    if("sleep_total" %in% names(df)) {
      valid_data <- df[!is.na(df$sleep_total), ]
    } else {
      # Otherwise use any available sleep data
      valid_data <- df
      for(col in existing_sleep_cols) {
        valid_data <- valid_data[!is.na(valid_data[[col]]), ]
      }
    }
    
    if(nrow(valid_data) == 0) return("")
    
    # Sample data if too many points for better visualization
    if(nrow(valid_data) > 50) {
      # Take every nth point to reduce clutter
      sample_interval <- ceiling(nrow(valid_data) / 50)
      valid_data <- valid_data[seq(1, nrow(valid_data), by = sample_interval), ]
    }
    
    dates <- format(valid_data$Date, "%m-%d")
    
    # Handle missing sleep columns with defaults
    if("sleep_light" %in% names(valid_data)) {
      sleep_light <- valid_data$sleep_light
      sleep_light[is.na(sleep_light)] <- 0
    } else if("sleep_total" %in% names(valid_data)) {
      sleep_light <- valid_data$sleep_total * 0.6  # Assume 60% light sleep
    } else {
      sleep_light <- rep(0, nrow(valid_data))
    }
    
    if("sleep_deep" %in% names(valid_data)) {
      sleep_deep <- valid_data$sleep_deep
      sleep_deep[is.na(sleep_deep)] <- 0
    } else if("sleep_total" %in% names(valid_data)) {
      sleep_deep <- valid_data$sleep_total * 0.25  # Assume 25% deep sleep
    } else {
      sleep_deep <- rep(0, nrow(valid_data))
    }
    
    if("sleep_rem" %in% names(valid_data)) {
      sleep_rem <- valid_data$sleep_rem
      sleep_rem[is.na(sleep_rem)] <- 0
    } else if("sleep_total" %in% names(valid_data)) {
      sleep_rem <- valid_data$sleep_total * 0.15  # Assume 15% REM sleep
    } else {
      sleep_rem <- rep(0, nrow(valid_data))
    }
    
    # Create safe JavaScript arrays
    labels_js <- paste0('["', paste(dates, collapse = '","'), '"]')
    light_js <- paste0('[', paste(sleep_light, collapse = ','), ']')
    deep_js <- paste0('[', paste(sleep_deep, collapse = ','), ']')
    rem_js <- paste0('[', paste(sleep_rem, collapse = ','), ']')
    
    js_code <- paste0(
      'setTimeout(function() {
        var ctx = document.getElementById("', chart_id, '");
        if(ctx && typeof Chart !== "undefined") {
          new Chart(ctx, {
            type: "bar",
            data: {
              labels: ', labels_js, ',
              datasets: [{
                label: "Light Sleep",
                data: ', light_js, ',
                backgroundColor: "#3498db",
                borderRadius: 5,
                borderSkipped: false
              }, {
                label: "Deep Sleep",
                data: ', deep_js, ',
                backgroundColor: "#2c3e50",
                borderRadius: 5,
                borderSkipped: false
              }, {
                label: "REM Sleep",
                data: ', rem_js, ',
                backgroundColor: "#9b59b6",
                borderRadius: 5,
                borderSkipped: false
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              interaction: {
                intersect: false,
                mode: "index"
              },
              plugins: {
                legend: {
                  position: "top"
                },
                tooltip: {
                  mode: "index",
                  intersect: false,
                  callbacks: {
                    title: function(context) {
                      return "Date: " + context[0].label;
                    },
                    label: function(context) {
                      return context.dataset.label + ": " + context.parsed.y.toFixed(1) + " hours";
                    }
                  }
                }
              },
              scales: {
                x: {
                  stacked: true,
                  title: {
                    display: true,
                    text: "Date"
                  },
                  ticks: {
                    maxTicksLimit: 15,
                    autoSkip: true,
                    maxRotation: 45
                  }
                },
                y: {
                  stacked: true,
                  title: {
                    display: true,
                    text: "Hours"
                  },
                  beginAtZero: true
                }
              }
            }
          });
        }
      }, 600);'
    )
    
    return(js_code)
  }
  
  # Activity Interactive Chart JavaScript
  create_activity_js <- function(df, chart_id) {
    # Check if activity column exists
    if(!"act_cat" %in% names(df)) return("")
    
    activities <- table(df$act_cat[!is.na(df$act_cat) & df$act_cat != ""])
    if(length(activities) == 0) return("")
    
    # Create safe JavaScript arrays
    labels_js <- paste0('["', paste(names(activities), collapse = '","'), '"]')
    data_js <- paste0('[', paste(as.numeric(activities), collapse = ','), ']')
    
    # Generate colors for each category
    colors <- c("#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c", "#34495e", "#e67e22", "#16a085", "#8e44ad")
    colors_needed <- min(length(activities), length(colors))
    colors_js <- paste0('["', paste(colors[1:colors_needed], collapse = '","'), '"]')
    
    js_code <- paste0(
      'setTimeout(function() {
        var ctx = document.getElementById("', chart_id, '");
        if(ctx && typeof Chart !== "undefined") {
          new Chart(ctx, {
            type: "doughnut",
            data: {
              labels: ', labels_js, ',
              datasets: [{
                data: ', data_js, ',
                backgroundColor: ', colors_js, ',
                borderWidth: 2,
                borderColor: "#fff",
                hoverOffset: 10,
                hoverBorderWidth: 3
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: {
                  position: "bottom",
                  labels: {
                    padding: 20,
                    usePointStyle: true
                  }
                },
                tooltip: {
                  callbacks: {
                    label: function(context) {
                      var total = context.dataset.data.reduce(function(a, b) { return a + b; }, 0);
                      var percentage = Math.round((context.parsed / total) * 100);
                      return context.label + ": " + context.parsed + " (" + percentage + "%)";
                    }
                  }
                }
              }
            }
          });
        }
      }, 700);'
    )
    
    return(js_code)
  }
  
  # Breathing Interactive Chart JavaScript
  create_breathing_js <- function(df, chart_id) {
    # Check if breathing column exists
    if(!"br_avg" %in% names(df)) return("")
    
    valid_data <- df[!is.na(df$br_avg), ]
    if(nrow(valid_data) == 0) return("")
    
    # Sample data if too many points for better visualization
    if(nrow(valid_data) > 50) {
      # Take every nth point to reduce clutter
      sample_interval <- ceiling(nrow(valid_data) / 50)
      valid_data <- valid_data[seq(1, nrow(valid_data), by = sample_interval), ]
    }
    
    dates <- format(valid_data$Date, "%m-%d")
    br_avg <- valid_data$br_avg
    
    # Create safe JavaScript arrays
    labels_js <- paste0('["', paste(dates, collapse = '","'), '"]')
    data_js <- paste0('[', paste(br_avg, collapse = ','), ']')
    
    js_code <- paste0(
      'setTimeout(function() {
        var ctx = document.getElementById("', chart_id, '");
        if(ctx && typeof Chart !== "undefined") {
          new Chart(ctx, {
            type: "line",
            data: {
              labels: ', labels_js, ',
              datasets: [{
                label: "Breathing Rate",
                data: ', data_js, ',
                borderColor: "#1abc9c",
                backgroundColor: "rgba(26, 188, 156, 0.1)",
                fill: true,
                tension: 0.4,
                borderWidth: 3,
                pointBackgroundColor: "#1abc9c",
                pointBorderColor: "#fff",
                pointBorderWidth: 2,
                pointRadius: function(context) {
                  return context.chart.data.labels.length > 30 ? 0 : 4;
                },
                pointHoverRadius: 8
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              interaction: {
                intersect: false,
                mode: "index"
              },
              plugins: {
                legend: {
                  display: false
                },
                tooltip: {
                  mode: "index",
                  intersect: false,
                  callbacks: {
                    title: function(context) {
                      return "Date: " + context[0].label;
                    },
                    label: function(context) {
                      return "Breathing Rate: " + context.parsed.y + " breaths/min";
                    }
                  }
                }
              },
              scales: {
                x: {
                  title: {
                    display: true,
                    text: "Date"
                  },
                  ticks: {
                    maxTicksLimit: 10,
                    autoSkip: true,
                    maxRotation: 45
                  }
                },
                y: {
                  title: {
                    display: true,
                    text: "Breaths/min"
                  },
                  beginAtZero: true
                }
              }
            }
          });
        }
      }, 800);'
    )
    
    return(js_code)
  }
  
  output$main_ui <- renderUI({
    switch(page(),
           "main" = mainPageUI(),
           "custom" = customPageUI(),
           "alldata" = allDataPageUI()
    )
  })
  
  mainPageUI <- function() {
    tagList(
      div(class = "main-title-container",
          div(class = "language-selector-container",
              selectInput("language_select", 
                         label = NULL,
                         choices = list("🇺🇸 English" = "en", "🇪🇸 Español" = "es"),
                         selected = selected_language(),
                         width = "120px")
          ),
          div(class = "main-title", t("main_title")),
          div(class = "features-container",
              div(class = "feature-item",
                  div(class = "bullet-point"),
                  div(class = "feature-text", t("feature_1"))
              ),
              div(class = "feature-item",
                  div(class = "bullet-point"),
                  div(class = "feature-text", t("feature_2"))
              ),
              div(class = "feature-item",
                  div(class = "bullet-point"),
                  div(class = "feature-text", t("feature_3"))
              ),
              div(class = "feature-item",
                  div(class = "bullet-point"),
                  div(class = "feature-text", t("feature_4"))
              ),
              div(class = "feature-item",
                  div(class = "bullet-point"),
                  div(class = "feature-text", t("feature_5"))
              ),
              div(class = "feature-item",
                  div(class = "bullet-point"),
                  div(class = "feature-text", t("feature_6"))
              )
          ),
          div(class = "start-button-container",
              actionButton("start_btn", t("start_button"), class = "start-btn")
          )
      )
    )
  }
  
  customPageUI <- function() {
    tagList(
      div(class = "page-title-container",
          div(class = "page-title", t("analysis_title"))
      ),
      div(class = "content-card",
          div(class = "file-input-container", style = "text-align: center;",
              div(class = "file-input-large",
                  fileInput("custom_file", t("upload_label"), accept = ".csv")
              )
          ),
          conditionalPanel(
            condition = "output.file_uploaded",
            div(class = "date-input-container",
                div(class = "date-input-large",
                    dateInput("custom_date", t("start_date"), format = "mm-dd-yyyy")
                ),
                div(class = "date-input-large",
                    dateInput("custom_end_date", t("end_date"), format = "mm-dd-yyyy")
                )
            ),
            div(class = "show-all-data-container",
                actionButton("show_all_data", t("show_all_data"), class = "btn-info")
            )
          ),
          uiOutput("custom_overview"),
          uiOutput("custom_charts"),
          uiOutput("custom_summary"),
          
          div(class = "generate-summary-container",
              actionButton("generate_text_summary_custom", t("generate_text_summary"), class = "generate-summary-btn"),
              actionButton("generate_llm_summary_custom", t("generate_llm_summary"), class = "generate-llm-btn")
          ),
          br(),
          
          actionButton("back_custom", t("back_button"), class = "btn-secondary"),
          
          div(style = "text-align: center;",
              downloadButton("download_summary_pdf", "Download Summary PDF")
          )
      )
    )
  }
  
  allDataPageUI <- function() {
    tagList(
      div(class = "page-title-container",
          div(class = "page-title", t("complete_dataset_title"))
      ),
      div(class = "content-card",
          uiOutput("all_data_overview"),
          uiOutput("all_data_charts"),
          uiOutput("all_data_summary"),
          div(class = "generate-summary-container",
              actionButton("generate_text_summary_all", t("generate_text_summary"), class = "generate-summary-btn"),
              actionButton("generate_llm_summary_all", t("generate_llm_summary"), class = "generate-llm-btn")
          ),
          br(),
          actionButton("back_all_data", t("back_to_analysis"), class = "btn-secondary")
      )
    )
  }
  
  # Language selection observer
  observeEvent(input$language_select, {
    selected_language(input$language_select)
  })
  
  # Navigation
  observeEvent(input$start_btn, { page("custom") })
  observeEvent(input$back_custom, { page("main") })
  
  # Navigation to and from all data page
  observeEvent(input$show_all_data, { 
    previous_page("custom")
    page("alldata") 
  })
  observeEvent(input$back_all_data, { 
    page(previous_page()) 
  })
  
  # Function to generate text summary
  generate_text_summary <- function(df, date_range_text) {
    if(nrow(df) == 0) {
      return(t("no_data_available"))
    }
    
    summary_parts <- c()
    
    # Basic stats
    total_records <- nrow(df)
    summary_parts <- c(summary_parts, t("analysis_of", total_records))
    if(date_range_text != "") {
      summary_parts <- c(summary_parts, t("from_period", date_range_text))
    }
    
    # Heart rate analysis
    if(!all(is.na(df$hr_avg))) {
      avg_hr <- round(mean(df$hr_avg, na.rm = TRUE), 0)
      min_hr <- round(min(df$hr_min, na.rm = TRUE), 0)
      max_hr <- round(max(df$hr_max, na.rm = TRUE), 0)
      
      hr_assessment <- if(avg_hr >= 60 && avg_hr <= 100) t("hr_normal") else 
                      if(avg_hr < 60) t("hr_low") else t("hr_high")
      
      summary_parts <- c(summary_parts, t("hr_averaged", avg_hr, hr_assessment, min_hr, max_hr))
    }
    
    # Sleep analysis
    if(!all(is.na(df$sleep_total))) {
      avg_sleep <- round(mean(df$sleep_total, na.rm = TRUE), 1)
      sleep_assessment <- if(avg_sleep >= 7 && avg_sleep <= 9) t("sleep_recommended") else 
                         if(avg_sleep < 7) t("sleep_low") else t("sleep_high")
      
      summary_parts <- c(summary_parts, t("sleep_averaged", avg_sleep, sleep_assessment))
      
      if(!all(is.na(df$sleep_deep))) {
        avg_deep <- round(mean(df$sleep_deep, na.rm = TRUE), 1)
        deep_percentage <- round((avg_deep / avg_sleep) * 100, 0)
        summary_parts <- c(summary_parts, t("deep_sleep", avg_deep, deep_percentage))
      }
    }
    
    # Activity analysis
    if(!all(is.na(df$act_cat))) {
      activities <- table(df$act_cat[!is.na(df$act_cat)])
      activity_count <- length(activities)
      most_common <- names(activities)[which.max(activities)]
      
      summary_parts <- c(summary_parts, t("activities_engaged", activity_count, most_common))
    }
    
    # Breathing rate analysis
    if(!all(is.na(df$br_avg))) {
      avg_breathing <- round(mean(df$br_avg, na.rm = TRUE), 1)
      breathing_assessment <- if(avg_breathing >= 12 && avg_breathing <= 20) t("breathing_normal") else 
                             if(avg_breathing < 12) t("breathing_low") else t("breathing_high")
      
      summary_parts <- c(summary_parts, t("breathing_averaged", avg_breathing, breathing_assessment))
    }
    
    # Overall assessment
    health_indicators <- c()
    if(!all(is.na(df$hr_avg)) && mean(df$hr_avg, na.rm = TRUE) >= 60 && mean(df$hr_avg, na.rm = TRUE) <= 100) {
      health_indicators <- c(health_indicators, t("normal_heart_rate"))
    }
    if(!all(is.na(df$sleep_total)) && mean(df$sleep_total, na.rm = TRUE) >= 7 && mean(df$sleep_total, na.rm = TRUE) <= 9) {
      health_indicators <- c(health_indicators, t("adequate_sleep"))
    }
    if(!all(is.na(df$br_avg)) && mean(df$br_avg, na.rm = TRUE) >= 12 && mean(df$br_avg, na.rm = TRUE) <= 20) {
      health_indicators <- c(health_indicators, t("normal_breathing"))
    }
    
    if(length(health_indicators) > 0) {
      summary_parts <- c(summary_parts, t("overall_indicates", paste(health_indicators, collapse = ", ")))
    }
    
    return(paste(summary_parts, collapse = " "))
  }
  
  # Generate Summary button handlers
  observeEvent(input$generate_text_summary_custom, {
    req(input$custom_file, input$custom_date, input$custom_end_date, full_data)
    start_date <- as.Date(input$custom_date)
    end_date <- as.Date(input$custom_end_date)
    
    # Filter data
    df <- full_data[!is.na(full_data$Date) & 
                      full_data$Date >= start_date & 
                      full_data$Date <= end_date, ]
    
    date_range_text <- paste(format(start_date, "%B %d, %Y"), "to", format(end_date, "%B %d, %Y"))
    summary_text <- generate_text_summary(df, date_range_text)
    global_summary(summary_text)
    
    output$custom_summary <- renderUI({
      div(class = "summary-output",
          h3(t("summary_title")),
          p(summary_text)
      )
    })
  })
  
  observeEvent(input$generate_text_summary_all, {
    req(full_data)
    
    # Use entire dataset
    df <- full_data
    
    # Create date range text for full dataset
    date_range_text <- if(sum(!is.na(full_data$Date)) > 0) {
      min_date <- min(full_data$Date, na.rm = TRUE)
      max_date <- max(full_data$Date, na.rm = TRUE)
      paste(format(min_date, "%B %d, %Y"), "to", format(max_date, "%B %d, %Y"))
    } else {
      ""
    }
    
    summary_text <- generate_text_summary(df, date_range_text)
    global_summary(summary_text)
    
    output$all_data_summary <- renderUI({
      div(class = "summary-output",
          h3(t("complete_summary_title")),
          p(summary_text)
      )
    })
  })
  
  # LLM Summary button handlers (placeholder functionality)
  observeEvent(input$generate_llm_summary_custom, {
    req(full_data, input$custom_date, input$custom_end_date)
    
    df <- full_data[full_data$Date >= input$custom_date & full_data$Date <= input$custom_end_date, ]
    json_data <- toJSON(df, dataframe = "rows", auto_unbox = TRUE)
    
    summary_text <- generate_llm_summary(
      json_data = json_data,
      start_date = as.character(input$custom_date),
      end_date = as.character(input$custom_end_date)
    )
    
    global_summary(summary_text)
    
    output$custom_summary <- renderUI({
      div(class = "card p-3 bg-light mt-4",
          h3("📋 Health Data Summary"),
          p(summary_text))
    })
  })
  
  
  observeEvent(input$generate_llm_summary_all, {
    req(full_data)
    
    # Use the full dataset
    df <- full_data
    
    # Convert to JSON for Python
    json_data <- toJSON(df, dataframe = "rows", auto_unbox = TRUE)
    
    # Generate summary
    summary_text <- generate_llm_summary(json_data)
    
    # Store and display it
    global_summary(summary_text)
    output$all_data_summary <- renderUI({
      div(class = "card p-3 bg-light mt-4",
          h3("📋 Health Data Summary"),
          p(summary_text))
    })
  })
  
  
  # File upload handlers
  output$file_uploaded <- reactive({
    return(!is.null(input$custom_file))
  })
  outputOptions(output, "file_uploaded", suspendWhenHidden = FALSE)
  
  observeEvent(input$custom_file, {
    req(input$custom_file)
    if(process_csv(input$custom_file$datapath)) {
      showNotification("CSV uploaded successfully!", type = "message")
    }
  })
  
  # Modern overview for All data page
  output$all_data_overview <- renderUI({
    req(full_data)
    
    if (nrow(full_data) == 0) {
      return(
        div(class = "overview-header",
            h2(t("no_data_found")),
            p("Please upload a CSV file to begin analysis.")
        )
      )
    }
    
    # Calculate overview metrics for entire dataset
    total_records <- nrow(original_data)
    valid_dates <- sum(!is.na(full_data$Date))
    
    # Date range
    date_range_text <- if(valid_dates > 0) {
      min_date <- min(full_data$Date, na.rm = TRUE)
      max_date <- max(full_data$Date, na.rm = TRUE)
      paste(format(min_date, "%m/%d/%Y"), "-", format(max_date, "%m/%d/%Y"))
    } else {
      "No valid dates found"
    }
    
    # Heart rate metrics
    avg_hr <- if(!all(is.na(full_data$hr_avg))) round(mean(full_data$hr_avg, na.rm = TRUE), 0) else "N/A"
    hr_range <- if(!all(is.na(full_data$hr_min)) && !all(is.na(full_data$hr_max))) {
      paste(round(min(full_data$hr_min, na.rm = TRUE), 0), "-", round(max(full_data$hr_max, na.rm = TRUE), 0))
    } else "N/A"
    
    # Sleep metrics
    avg_sleep <- if(!all(is.na(full_data$sleep_total))) paste(round(mean(full_data$sleep_total, na.rm = TRUE), 1), "hrs") else "N/A"
    
    # Activity count
    activity_count <- if(!all(is.na(full_data$act_cat))) length(unique(full_data$act_cat[!is.na(full_data$act_cat)])) else 0
    
    # Breathing rate
    avg_breathing <- if(!all(is.na(full_data$br_avg))) round(mean(full_data$br_avg, na.rm = TRUE), 1) else "N/A"
    
    # Data completeness
    completeness <- round((valid_dates / total_records) * 100, 1)
    
    tagList(
      div(class = "overview-header",
          h2(t("complete_analysis_title")),
          p(t("comprehensive_subtitle")),
          div(class = "date-range-badge", date_range_text)
      ),
      div(class = "overview-container",
          div(class = "overview-card",
              span(class = "card-icon", "📊"),
              div(class = "card-title", t("total_records")),
              div(class = "card-value", total_records),
              div(class = "card-subtitle", t("valid_dates_percent", completeness))
          ),
          div(class = "overview-card",
              span(class = "card-icon", "💓"),
              div(class = "card-title", t("heart_rate")),
              div(class = "card-value", avg_hr),
              div(class = "card-subtitle", if(hr_range != "N/A") t("range_bpm", hr_range) else t("average_bpm"))
          ),
          div(class = "overview-card",
              span(class = "card-icon", "😴"),
              div(class = "card-title", t("sleep_average")),
              div(class = "card-value", avg_sleep),
              div(class = "card-subtitle", t("per_night"))
          ),
          div(class = "overview-card",
              span(class = "card-icon", "🏃"),
              div(class = "card-title", t("activities")),
              div(class = "card-value", activity_count),
              div(class = "card-subtitle", t("unique_categories"))
          ),
          if(avg_breathing != "N/A") {
            div(class = "overview-card",
                span(class = "card-icon", "🫁"),
                div(class = "card-title", t("breathing_rate")),
                div(class = "card-value", avg_breathing),
                div(class = "card-subtitle", t("breaths_min"))
            )
          },
          div(class = "overview-card",
              span(class = "card-icon", "📅"),
              div(class = "card-title", t("data_span")),
              div(class = "card-value", if(valid_dates > 0) paste(as.numeric(difftime(max(full_data$Date, na.rm = TRUE), min(full_data$Date, na.rm = TRUE), units = "days")), t("total_days")) else "N/A"),
              div(class = "card-subtitle", t("total_time_period"))
          )
      )
    )
  })
  
  # Generate charts for all data
  output$all_data_charts <- renderUI({
    req(full_data)
    if(nrow(full_data) > 0) {
      HTML(generate_interactive_charts(full_data, "alldata"))
    } else {
      NULL
    }
  })
  
  # Modern overview for Custom date range
  output$custom_overview <- renderUI({
    req(input$custom_file, input$custom_date, input$custom_end_date, full_data)
    start_date <- as.Date(input$custom_date)
    end_date <- as.Date(input$custom_end_date)
    
    # Filter data
    df <- full_data[!is.na(full_data$Date) & 
                      full_data$Date >= start_date & 
                      full_data$Date <= end_date, ]
    
    if (nrow(df) == 0) {
      return(
        div(class = "overview-header",
            h2(t("no_data_found")),
            p(t("no_records_message")),
            div(class = "date-range-badge",
                paste(format(start_date, "%m/%d/%Y"), "-", format(end_date, "%m/%d/%Y"))
            )
        )
      )
    }
    
    # Calculate overview metrics
    total_records <- nrow(df)
    date_range_text <- paste(format(start_date, "%m/%d/%Y"), "-", format(end_date, "%m/%d/%Y"))
    
    # Heart rate metrics
    avg_hr <- if(!all(is.na(df$hr_avg))) round(mean(df$hr_avg, na.rm = TRUE), 0) else "N/A"
    hr_range <- if(!all(is.na(df$hr_min)) && !all(is.na(df$hr_max))) {
      paste(round(min(df$hr_min, na.rm = TRUE), 0), "-", round(max(df$hr_max, na.rm = TRUE), 0))
    } else "N/A"
    
    # Sleep metrics
    avg_sleep <- if(!all(is.na(df$sleep_total))) paste(round(mean(df$sleep_total, na.rm = TRUE), 1), "hrs") else "N/A"
    
    # Activity count
    activity_count <- if(!all(is.na(df$act_cat))) length(unique(df$act_cat[!is.na(df$act_cat)])) else 0
    
    # Breathing rate
    avg_breathing <- if(!all(is.na(df$br_avg))) round(mean(df$br_avg, na.rm = TRUE), 1) else "N/A"
    
    tagList(
      div(class = "overview-header",
          h2(t("overview_title")),
          p(t("overview_subtitle")),
          div(class = "date-range-badge", date_range_text)
      ),
      div(class = "overview-container",
          div(class = "overview-card",
              span(class = "card-icon", "📊"),
              div(class = "card-title", t("total_records")),
              div(class = "card-value", total_records),
              div(class = "card-subtitle", t("data_points"))
          ),
          div(class = "overview-card",
              span(class = "card-icon", "💓"),
              div(class = "card-title", t("heart_rate")),
              div(class = "card-value", avg_hr),
              div(class = "card-subtitle", if(hr_range != "N/A") t("range_bpm", hr_range) else t("average_bpm"))
          ),
          div(class = "overview-card",
              span(class = "card-icon", "😴"),
              div(class = "card-title", t("sleep_average")),
              div(class = "card-value", avg_sleep),
              div(class = "card-subtitle", t("per_night"))
          ),
          div(class = "overview-card",
              span(class = "card-icon", "🏃"),
              div(class = "card-title", t("activities")),
              div(class = "card-value", activity_count),
              div(class = "card-subtitle", t("unique_categories"))
          ),
          if(avg_breathing != "N/A") {
            div(class = "overview-card",
                span(class = "card-icon", "🫁"),
                div(class = "card-title", t("breathing_rate")),
                div(class = "card-value", avg_breathing),
                div(class = "card-subtitle", t("breaths_min"))
            )
          }
      )
    )
  })

  observe({
    req(input$custom_file, input$custom_date, input$custom_end_date, full_data)
    start_date <- as.Date(input$custom_date)
    end_date <- as.Date(input$custom_end_date)
    
    # Filter data
    df <- full_data[!is.na(full_data$Date) & 
                      full_data$Date >= start_date & 
                      full_data$Date <= end_date, ]
    
    output$custom_charts <- renderUI({
      if(nrow(df) > 0) {
        HTML(generate_interactive_charts(df, "custom"))
      } else {
        NULL
      }
    })
  })
  
  # Download summary PDF handler
  output$download_summary_pdf <- downloadHandler(
    filename = function() {
      paste0("health_summary_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      # Here you generate the PDF file with the summary
      # For example, you can use rmarkdown::render or other pdf generating methods
      # As a minimal example, write the summary text to a plain text PDF
      # You can replace this with your actual PDF generation code
      library(rmarkdown)
      tempReport <- tempfile(fileext = ".Rmd")
      cat(
        "---
output: pdf_document
---

# Health Data Summary

", global_summary(), file = tempReport)
      
      rmarkdown::render(
        tempReport,
        output_file = file,
        output_format = "pdf_document",
        params = list(summary_text = global_summary()),
        envir = new.env(parent = globalenv()),
        quiet = TRUE
      )
    }
  )
}

shinyApp(ui, server)
