# MSc Dissertation – Experimental Evidence

## Research Project

**Design and Performance Evaluation of a Serverless Cloud-Based Architecture for Reducing Infrastructure Cost and Improving Scalability During Peak Traffic in E-Commerce Applications**

This folder contains supporting evidence from the experimental evaluation conducted for my MSc Computer Science dissertation at York St John University. The evidence supports the performance and infrastructure cost analysis presented in Chapter 4.

## Experimental Environment

- **Cloud provider:** Amazon Web Services (AWS)
- **Region:** Europe (London), eu-west-2
- **Serverless architecture:** AWS Lambda, Amazon API Gateway and Amazon DynamoDB
- **Traditional architecture:** Amazon EC2, Application Load Balancer and Auto Scaling Group
- **Infrastructure provisioning:** Terraform
- **Load-testing tool:** Locust
- **Workload levels:** 200 and 400 concurrent users
- **Test dates:** 16 and 18 October 2026

## Experimental Results

| Architecture | Concurrent users | Total requests | Failed requests | Average response time (ms) | Throughput (RPS) |
|---|---:|---:|---:|---:|---:|
| Serverless | 200 | 365,203 | 0 | 103.84 | 405.63 |
| Traditional | 200 | 90,017 | 0 | 1,578.50 | 99.99 |
| Serverless | 400 | 263,909 | 0 | 410.44 | 439.07 |
| Traditional | 400 | 75,733 | 709 | 2,580.60 | 126.12 |

*Source: Locust workload testing reports, October 2026.*

## Experimental Evidence and Reports

The evidence is organised into folders corresponding to the four workload experiments.

| Experiment | Test date | Evidence folder |
|---|---|---|
| Serverless – 200 users | 18 October 2026 | [View evidence](serverless-200-users-2026-10-18/) |
| Traditional – 200 users | 18 October 2026 | [View evidence](traditional-200-users-2026-10-18/) |
| Serverless – 400 users | 16 October 2026 | [View evidence](Serverless-400-users-2026-10-16/) |
| Traditional – 400 users | 16 October 2026 | [View evidence](traditional-400-users-2026-10-16/) |

Each folder contains the available experimental records, including Locust HTML reports, CSV exports, performance screenshots and AWS monitoring evidence.

**PDF copies of all four Locust reports have been uploaded to GitHub** to make the experimental results easier to examine. These PDFs contain the available request statistics, response-time measurements and performance graphs.

### How to View the Reports

1. Select the relevant experimental folder using the links above.
2. Open the PDF file to view the Locust report directly on GitHub.
3. For additional examination, download the original HTML report and open it in a web browser.
4. Consult the available CSV exports for the underlying numerical results.

The PDF reports are provided for convenient viewing, while the original HTML and CSV files are retained as supporting experimental records.

## Infrastructure Cost Evidence

The [aws-cost-explorer](aws-cost-explorer/) folder contains AWS Cost Explorer billing exports used for the infrastructure cost evaluation.

The billing analysis considered architecture-specific service charges and identified shared or unattributed expenditure.

Although the serverless architecture incurred higher recorded architecture-specific charges, it processed substantially more requests during the experiments. An exploratory cost-per-request comparison was therefore included in Chapter 4.

**Cost evaluation limitation:** AWS Cost Explorer records cover full calendar days rather than individual Locust testing periods. Consequently, the estimated cost per request should not be interpreted as a precise measurement of the cost of each experiment.

## Reproducibility and Limitations

Terraform was used to provision the experimental infrastructure in the AWS London region. The resources were destroyed after testing to avoid unnecessary infrastructure charges.

The Terraform configuration, application code and load-testing scripts are maintained in the main project repository.

The archived evidence provides a record of the experimental results. Reproducing the experiments would require redeploying the infrastructure and executing the workload tests under comparable conditions.

The findings apply to the configurations and workload levels evaluated in this study and should not be interpreted as universal performance or cost guarantees.

## Academic Reference

This evidence archive supports the experimental results presented in **Chapter 4 – Results and Evaluation** of the MSc dissertation.

The dissertation report provides the detailed research methodology, experimental analysis, interpretation of findings and conclusions.
