from openai import OpenAI
import pandas as pd
import re

client = OpenAI(api_key="enter api key here: sk----")

def generate_llm_summary(json_data: str, start_date: str, end_date: str, date_column: str = "date") -> str:
    """
    Generate a caregiver-friendly summary from health data JSON between given dates.
    Includes basic de-identification before sending to LLM.
    """

    # Load JSON data into DataFrame
    df = pd.read_json(json_data)

    # Ensure date column is datetime type
    df[date_column] = pd.to_datetime(df[date_column])

    # Filter dataframe for the requested date range (inclusive)
    mask = (df[date_column] >= pd.to_datetime(start_date)) & (df[date_column] <= pd.to_datetime(end_date))
    filtered_df = df.loc[mask]

    if filtered_df.empty:
        return f"No data found between {start_date} and {end_date}. Please check the date range or data."

    # -------- De-identification Section --------
    # Drop known PII columns if present
    pii_columns = ['name', 'address', 'location', 'caregiver_name', 'email', 'phone']
    for col in pii_columns:
        if col in filtered_df.columns:
            filtered_df[col] = '[REDACTED]'

    # Redact likely names in free-text columns (e.g., 'notes') using basic regex
    def redact_names(text):
        if isinstance(text, str):
            return re.sub(r'\b[A-Z][a-z]+\b', '[REDACTED]', text)
        return text

    text_cols = ['notes', 'observations', 'comments']
    for col in text_cols:
        if col in filtered_df.columns:
            filtered_df[col] = filtered_df[col].apply(redact_names)
    # -------------------------------------------

    # Convert filtered data to string for prompt (limit to 20 rows to avoid token overload)
    data_sample = filtered_df.head(20).to_string(index=False)

    prompt = f"""
Summarize the following caregiver health data between {start_date} and {end_date} in clear, caregiver-friendly language (6th–8th grade level).  
Focus on important trends, anomalies, and suggestions to support caregiving.

Data:
{data_sample}
"""

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a helpful assistant generating medical summaries for caregivers."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        max_tokens=300
    )

    return response.choices[0].message.content.strip()
