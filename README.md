# Financial-Fraud-Detection
### My capstone project for Fullstack Academy's Data Analysis program. Analyzes ~100MB credit card transaction data for fraud patterns using Jupyter Notebook (Python preprocessing, MySQL batch insertion), SQL scripts, Tableau dashboard, and Excel files.

This repository is my capstone project for my Data Analysis program at Fullstack Academy. The dataset contained 389,002 credit card transactions across 23 features,, including timestamps, amounts, categories, demographics, and fraud labels. My analytical process included data importation, significant and rigorous data preprocessing, querying in MySQL, and dynamic visualizatins in Tableau Public. 

Below, I will detail the process that I took and the key insights I derived during this process.

#### Initial Attempt and the Large Dataset Challenge
I started this process by opening the cc_fraud_data.csv file in Excel as there were tasks that I needed to accomplish in Excel first for my Capstone project. As soon as I started with the dataset, I realized that there were issues with the timestamped data (specifically the trans_date_trans_time column and the dob column. The issue was that the these columns were in mixed formats (e.g., 09-06-2025 01:05 as DD-MM-YYYY HH:MM, 06/09/2025 01:05 as MM/DD/YYYY HH:MM). The issue was that I could not analyze the data becuase of the mixed formatting. I attempted to fix this issue in Excel, however I was unable to do this properly chiefly because the program was freezing and could not process my requests. This also happened with simple filtering, which I quickly assumed was due to the large size of the file. The sorting of the time-date columns was also difficult because I could not clearly identify or distinguish a pattern with the timestamps. Some indiviauls in my cohort at Fullstack were having similar issues, and our instructors offered a smaller 60,000 row dataset, however, one of the biggest reasons I selected this Capstone project was due to the size of the dataset. I decided that I would find a solution to my problem and would teach me something. I will note, that I had absolutely no idea what I was getting myself into but I was committed to figuring it out. 

#### Failed MySQL Import: Workbench Limitations
I figured, if Excel would not work - I could use MySQL Workbench, which I needed to use anyway for the Capstone, to process and clean the data. In our program we learned that we could import datasets using commands and the Table Import Wizard, and that is exactly what I proceeded to do. I created a transactions table in a 'finance' database. The import was slow, extremely slow, and I woke up the next morning and found that the Workbench has crashed. No luck. This setback echoed the limitations with Excel, and I recalled early lectures on Python's ability to handle large datasets, so I shifted my approach to a Python and started looking at ways to clean and import the data efficiently. 

#### Data Import and Preprocessing in Python 
Loading the data into Python was a breeze - no difficulty there. I immediately was able to see the dataset, view the features, and was able to confirm that there were no missing values in the dataset. So my attention immediately shifted to the timedate columns. I inspected the trans_date_trans_time column, and found these two mixed formats: DD-MM-YYYY HH:MM and MM/DD/YYYY HH:MM. My first inclination was to use the 'pd.to_datetime' command which produced a solution that worked for half the rows, the other half produced NaT errors. So I referred to the documentation - and realized that I was going to need a function to parse both formats. 

```python    
def convert_date_format(date_str):
    try:
        parsed_date = pd.to_datetime(date_str, format='%m/%d/%Y %H:%M', errors='coerce')
        if pd.notna(parsed_date):
            return parsed_date.strftime('%d-%m-%Y %H:%M')

        parsed_date = pd.to_datetime(date_str, format='%d-%m-%Y %H:%M', errors='coerce')
        if pd.notna(parsed_date):
            return parsed_date.strftime('%d-%m-%Y %H:%M')

    except Exception:
        return date_str
```
I applied this function, and was successfully able to standardize the column data to DD-MM-YYYY HH:MM, then I converted to MM-DD-YYYY HH:MM.

```python
df['trans_date_trans_time'] = pd.to_datetime(df['trans_date_trans_time'], format = '%d-%m-%Y %H:%M').dt.strftime('%m-%d-%Y %H:%M')
```
And confirmed that this worked. Success! I then renamed the column to trans_datetime for simplicity.

I attempted to use the same process for the 'dob' column but could not as it did not include the HH:MM portion, so I created another function and followed the same process.


```python
def convert_date_format_only(date_str):
    try:
        parsed_date = pd.to_datetime(date_str, format='%m/%d/%Y', errors='coerce')
        if pd.notna(parsed_date):                             
            return parsed_date.strftime('%d-%m-%Y')

        parsed_date = pd.to_datetime(date_str, format='%d-%m-%Y', errors='coerce')
        if pd.notna(parsed_date):
            return parsed_date.strftime('%d-%m-%Y')  

    except Exception:
        return date_str
```


After confirming that this formatting process was successfully completed, I confirmed there no missing values and admittedly was extremely excited for this first win. The next challenge: creating a connection with MySQL. 

#### MySQL Export - 'If Only It Would Export'
I retruned to MySQL and created a database named 'finance_alpha' and designed a transactions table with a scheme to match the datasets 23 columns. 

```sql
CREATE TABLE transactions (
    `index` INT,
    trans_datetime DATETIME,
    cc_num VARCHAR(20),
    merchant VARCHAR(75),
    category VARCHAR(50),
    amt DECIMAL(10,2),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1),
    street VARCHAR(100),
    city VARCHAR(100),
    state CHAR(2),
    zip INT,
    lat DECIMAL(9,6),
    `long` DECIMAL(9,6),
    city_pop INT,
    job VARCHAR(100),
    dob DATE,
    trans_num VARCHAR(50),
    unix_time INT,
    merch_lat DECIMAL(9,6),
    merch_long DECIMAL(9,6),
    is_fraud INT,
    PRIMARY KEY (`index`)
);
```
Then the process of researching and creating a connection between my Python script and MySQL Workbench. Now, this process was also entirely new to me and required research, trial-and-error (emphasis on trial-and-error...) as this for me was entirely uncharted territory. 

I was able to create a connection and insert the data into the transactions table. The initial attempts involved a row-by-row insertion method, which was incredibly time consuming and was both timing out on MySQL and the kernal in the Jupyter Notebook. There had to be a solution, and stumbled my way into batch processing. This process essentially instructed Python to send packets of data in batches to MySQL. I did not know what row quantity was considered large or small - so I arbitrarily assigned the value to be 10000 rows at a time, and the function I wrote would return any batches that were not successfully connected. 390,002 divided by 10000, or about 40 batches total. This did work, partially, however MySQL was timing out. So I researched, and found I could increase the timeout and packet limits in MySQL and reran the Python script. 

```sql
SET GLOBAL max_allowed_packet = 1073741824;
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
```

```python
df['trans_datetime'] = pd.to_datetime(df['trans_datetime'], format='%m-%d-%Y %H:%M')
df['dob'] = pd.to_datetime(df['dob'], format='%m-%d-%Y').dt.date

connection = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='Washington1776!',
    database='finance_alpha'
)

if connection.is_connected():
    print('Connection Established')

cursor = connection.cursor()

sql = """
INSERT INTO transactions (
    `index`, trans_datetime, cc_num, merchant, category, amt,
    first_name, last_name, gender, street, city, state, zip, lat,
    `long`, city_pop, job, dob, trans_num, unix_time,
    merch_lat, merch_long, is_fraud
) VALUES (
    %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s,
    %s, %s, %s
)
"""
batch_size = 10000
error_batches = []

for i in range(0, len(df), batch_size):
    batch = df.iloc[i:i + batch_size]
    data = [tuple(row) for row in batch.itertuples(index=False)]

    connection.ping(reconnect=True)
    try:
        cursor.executemany(sql, data)
        connection.commit()
    except mysql.connector.Error as err:
        error_batches.append((i, i + batch_size))
        print(f"Error in batch {i} to {i + batch_size}: {err}")

cursor.close()
connection.close()

if error_batches:
    print(f" Batches Failed: {error_batches}")
else:
    print('Upload Successful')
```
To my absolute amazement, this not only worked - it returned no errors and completed this process in less than a minute. 

#### Analysis
Analysis was completed in both Python and in Tableau. Linked visuals can be found within the repository and Jupyter Notebook.  

https://public.tableau.com/views/Fraud_Detection_17461454514820/FraudDetectionDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

### EDA Insights
1) Fraud in this dataset was actually rare, approximately 1% of the transactions.
2) There are categorical risks associated with fraud, particularly with online shopping (1.63%), misc_net (1.5%) and at the grocery store (1.4%). This would be something that could be addressed by creating better security protocols for online shopping.
3) There were greater amounts of fraudulent activity in January, February, and March. 
4) The data suggested greater amounts of fraudelent activity in Rhode Island and Alaska - although bias may exist due to population and number of transactions. 
