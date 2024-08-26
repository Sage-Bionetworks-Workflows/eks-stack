# This script is intended to be used to convert a Trivy Vulnerabilities report into a CSV.

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
