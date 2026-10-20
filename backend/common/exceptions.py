"""
FactoryOS AI — Structured Error Handling
Provides unified API error serialization and predictable error codes.
"""
from datetime import datetime, timezone
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger("factoryos.api")

def custom_exception_handler(exc, context):
    """
    Standardize all DRF exceptions and unhandled system exceptions into
    a predictable enterprise JSON structure.
    """
    response = exception_handler(exc, context)

    timestamp = datetime.now(timezone.utc).isoformat()

    if response is not None:
        status_code = response.status_code
        error_code = "API_ERROR"

        if status_code == status.HTTP_400_BAD_REQUEST:
            error_code = "VALIDATION_ERROR"
        elif status_code == status.HTTP_404_NOT_FOUND:
            error_code = "NOT_FOUND"
        elif status_code == status.HTTP_403_FORBIDDEN:
            error_code = "PERMISSION_DENIED"
        elif status_code == status.HTTP_401_UNAUTHORIZED:
            error_code = "AUTHENTICATION_FAILED"
        elif status_code == status.HTTP_405_METHOD_NOT_ALLOWED:
            error_code = "METHOD_NOT_ALLOWED"
        elif status_code >= 500:
            error_code = "INTERNAL_SERVER_ERROR"

        custom_data = {
            "success": False,
            "error": {
                "code": error_code,
                "status_code": status_code,
                "message": (
                    response.data.get("detail", "Request failed validation or processing.")
                    if isinstance(response.data, dict) and "detail" in response.data
                    else "Validation failed for request parameters."
                ),
                "details": response.data,
                "timestamp": timestamp,
            },
        }
        response.data = custom_data
        return response

    # Unhandled server exception
    logger.exception("Unhandled server exception: %s", exc)
    return Response(
        {
            "success": False,
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "message": "An unexpected internal server error occurred.",
                "details": str(exc),
                "timestamp": timestamp,
            },
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
