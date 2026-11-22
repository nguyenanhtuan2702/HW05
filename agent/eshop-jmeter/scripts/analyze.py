"""Summarize JMeter CSV JTL with the dashboard's default P95 convention."""
import argparse
import csv
from collections import defaultdict
from math import floor
from pathlib import Path


def p95(values):
    values = sorted(values)
    rank = min(len(values) - 1, max(0, .95 * (len(values) + 1) - 1))
    index = floor(rank)
    return values[index] + (rank - index) * (values[min(index + 1, len(values)-1)] - values[index])


def summarize(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        fields = {"label", "timeStamp", "elapsed", "success"}
        if not fields.issubset(reader.fieldnames or []):
            raise ValueError("Expected CSV JTL with label, timeStamp, elapsed, success.")
        rows = list(reader)
    if not rows:
        raise ValueError("Empty JTL.")
    groups = defaultdict(list)
    for row in rows:
        groups[row["label"]].append(row)
    span_ms = max(int(r["timeStamp"]) + int(r["elapsed"]) for r in rows) - min(int(r["timeStamp"]) for r in rows)
    lines = ["# JMeter results", "", f"Source: {path.name}", "",
             "| Sampler | Samples | Errors | P95 (ms) | Max (ms) |",
             "|---|---:|---:|---:|---:|"]
    for label, samples in [*groups.items(), ("Total", rows)]:
        elapsed = [int(r["elapsed"]) for r in samples]
        errors = sum(r["success"].lower() != "true" for r in samples)
        lines.append(f"| {label} | {len(samples)} | {errors} | {p95(elapsed):.2f} | {max(elapsed)} |")
    if span_ms > 0:
        lines.extend(["", f"Throughput: {len(rows)*1000/span_ms:.2f} requests/s."])
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("jtl", type=Path)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    report = summarize(args.jtl)
    if args.out:
        args.out.write_text(report, encoding="utf-8")
    print(report)
