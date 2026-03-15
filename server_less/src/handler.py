import base64
import json
import logging
import os
import uuid

import boto3
import requests


logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

ssm = boto3.client("ssm")

GITHUB_API_URL = "https://api.github.com"


def lambda_handler(event, context):
    failures = []

    for record in event.get("Records", []):
        message_id = record["messageId"]

        try:
            payload = json.loads(record["body"])
            validated = validate_payload(payload)

            github_token = get_github_token()
            owner = os.environ["GITHUB_OWNER"]
            repo = os.environ["GITHUB_REPO"]
            base_branch = os.environ["GITHUB_BASE_BRANCH"]

            branch_name = build_branch_name(validated["environment"], validated["database_name"])
            file_path, file_content = build_tfvars_file(
                validated["environment"],
                validated["database_name"],
                validated["database_engine"],
            )

            session = build_github_session(github_token)

            base_sha = get_branch_sha(session, owner, repo, base_branch)
            create_branch(session, owner, repo, branch_name, base_sha)

            create_or_update_file(
                session=session,
                owner=owner,
                repo=repo,
                branch=branch_name,
                file_path=file_path,
                file_content=file_content,
                commit_message=f"Add RDS request for {validated['database_name']}",
            )

            create_pull_request(
                session=session,
                owner=owner,
                repo=repo,
                head_branch=branch_name,
                base_branch=base_branch,
                title=f"Provision {validated['environment']} DB: {validated['database_name']}",
                body=build_pr_body(validated),
            )

            logger.info(
                "Processed request successfully for database %s",
                validated["database_name"],
            )

        except Exception as exc:
            logger.exception("Failed processing message %s: %s", message_id, exc)
            failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": failures}


def validate_payload(payload):
    database_name = payload.get("database_name")
    database_engine = payload.get("database_engine")
    environment = payload.get("environment")

    if not database_name:
        raise ValueError("database_name is required")

    if environment not in ["dev", "prod"]:
        raise ValueError("environment must be dev or prod")

    engine_map = {
        "mysql": "aurora-mysql",
        "postgresql": "aurora-postgresql",
        "aurora-mysql": "aurora-mysql",
        "aurora-postgresql": "aurora-postgresql",
    }

    if database_engine not in engine_map:
        raise ValueError("database_engine must be mysql or postgresql")

    return {
        "database_name": sanitize_name(database_name),
        "database_engine": engine_map[database_engine],
        "environment": environment,
    }


def sanitize_name(name):
    cleaned = name.strip().lower().replace(" ", "-")
    cleaned = "".join(c for c in cleaned if c.isalnum() or c in "-_")

    if not cleaned:
        raise ValueError("database_name is invalid")

    return cleaned


def get_github_token():
    parameter_name = os.environ["GITHUB_TOKEN_PARAMETER_NAME"]
    response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
    return response["Parameter"]["Value"]


def build_branch_name(environment, database_name):
    suffix = uuid.uuid4().hex[:8]
    return f"rds-request/{environment}/{database_name}-{suffix}"


def build_tfvars_file(environment, database_name, database_engine):
    file_path = f"requests/{environment}/{database_name}.tfvars"

    content = f'''db_name     = "{database_name}"
environment = "{environment}"
engine      = "{database_engine}"
'''

    return file_path, content


def build_pr_body(payload):
    return f"""Automated request for RDS provisioning

- DB Name: {payload["database_name"]}
- Engine: {payload["database_engine"]}
- Environment: {payload["environment"]}
"""


def build_github_session(github_token):
    session = requests.Session()
    session.headers.update(
        {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {github_token}",
            "User-Agent": "aurora-serverless-lambda",
        }
    )
    return session


def get_branch_sha(session, owner, repo, branch_name):
    response = session.get(
        f"{GITHUB_API_URL}/repos/{owner}/{repo}/git/ref/heads/{branch_name}",
        timeout=20,
    )
    check_github_response(response, 200)
    return response.json()["object"]["sha"]


def create_branch(session, owner, repo, branch_name, sha):
    response = session.post(
        f"{GITHUB_API_URL}/repos/{owner}/{repo}/git/refs",
        json={
            "ref": f"refs/heads/{branch_name}",
            "sha": sha,
        },
        timeout=20,
    )

    if response.status_code in [201, 422]:
        return

    check_github_response(response, 201)


def create_or_update_file(session, owner, repo, branch, file_path, file_content, commit_message):
    existing_sha = None

    get_response = session.get(
        f"{GITHUB_API_URL}/repos/{owner}/{repo}/contents/{file_path}",
        params={"ref": branch},
        timeout=20,
    )

    if get_response.status_code == 200:
        existing_sha = get_response.json()["sha"]
    elif get_response.status_code != 404:
        check_github_response(get_response, 200)

    body = {
        "message": commit_message,
        "content": base64.b64encode(file_content.encode("utf-8")).decode("utf-8"),
        "branch": branch,
    }

    if existing_sha:
        body["sha"] = existing_sha

    put_response = session.put(
        f"{GITHUB_API_URL}/repos/{owner}/{repo}/contents/{file_path}",
        json=body,
        timeout=20,
    )

    if put_response.status_code not in [200, 201]:
        check_github_response(put_response, 201)


def create_pull_request(session, owner, repo, head_branch, base_branch, title, body):
    response = session.post(
        f"{GITHUB_API_URL}/repos/{owner}/{repo}/pulls",
        json={
            "title": title,
            "head": head_branch,
            "base": base_branch,
            "body": body,
        },
        timeout=20,
    )
    check_github_response(response, 201)
    return response.json()["html_url"]


def check_github_response(response, expected_status):
    if response.status_code != expected_status:
        raise RuntimeError(
            f"GitHub API error: status={response.status_code}, body={response.text}"
        )