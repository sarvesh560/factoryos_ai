"""
FactoryOS AI — Onboarding URL Routing
Phase 2: Universal Manufacturing Onboarding
"""
from django.urls import path
from .views import (
    AISuggestionView,
    IndustryTemplatesView,
    OnboardingDraftListCreateView,
    OnboardingDraftDetailView,
    OnboardingActivateView,
)

app_name = "onboarding"

urlpatterns = [
    path("ai-suggest/", AISuggestionView.as_view(), name="ai_suggest"),
    path("templates/", IndustryTemplatesView.as_view(), name="templates"),
    path("drafts/", OnboardingDraftListCreateView.as_view(), name="drafts_list_create"),
    path("drafts/<uuid:pk>/", OnboardingDraftDetailView.as_view(), name="draft_detail"),
    path("activate/", OnboardingActivateView.as_view(), name="activate"),
]
