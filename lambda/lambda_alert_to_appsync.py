"""AWS Lambda: IoT → AppSync createAlert mutation."""

import datetime
import json
import os

import requests

APPSYNC_URL = os.environ["APPSYNC_URL"]  # e.g. https://xxxx.appsync-api.ap-southeast-1.amazonaws.com/graphql
API_KEY = os.environ["APPSYNC_API_KEY"]  # created by Amplify (quick demo)


def handler(event, _):
    # Assume IoT Rule sends the original JSON in the SNS message body
    # Example payload structure: {"id": 1714182712345, "risk":0.72, "summary":"推擠警示", "image_url":"s3://..."}
    payload = json.loads(event["Records"][0]["Sns"]["Message"])
    if float(payload.get("risk", 0)) < 0.6:
        return {"status": "ignored"}

    mutation = """
      mutation CreateAlert($input: CreateAlertInput!) {
        createAlert(input: $input) { id }
      }
    """
    variables = {
        "input": {
            "id": payload["id"],
            "ts": now,
            "msg": payload["summary"],
            "level": payload["risk_level"],  # 1‒10
            "location": payload["gate"],  # "Gate A"
            "imgUrl": payload["image_url"],
            "resolved": False,
        }
    }
    resp = requests.post(
        APPSYNC_URL,
        json={"query": mutation, "variables": variables},
        headers={"x-api-key": API_KEY, "Content-Type": "application/json"},
        timeout=10,
    )
    resp.raise_for_status()
    return resp.json()
