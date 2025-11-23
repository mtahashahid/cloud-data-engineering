**Project: Banggood Scraping & Analysis**

**Overview**:
- **Purpose**: Scrape product listings from Banggood, clean and transform the data, run Python exploratory analyses (with plots) and store table-level data in SQL for aggregated queries and insights.

**Scraping Methodology**:
- **Tools**: Selenium (Chrome webdriver) + BeautifulSoup for parsing; CSV output via Python `csv`.
- **Approach**: A list of category pages (see `URL` list in the notebook) is visited in headless Chrome. For each category the scraper:
  - loads the page with `driver.get(...)` and waits `WAIT_TIME` seconds for content to render,
  - parses the product container `ul.goodlist > li` and extracts fields via `parse_product()` (selectors for `.title`, `.price`, `.review`, `.review-text`, and `a[href]`),
  - follows pagination by locating a `.next-page` element and clicking it with JS to advance pages,
  - writes results to `raw_data.csv` (variable `OUTPUT_FILE`).

**Cleaning & Transformation Steps**:
- **Load raw CSV**: `df = pd.read_csv('./raw_data.csv')`.
- **String cleaning helper**: `clean_column(df, col, remove_strings)` removes currency symbols and thousand separators (example removes `US$`, `,`, spaces).
- **Type conversion**: Convert `price`, `rating`, and `reviews` to numeric with `pd.to_numeric(..., errors='coerce')` and drop or impute missing values where appropriate.
- **Missing values**: Ratings filled with 0 where missing (`df['rating'] = df['rating'].fillna(0)`), and rows with key nulls are dropped before analyses.
- **Derived features**:
  - `popularity = round(rating * log1p(reviews))` — a combined engagement metric;
  - `high_engagement = (reviews > 100) & (rating > 4.5)` — boolean flag for high-performing SKUs;
  - `value_score = (rating * reviews) / price` — metric for pricing competitiveness/value-per-dollar.
- **Save cleaned data**: `df.to_csv('./banggood_clean_data.csv')`.

**Python Exploratory Analyses (reproducible plots)**:
- How to regenerate: open the notebook `Banggood_project.ipynb` and run the Part 3 cells. The notebook uses `pandas`, `seaborn`, and `matplotlib`.

- **Analysis 1 — Max price product per category**:
  - Code: `idx = df.groupby('category')['price'].idxmax(); max_price_products = df.loc[idx]`
  - Purpose: Identify premium SKUs to evaluate high-ticket opportunities.

- **Analysis 2 — Price distribution per category (barplot)**:
  - Code: convert price numeric and then `sns.barplot(x='category', y='price', data=df_clean)`
  - Plot: `Price Distribution per Category` (rotate x labels for readability).

- **Analysis 3 — Rating vs Price (scatter + trendline)**:
  - Code: `sns.scatterplot(x='price', y='rating', ...)` plus `sns.regplot(..., scatter=False)`
  - Purpose: Inspect whether higher-priced products have systematically higher ratings.

- **Analysis 4 — Top reviewed product per category**:
  - Code: group by `category`, find idx of max `reviews`, plot barplot and annotate product names.
  - Plot: `Top Reviewed Product per Category` with product labels beside bars.

- **Analysis 5 — Best value product per category**:
  - Code: create `value_score` and group to find max per category; plot barplot and annotate names.
  - Purpose: Highlight SKUs with high engagement and rating relative to price.

**SQL Aggregated Insights**:
- The cleaned dataframe is written into SQL tables by category via SQLAlchemy using a connection string in the notebook (example uses `mssql+pyodbc://sa:admin1234@localhost/banggood?...`). Ensure credentials & drivers are configured before running.
- Example queries demonstrated in the notebook (and simple variants you can run):

  - Average price and rating for a category (example used `[Car Electronics]`):
    ```sql
    SELECT AVG(price) AS average_price, AVG(rating) AS average_rating
    FROM [Car Electronics];
    ```

  - Product count per category (example used `[Earbud and Headphones]`):
    ```sql
    SELECT COUNT(DISTINCT name) AS products_count
    FROM [Earbud and Headphones];
    ```

  - Top 5 products by reviews (example for Car Electronics):
    ```sql
    SELECT TOP 5 *
    FROM [Car Electronics]
    ORDER BY reviews DESC;
    ```

  - Additional useful queries:
    - Average `value_score` per category
    - Count of `high_engagement` products per category
    - 90th percentile price by category to identify premium bracket

