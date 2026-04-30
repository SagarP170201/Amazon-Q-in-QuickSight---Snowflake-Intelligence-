# Test Questions — XpressBees Profitability AI Agent

## Questions Tab (26 questions)

### Answerable with Single Month (Feb 2026) - 14 questions

| # | Question | VQR Added |
|---|----------|-----------|
| Q1 | What is my overall business this month? | Yes |
| Q6 | Who are my top 5 customers? Top 10? Top 20? | Yes (3 VQRs) |
| Q10 | Which customer gives me maximum load on DEL-BLR lane? | Yes |
| Q11 | What is my overall yield this month? | Yes |
| Q12 | What is the yield of my top 10 customers? Top 20? | Yes |
| Q17 | Which cost is driving the loss for the client? | Yes |
| Q18 | Which cost is driving the loss for the lane? | Yes |
| Q19 | What is the national vs regional volume comparison? | Yes |

### Needs Multi-Month Data - 12 questions

| # | Question | Data Needed |
|---|----------|-------------|
| Q2 | What was my business last month? | 2 months |
| Q3 | What was my business in the last 3 months? | 3 months |
| Q4 | What was my business this quarter? | 3 months |
| Q5 | What is my YTD business? | 12 months |
| Q7 | How many new customers have been added? | 2+ months |
| Q8 | Which customers have potential for growth? | metadata needed |
| Q9 | Who are the up/down trading customers? | 2+ months |
| Q13 | Which customer's yield dropped last month vs prior? | 2 months |
| Q14 | What is the uptrading/downtrading status yesterday? | daily granularity |
| Q15 | What is the uptrading/downtrading status last 7 days? | daily granularity |
| Q16 | What is YoY growth for top clients? | 12+ months |
| Q20-23 | How can I improve margin? What operational changes? | RCA (Cortex Search) |

## Uday Sir Tab (3 questions)

| # | Question | Status |
|---|----------|--------|
| U1 | Customers who went from negative margin to positive margin | Needs 2+ months |
| U2 | Customers who went from positive to negative margin | Needs 2+ months |
| U3 | Top 10 negative margin customers with revenue > 10 lacs | VQR Added (same as Q19 variant) |

## Mayank Sir Tab (9 questions)

| # | Question | Status |
|---|----------|--------|
| M1 | Top 20 downtrading customers (by revenue) Jan'26 vs Dec'25 | Needs 2 months |
| M2 | Top 20 uptrading customers (by revenue) Jan'26 vs Dec'25 | Needs 2 months |
| M3 | Revenue, RPK, Yield, Volume trend Apr'25 to Jan'26 | Needs 10 months |
| M4 | Top 10 customers (>10L) whose yield dropped Jan'26 vs Apr'25 | Needs 10 months |
| M5 | Trend of National vs Regional for top 10 customers | Needs 10 months |
| M6 | Top 10 negative margin customers (>10L/month) in Jan'26 | VQR Added |
| M7 | Top 5 OD pairs contributing to negative margin per customer | VQR Added |
| M8 | Top 10 negative margin lanes in National Linehaul | VQR Added |
| M9 | Top 10 positive margin lanes in National Linehaul | VQR Added |

## Summary

| Category | Total | Answerable Now | Needs Multi-Month |
|----------|-------|----------------|-------------------|
| Questions tab | 26 | 14 | 12 |
| Uday sir tab | 3 | 1 | 2 |
| Mayank sir tab | 9 | 4 | 5 |
| **Total** | **38** | **19** | **19** |

**Note**: For all questions, recommended top 5 for single grain (client/lane) and top 3 for double grain (lane + client).
