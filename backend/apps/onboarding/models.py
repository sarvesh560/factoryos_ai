"""
FactoryOS AI — Onboarding Session & Draft Models
Phase 2: Universal Manufacturing Onboarding
"""
import uuid
from django.db import models

class DraftStatus(models.TextChoices):
    DRAFT = "DRAFT", "Draft In Progress"
    ACTIVATED = "ACTIVATED", "Activated into Production"

class OnboardingDraft(models.Model):
    """
    Persisted wizard state allowing users to save, resume, and modify onboarding sessions
    before performing atomic production activation.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, help_text="Proposed Factory or Project Name")
    status = models.CharField(
        max_length=50,
        choices=DraftStatus.choices,
        default=DraftStatus.DRAFT,
    )
    current_step = models.PositiveIntegerField(default=1, help_text="Last active wizard step (1-8)")
    ai_prompt = models.TextField(blank=True, default="", help_text="Natural language description provided to AI Advisor")
    ai_suggestions = models.JSONField(default=dict, blank=True, help_text="Last generated AI suggestions")
    wizard_data = models.JSONField(
        default=dict,
        blank=True,
        help_text="Complete structured state across all 8 wizard steps",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]
        verbose_name = "Onboarding Draft"
        verbose_name_plural = "Onboarding Drafts"

    def __str__(self):
        return f"{self.name} (Step {self.current_step} - {self.status})"
