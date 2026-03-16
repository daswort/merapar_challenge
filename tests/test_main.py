from unittest.mock import patch

from fastapi.testclient import TestClient

from app.main import app, get_dynamic_string, DEFAULT_STRING


SSM_RESPONSE = {
    "Parameter": {
        "Name": "/merapar-challenge/dynamic_string",
        "Value": "Hello from tests",
        "Type": "String",
    }
}

client = TestClient(app)


@patch("app.main.ssm")
def test_get_dynamic_string_returns_value(mock_ssm):
    mock_ssm.get_parameter.return_value = SSM_RESPONSE
    result = get_dynamic_string()
    assert result == "Hello from tests"
    mock_ssm.get_parameter.assert_called_once()


@patch("app.main.ssm")
def test_get_dynamic_string_uses_parameter_name_env(mock_ssm, monkeypatch):
    monkeypatch.setenv("PARAMETER_NAME", "/custom/param")
    mock_ssm.get_parameter.return_value = SSM_RESPONSE
    get_dynamic_string()
    mock_ssm.get_parameter.assert_called_once_with(
        Name="/custom/param", WithDecryption=False
    )


@patch("app.main.ssm")
def test_get_dynamic_string_returns_default_on_ssm_failure(mock_ssm):
    mock_ssm.get_parameter.side_effect = Exception("SSM unavailable")
    result = get_dynamic_string()
    assert result == DEFAULT_STRING


@patch("app.main.get_dynamic_string", return_value="Test Value")
def test_root_redirects_to_dynamic_string(mock_fn):
    response = client.get("/", follow_redirects=False)
    assert response.status_code == 307
    assert response.headers["location"] == "/dynamic-string"


@patch("app.main.get_dynamic_string", return_value="Test Value")
def test_dynamic_string_returns_html(mock_fn):
    response = client.get("/dynamic-string")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]


@patch("app.main.get_dynamic_string", return_value="Test Value")
def test_dynamic_string_renders_value(mock_fn):
    response = client.get("/dynamic-string")
    assert "The saved string is" in response.text
    assert "Test Value" in response.text


@patch("app.main.get_dynamic_string", return_value="<script>alert(1)</script>")
def test_dynamic_string_escapes_html(mock_fn):
    response = client.get("/dynamic-string")
    assert "<script>" not in response.text
    assert "&lt;script&gt;" in response.text
