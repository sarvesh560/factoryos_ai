"""
FactoryOS AI — Factory API Routing
Phase 2: Universal Manufacturing Onboarding & Multi-Tenant Management
"""
from django.urls import path
from .views import (
    FactoryListView,
    FactoryDetailView,
    FactoryArchiveView,
    FactoryOverviewView,
    FactoryProductListView,
)

urlpatterns = [
    path("", FactoryListView.as_view(), name="factory-list"),
    path("<uuid:pk>/", FactoryDetailView.as_view(), name="factory-detail"),
    path("<uuid:pk>/archive/", FactoryArchiveView.as_view(), name="factory-archive"),
    path("<uuid:pk>/overview/", FactoryOverviewView.as_view(), name="factory-overview"),
    path("<uuid:pk>/products/", FactoryProductListView.as_view(), name="factory-product-list"),
]
