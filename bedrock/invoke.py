"""Invokes the NF bedrock agent"""
import json
import uuid

import boto3
from botocore.exceptions import ClientError


def invoke_agent(agents_runtime_client, agent_id, agent_alias_id, session_id, prompt):
    """
    Sends a prompt for the agent to process and respond to.

    Args:
        agent_id: The unique identifier of the agent to use.
        agent_alias_id: The alias of the agent to use.
        session_id: The unique identifier of the session. Use the same value across requests
                    to continue the same conversation.
        prompt: The prompt that you want Claude to complete.

    Returns:
        Inference response from the model.
    """

    try:
        response = agents_runtime_client.invoke_agent(
            agentId=agent_id,
            agentAliasId=agent_alias_id,
            sessionId=session_id,
            inputText=prompt,
        )

        completion = ""

        for event in response.get("completion"):
            chunk = event["chunk"]
            completion = completion + chunk["bytes"].decode()

    except ClientError as e:
        print(f"Couldn't invoke agent. {e}")
        raise

    return completion


if __name__ == "__main__":
    runtime_client = boto3.client(
        service_name="bedrock-agent-runtime", region_name="us-east-1"
    )
    response = invoke_agent(
        agents_runtime_client=runtime_client,
        agent_id="7O1Q74HUYJ",
        agent_alias_id="EGWXPZWTLS",
        session_id=str(uuid.uuid1()),
        prompt="give me some observations about NF1fl/fl;Dhh-Cre"
    )
    print(json.loads(response))
