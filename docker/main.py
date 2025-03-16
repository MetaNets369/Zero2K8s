from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Union  # Python 3.9 compatibility fix

app = FastAPI(title="Zero2K8s Central Orchestration Platform (COP)", version="1.0")

# Mock MCP classes for testing
class MockMCPServer:
    def handle_request(self, data):
        return {"response": "Mock MCP handshake successful", "data": data}

    def get_resource(self, resource_id):
        resources = {"minikube_status": {"data": {"status": "running", "version": "1.32.0"}, "status": "success"}}
        return resources.get(resource_id)

    def invoke_tool(self, tool_id, data):
        if tool_id == "minikube_cmd":
            return {"output": f"Executed: {data['command']}", "status": "success"}
        return None

    def get_prompt(self, prompt_id):
        prompts = {
            "monitoring_workflow": {
                "steps": ["scrape_metrics", "log_data"],
                "description": "Monitor system metrics"
            }
        }
        return prompts.get(prompt_id)

mcp_server = MockMCPServer()

# Pydantic Models
class ResourceResponse(BaseModel):
    data: dict
    status: str = "success"

class ToolRequest(BaseModel):
    command: str
    params: Union[dict, None] = None  # Python 3.9 syntax

@app.get("/metrics")
async def metrics():
    return {"status": "up", "version": "1.0"}

@app.post("/mcp/handshake")
async def mcp_handshake(data: dict):
    response = mcp_server.handle_request(data)
    if not response:
        raise HTTPException(status_code=400, detail="Invalid MCP handshake")
    return response

@app.get("/mcp/resource/{resource_id}")
async def get_resource(resource_id: str):
    resource = mcp_server.get_resource(resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    return resource

@app.post("/mcp/tool/{tool_id}")
async def invoke_tool(tool_id: str, request: ToolRequest):
    result = mcp_server.invoke_tool(tool_id, request.dict())
    if not result:
        raise HTTPException(status_code=404, detail="Tool not found")
    return result

@app.get("/mcp/prompt/{prompt_id}")
async def get_prompt(prompt_id: str):
    prompt = mcp_server.get_prompt(prompt_id)
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt not found")
    return prompt

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)