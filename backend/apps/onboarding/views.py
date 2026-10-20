"""
FactoryOS AI — Universal Onboarding Views & APIs
Phase 2: Universal Manufacturing Onboarding
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema, OpenApiResponse

from .models import OnboardingDraft
from .serializers import (
    AISuggestionRequestSerializer,
    AISuggestionResponseSerializer,
    IndustryTemplateSerializer,
    OnboardingDraftSerializer,
    OnboardingActivateRequestSerializer,
)
from .services.ai_service import get_ai_service
from .services.templates import get_templates
from .services.onboarding_service import OnboardingService
from apps.factories.serializers import FactoryListSerializer

class AISuggestionView(APIView):
    """
    AI-Assisted Factory Onboarding Advisor.
    Accepts natural language manufacturing descriptions and returns structured proposals
    for products, raw materials, process stages, equipment categories, and shift topologies.
    """

    @extend_schema(
        summary="AI Assisted Factory Onboarding Suggestion",
        description="Generates proposed factory hierarchy, process stages, and equipment from a natural language prompt.",
        request=AISuggestionRequestSerializer,
        responses={200: AISuggestionResponseSerializer},
    )
    def post(self, request):
        serializer = AISuggestionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        prompt = serializer.validated_data["prompt"]
        ai_service = get_ai_service()
        recommendation = ai_service.generate_recommendations(prompt)

        return Response(
            {
                "success": True,
                "data": recommendation,
            },
            status=status.HTTP_200_OK,
        )

class IndustryTemplatesView(APIView):
    """
    Retrieve pre-configured, 100% customizable templates across industrial domains.
    """

    @extend_schema(
        summary="List Industry Templates",
        description="Returns predefined starting templates across automotive, electronics, medical, food, and custom domains.",
        responses={200: IndustryTemplateSerializer(many=True)},
    )
    def get(self, request):
        templates = get_templates()
        return Response(
            {
                "success": True,
                "count": len(templates),
                "results": templates,
            },
            status=status.HTTP_200_OK,
        )

class OnboardingDraftListCreateView(APIView):
    """
    List or create saved wizard drafts for later completion.
    """

    @extend_schema(
        summary="List Onboarding Drafts",
        description="Retrieve all saved onboarding wizard drafts.",
        responses={200: OnboardingDraftSerializer(many=True)},
    )
    def get(self, request):
        drafts = OnboardingDraft.objects.all()
        serializer = OnboardingDraftSerializer(drafts, many=True)
        return Response(
            {
                "success": True,
                "count": drafts.count(),
                "results": serializer.data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Save Onboarding Draft",
        description="Save or update current onboarding wizard state.",
        request=OnboardingDraftSerializer,
        responses={201: OnboardingDraftSerializer},
    )
    def post(self, request):
        serializer = OnboardingDraftSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        draft = serializer.save()
        return Response(
            {
                "success": True,
                "data": OnboardingDraftSerializer(draft).data,
            },
            status=status.HTTP_201_CREATED,
        )

class OnboardingDraftDetailView(APIView):
    """
    Retrieve, update, or delete a saved onboarding draft.
    """

    @extend_schema(
        summary="Get Onboarding Draft",
        description="Retrieve a specific saved onboarding draft by UUID.",
        responses={200: OnboardingDraftSerializer},
    )
    def get(self, request, pk):
        draft = get_object_or_404(OnboardingDraft, pk=pk)
        return Response(
            {
                "success": True,
                "data": OnboardingDraftSerializer(draft).data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Update Onboarding Draft",
        description="Update an existing onboarding draft.",
        request=OnboardingDraftSerializer,
        responses={200: OnboardingDraftSerializer},
    )
    def put(self, request, pk):
        draft = get_object_or_404(OnboardingDraft, pk=pk)
        serializer = OnboardingDraftSerializer(draft, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        updated = serializer.save()
        return Response(
            {
                "success": True,
                "data": OnboardingDraftSerializer(updated).data,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Delete Onboarding Draft",
        description="Delete a saved onboarding draft.",
        responses={204: OpenApiResponse(description="Draft deleted")},
    )
    def delete(self, request, pk):
        draft = get_object_or_404(OnboardingDraft, pk=pk)
        draft.delete()
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)

class OnboardingActivateView(APIView):
    """
    Atomic Production Activation.
    Validates wizard steps and creates Organization, Factory, Products, Raw Materials,
    Process Stages, Production Lines, Machines, and Operating Shifts in a single database transaction.
    """

    @extend_schema(
        summary="Activate Factory Onboarding",
        description="Atomically commits onboarding wizard configuration to production.",
        request=OnboardingActivateRequestSerializer,
        responses={201: OpenApiResponse(description="Factory activated successfully")},
    )
    def post(self, request):
        serializer = OnboardingActivateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        wizard_data = serializer.validated_data["wizard_data"]
        draft_id = serializer.validated_data.get("draft_id")

        created_factory = OnboardingService.activate_factory(
            wizard_data=wizard_data,
            draft_id=str(draft_id) if draft_id else None,
        )

        return Response(
            {
                "success": True,
                "message": f"Factory '{created_factory.name}' successfully activated into production.",
                "data": FactoryListSerializer(created_factory).data,
            },
            status=status.HTTP_201_CREATED,
        )
