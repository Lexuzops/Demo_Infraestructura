import os
import uuid
from flask import Flask, render_template, request, redirect, url_for, flash
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__)

# Configuración DynamoDB (usa variables de entorno o rol de IAM en AWS)
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DDB_TABLE_NAME = os.getenv("DDB_TABLE_NAME", "Items")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = dynamodb.Table(DDB_TABLE_NAME)


@app.route("/", methods=["GET"])
def index():
    """
    Página principal:
    - Lista los ítems de DynamoDB
    - Muestra el formulario para agregar nuevos
    """
    try:
        response = table.scan()
        items = response.get("Items", [])
    except ClientError as e:
        print(f"Error al leer de DynamoDB: {e}")
        items = []
        flash("Error al cargar datos desde DynamoDB", "danger")

    return render_template("index.html", items=items)


@app.route("/add", methods=["POST"])
def add_item():
    """
    Inserta un nuevo ítem en DynamoDB
    """
    name = request.form.get("name")
    description = request.form.get("description")

    if not name:
        flash("El nombre es obligatorio", "warning")
        return redirect(url_for("index"))

    item = {
        "id": str(uuid.uuid4()),
        "name": name,
        "description": description or ""
    }

    try:
        table.put_item(Item=item)
        flash("Ítem creado correctamente", "success")
    except ClientError as e:
        print(f"Error al insertar en DynamoDB: {e}")
        flash("Error al guardar en DynamoDB", "danger")

    return redirect(url_for("index"))


@app.route("/delete/<item_id>", methods=["POST"])
def delete_item(item_id):
    """
    Elimina un ítem por id (opcional, para completar CRUD básico)
    """
    try:
        table.delete_item(Key={"id": item_id})
        flash("Ítem eliminado", "info")
    except ClientError as e:
        print(f"Error al eliminar de DynamoDB: {e}")
        flash("Error al eliminar en DynamoDB", "danger")

    return redirect(url_for("index"))


if __name__ == "__main__":
    # Para desarrollo local
    app.run(host="0.0.0.0", port=5000, debug=False)
