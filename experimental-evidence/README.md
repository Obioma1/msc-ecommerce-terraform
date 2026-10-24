# MSc Dissertation – Experimental Evidence

## Research Project

Design and Performance Evaluation of a Serverless Cloud-Based Architecture for Reducing Infrastructure Cost and Improving Scalability During Peak Traffic in E-Commerce Applications.

## Experimental Environment

- Cloud provider: Amazon Web Services (AWS)
- Region: Europe (London), eu-west-2
- Load testing tool: Locust
- Workload levels: 200 and 400 concurrent users
- Architectures: Serverless and traditional EC2-based deployment

## Experimental Results

| Architecture | Users | Total requests | Failed requests |
|---|---:|---:|---:|
| Serverless | 200 | 365,203 | 0 |
| Traditional | 200 | 90,017 | 0 |
| Serverless | 400 | 263,909 | 0 |
| Traditional | 400 | 75,733 | 709 |

## Evidence

Each experimental folder contains the available Locust reports, exported statistics and AWS monitoring screenshots.

The `aws-cost-explorer` folder contains billing exports used to evaluate recorded infrastructure expenditure.

AWS billing data covers calendar days rather than individual Locust execution periods. Cost-per-request estimates should therefore be interpreted as exploratory comparisons.

## Reproducibility

Terraform configuration files are maintained in the main project repository. Experimental infrastructure was destroyed after testing to prevent unnecessary AWS charges.
