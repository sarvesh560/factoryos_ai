"""
FactoryOS AI — URL Configuration
Phase 1: Production-Grade Foundation
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)
from common.views import HealthCheckView

urlpatterns = [
    path("admin/", admin.site.urls),
    # System Health Check
    path("api/health/", HealthCheckView.as_view(), name="health-check"),
    # OpenAPI Schema and Interactive Documentation
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "api/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
    # Business Modules
    path("api/companies/", include("apps.factories.company_urls")),
    path("api/factories/", include("apps.factories.urls")),
    path("api/onboarding/", include("apps.onboarding.urls")),
    path("api/processes/", include("apps.processes.urls")),
    path("api/automation/", include("apps.agent_automation.urls")),
]
