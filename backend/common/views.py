"""
FactoryOS AI — Health Check and System Status View
"""
import time
from datetime import datetime, timezone
from django.db import connection
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from drf_spectacular.utils import extend_schema, OpenApiResponse

class HealthCheckView(APIView):
    """
    Health check endpoint for container probes and Flutter frontend connectivity tracking.
    """
    permission_classes = []

    @extend_schema(
        summary="System and Database Health Check",
        description="Returns system status, database connectivity, environment mode and timestamp.",
        responses={
            200: OpenApiResponse(description="System and PostgreSQL are operational"),
            503: OpenApiResponse(description="PostgreSQL or system services are degraded"),
        },
    )
    def get(self, request):
        start_time = time.time()
        db_healthy = False
        db_latency_ms = None
        db_vendor = getattr(connection, 'vendor', 'unknown')
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1;")
                cursor.fetchone()
            db_healthy = True
            db_latency_ms = round((time.time() - start_time) * 1000, 2)
            db_details = f"{db_vendor.capitalize()} connection active"
        except Exception as e:
            db_healthy = False
            db_details = str(e)

        overall_status = "healthy" if db_healthy else "degraded"
        http_status = status.HTTP_200_OK if db_healthy else status.HTTP_503_SERVICE_UNAVAILABLE

        payload = {
            "success": db_healthy,
            "status": overall_status,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "services": {
                "database": {
                    "engine": db_vendor,
                    "connected": db_healthy,
                    "latency_ms": db_latency_ms,
                    "details": db_details,
                },
                "api": {
                    "version": "1.0.0 (Phase 1)",
                    "mode": "development",
                    "auth_required": False,
                },
            },
        }

        return Response(payload, status=http_status)
