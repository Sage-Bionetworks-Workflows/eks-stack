# This script is intended to be used to convert a Trivy report
# (other than VulnerabilityAssessmentReports) into a CSV.


import yaml
import csv
import sys


def yaml_to_csv(input_file, output_file):
    with open(input_file, "r") as file:
        data = yaml.safe_load(file)

    results = []
    for item in data["items"]:
        metadata = item["metadata"]
        report = item.get("report", {})
        annotations = metadata.get("annotations", {})
        labels = metadata.get("labels", {})

        namespace = metadata.get("namespace", "Unknown")
        if not namespace:
            namespace = labels.get("trivy-operator.resource.namespace", "Unknown")

        resource_name = annotations.get("trivy-operator.resource.name")
        if not resource_name:
            resource_name = labels.get("trivy-operator.resource.name", "Unknown")

        resource_kind = labels.get("trivy-operator.resource.kind", "Unknown")

        # If there are no checks, add a single row with summary information
        if not report.get("checks"):
            summary = report.get("summary", {})
            results.append(
                {
                    "Namespace": namespace,
                    "ResourceName": resource_name,
                    "ResourceKind": resource_kind,
                    "CheckID": "",
                    "Severity": "",
                    "Title": "",
                    "Description": "",
                    "Remediation": "",
                    "Success": "",
                    "CriticalCount": summary.get("criticalCount", 0),
                    "HighCount": summary.get("highCount", 0),
                    "MediumCount": summary.get("mediumCount", 0),
                    "LowCount": summary.get("lowCount", 0),
                }
            )
        else:
            for check in report.get("checks", []):
                results.append(
                    {
                        "Namespace": namespace,
                        "ResourceName": resource_name,
                        "ResourceKind": resource_kind,
                        "CheckID": check.get("checkID", ""),
                        "Severity": check.get("severity", ""),
                        "Title": check.get("title", ""),
                        "Description": check.get("description", ""),
                        "Remediation": check.get("remediation", ""),
                        "Success": check.get("success", ""),
                        "CriticalCount": report["summary"].get("criticalCount", 0),
                        "HighCount": report["summary"].get("highCount", 0),
                        "MediumCount": report["summary"].get("mediumCount", 0),
                        "LowCount": report["summary"].get("lowCount", 0),
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
