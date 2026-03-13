import os
from dotenv import load_dotenv
from fastapi import FastAPI, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

load_dotenv()

app = FastAPI()
templates = Jinja2Templates(directory="app/templates")


def get_dynamic_string():
    value = os.getenv("DYNAMIC_STRING")
    if not value:
        raise RuntimeError("DYNAMIC_STRING is not set. Add it to your .env file.")
    return value


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
        "index.html", {"request": request, "dynamic_string": current_value}
    )
