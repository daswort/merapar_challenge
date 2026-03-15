import os
import boto3

from fastapi import FastAPI, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from mangum import Mangum

AWS_REGION = os.getenv("AWS_REGION", "us-east-2")
TEMPLATE_DIR = os.path.join(os.path.dirname(__file__), "templates")

app = FastAPI()
templates = Jinja2Templates(directory=TEMPLATE_DIR)
ssm = boto3.client("ssm", region_name=AWS_REGION)


DEFAULT_STRING = "No dynamic string configured"


def get_dynamic_string():
    param_name = os.environ.get("PARAMETER_NAME", "/merapar/dynamic_string")
    try:
        parameter = ssm.get_parameter(Name=param_name, WithDecryption=False)
        return parameter["Parameter"]["Value"]
    except Exception:
        return DEFAULT_STRING


@app.get("/", include_in_schema=False)
async def root_redirect():
    return RedirectResponse(
        url="/dynamic-string",
        status_code=status.HTTP_307_TEMPORARY_REDIRECT,
    )


@app.get("/dynamic-string", response_class=HTMLResponse)
async def read_item(request: Request):
    current_value = get_dynamic_string()
    return templates.TemplateResponse(
        request, "index.html", {"dynamic_string": current_value}
    )


handler = Mangum(app)
