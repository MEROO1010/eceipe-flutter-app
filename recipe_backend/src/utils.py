from flask import jsonify


def success(data=None, message="Operation successful", status=200):
    return jsonify({"success": True, "data": data, "message": message}), status


def error(error_text, message=None, status=400):
    return (
        jsonify(
            {
                "success": False,
                "error": error_text,
                "message": message or error_text,
            }
        ),
        status,
    )
