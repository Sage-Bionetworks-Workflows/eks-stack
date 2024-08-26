# This script is intended to be used to convert a Trivy Vulnerabilities report into a CSV.
# Using this script will require a couple of setup steps first. You will need to:
# 1. Authenticate with AWS with the credentials you are using for the appropriate AWS account that k8s is deployed to.
# ```
# export AWS_PROFILE=<my-aws-profile>
# aws sso login
# ```
# 2. Update your kube-config with eks.
# ```
# aws eks update-kubeconfig --region us-east-1 --name dpe-k8
# ```
# 3. Extract the Trivy reports that you are interested in.
# ```
# kubectl get Vulnerabilityassessmentreports -A -o yaml > vulnerability_reports.yaml
# ```
# 4. Then, you can execute this script.
# ```
# python trivy_vulnerabilities_to_csv.py vulnerability_reports.yaml vulnerability_reports.csv
# ```

import yaml
import csv
import sys


def yaml_to_csv(input_file, output_file):
    with open(input_file, "r") as file:
        data = yaml.safe_load(file)

    results = []
    for item in data["items"]:
        metadata = item["metadata"]
        report = item["report"]

        for vulnerability in report.get("vulnerabilities", []):
            results.append(
                {
                    "Namespace": metadata["namespace"],
                    "Resource": f"{metadata['labels'].get('trivy-operator.resource.kind', 'Unknown')}/{metadata['name']}",
                    "InstalledVersion": vulnerability.get("installedVersion", ""),
                    "FixedVersion": vulnerability.get("fixedVersion", ""),
                    "Severity": vulnerability.get("severity", ""),
                    "VulnerabilityID": vulnerability.get("vulnerabilityID", ""),
                    "Title": vulnerability.get("title", ""),
                    "PrimaryLink": vulnerability.get("primaryLink", ""),
                }
            )

    with open(output_file, "w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_yaml_file> <output_csv_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    yaml_to_csv(input_file, output_file)
