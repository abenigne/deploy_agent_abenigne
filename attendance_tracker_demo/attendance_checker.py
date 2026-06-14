import json
import csv

with open("Helpers/config.json") as f:
    config = json.load(f)

WARNING = config["warning_threshold"]
FAILURE = config["failure_threshold"]

with open("Helpers/assets.csv") as f:
    reader = csv.DictReader(f)
    for row in reader:
        attended = int(row["classes_attended"])
        total = int(row["total_classes"])
        pct = (attended / total) * 100
        if pct < FAILURE:
            status = "FAIL"
        elif pct < WARNING:
            status = "WARNING"
        else:
            status = "OK"
        print(f"{row['name']}: {pct:.1f}% - {status}")
