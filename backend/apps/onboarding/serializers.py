"""
FactoryOS AI — Onboarding Serializers
Phase 2: Universal Manufacturing Onboarding
"""
from rest_framework import serializers
from .models import OnboardingDraft

class AISuggestionRequestSerializer(serializers.Serializer):
    prompt = serializers.CharField(
        min_length=3,
        help_text="Natural language description of your manufacturing process, products, and equipment.",
    )

class AISuggestionResponseSerializer(serializers.Serializer):
    source = serializers.CharField()
    provider_name = serializers.CharField()
    disclaimer = serializers.CharField()
    confirmation_required = serializers.BooleanField(default=True)
    original_prompt = serializers.CharField()
    recommended_configuration = serializers.DictField()

class IndustryTemplateSerializer(serializers.Serializer):
    id = serializers.CharField()
    title = serializers.CharField()
    industry_type = serializers.CharField()
    industry_custom = serializers.CharField()
    description = serializers.CharField()
    icon = serializers.CharField()
    defaults = serializers.DictField()

class OnboardingDraftSerializer(serializers.ModelSerializer):
    class Meta:
        model = OnboardingDraft
        fields = [
            "id",
            "name",
            "status",
            "current_step",
            "ai_prompt",
            "ai_suggestions",
            "wizard_data",
            "created_at",
            "updated_at",
        ]

class OnboardingActivateRequestSerializer(serializers.Serializer):
    wizard_data = serializers.DictField(
        help_text="Complete structured state containing company, factory, products, materials, stages, lines, machines, and shifts.",
    )
    draft_id = serializers.UUIDField(
        required=False,
        allow_null=True,
        help_text="Optional ID of draft to mark as ACTIVATED",
    )
