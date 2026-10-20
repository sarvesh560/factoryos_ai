"""
FactoryOS AI — Company / Organization API Routing
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
from django.urls import path
from .views import (
    CompanyListCreateView,
    CompanyDetailView,
    CompanyArchiveView,
    CompanyFactoriesView,
)

urlpatterns = [
    path("", CompanyListCreateView.as_view(), name="company-list-create"),
    path("<uuid:pk>/", CompanyDetailView.as_view(), name="company-detail"),
    path("<uuid:pk>/archive/", CompanyArchiveView.as_view(), name="company-archive"),
    path("<uuid:pk>/factories/", CompanyFactoriesView.as_view(), name="company-factories"),
]
