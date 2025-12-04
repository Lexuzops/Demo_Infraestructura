import pytest
from botocore.exceptions import ClientError
import sys, pathlib

sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
from miapp.app import app as flask_app


class FakeTable:
    def __init__(self):
        self.items = []
        self.scan_called = False
        self.put_calls = []
        self.delete_calls = []
        self.fail_scan = False
        self.fail_put = False
        self.fail_delete = False

    def scan(self):
        self.scan_called = True
        if self.fail_scan:
            raise ClientError({"Error": {"Code": "500", "Message": "boom"}}, "Scan")
        return {"Items": self.items}

    def put_item(self, Item):
        if self.fail_put:
            raise ClientError({"Error": {"Code": "500", "Message": "boom"}}, "PutItem")
        self.put_calls.append(Item)

    def delete_item(self, Key):
        if self.fail_delete:
            raise ClientError(
                {"Error": {"Code": "500", "Message": "boom"}}, "DeleteItem"
            )
        self.delete_calls.append(Key)


@pytest.fixture(autouse=True)
def setup_app(monkeypatch):
    flask_app.config.update(
        TESTING=True,
        SECRET_KEY="test-secret",
    )
    fake_table = FakeTable()
    monkeypatch.setattr("miapp.app.table", fake_table)

    # opcional: evitar depender de templates
    def fake_render(template, items):
        return f"items:{','.join([i.get('name','') for i in items])}"

    monkeypatch.setattr("miapp.app.render_template", fake_render)

    yield fake_table


@pytest.fixture
def client():
    return flask_app.test_client()


def test_index_lists_items(client, setup_app):
    setup_app.items = [{"id": "1", "name": "foo"}]
    res = client.get("/")
    assert res.status_code == 200
    assert "foo" in res.get_data(as_text=True)
    assert setup_app.scan_called


def test_index_handles_scan_error(client, setup_app):
    setup_app.fail_scan = True
    res = client.get("/")
    assert res.status_code == 200  # maneja error y sigue respondiendo
    assert setup_app.scan_called


def test_add_item_creates_record(client, setup_app):
    res = client.post("/add", data={"name": "nuevo", "description": "desc"})
    assert res.status_code == 302  # redirección
    assert len(setup_app.put_calls) == 1
    stored = setup_app.put_calls[0]
    assert stored["name"] == "nuevo"
    assert stored["description"] == "desc"
    assert "id" in stored


def test_add_item_requires_name(client, setup_app):
    res = client.post("/add", data={"name": ""})
    assert res.status_code == 302
    assert setup_app.put_calls == []


def test_delete_item_calls_ddb(client, setup_app):
    client.post("/delete/abc-123")
